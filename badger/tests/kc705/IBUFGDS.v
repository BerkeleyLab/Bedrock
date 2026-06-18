`timescale 1ns / 1ns

module IBUFGDS (
	output O,
	input I,
	input IB
);
	parameter DIFF_TERM = "FALSE";
	buf B1(O, I);
endmodule
