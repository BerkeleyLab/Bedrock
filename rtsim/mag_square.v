`timescale 1ns / 1ns

module mag_square(
	input clk,
	// IQ pair defined to start when iq is high, last exactly two cycles
	input iq,
	input signed [17:0] d_in,
	output signed [18:0] mag2_out
);
// Full scale input on both I and Q gives full-scale positive output.
// Saturation step only kicks in when I and Q are full-scale negative.

`define SAT(x,old,new) ((~|x[old:new] | &x[old:new]) ? x[new:0] : {x[old],{new{~x[old]}}})

reg signed [35:0] sqr1=0;
wire signed [18:0] sqr1s=sqr1[35:17];
reg signed [18:0] sqr2=0, sqr3=0;
reg signed [19:0] mag1=0;
reg signed [18:0] mag2=0;
always @(posedge clk) begin
	sqr1 <= d_in*d_in;
	sqr2 <= sqr1s;
	sqr3 <= sqr2;
	if (~iq) mag1 <= sqr2+sqr3+1;
	mag2 <= `SAT(mag1,19,18);
end
// mag2 must be positive!
assign mag2_out = mag2;

endmodule
