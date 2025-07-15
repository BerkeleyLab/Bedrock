`timescale 1ns / 1ns
// Synthesizes to 80 4-LUTs and 2 MULT18X18s at 150 MHz in XC3Sxxx-4 using XST-10.1i

// Name: Near-IQ Downconverter
//% Provide LO at cosd and sind ports
//% Output is stream of IQ samples
// Input cosd and sind are ordinary LO signals, and this module reorders them.
// N.B.: full-scale negative is an invalid LO value.
//
// Compute IQ by performing the matrix multiplication described in the paper below
// http://recycle.lbl.gov/~ldoolitt/llrf/down/reconstruct.pdf
// Where n and n+1 are consecutive samples in time
// | I | =  |  sin[n + 1]\theta   -sin n\theta |  X  | a_data[n]   |
// | Q |    | -cos[n + 1]\theta    cos n\theta |     | a_data[n+1] |
// Larry Doolittle, LBNL, 2014
module fdownconvert #(
	parameter a_dw=16,  // XXX don't change this
	parameter o_dw=16   // XXX don't change this
) (
	input clk,  // timespec 6.66 ns
	input mod2,
	input signed [17:0] cosd,  // LO input
	input signed [17:0] sind,  // LO input

	input signed [a_dw-1:0] a_data,   // ADC readings
	input a_gate,
	input a_trig,

	output signed [o_dw-1:0] o_data,  // Interleaved I&Q
	output o_gate,
	output o_trig,
	output time_err   // TODO: Explain this
);

// reordering logic, generate the delayed signals for the above matrix multiplication
reg signed [17:0] cosd_d1=0, cosd_d2=0, cosd_r=0;
reg signed [17:0] sind_d1=0, sind_d2=0, sind_r=0;
always @(posedge clk) begin
	cosd_d1 <= cosd;
	cosd_d2 <= cosd_d1;
	cosd_r <= ~mod2 ? cosd_d2 : cosd;
	sind_d1 <= sind;
	sind_d2 <= sind_d1;
	sind_r <= ~mod2 ? sind_d2 : sind;
end

// downconvert input signal to I and Q
// an extra pipeline stage has been added to help routing near multiplier
reg signed [32:0] mul_i=0, mul_q=0, mul_i1=0, mul_q1=0, mul_i2=0, mul_q2=0;
always @(posedge clk) begin
	mul_i  <= a_data * cosd_r;
	mul_i1 <= mul_i;
	mul_i2 <= mul_i1;
	mul_q  <= a_data * sind_r;
	mul_q1 <= mul_q;
	mul_q2 <= mul_q1;
end

`define SAT(x,old,new) ((~|x[old:new] | &x[old:new]) ? x[new:0] : {x[old],{new{~x[old]}}})
reg signed [15:0] iq_out0=0;
reg signed [16:0] sum_i1x=0, sum_q1x=0, sum_q2x=0;
always @(posedge clk) begin
	sum_i1x <= $signed(mul_i1[32:17]) - $signed(mul_i2[32:17]);
	sum_q1x <= $signed(mul_q2[32:17]) - $signed(mul_q1[32:17]);
	sum_q2x <= sum_q1x;
end
wire signed [16:0] iq_mux = mod2 ? sum_q2x : sum_i1x;
always @(posedge clk) iq_out0 <= `SAT(iq_mux,16,15);

reg last_mod2=0, time_err_r=0;
always @(posedge clk) begin
	last_mod2 <= mod2;
	time_err_r <= (mod2 ^ ~last_mod2) | ~a_gate;
end

`undef SAT

assign o_data = iq_out0;
assign o_gate = 1'b1;
assign o_trig = mod2;
assign time_err = time_err_r;

endmodule
