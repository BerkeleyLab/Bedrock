`timescale 1ns / 1ns

(* ivl_synthesis_cell *)
module IBUFDS_GTE2 (
	output O,
	output ODIV2,
	input I,
	input IB,
	input CEB
);
	parameter DIFF_TERM = "FALSE";
	buf B1(O, I);

	reg x=0;
	always @(posedge I) x<=~x;
	buf B2(ODIV2, x);
endmodule
