`timescale 1ns / 1ns

// Outer Product
// Takes a single value x, and multiplies it by a constant vector stored
// in local-bus-writable memory.  The rsult is time-multiplexed x*B.

// The input x can be continually varying; this module will take a snapshot
// of it at the right time so that the whole output vector comes from a
// single, self-consistent value of x.  That snapshot happens two cycles
// after start.  Changeover between x values on the output, starting with
// vector element zero, shows up six cycles after start.

module outer_prod(
	input clk,
	input start,
	input signed [17:0] x,
	// Local Bus
	(* external *)
	input signed [17:0] k_out,  // external
	// 9 should be pcw-1
	(* external *)
	output [9:0] k_out_addr,  // external
	output signed [17:0] result
);

// Program counter
parameter pcw = 10;  // must not be wider than lb_addr input port
reg [pcw-1:0] pc=0;
always @(posedge clk) pc <= start ? 0 : pc+1;

wire grab;
reg_delay #(.dw(1), .len(2))
	zd(.clk(clk), .reset(1'b0), .gate(1'b1), .din(start), .dout(grab));

assign k_out_addr = pc;

// As always, demand that k is not full-scale negative
reg signed [17:0] x_hold=0;
reg signed [35:0] mul1=0;
wire signed [17:0] mul1s=mul1[34:17];
reg signed [17:0] k_out1=0, mul2=0, mul3=0;
always @(posedge clk) begin
	if (grab) x_hold <= x;
	k_out1 <= k_out;
	mul1 <= k_out1 * x_hold;
	mul2 <= mul1s;
	mul3 <= mul2;
end

assign result = mul3;

endmodule
