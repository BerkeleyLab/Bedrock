`timescale 1ns / 1ns

// Truly pathetic.  Just enough to satisfy s6_gtp_wrap.v.
(* ivl_synthesis_cell *)
module BUFIO2(output DIVCLK, input I);
	parameter DIVIDE=1;
	parameter DIVIDE_BYPASS="TRUE";
	buf B1(DIVCLK, I);
endmodule
