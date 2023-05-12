`timescale 1ns / 1ns

// Encapsulation of the serialization step in LBNL's conveyor belt
// Instantiated by e.g., serializer_multichannel.v
module serialize #(
	parameter dwi=28  // result width
) (
	input clk,  // timespec 8.4 ns
	input samp, // Snap signal for data_in
	input signed [dwi-1:0] data_in,
	input signed [dwi-1:0] stream_in,
	output signed [dwi-1:0] stream_out,
	input gate_in,
	output gate_out,
	output strobe_out
);

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
