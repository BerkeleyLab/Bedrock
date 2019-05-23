`timescale 1ns / 1ns

// Complex-valued single-pole filter and scaling
// Larry Doolittle, LBNL, February 2014
// 150+ MHz in Spartan-6 speed grade 3, using 4 DSP48A1s, 189 LUTs
// 160+ MHz in  Artix-7  speed grade 2, using 4 DSP48E1s, 184 LUTs

// y*z = y + ky*z^{-1}*y + kx*x

// Besides the intrinsic filter group delay, computation adds
// four cycles of pipelining delay from x to y.

// All of x, kx, ky, and y are complex-valued, interleaved,
// real when iq==1 and imaginary when iq==0.

// Do not use negative full-scale values for kx or ky.
// Needs evaluation for round-off error and possible resulting bias.

module lp(
	input clk,  // timespec 6.66 ns
	input iq,
	input signed [17:0] x,
	input signed [17:0] kx,  // external
	output [0:0] kx_addr,    // external address for kx
	input signed [17:0] ky,  // external
	output [0:0] ky_addr,    // external address for ky
	output signed [19:0] y
);

assign kx_addr = iq;
assign ky_addr = iq;

reg signed [20:0] yr=0;
wire signed [19:0] xmr, ymr;
sub_mul xmul(.clk(clk), .iq(iq), .x(x),  .y(kx), .z(xmr));
sub_mul ymul(.clk(clk), .iq(iq), .x(yr[20:3]), .y(ky), .z(ymr));

`define SAT(x,old,new) ((~|x[old:new] | &x[old:new]) ? x[new:0] : {x[old],{new{~x[old]}}})

reg signed [21:0] sum=0;
always @(posedge clk) begin
	// When you peek inside sub_mul, you can see
	// this is really a five-way summing junction.
	sum <= xmr + ymr + yr;
	yr <= `SAT(sum,21,20);
end
assign y = yr[20:1];

endmodule


module sub_mul(
	input clk,
	input iq,
	input signed [17:0] x,
	input signed [17:0] y,
	output signed [19:0] z
);

// Flow-through vector multiplier
// x, y, and z are interleaved I-Q complex numbers
// iq set high for I, low for Q at input, a pair is I followed by Q.
// Assumes there is some guarantee that you will never multiply two
// full-scale negative values together.

// Based on the well-exercised complex_mul.v, but without its
// final saturation and register.

reg [2:0] iq_sr=0;
always @(posedge clk) iq_sr <= {iq_sr[1:0],iq};

// Keep guard bits through the addition step.
reg signed [17:0] x1=0, x2=0, y1=0;
reg signed [35:0] prod1=0, prod2=0;
wire signed [18:0] prod1_msb = prod1[34:16];
wire signed [18:0] prod2_msb = prod2[34:16];
reg signed [18:0] prod1_d=0, prod2_d=0;
wire signed [17:0] m2mux = iq_sr[1] ? x2 : x;
always @(posedge clk) begin
	x1 <= x;
	x2 <= x1;
	y1 <= y;
	prod1 <= x * y;
	prod2 <= m2mux * y1;
	prod1_d <= prod1_msb;
	prod2_d <= prod2_msb;
end
wire iqx = iq_sr[2];
//wire signed [18:0] zl = iqx ? prod2_d : prod1_d;
//wire signed [18:0] zr = iqx ? prod2_msb : prod1_msb;
assign z = iqx ? (prod2_d + prod2_msb) : (prod1_d - prod1_msb);

endmodule
