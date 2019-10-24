// 8b9b receiver based on an SDR ISERDES implementation
// First it is sync, then 8 data, if first bit is 1'b0 then another byte,
	// is present in the frame.
	// e.g.
	// 1111111 [0]XXXXXXXX [0]XXXXXXXX [1]
	// Would be a two-byte frame
	//
`timescale 1ns / 1ns

module oversampled_rx_8b9b #(
	parameter word_width=8
) (
	input clk,  // single clock domain here
	input sync_reset,
	input [3:0] int_data,
	input enable, // Enable input
	output reg [word_width-1:0] word_out, // Parallel data out
	output reg word_write,
	output reg frame_complete
);

reg int_bit=1'b0;
reg n_start_detect=0;
reg [3:0] r_int_data=4'b1111;
parameter IDLE=2'b00,ONCE=2'b01,RECEIVE=2'b10,COMMIT=2'b11;
reg [1:0] state=IDLE;
reg [1:0] int_latch_point=0, latch_point=0;
reg [word_width-1:0] int_result=0;
reg [2:0] bit_counter=0;

// int_data(0) is first to arrive, int_data(3) is last
always @(posedge clk) begin
	// Start is when the line goes low
	n_start_detect <= int_data[0]& int_data[1]&int_data[2]&int_data[3];
	// Based on the start detect point we step one cycle later in time and latch
	// there...
	int_latch_point <= ~int_data[0] ? 2'b01:
	~int_data[1] ? 2'b10:
	~int_data[2] ? 2'b11:
	2'b00;
// Retime to 'flatten' data into a single cycle as latch point "00" is a
// cycle out of time relative to the other three
r_int_data <= int_data ;
int_bit    <= latch_point==2'b00 ? int_data[0]:
	latch_point==2'b01 ? r_int_data[1]:
	latch_point==2'b10 ? r_int_data[2]:
	r_int_data[3];
end

always @(posedge clk)
begin
	if (sync_reset)  begin
		word_write <= 1'b0;
	end
	else begin
		word_write     <= 1'b0;
		frame_complete <= 1'b0;

		case (state)
			IDLE : begin// Check for start bit
				if ((enable) & (~n_start_detect)) begin
					latch_point <= int_latch_point;
					bit_counter <= $unsigned(word_width-1);//, next_highest_power_of_two(word_width));
					state       <= ONCE;
				end
			end
			ONCE: begin
				state <= RECEIVE;
			end
			RECEIVE: begin// Copy the bits into the receive register and shift// More efficient than using a counter index
				bit_counter <= bit_counter - 1;
				int_result  <= {int_bit , int_result[word_width-1:1]};
				if (bit_counter==0) begin
					state <= COMMIT;
				end
			end
			COMMIT:begin// Check to see if the frame is complete
				word_out   <= int_result;
				word_write <= 1'b1;// If the 9th bit is 1'b0 then the frame isn't complete
				bit_counter <= $unsigned(word_width-1);//, next_highest_power_of_two(word_width));
				state       <= RECEIVE;
				if (int_bit) begin
					state          <= IDLE;
					frame_complete <= 1'b1;
				end
			end
			default:
				state <= IDLE;
		endcase
	end
end
endmodule
