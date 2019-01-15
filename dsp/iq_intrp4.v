`timescale 1ns / 1ns

// Pull apart and interpolate a four-way interpolated IQ stream
// into its individual components
module iq_intrp4(
	input clk,
	input sync,
	input signed [21:0] in,
	output signed [17:0] out1,
	output signed [17:0] out2,
	output signed [17:0] out3,
	output signed [17:0] out4
);

reg sync1=0;
always @(posedge clk) sync1 <= sync;
wire samp = sync | sync1;

wire signed [25:0] in_e=in;  // sign-extend four extra bits
wire signed [25:0] d_out;
doublediff #(.dw(26), .dsr_len(8)) dd(.clk(clk), .d_in(in_e), .g_in(1'b1), .d_out(d_out));

wire signed [25:0] in4 = d_out;
reg signed [25:0] in1=0, in2=0, in2_d=0, in3=0, in3_d=0, in4_d=0;
always @(posedge clk) begin
	in4_d <= in4;  in3 <= in4_d;
	in3_d <= in3;  in2 <= in3_d;
	in2_d <= in2;  in1 <= in2_d;
end

iq_inter #(.dwi(26), .dwo(18)) di1(.clk(clk), .samp(samp), .in(in1), .out(out1));
iq_inter #(.dwi(26), .dwo(18)) di2(.clk(clk), .samp(samp), .in(in2), .out(out2));
iq_inter #(.dwi(26), .dwo(18)) di3(.clk(clk), .samp(samp), .in(in3), .out(out3));
iq_inter #(.dwi(26), .dwo(18)) di4(.clk(clk), .samp(samp), .in(in4), .out(out4));

endmodule
