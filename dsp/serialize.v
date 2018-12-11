`timescale 1ns / 1ns

module serialize(
	input clk,  // timespec 8.4 ns
	input samp, // Snap signal for data_in
	input signed [dwi-1:0] data_in,
	input signed [dwi-1:0] stream_in,
	output signed [dwi-1:0] stream_out,
	input gate_in,
	output gate_out,
	output strobe_out
);
parameter dwi=28;  // result width
// Difference between above two widths should be N*log2 of the maximum number
// of samples per CIC sample, where N=2 is the order of the CIC filter.

reg signed [dwi-1:0] stream_reg=0;
reg gate_reg=0;
always @(posedge clk) begin
	stream_reg <= samp ? data_in : stream_in;
	gate_reg <= samp ? samp : gate_in;
end
assign stream_out = stream_reg;
assign gate_out = gate_reg;
assign strobe_out=samp;
endmodule
