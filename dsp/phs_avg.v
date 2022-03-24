`timescale 1ns / 1ns

// Phase averaging: LCLS-II
// Basic idea is to multiply the forward downconverted signal with a user-settable PRL gain.
// Similarly multiply the reverse downconverted signal with a PRL gain.
// Note: All inputs are complex interleaved I/Q data.
// Then average these products and discard real values, consider only imag.
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
    parameter dwi = 17,
    parameter dwj = 16)
(
	input clk,  // timespec 6.66 ns
	input reset,
	input iq,
	input signed [dwi-1:0] x,
	input signed [15:0] kx,  // external
	output [0:0] kx_addr,    // external address for kx
	input signed [dwi-1:0] y,
	input signed [15:0] ky,  // external
	output [0:0] ky_addr,    // external address for kx
       output signed [dwi+3:0] sum_filt, // debug only
	output signed [dwi+1:0] z
);

assign kx_addr = iq;
assign ky_addr = iq;

wire signed [dwi+1:0] xmr, ymr;

phs_avg_mul #(.dwi(17), .dwj(16)) xmul(.clk(clk), .iq(iq), .x(x),  .y(kx), .z(xmr));
phs_avg_mul #(.dwi(17), .dwj(16)) ymul(.clk(clk), .iq(iq), .x(y),  .y(ky), .z(ymr));

reg signed [dwi+2:0] sum = 0, sum1 = 0;
reg signed [dwi+3:0] intg = 0;
always @(posedge clk) begin
        sum <= xmr + ymr;
        sum1 <= sum;
        if (reset) intg <= 0;
        else intg <= sum + intg; // Integrator
end

// 2-tap filter [1, 1]
assign sum_filt = sum1 + sum; // Debug only

assign z = intg[dwi+2:1];

endmodule

module phs_avg_mul #(
    parameter dwi = 17,
    parameter dwj = 16)
(
	input clk,
	input iq,
	input signed [dwi-1:0] x,
	input signed [dwj-1:0] y,
	output signed [dwi+1:0] z
);

reg signed [dwj-1:0] y1 = 0;
reg signed [(dwi+dwj)-1:0] prod = 0;
wire signed [dwi+1:0] prod_msb = prod[(dwi+dwj)-2:dwi-4];
always @(posedge clk) begin
        y1 <= y;
        prod <= x * y1;
end

assign z = prod_msb;
endmodule
