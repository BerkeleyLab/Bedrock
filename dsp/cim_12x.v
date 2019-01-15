`timescale 1ns / 1ns

// Cascaded Integrator Multiplexor
module cim_12x #(
	parameter dw=32,  // data width of mon_chan output
	// should be CIC input data width (18), plus 2 * log2(max sample period)
	// also should match width of sr_out port
	parameter scale = 18'd65536  // applies to non-downconverted channels
	// (inm and outm), opportunity to use values that trigger synthesis
	// of an actual multiplier to get scaling consistency with
	// downconverted channels, e.g., 18'd61624 == floor((32/33)^2*2^16)
) (
	input clk,
	input signed [15:0] adca,
	input signed [15:0] adcb,
	input signed [15:0] adcc,
	input signed [15:0] inm,
	input signed [15:0] outm,
	input iqs,
	input signed [15:0] adcx,
	input signed [17:0] cosa,
	input signed [17:0] sina,
	input signed [17:0] cosb,
	input signed [17:0] sinb,
	input sample,

	// unprocessed double-integrator output
	output [dw-1:0] sr_out,
	output sr_val,
	input reset
);

`ifdef SIMULATE
`define FILL_BIT 1'bx
`else
`define FILL_BIT 1'b0
`endif

// Each mon_2chan instantiation includes (twice, one for cos, one for sin) the multiplier, double integrator, and sampling/shift-out register
// Snapshots double-integrator outputs at times flagged by "sample", then shifts the results out on the next twelve cycles.
wire signed [dw-1:0] s01;  wire g01;
wire signed [dw-1:0] s03;  wire g03;
mon_2chan #(.dwi(16), .rwi(dw)) mon01(.clk(clk), .adcf(adca), .mcos(cosa), .msin(sina), .samp(sample), .s_in(s03), .s_out(s01), .g_in(g03), .g_out(g01), .reset(reset));

wire signed [dw-1:0] s05;  wire g05;
mon_2chan #(.dwi(16), .rwi(dw)) mon03(.clk(clk), .adcf(adcb), .mcos(cosa), .msin(sina), .samp(sample), .s_in(s05), .s_out(s03), .g_in(g05), .g_out(g03), .reset(reset));

wire signed [dw-1:0] s07;  wire g07;
mon_2chan #(.dwi(16), .rwi(dw)) mon05(.clk(clk), .adcf(adcc), .mcos(cosa), .msin(sina), .samp(sample), .s_in(s07), .s_out(s05), .g_in(g07), .g_out(g05), .reset(reset));

wire signed [dw-1:0] s09;  wire g09;
mon_2chiq #(.dwi(16), .rwi(dw)) mon07(.clk(clk), .iqd(inm),  .scale(scale), .iqs(iqs),  .samp(sample), .s_in(s09), .s_out(s07), .g_in(g09), .g_out(g07), .reset(reset));

wire signed [dw-1:0] s11;  wire g11;
mon_2chiq #(.dwi(16), .rwi(dw)) mon09(.clk(clk), .iqd(outm), .scale(scale), .iqs(iqs),  .samp(sample), .s_in(s11), .s_out(s09), .g_in(g11), .g_out(g09), .reset(reset));

wire signed [dw-1:0] s13;  wire g13;
mon_2chan #(.dwi(16), .rwi(dw)) mon11(.clk(clk), .adcf(adcx), .mcos(cosb), .msin(sinb), .samp(sample), .s_in(s13), .s_out(s11), .g_in(g13), .g_out(g11), .reset(reset));

// terminate the chain
assign s13 = {dw{`FILL_BIT}};
assign g13 = 0;

// use the results of the chain
assign sr_out = s01;  // data
assign sr_val = g01;  // gate

endmodule
