// clk_out must be more than twice as fast as the gate_in rate.
`timescale 1ns / 1ns
module data_xdomain(clk_in, gate_in, data_in,
	clk_out, gate_out, data_out);

parameter size=16;
	input clk_in, gate_in, clk_out;
	input [size-1:0] data_in;
	output reg [size-1:0] data_out;
	output reg gate_out;
initial gate_out=0;
initial data_out=0;

reg [size-1:0] data_latch=0;
always @(posedge clk_in) if (gate_in) data_latch <= data_in;

wire gate_x;
flag_xdomain foo(
	.clk1(clk_in),  .flagin_clk1(gate_in),
	.clk2(clk_out), .flagout_clk2(gate_x));

// It can be argued that the final pipeline stage is not needed,
// but then you'd need oddball timing constraints on the data path.
reg [size-1:0] data_pipe=0;
always @(posedge clk_out) begin
	data_pipe <= data_latch;
	gate_out <= gate_x;
	if (gate_x) data_out <= data_pipe;
end

endmodule
