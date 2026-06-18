`timescale 1ns / 1ns

module dot_prod(
	input clk,
	input start,
	input signed [17:0] x,  // positions from resonator.v
	(*external*)
	input signed [17:0] k_out,  // external
	// 9 should be pcw-1
	(*external*)
	output [9:0] k_out_addr,  // external
	output signed [17:0] result,
	output strobe  // at time of res valid
);

// Program counter
parameter pcw = 10;
reg [pcw-1:0] pc=0;
always @(posedge clk) pc <= start ? 0 : pc+1;
assign k_out_addr = pc;

wire zero;
reg_delay #(.dw(1), .len(6))
	zd(.clk(clk), .reset(1'b0), .gate(1'b1), .din(start), .dout(zero));

`define SAT(x,old,new) ((~|x[old:new] | &x[old:new]) ? x[new:0] : {x[old],{new{~x[old]}}})

// As always, demand that k is not full-scale negative
reg signed [35:0] mul1=0;
wire signed [19:0] mul1s=mul1[34:15];
reg signed [19:0] mul2=0, mul3=0;
reg signed [17:0] k_out1=0;
reg signed [23:0] acc1=0;
reg signed [19:0] acc2=0;
reg strobe_r;
always @(posedge clk) begin
	k_out1 <= k_out;
	mul1 <= k_out1 * x;
	mul2 <= mul1s;
	mul3 <= mul2;
	acc1 <= (zero ? 0 : acc1) + mul3;
	if (zero) acc2 <= `SAT(acc1,23,19);
	strobe_r <= zero;
end
`undef SAT

assign result = acc2[19:2];
assign strobe = strobe_r;

endmodule
