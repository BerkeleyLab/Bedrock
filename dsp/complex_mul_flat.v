`timescale 1ns / 1ns
// TODO:
// Could potentially save a cycle in the flip-flop, by combining Add and Saturate into 1 cycle
module complex_mul_flat(
	input clk,  // Rising edge clock input; all logic is synchronous in this domain
	input gate_in,  // Flag marking input data valid
	input signed [17:0] x_I,  // Multiplicand 1, real
	input signed [17:0] x_Q,  // Multiplicand 1, imag
	input signed [17:0] y_I,  // Multiplicand 2, real
	input signed [17:0] y_Q,  // Multiplicand 2, imag
	output signed [17:0] z_I,  // Result, real
	output signed [17:0] z_Q,  // Result, imag
	output signed [35:0] z_I_all,  // Result, real, large
	output signed [35:0] z_Q_all,  // Result, imag, large
	output gate_out  // Delayed version of gate_in
);

// Flow-through vector multiplier
// Assumes there is some guarantee that you will never multiply two
// full-scale negative values together.
// (A + j B) * (C + j D)
reg signed [35:0] AC=0, BD=0, AD=0, BC=0, z_I_all_i=0, z_Q_all_i=0;
reg signed [18:0] I_small=0, Q_small=0;

`define SAT(x,old,new) ((~|x[old:new] | &x[old:new]) ? x[new:0] : {x[old],{new{~x[old]}}})

// Keep one guard bit through the addition step.  That, and the
// strange-looking "+1" below, reduces the average error offset
// to -1/4 result bit.
wire signed [19:0] z_I_sel=z_I_all_i[35:16], z_Q_sel=z_Q_all_i[35:16];

always @(posedge clk) begin
	AC <= x_I * y_I;
	BD <= x_Q * y_Q;
	AD <= x_I * y_Q;
	BC <= x_Q * y_I;
	// Fit 2 36bit signed number additions into a 35 bit number, as signed multiply
	// produces a bogus bit
	z_I_all_i <= AC - BD;
	z_Q_all_i <= AD + BC + 1;
	I_small <= `SAT(z_I_sel, 19, 18);
	Q_small <= `SAT(z_Q_sel, 19, 18);
end

assign z_I_all = z_I_all_i;
assign z_Q_all = z_Q_all_i;
assign z_I = I_small[18:1];
assign z_Q = Q_small[18:1];


// This gate input isn't really used, but describes the length of this
// pipeline to let users keep track of the data flow.

reg [2:0] gate_sr=0;
always @(posedge clk) gate_sr <= {gate_sr[1:0],gate_in};
assign gate_out = gate_sr[2];

endmodule
