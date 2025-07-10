// A gap detector for timing transmissions from the MAC.
// The `scanner` module looks ahead for a suitable gap in the packet badger
// data stream. Once found it indicates to the MAC, downstream of the
// ring-buffer, that its TX - packet can now be multiplexed onto the stream.

module precog #(
	// packet address width, 11 IRL
	parameter PAW=11,
	// latency from beginning of detected gap to `clear_to_send` going high
	parameter LATENCY=11
) (
	input clk,
	input ce,  // Clock enable strobe for slower line rates
	// during a gap of N cycles, `scanner_busy` goes low for N cycles
	input scanner_busy,
	// Minimum width of the gap. tx_packet_width must be <= LATENCY - 2
	input [PAW-1:0] tx_packet_width,
	// pulse to latch `tx_packet_width` and start searching for a gap
	input request_to_send,
	// Rising edge: `LATENCY` cycles after the beginning of the detected gap
	// Falling edge: `tx_packet_width` cycles after the rising edge
	output reg clear_to_send
);

initial clear_to_send = 0;
reg [PAW-1:0] gap_width = 0;
reg [PAW-1:0] tx_packet_width_l = 0;
reg [   11:0] delay_cnt = 0;
reg [    1:0] state = 0;
wire is_gap = gap_width >= tx_packet_width_l;
localparam ST_WAIT_RTS = 0;
localparam ST_WAIT_GAP = 1;
localparam ST_WAIT_RISING = 2;
localparam ST_WAIT_FALLING = 3;

always @(posedge clk) begin
	clear_to_send <= 0;
	if (gap_width < 2^PAW - 1)
		gap_width <= scanner_busy ? 0 : gap_width + 1;
	case (state)
		ST_WAIT_RTS: begin
			tx_packet_width_l <= tx_packet_width;
			if (request_to_send)
				state <= ST_WAIT_GAP;
		end

		ST_WAIT_GAP: begin
			delay_cnt <= 0;
			if (is_gap)
				state <= ST_WAIT_RISING;
		end

		ST_WAIT_RISING: begin
			delay_cnt <= delay_cnt + 1;
			if (delay_cnt >= LATENCY - tx_packet_width_l - 2) begin
				delay_cnt <= 0;
				clear_to_send <= 1;
				state <= ST_WAIT_FALLING;
			end
		end

		ST_WAIT_FALLING: begin
			delay_cnt <= delay_cnt + 1;
			if (delay_cnt >= tx_packet_width_l - 1)
				state <= ST_WAIT_RTS;
			else
				clear_to_send <= 1;
		end

		default: begin
			state <= ST_WAIT_RTS;
			gap_width <= 0;
			delay_cnt <= 0;
		end
	endcase
end

endmodule
