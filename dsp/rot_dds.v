// Phase Rotating Direct Digital Synthesis of sin/cos
// 18 bit output coming from cordicg
// Note that phase_step_h and phase_step_l combined fit in a 32-bit word.
// This is intentional, to allow atomic updates of the two controls
// in 32-bit systems.  Indeed, when modulo==0, those 32 bits can be considered
//
// a simple fast binary DDS control for quirky (non-binary-rounding) phase
// steps like:
// 7/33 for LCLS-II
// 8/11 for SSRF
// 9/13 for Argonne RIA
//
// Synthesizes to ??? slices at ??? MHz in XC3Sxxx-4 using XST-??
//

`timescale 1ns / 1ns

module rot_dds(
	input clk,  // timespec 9.0 ns
	input reset,  // active high, synchronous with clk
	output signed [17:0] sina,
	output signed [17:0] cosa,
	input [19:0] phase_step_h,
	input [11:0] phase_step_l,
	input [11:0] modulo
);

// 2^17/1.64676 = 79594, use a smaller value to keep CORDIC round-off
// from overflowing the output
parameter lo_amp = 18'd79590;
// Sometimes we cheat and use slightly smaller values than above,
// to make other computations fit better.

wire [18:0] phase_acc;
ph_acc ph_acc_i (
  .clk(clk), .reset(reset), .en(1'b1), // input
  .phase_acc(phase_acc), // output [18:0]
  .phase_step_h(phase_step_h), // input [19:0]
  .phase_step_l(phase_step_l), // input [11:0]
  .modulo(modulo) // input [11:0]
);
// See rot_dds_config

cordicg_b22 #(.nstg(20), .width(18), .def_op(0)) trig(.clk(clk), .opin(2'b00),
	.xin(lo_amp), .yin(18'd0), .phasein(phase_acc),
// 2^17/1.64676 = 79594, use a smaller value to keep CORDIC round-off
// from overflowing the output
	.xout(cosa), .yout(sina));

endmodule
