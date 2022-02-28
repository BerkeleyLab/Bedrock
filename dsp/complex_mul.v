`timescale 1ns / 1ns

// Complex number multiplication, as in
//   (a+ib)*(c+id) = (a*c-b*d)+i(a*d+b*c).
// All the complex numbers are IQ-serialized, such that port x
// carries a+ib, port y carries c+id, and port z carries the result.

// It produces up to one answer every two clock cycles.
// The 18-bit inputs and output are assumed scaled to [-1,1).

// This module uses two 18-bit signed hardware multipliers,
// and can clock at over 100 MHz in Spartan-6.

// It's pretty easy to ask for results that would overflow the representable
// numbers; an extreme case is (1+i)*(1-i) = 2.  All such results get
// saturated to the maximum representable positive or negative number.

// A second copy of the result with no rounding error is also provided
// in z_all.  Using both outputs will consume more FPGA resources than
// using either one alone.

// Output results are delayed four cycles from the input.
// The gate_out port is nothing more or less than the gate_in
// port, delayed four cycles.  Only the iq control is used to control
// the data paths inside this module.

module complex_mul #(
    parameter dw = 18)
(
	input clk,  // Rising edge clock input; all logic is synchronous in this domain
	input gate_in,  // Flag marking input data valid
	input signed [dw-1:0] x,  // Multiplicand, signed, time-interleaved real and imaginary
	input signed [dw-1:0] y,  // Multiplicand, signed, time-interleaved real and imaginary
	input iq,  // Flag marking the real (I) part of the complex pair
	output signed [dw-1:0] z,  // Result
	output signed [(2*dw)-1:0] z_all,  // Result
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

reg signed [dw-1:0] x1=0, x2=0, y1=0;
reg signed [(2*dw)-1:0] prod1=0, prod2=0;
reg signed [(2*dw)-1:0] prod1_d=0, prod2_d=0;
reg signed [(2*dw)-1:0] sumi=0, sumq=0;
wire signed [dw-1:0] m2mux = iq_sr[1] ? x2 : x;
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
wire signed [(2*dw)-1:0] mux = iqx ? sumq : sumi;
reg signed [dw:0] zr=0;
reg signed [(2*dw)-1:0] mux_r=0;
wire signed [(dw+1):0] zsel=mux[(2*dw)-1:(dw-2)];
always @(posedge clk) begin
	zr <= `SAT(zsel, dw+1, dw);
	mux_r <= mux;
end
assign z = zr[dw:1];
assign z_all = mux_r;

// This gate input isn't really used, but describes the length of this
// pipeline to let users keep track of the data flow.

reg [3:0] gate_sr=0;
always @(posedge clk) gate_sr <= {gate_sr[2:0],gate_in};
assign gate_out = gate_sr[3];

endmodule
