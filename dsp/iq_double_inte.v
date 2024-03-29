`timescale 1ns / 1ns

// Double-integrator for interleaved I-Q samples
// Front end of a second-order CIC, see iq_chain4

module iq_double_inte #(
	parameter dwi=16,  // data width in
	parameter dwo=28   // data width out
) (
	input clk,  // timespec 8.4 ns
	input signed [dwi-1:0] in,  // IQ muxed
	output signed [dwo-1:0] out
);

reg signed [dwo-1:0] int1=0, int1_d=0, int2=0, int2_d=0;
always @(posedge clk) begin
	int1 <= int1_d + in;  // Add to the delayed sample
	int1_d <= int1;  // Delay
	int2 <= int2_d + int1; // Second addition to further delayed sample
	int2_d <= int2;  // Delay
end
assign out = int2;

endmodule
