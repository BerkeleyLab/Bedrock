module digitizer_slowread(
	// local bus -- minimize or eliminate uses
	input lb_clk,

	// 8 channels high-speed 16-bit parallel ADC data
	input adc_clk,
	input [127:0] adc_data,

	// specialized control
	input slow_snap,  // must be in adc_clk domain
	input slow_read_lb,  // -- external strobe must be in lb_clk domain

	// Items for read address map
	output [7:0] slow_chain_out,

	// Software writable registers
	input [7:0] tag_now  // --external
);

// Explode the adc_data
wire signed [15:0] U3DA = adc_data[15:0];
wire signed [15:0] U3DB = adc_data[31:16];
wire signed [15:0] U3DC = adc_data[47:32];
wire signed [15:0] U3DD = adc_data[63:48];
wire signed [15:0] U2DA = adc_data[79:64];
wire signed [15:0] U2DB = adc_data[95:80];
wire signed [15:0] U2DC = adc_data[111:96];
wire signed [15:0] U2DD = adc_data[127:112];

// Compute minmax
wire signed [15:0] U2DA_min, U2DA_max;
wire signed [15:0] U2DB_min, U2DB_max;
wire signed [15:0] U2DC_min, U2DC_max;
wire signed [15:0] U2DD_min, U2DD_max;
wire signed [15:0] U3DA_min, U3DA_max;
wire signed [15:0] U3DB_min, U3DB_max;
wire signed [15:0] U3DC_min, U3DC_max;
wire signed [15:0] U3DD_min, U3DD_max;
wire minmax_reset = slow_snap;
minmax #(16) mm1(.clk(adc_clk), .xin(U2DA), .reset(minmax_reset), .xmin(U2DA_min), .xmax(U2DA_max));
minmax #(16) mm2(.clk(adc_clk), .xin(U2DB), .reset(minmax_reset), .xmin(U2DB_min), .xmax(U2DB_max));
minmax #(16) mm3(.clk(adc_clk), .xin(U2DC), .reset(minmax_reset), .xmin(U2DC_min), .xmax(U2DC_max));
minmax #(16) mm4(.clk(adc_clk), .xin(U2DD), .reset(minmax_reset), .xmin(U2DD_min), .xmax(U2DD_max));
minmax #(16) mm5(.clk(adc_clk), .xin(U3DA), .reset(minmax_reset), .xmin(U3DA_min), .xmax(U3DA_max));
minmax #(16) mm6(.clk(adc_clk), .xin(U3DB), .reset(minmax_reset), .xmin(U3DB_min), .xmax(U3DB_max));
minmax #(16) mm7(.clk(adc_clk), .xin(U3DC), .reset(minmax_reset), .xmin(U3DC_min), .xmax(U3DC_max));
minmax #(16) mm8(.clk(adc_clk), .xin(U3DD), .reset(minmax_reset), .xmin(U3DD_min), .xmax(U3DD_max));

// Slow chain synchronized with banyan buffer
// Necessarily matches minmax_reset
// Slow chain will read out _previous_ ADC minmax values,
// and the timestamp as of the beginning of the acquisition.
// It's OK to read out the slow chain _during_ the buffer fill process.
wire slow_read_x;
flag_xdomain slow_read_xdomain  (.clk1(lb_clk), .flagin_clk1(slow_read_lb),   .clk2(adc_clk), .flagout_clk2(slow_read_x));
wire slow_op = slow_snap | slow_read_x;

// Cycle counter
wire [7:0] timestamp_out;
timestamp ts(.clk(adc_clk), .aux_trig(1'b0), .slow_op(slow_op), .slow_snap(slow_snap),
	.shift_in(8'b0), .shift_out(timestamp_out)
);

// Our share of slow readout
// tag_now and tag_old are set up for causality and consistency detection when
// changing other controls. tag_now shows the value of tag at the end-time of
// the buffer, tag_old shows it at the begin-time of the buffer.  Not perfect
// because of non-boxcar filtering and sloppy pipelining.
reg [7:0] tag_old=0;
`define SLOW_SR_LEN 17*16
`define SLOW_SR_DATA { \
	U3DA_min, U3DA_max, U3DB_min, U3DB_max, U3DC_min, U3DC_max, U3DD_min, U3DD_max, \
	U2DA_min, U2DA_max, U2DB_min, U2DB_max, U2DC_min, U2DC_max, U2DD_min, U2DD_max, \
	tag_now, tag_old }
parameter sr_length = `SLOW_SR_LEN;
reg [sr_length-1:0] slow_read=0;
always @(posedge adc_clk) if (slow_op) begin
	slow_read <= slow_snap ? `SLOW_SR_DATA : {slow_read[sr_length-9:0],timestamp_out};
	if (slow_snap) tag_old <= tag_now;
end

// Cross clock domains
// Simple because slow_read_lb is low-duty-factor
reg [7:0] slow_chain_out_r=0;
always @(posedge lb_clk) if (slow_read_lb) slow_chain_out_r <= slow_read[sr_length-1:sr_length-8];
assign slow_chain_out = slow_chain_out_r;

endmodule
