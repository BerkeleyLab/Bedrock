`timescale 1ns / 1ns

// Second-order CIC interpolation of an IQ data stream
// Expect input valid for 2 cycles (marked by active-high samp signal)
// out of 2*N.
// Well, this is only the integration half of the CIC filter, someone
// else (e.g., iq_intrp4) needs to do the differentiation.

module iq_inter(clk,samp,in,out);
parameter dwi=22;  // data width in
parameter dwo=18;  // data width out
	input clk;  // timespec 8.4 ns
	input samp;
	input signed [dwi-1:0] in;
	output signed [dwo-1:0] out;

reg signed [dwi-1:0] sreg=0, sreg_d=0, int1=0, int1_d=0, int2=0, int2_d=0;
always @(posedge clk) begin
	sreg <= samp ? in : sreg_d;
	sreg_d <= sreg;
	int1 <= int1_d + sreg;
	int1_d <= int1;
	int2 <= int2_d + int1;
	int2_d <= int2;
end
assign out = int2[dwi-1:dwi-dwo];

endmodule
