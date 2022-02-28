`timescale 1ns / 1ns

// Phase averaging: LCLS-II
// Basic idea is to multiply the foward downconverted signal with a user-settable PRL gain.
// Similarly multiply the reverse downconverted signal with a PRL gain.
// Note: All inputs are complex interleaved I/Q data.
// Then average these products and disgard real values, consider only imag.
// Finally integrate the averaged values.

// Complex multiplication:
// (a + ib) * (c + id) --> forward * PRL gain
// (w + ix) * (y + iz) --> reverse * PRL gain
// (a*c - b*d) + i (a*d + b*c) --> M1
// (w*y - x*z) + i (w*z + x*y) --> M2

// Since we just need the imag term, we can do:
// (a*d + b*c) --> (R*I + I*R)
// So for each operation we now need 1 multiplier (because interleaved I/Q
// data). This is accomplished using phs_avg_mul module.

// Averaging:
// (a*d + b*c + w*z + x*y) -->  (R*I + I*R) + (R*I + I*R) --> sum
// In total 2 multipliers(one for each pair of input) and 2 adders(adding each product and integrator)

// Computation adds four cycles of pipelining delay from inputs to z.

// All of x, kx, y, ky and z are complex-valued, interleaved,
// real when iq==1 and imaginary when iq==0.

module phs_avg #(
    parameter dw = 18)
(
	input clk,  // timespec 6.66 ns
	input iq,
	input signed [dw-1:0] x,
	input signed [dw-1:0] kx,  // external
	output [0:0] kx_addr,    // external address for kx
	input signed [dw-1:0] y,
	input signed [dw-1:0] ky,  // external
	output [0:0] ky_addr,    // external address for kx
	output signed [dw+1:0] z
);

assign kx_addr = iq;
assign ky_addr = iq;

wire signed [dw+1:0] xmr, ymr;

phs_avg_mul xmul(.clk(clk), .iq(iq), .x(x),  .y(kx), .z(xmr));
phs_avg_mul ymul(.clk(clk), .iq(iq), .x(y),  .y(ky), .z(ymr));

`define SAT(x,old,new) ((~|x[old:new] | &x[old:new]) ? x[new:0] : {x[old],{new{~x[old]}}})

reg signed [dw+2:0] sum = 0;
reg signed [dw+3:0] intg = 0;
always @(posedge clk) begin
	sum <= xmr + ymr;
        intg <= sum + intg; // Integrator
end
assign z = intg[dw+2:1];

endmodule

module phs_avg_mul #(
    parameter dw = 18)
(
	input clk,
	input iq,
	input signed [dw-1:0] x,
	input signed [dw-1:0] y,
	output signed [dw+1:0] z
);

reg signed [dw-1:0] y1 = 0;
reg signed [(2*dw)-1:0] prod = 0;
wire signed [dw+1:0] prod_msb = prod[(2*dw)-2:dw-3];
always @(posedge clk) begin
	y1 <= y;
	prod <= x * y1;
end

assign z = prod_msb;
endmodule
