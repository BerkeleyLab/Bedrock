`timescale 1ns / 1ns

// First-order CIC interpolator
module interp0(
	input clk,
	input  [17:0] d_in,
	input strobe,
	output [17:0] d_out
);

// span should be log2(update interval), right?

// Coarse stepwise frequency changes are bad, as we discovered
// experimentally in hardware at APEX.  But linear small-steps
// like this should be fine.  The consequences get integrated
// one more time (to get phase) before they show up on an "ADC".
parameter span=6;

// Differentiate
reg signed [17:0] d_last=0, diff=0;
always @(posedge clk) if (strobe) begin
	d_last <= d_in;
	diff <= d_in - d_last;
end

// Integrate
reg signed [17+span:0] i1=0;
always @(posedge clk) begin
	i1 <= i1+diff;
end
assign d_out = i1[17+span:span];

endmodule
