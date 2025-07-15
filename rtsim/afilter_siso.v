`define AUTOMATIC_self
`define AUTOMATIC_outer_prod
`define AUTOMATIC_resonator
`define AUTOMATIC_dot

`timescale 1ns / 1ns

`include "afilter_siso_auto.vh"

// afilter_siso: single-input single-output audio filter
// combines outer_prod, resonator, and dot_prod to make a digital filter
// with an "arbitrary" number of poles and zeros.
// The "audio" part of the description refers to the limitation
// on frequency: angular frequency in radians per step is limited
// to 1/16.  See slide7.tex.
// cav4_mech uses generate loops to produce a MIMO filter also based
// on resonator; this version is at least useful for testing and education.

// XXX core problem remaining:
//  processing doesn't stop when the filter is "finished", all the
//  counters in the submodules just wrap around.  Only deadly if
//  run_filter _doesn't_ show up more often than every 1024 cycles.
module afilter_siso #(
	parameter pcw = 10
) (
	input clk,
	input reset, // XXX unimplemented, would be nice to have the ability to force filter state to zero
	input run_filter,
	input signed [17:0] u_in,
	output signed [17:0] y_out,
	output filter_done,
	output res_clip,  // raw, not latched, warning signal that saturation happened
	`AUTOMATIC_self
);

// Create suitably timed start pulses for three submodules
wire start_out, start_res, start_dot;
reg_delay #(.dw(1), .len(3)) start_out_g(.clk(clk), .reset(1'b0), .gate(1'b1), .din(run_filter), .dout(start_out));
reg_delay #(.dw(1), .len(1)) start_res_g(.clk(clk), .reset(1'b0), .gate(1'b1), .din(run_filter), .dout(start_res));
reg_delay #(.dw(1), .len(10)) start_dot_g(.clk(clk), .reset(1'b0),  .gate(1'b1), .din(run_filter), .dout(start_dot));

// Take input detuning, expand to drive each filter
wire signed [17:0] x_drive;
(* lb_automatic *)
outer_prod #(.pcw(pcw)) outer_prod  // auto
	(.clk(clk), .start(start_out),
	.x(u_in), .result(x_drive),
	`AUTOMATIC_outer_prod
);

// Filter bank
wire signed [17:0] res_x;
(* lb_automatic *)
resonator #(.pcw(pcw)) resonator // auto
	(.clk(clk), .start(start_res),
	.drive(x_drive),
	.position(res_x), .clip(res_clip),
	`AUTOMATIC_resonator
);

// Combine bank results to get piezo drive
(* lb_automatic *)
dot_prod #(.pcw(pcw)) dot // auto
	(.clk(clk), .start(start_dot), .x(res_x),
	.result(y_out), .strobe(filter_done),
	`AUTOMATIC_dot
);

endmodule
