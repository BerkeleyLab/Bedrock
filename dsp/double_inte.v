`timescale 1ns / 1ns
// 2 steps of CIC integration. Reset to 0
module double_inte(
	input clk,  // timespec 8.4 ns
	input signed [dwi-1:0] in,  // possibly muxed
	output signed [dwo-1:0] out,
	input reset  // reset integrator to 0
);

parameter dwi=16;  // data width in
parameter dwo=28;  // data width out n bits more the in, 2^n should be more than the cic factor^2 in sel case, 47^2=2209 adding 12 bit seems a little limited

reg [1:0] reset_r = 0;
always @(posedge clk) begin
	reset_r <= {reset_r[0], reset};
end
reg signed [dwo-1:0] int1 = 0, int2 = 0;
reg ignore=0;
always @(posedge clk) begin
	{int1, ignore} <= |reset_r ? 0 : ($signed({int1, 1'b1}) + in);
	int2 <= |reset_r ? 0 : (int2 + int1);
end
assign out = int2;

endmodule
