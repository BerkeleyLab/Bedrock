`timescale 1ns / 1ns

module BUFGCE (
	output O,
	input I,
	input CE
);
	// verilator lint_save
	// verilator lint_off MULTIDRIVEN
	reg x=0;
	always @(posedge I) if (CE) x<=1;
	always @(negedge I) x<=0;
	// verilator lint_restore
	buf b(O, x);
endmodule
