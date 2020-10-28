// There are MANY pi-loops among us, but none seemed to fit the ORNL cause, so here we go:
// PI Loop
//                            K_p
//                             +
//                             |
//  -Measure  +-----+          v
// +--------->+     |    +-----+-----+                                    +-----+
//            | Sum +--->+complex_mul+-+--------------------------------->+     |
// +--------->+     |    +-----------+ |                                  |     |Pi_Out
//  Setpoint  +-----+                  |                                  | SUM +------>
//                                     |    +---+      +------------+     |     |
//                                     +--->+mul+----->+ Integrator +---->+     |
//                                          +-+-+      +------------+     +-----+
//                                            ^
//                                            |
//                                            +
//                                         K_i/K_p
//
// Created with http://asciiflow.com
// DELAY: 9 cycles of delay at @clk
`timescale 1ns / 1ns

// Universal definition; note: old and new are msb numbers, not bit widths.
//  0. assert old > new
//  1. Should really be called downsize and check for saturate
//  2. if x[old:new] are all ones or zeros: then it's safe to resize the signal
//  3. Else: Rail the signal
`define SAT(x,old,new) ((~|x[old:new] | &x[old:new]) ? x[new:0] : {x[old],{new{~x[old]}}})

// TODO: Potentially parametrize input and output signal widths
//     : Rename Ref_i/q to Setpoint_i/q
module non_iq_interleaved_piloop (
	// Everything here is in one clock domain, matches ADC
	input clk,
	input feedback_enable,
	// Kp and Ki for the PI loop
	input signed [KW-1:0] Kp_I, // external
	input signed [KW-1:0] Kp_Q, // external
	input signed [KW-1:0] Ki_over_Kp,  // external
	input [3:0] post_mult_shift,
	// Reference and input
	input signed [18:0] err_i,
	input signed [18:0] err_q,

	input signed [16:0] fdfwd_i,
	input signed [16:0] fdfwd_q,
	input integrator_gate,
	input integrator_reset,

	output reg signed [17:0] pi_out_i,
	output reg signed [17:0] pi_out_q
);

initial begin
	pi_out_i=0;
	pi_out_q=0;
end

parameter KW = 18; // Bit-width of PI gains

// Assuming K's are w bits wide

// Clamp errors - long story, not efficient, but see llc-suite fdbk_loop.v
wire signed [17:0] err1_i = $signed(`SAT(err_i, 18, 13)) <<< 3;
wire signed [17:0] err1_q = $signed(`SAT(err_q, 18, 13)) <<< 3;

// Stage 2: Proportional gain stage
// (err_i + j err_q) * (Kp_I + j Kp_Q)
// DELAY: 3 cycles
wire signed [17:0] prop_out_I, prop_out_Q;
complex_mul_flat cmul_flat(.clk(clk), .gate_in(1'b1),
	.x_I(err1_i), .x_Q(err1_q), .y_I(Kp_I), .y_Q(Kp_Q),
	.z_I(prop_out_I), .z_Q(prop_out_Q));

wire signed [17:0] prop_out_g_I = feedback_enable ? prop_out_I : 18'd0;
wire signed [17:0] prop_out_g_Q = feedback_enable ? prop_out_Q : 18'd0;


// Stage 3: K_i mul and Integrator
// DELAY: 2 cycles
wire signed [20:0] integrator_out_I, integrator_out_Q;
multiply_accumulate #(.KW(KW)) mi_I(.clk(clk), .enable(integrator_gate),
	.reset(integrator_reset), .constant(Ki_over_Kp), .downscale(post_mult_shift),
	.signal(prop_out_g_I), .correction(fdfwd_i), .accumulated(integrator_out_I));
multiply_accumulate #(.KW(KW)) mi_Q(.clk(clk), .enable(integrator_gate),
	.reset(integrator_reset), .constant(Ki_over_Kp), .downscale(post_mult_shift),
	.signal(prop_out_g_Q), .correction(fdfwd_q), .accumulated(integrator_out_Q));

// Stage 4: Kp + Ki
// DELAY: 2 cycles
// TODO: Add and saturate in 1 cycle
reg signed [18:0] pi_out_I_s=0, pi_out_Q_s=0;
always @ (posedge clk) begin
	pi_out_I_s <= $signed(integrator_out_I[20:3]) + prop_out_g_I;
	pi_out_Q_s <= $signed(integrator_out_Q[20:3]) + prop_out_g_Q;
	pi_out_i <= `SAT(pi_out_I_s, 18, 17);
	pi_out_q <= `SAT(pi_out_Q_s, 18, 17);
end
endmodule
