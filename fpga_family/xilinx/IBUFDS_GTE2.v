`timescale 1ns / 1ns

(* ivl_synthesis_cell *)
module IBUFDS_GTE2( output O, input I, input IB, input CEB);
	parameter DIFF_TERM = "FALSE";
	buf B1(O, I);
endmodule
