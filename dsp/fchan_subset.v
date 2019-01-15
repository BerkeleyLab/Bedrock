`timescale 1ns / 1ns

// Name: Channel Subset
//% Runtime-configurable selection of which data to keep within each block
//% Typically used on the input to a waveform memory
module fchan_subset(
	input clk,
	input [len-1:0] keep,
	input signed [a_dw-1:0] a_data,
	input a_gate, a_trig,
	output signed [o_dw-1:0] o_data,
	output o_gate, o_trig,
	output time_err
);

parameter a_dw=20;
parameter o_dw=20;
parameter len=16;

reg [len-1:0] live=0;
always @(posedge clk) begin
	if (a_gate | a_trig) live <= a_trig ? keep : {live[len-2:0],1'b0};
end

assign o_data = a_data;
assign o_gate = a_gate & live[len-1];
assign o_trig = a_trig;

demand_gpt #(.gpt(len)) tcheck(.clk(clk), .gate(a_gate), .trig(a_trig), .time_err(time_err));

endmodule
