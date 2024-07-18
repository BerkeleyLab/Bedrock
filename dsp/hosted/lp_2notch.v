`timescale 1ns / 1ns

// Combines three single (complex) pole filters into something that
// can be configured to give two notches plus low-pass.
// See lp_2notch_theory.py

`include "lp_2notch_auto.vh"

module lp_2notch(
	input clk,  // timespec 6.66 ns
	input iq,
	input signed [17:0] x,
	output signed [19:0] y,
	`AUTOMATIC_self
);

`AUTOMATIC_decode

// Note newly broken symmetry between the multiple instances!
// lp2a intended for low-pass, max bandwidth 0.47 MHz
// lp2b intended for 8pi/9 mode, max offset 1.87 MHz
// lp2c intended for 7pi/9 mode, max offset 7.50 MHz
// New instance names translate into new and obviously incompatible
// newad register names.  Permits a try/except construction
// so software can support both support old and new bitfiles.

wire signed [21:0] y1;
lp #(.shift(4)) lp2a // auto
	(.clk(clk), .iq(iq),
	.x(x), .y(y1), `AUTOMATIC_lp2a);

wire signed [19:0] y2;
lp #(.shift(2)) lp2b // auto
	(.clk(clk), .iq(iq),
	.x(x), .y(y2), `AUTOMATIC_lp2b);

wire signed [17:0] y3;
lp #(.shift(0)) lp2c // auto
	(.clk(clk), .iq(iq),
	.x(x), .y(y3), `AUTOMATIC_lp2c);

// Actually saturate sum, just in case
wire [22:0] y_sum = y1+y2+y3;
`define SAT(x,old,new) ((~|x[old:new] | &x[old:new]) ? x[new:0] : {x[old],{new{~x[old]}}})
reg [21:0] y_out=0;
always @(posedge clk) y_out <= `SAT(y_sum, 22, 21);
`undef SAT

// Very stupid extra delay, only here to keep historical I-Q relationship.
// XXX get rid of this!
reg [21:0] y_del=0;
always @(posedge clk) y_del <= y_out;
assign y = y_del[21:2];

endmodule
