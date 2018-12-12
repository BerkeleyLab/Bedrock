`timescale 1ns / 1ns

// Filters and decimates four I-Q multiplexed data streams
// down to a single data path
// Uses second-order CIC filtering.
// Larry Doolittle, LBNL, 2014

module iq_chain4(
	input clk,
	input sync,
	input signed [17:0] in1,
	input signed [17:0] in2,
	input signed [17:0] in3,
	input signed [17:0] in4,
	output signed [21:0] out
);

reg sync1=0;
always @(posedge clk) sync1 <= sync;
wire samp = sync | sync1;

wire signed [21:0] o1, o2, o3, o4;
iq_double_inte #(.dwi(18), .dwo(22)) di1(.clk(clk), .in(in1), .out(o1));
iq_double_inte #(.dwi(18), .dwo(22)) di2(.clk(clk), .in(in2), .out(o2));
iq_double_inte #(.dwi(18), .dwo(22)) di3(.clk(clk), .in(in3), .out(o3));
iq_double_inte #(.dwi(18), .dwo(22)) di4(.clk(clk), .in(in4), .out(o4));

wire signed [21:0] s1, s2, s3, s4;
reg signed [21:0] c1=0, c2=0, c3=0, c4=0;
always @(posedge clk) begin
	c1 <= s2;
	c2 <= s3;
	c3 <= s4;
end

serialize #(.dwi(22)) ser1(.clk(clk), .samp(samp), .data_in(o1), .stream_in(c1), .stream_out(s1), .gate_in(1'b1));
serialize #(.dwi(22)) ser2(.clk(clk), .samp(samp), .data_in(o2), .stream_in(c2), .stream_out(s2), .gate_in(1'b1));
serialize #(.dwi(22)) ser3(.clk(clk), .samp(samp), .data_in(o3), .stream_in(c3), .stream_out(s3), .gate_in(1'b1));
serialize #(.dwi(22)) ser4(.clk(clk), .samp(samp), .data_in(o4), .stream_in(c4), .stream_out(s4), .gate_in(1'b1));

wire signed [21:0] d_out;
doublediff #(.dw(22), .dsr_len(8)) dd(.clk(clk), .d_in(s1), .g_in(1'b1), .d_out(d_out));
assign out = d_out;

endmodule
