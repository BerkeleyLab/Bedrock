`timescale 1ns / 1ns
module interp1(
	input clk,
	input signed [17:0] x,
	output signed [15:0] y
);

// y is double-integrated value of x
// x is assumed to be doubly-differentiated from the signal of interest,
// presumably from a ROM.
// Configured to support x updated every 47 clk cycles,
// and limited in amplitude a little:
// 47^2 = 2209, but keep output < 2047

reg signed [29:0] i1=0, i2=0;
always @(posedge clk) begin
	i1 <= i1+x;
	i2 <= i2+i1;
end
assign y = i2[27:12];

endmodule
