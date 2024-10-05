`timescale 1ns / 1ns

`include "piezo_control_auto.vh"

module piezo_control(
	input clk,
	input [35:0] sr_in,
	input sr_valid,
	output [17:0] piezo_ctl,
	output piezo_stb,
	output [6:0] sat_count,
	output signed [23:0] trace_out,
	output trace_out_gate,   // use piezo_stb for boundary
	(* external *)
	input [15:0] piezo_dc,  // external
	(* external *)
	input [19:0] sf_consts,  // external
	(* external *)
	output [2:0] sf_consts_addr,  // external
	(* external *)
	input [0:0] trace_en,  // external
	(* external *)
	output [6:0] trace_en_addr  // external address for trace_en
	//`AUTOMATIC_self
);
`undef AUTOMATIC_self

// Non-zero placeholder
// Eventually intend to use reg_mac2 or similar;
// that code takes 2K address space, and we need a bit more
// locally for interfacing (see apex2/lqg_loop1.v).

assign piezo_stb = 1;
assign piezo_ctl = {piezo_dc, 2'b0};
assign sat_count = 0;
assign trace_out = 0;
assign trace_out_gate = 0;
assign sf_consts_addr = 0;
assign trace_en_addr = 0;

endmodule
