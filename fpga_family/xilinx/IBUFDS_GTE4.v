`timescale 1ns / 1ns

(* ivl_synthesis_cell *)
module IBUFDS_GTE4(
    input I,
    input IB,
    input CEB,
    output O,
    output ODIV2
);
	parameter DIFF_TERM = "FALSE";
	buf B1(O, I);

	reg x=0;
	always @(posedge I) x<=~x;
	buf B2(ODIV2, x);

endmodule
