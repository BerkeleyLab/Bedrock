`timescale 1ns / 1ns

module mixer(clk,adcf,mult,mixout);
parameter dwi=16;  // data width
parameter davr=4;  // average width if the following cic averaging 64,
// then the useful data increase sqrt(64), so increase 3 bits,
// for rounding error, save 4 bits more
parameter dwlo=18;  // lo width using 18 bits
input clk;  // timespec 8.4 ns
input signed [dwi-1:0] adcf;  // possibly muxed
input signed [dwlo-1:0] mult;
output signed [dwi-1+davr:0] mixout;

reg signed [dwi-1+davr:0] mixout_r=0;
reg signed [dwi-1:0] adcf1=0;
reg signed [dwlo-1:0] mult1=0;
reg signed [dwi+dwlo-1:0] mix_out_r=0;
reg signed [dwi-1+davr:0] mix_out1=0, mix_out2=0;
parameter NORMALIZE=0;
generate
if (NORMALIZE==1) begin
	reg  signed [dwi+dwlo-1:0] mixmulti=0;
	wire signed [dwi+dwlo-1:0] mix_out_w=mixmulti;//adcf*mult;
	always @(posedge clk) begin
		mixmulti <=adcf*mult;
		mixout_r <=mix_out_w[dwi+dwlo-1:dwlo-davr]+mix_out_w[dwlo-davr-1];
	end
	assign mixout = mixout_r;
end
else begin
// adc value can be anything, including -F.S., but
// demand that multiplier is never -F.S., so there is
// an "extra" sign bit that can be ignored.
	always @(posedge clk) begin
		adcf1 <= adcf;
		mult1 <= mult;
		mix_out_r <= adcf1 * mult1;  // internal multiplier pipeline
		mix_out1 <= mix_out_r[dwi-2+dwlo:dwlo-davr-1];
		mix_out2 <= mix_out1;
	end
	assign mixout = mix_out2;
end
endgenerate
endmodule
