// clk_out must be more than twice as fast as the gate_in rate.
`timescale 1ns / 1ns
module data_xdomain #(
	parameter size=16
) (
	input clk_in,
	input gate_in,
	input [size-1:0] data_in,
	input clk_out,
	output gate_out,
	output [size-1:0] data_out
);

reg [size-1:0] data_latch=0;
always @(posedge clk_in) if (gate_in) data_latch <= data_in;

wire gate_x;
flag_xdomain foo(
	.clk1(clk_in),  .flagin_clk1(gate_in),
	.clk2(clk_out), .flagout_clk2(gate_x));

wire [size-1:0] data_pipe;
`ifdef HAPPY_VIVADO
// Using data_latch directly is OK by Vivado, but simulation shows
// that doing so markedly reduces the available throughput.
assign data_pipe = data_latch;
`else
// Vivado complains bitterly about this version, calling it
// CDC-4 Critical.  See UG906 for discussion.
reg_tech_cdc #(.POST_STAGES(0)) rtc[size-1:0] (.C(clk_out),
	.I(data_latch), .O(data_pipe));
`endif

// CDC-15  Warning  Clock enable controlled CDC structure detected
// "The CDC engine only checks that [CE] is [valid in clk_out].
// Also, you are responsible for constraining the latency from the
// [clk_in] domain to [clk_out latch input], which is usually done
// by a set_max_delay -datapath_only constraint."
reg [size-1:0] data_out_r=0;
reg gate_out_r=0;
always @(posedge clk_out) begin
	if (gate_x) data_out_r <= data_pipe;
	gate_out_r <= gate_x;
end
assign data_out = data_out_r;
assign gate_out = gate_out_r;

endmodule
