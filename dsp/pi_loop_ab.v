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
// Note: All the traces here are Complex I-Q signals interleaved in a single stream
// Created with http://asciiflow.com

`timescale 1ns / 1ns

//`include "pi_loop_ab_auto.vh"
module pi_loop_ab (
	// Everything here is in one clock domain, matches ADC
	input clk,
	// Kp and Ki for the PI loop
	input signed [KW-1:0] Kp_I, // external
	input signed [KW-1:0] Kp_Q, // external
	input signed [KW-1:0] Ki_over_Kp,  // external

	// Reference and input
	input signed [17:0] ref_iq,
	input iq,
	input signed [17:0] measured_iq,

	input reverse,
	input integrator_enable, // external
	output reg signed [17:0] pi_out_iq
);
parameter KW = 18;

// Assuming K's are w bits wide

// Stage 1: difference between measured and reference
reg iq_d1 = 0;
wire iq_d2 = 0;
wire signed [18:0] err_c = ref_iq - measured_iq;
reg signed [18:0] err_iq = 0;
always @ (posedge clk) begin
        err_iq <= reverse ? (-err_c) : err_c;
        iq_d1 <= iq;
end

// Stage 2: Proportional gain stage
wire signed [17:0] prop_out;
complex_mul kp_cmul
	(.clk(clk),
	.gate_in(1'b1),
	.iq(iq_d1),
	.x(err_iq[18:1]),
	.y(iq_d1 ? Kp_I : Kp_Q),
	.z(prop_out),
	.gate_out(iq_d2)
);

reg signed [17+KW:0] pi_out_large;
reg signed [KW+18-1:0] integrator_in_large;

// Stage 3: K_i mul and Integrator
`define SAT(x,old,new) ((~|x[old:new] | &x[old:new]) ? x[new:0] : {x[old],{new{~x[old]}}})
reg signed [20:0] integrator_in, integrator_in_d1, integrator_in_d2;
reg signed [21:0] integrator_sum;
reg signed [20:0] integrator_out;
wire signed [20:0] integrator_sat = `SAT(integrator_sum, 21, 20);

// TODO: Ensure that iq is time stable. This can be done through simulation
always @ (posedge clk) begin
	integrator_in_large <= prop_out * Ki_over_Kp;
	// TODO: Don't waste a flip-flop here
	integrator_in <= integrator_in_large[KW+18-1: KW+18-1 - 20];
	integrator_in_d1 <= integrator_in;
	integrator_in_d2 <= integrator_in_d1;
	integrator_sum <= integrator_in <<< 4 + 1'b1 + integrator_in_d2;
	integrator_out <= integrator_enable? integrator_sat : 0;
end

// Stage 4: Kp + Ki
// TODO: prop_out should be delayed by 5 cycles(?)
reg [18:0] pi_out_s;
always @ (posedge clk) begin
	pi_out_s <= integrator_out[20:3] + prop_out;
	pi_out_iq <= `SAT(pi_out_s, 18, 17);
end

endmodule
