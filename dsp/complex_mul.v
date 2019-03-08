`timescale 1ns / 1ns

module complex_mul(
	input clk,  // Rising edge clock input; all logic is synchronous in this domain
	input gate_in,  // Flag marking input data valid
	input signed [17:0] x,  // Multiplicand, signed, time-interleaved real and imaginary
	input signed [17:0] y,  // Multiplicand, signed, time-interleaved real and imaginary
	input iq,  // Flag marking the real (I) part of the complex pair
	output signed [17:0] z,  // Result
	output signed [35:0] z_all,  // Result
	output gate_out  // Delayed version of gate_in
);

// Flow-through vector multiplier
// x, y, and z are interleaved I-Q complex numbers
// iq set high for I, low for Q at input, a pair is I followed by Q.
// Assumes there is some guarantee that you will never multiply two
// full-scale negative values together.

reg [3:0] iq_sr=0;
always @(posedge clk) iq_sr <= {iq_sr[3:0],iq};

// Keep one guard bit through the addition step.  That, and the
// strange-looking "+1" below, reduces the average error offset
// to -1/4 result bit.

reg signed [17:0] x1=0, x2=0, y1=0;
reg signed [35:0] prod1=0, prod2=0;
reg signed [35:0] prod1_d=0, prod2_d=0;
reg signed [35:0] sumi=0, sumq=0;
wire signed [17:0] m2mux = iq_sr[1] ? x2 : x;
always @(posedge clk) begin
	x1 <= x;
	x2 <= x1;
	y1 <= y;
	prod1 <= x*y;
	prod2 <= m2mux * y1;
	prod1_d <= prod1;
	prod2_d <= prod2;
	sumi <= prod1_d - prod1;
	sumq <= prod2_d + prod2 + 1;
end

`define SAT(x,old,new) ((~|x[old:new] | &x[old:new]) ? x[new:0] : {x[old],{new{~x[old]}}})
wire iqx = iq_sr[3];
wire signed [35:0] mux = iqx ? sumq : sumi;
reg signed [18:0] zr=0;
reg signed [35:0] mux_r=0;
wire signed [19:0] zsel=mux[35:16];
always @(posedge clk) begin
	zr <= `SAT(zsel, 19, 18);
	mux_r <= mux;
end
assign z = zr[18:1];
assign z_all = mux_r;

// This gate input isn't really used, but describes the length of this
// pipeline to let users keep track of the data flow.

reg [3:0] gate_sr=0;
always @(posedge clk) gate_sr <= {gate_sr[2:0],gate_in};
assign gate_out = gate_sr[3];

endmodule
