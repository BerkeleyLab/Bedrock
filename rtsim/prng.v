`timescale 1ns / 1ns

`include "prng_auto.vh"
// Almost useless shell around two tt880v modules
module prng(
	input clk,
	output [31:0] rnda,
	output [31:0] rndb,
	input [0:0] random_run,  // external
	input [31:0] iva,  // external plus-we
	input [31:0] ivb,  // external plus-we
	// Everything else above is robust and pretty good.
	// Minor loss in efficiency from having two 32-bit registers when zero would do.
	// The following get hacked in.
	input iva_we,  // special for above, keep a trailing _we
	input ivb_we  // special for above, keep a trailing _we

);

reg iva_strobe=0; always @(posedge clk) iva_strobe <= iva_we; wire tt800_ena = random_run | iva_strobe;
reg ivb_strobe=0; always @(posedge clk) ivb_strobe <= ivb_we; wire tt800_enb = random_run | ivb_strobe;

tt800v tt800a(.clk(clk), .en(tt800_ena), .init(iva_strobe), .initv(iva), .y(rnda));
tt800v tt800b(.clk(clk), .en(tt800_enb), .init(ivb_strobe), .initv(ivb), .y(rndb));

endmodule
