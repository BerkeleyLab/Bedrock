// Just like down_5_12, but leave off the fancy rms error calculation
// Used to estimate resources in synthesis.
module down_5_12_small(
	input clk,
	input signed [15:0] adc,
	input [3:0] phase,
	output stb,
	output sig_cl,
	output signed [16:0] sig_i,
	output signed [16:0] sig_q
);

down_5_12 down(.clk(clk), .adc(adc), .phase(phase),
	.stb(stb), .sig_cl(sig_cl),
	.sig_i(sig_i), .sig_q(sig_q)
);

endmodule
