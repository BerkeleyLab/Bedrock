// Connection to Digilent PmodGPS 541-237 R3
// Can use this as a frequency reference to calibrate on-board oscillator
module gps_test #(
	// 9600 baud at 125 MHz
	parameter cfg_divider = 20'd13021,
	parameter dw=27,
	parameter arms=24
) (
	input [3:0] gps_pins,
	input clk,
	input [9:0] lb_addr,
	output [7:0] lb_dout,
	output buf_full,
	output [13:0] buf_status,
	output [dw:0] f_read,
	output [3:0] pps_cnt
);

// Pin assignment
// these have already been moved to our clk domain
wire ser_rx  = gps_pins[2];  // PmodGPS calls this TXD
wire pps_pin = gps_pins[3];


// UART needs initialization
reg resetn=0;  always @(posedge clk) resetn <= 1;

// UART
wire [7:0] nmea_data;
wire nmea_valid;
wire tx_unused, busy_unused;
simpleuart simpleuart(
	.clk(clk),
	.resetn(resetn),
	.ser_tx(tx_unused),
	.ser_rx(ser_rx),
	.cfg_divider (cfg_divider),
	.b_we (1'b0),
	.b_re (1'b1),
	.b_di (8'b0),
	.b_do (nmea_data),
	.b_dv (nmea_valid),
	.b_busy(busy_unused)
);

// Ping-pong buffer for NMEA messages, flipping the buffer
// at the rising edge of the PPS signal.
// NMEA messages are sent in the interval between pps signals,
// both conceptually and empirically.  I've never seen one of
// those messages longer than 475 bytes, but size the buffer
// to allow for more than 512, just in case.
// Even 2 x 1024 x 8 still fits in a single 7-series block RAM.
reg [9:0] buf_waddr=0, buf_filled=0;
reg [3:0] buf_cnt=0;
wire buf_sel=buf_cnt[0];  // ping-pong
wire pps_edge;  // single-cycle, computed below
assign buf_full = &buf_waddr;
always @(posedge clk) begin
	if (nmea_valid & ~buf_full) buf_waddr <= buf_waddr+1;
	if (pps_edge) begin
		buf_waddr <= 0;
		buf_filled <= buf_waddr;
		buf_cnt <= buf_cnt+1;
	end
end
dpram #(.aw(11), .dw(8)) dpram(
	.clka(clk), .addra({buf_sel, buf_waddr}), .dina(nmea_data), .wena(nmea_valid),
	.clkb(clk), .addrb({~buf_sel, lb_addr}), .doutb(lb_dout));
assign buf_status = {buf_cnt, buf_filled};  // 4 bits + 10 bits = 14 bits
// Rule is that if buf_cnt changes while you read the buffer,
// the data is corrupted and must be discarded (in software).

// At least 27-bit frequency counter
// Has to register a little more than 125M
// Counters are dw wide; an overflow bit is included
// in f_read, making it dw+1 wide.
reg pps_pin_r=0, pps_tick=0, pps_arm=0;
reg [dw-1:0] f_count=0, f_read_r=0;
wire [dw:0] f_count1 = f_count + 1;
reg f_count_ovf=0, f_read_ovf=0;
reg [3:0] pps_cnt_r=0;
always @(posedge clk) begin
	pps_pin_r <= pps_pin;
	pps_tick <= pps_pin & ~pps_pin_r & pps_arm;  // positive edge detect
	f_count <= f_count1;
	f_count_ovf <= f_count_ovf | f_count1[dw];
	// Convention is that pps signals are high for 100 ms
	if (f_count[arms]) pps_arm <= 1;  // arms=24: re-arm 134 ms after trigger
	if (pps_tick) begin
		f_count <= 0;
		f_count_ovf <= 0;
		pps_arm <= 0;
		f_read_r <= f_count;
		f_read_ovf <= f_count_ovf;
		pps_cnt_r <= pps_cnt_r + 1;
	end
end
assign f_read = {f_read_ovf, f_read_r};
assign pps_cnt = pps_cnt_r;
assign pps_edge = pps_tick;

endmodule
