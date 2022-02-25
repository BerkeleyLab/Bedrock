`timescale 1ns / 1ns

// Phase averaging: LCLS-II
// Basic idea is to multiply the foward downconverted signal with a
// user-settable PRL gain. Similarly multiply the
// reverse downconverted signal(complex) with a PRL gain(maybe a complex conjugate).
// Note: All inputs are complex interleaved I/Q data.
// Then average these products and disgard real values, consider only imag.

// Complex multiplication:
// (a + ib) * (c + id) --> forward * PRL gain
// (w + ix) * (y + iz) --> reverse * PRL gain
// (a*c - b*d) + i (a*d + b*c) --> M1
// (w*y - x*z) + i (w*z + x*y) --> M2

// Since we just need the imag term, we can do:
// (a*d + b*c) --> (R*I + I*R)
// So for each multiplication we now need 1 multiplier(because of interleaved I/Q data
// stream) and 1 adders.

// Averaging:
// (a*d + b*c + w*z + x*y -->  (R*I + I*R) + (R*I + I*R)
// So in total 2 multipliers and 3 adders

// Computation adds four cycles of pipelining delay from inputs to z.

// All of x, kx, y, ky and z are complex-valued, interleaved,
// real when iq==1 and imaginary when iq==0.

module phs_avg #(
    parameter aw = 18 )
(
	input clk,  // timespec 6.66 ns
	input iq,
	input signed [aw-1:0] x,
	input signed [17:0] kx,  // external
	output [0:0] kx_addr,    // external address for kx
	input signed [aw-1:0] y,
	input signed [17:0] ky,  // external
	output [0:0] ky_addr,    // external address for kx
	output signed [aw+1:0] z
);

assign kx_addr = iq;
assign ky_addr = iq;

wire signed [aw+1:0] xmr, ymr;

mul xmul(.clk(clk), .iq(iq), .x(x),  .y(kx), .z(xmr));
mul ymul(.clk(clk), .iq(iq), .x(y),  .y(ky), .z(ymr));

`define SAT(x,old,new) ((~|x[old:new] | &x[old:new]) ? x[new:0] : {x[old],{new{~x[old]}}})

reg signed [aw+2:0] sum=0;
always @(posedge clk) begin
	sum <= xmr + ymr;
end
assign z = sum[aw+1:1];

endmodule

module mul #(
    parameter aw = 18)
(
	input clk,
	input iq,
	input signed [aw-1:0] x,
	input signed [aw-1:0] y,
	output signed [aw+1:0] z
);

reg signed [aw-1:0] y1 = 0;
reg signed [(2*aw)-1:0] prod = 0;
wire signed [aw:0] prod_msb = prod[(2*aw)-1:aw-2];
reg signed [aw:0] prod_i = 0;
reg signed [aw+1:0] sum = 0;
always @(posedge clk) begin
	y1 <= y;
	prod <= x * y1;
	prod_i <= prod_msb;
    sum <= prod_i + prod_msb;
end

assign z = sum;
endmodule
