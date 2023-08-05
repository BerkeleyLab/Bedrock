`timescale 1ns / 1ns

module BUFGCE (
	output O,
	input I,
	input CE
);
	reg x=0;
	always @(posedge I) if (CE) x<=1;
	always @(negedge I) x<=0;
	buf b(O, x);
endmodule
