`timescale 1ns / 1ns

// permute np ports, each dw bits wide, using rl levels of 2-way mux
//  np must be 2**rl
//
// Networking equipment with similar topology is known as a Banyan switch,
// so I'll use that name.  A non-folded Banyan switch actually has two
// switches of this type back-to-back; I can leave off the second half
// because in my application the output channels are fungible.
//
// The intended use case is to route 8 x ADC data to 8 x data sinks,
// in any of the following configurations:
//  8 parallel  :   1 combination    x  1 time state
//  4 parallel  :  70 combinations   x  2 time states
//  2 parallel  :  28 combinations   x  4 time states
//  1 at a time :   8 possibilities  x  8 time states
// for 1*1 + 70*2 + 28*4 + 8*8 = 317 useful configurations
//
// Represent the channel selection configuration with an 8-bit mask of
// which channels to look at.  Only 1+70+28+8 = 107 of 256 possible masks
// are valid, since it's invalid to have 0, 3, 5, 6, or 7 bits set.
// Configuration also includes 3 bits of time_state.
//
// time_state and mask_in are processed at full bandwidth.
// There are rl+1 cycles of latency from a change of these
// control inputs to the new data_out permutation appearing.
// There are only rl cycles of latency to mask_out.
//
// The implementation is done with recursive instantiation of itself.
// The capability of doing recursion in Verilog is explicitly acknowledged
// and blessed by the Verilog-2005 standard, and it works without problem
// for me in Icarus Verilog, Verilator, Xilinx XST, and Xilinx Vivado.
//
// An N=8 dw=16 instantiation in Kintex speed grade 2 seems capable of
// running at ridiculous clock rates (over 550 MHz?), consuming on the
// order of 430 LUT.  The data muxes alone ought to use 384 LUT outputs.
// Even a lowly Spartan-6 should manage 160 MHz, using about 226 LUT
// (437 LUT outputs).
//
// Used successfully on hardware since 2016.

module banyan #(
	parameter dw=16,  // data width
	parameter np=8,   // number of ports, must be a power of 2
	parameter rl=3    // number of routing layers == log_2(np)
) (
	input clk,
	input [rl-1:0] time_state,
	input [np-1:0] mask_in,
	input [dw*np-1:0] data_in,
	output [np-1:0] mask_out,   // for DPRAM write-enable
	output [dw*np-1:0] data_out
);

localparam M = np/2;   // number of swap-boxes
wire two_or_more;  // use balance mode, when more than one bit of mask is set
two_set #(.dw(np)) two_set(.d(mask_in), .two(two_or_more));

wire [M-1:0] mask_upper = mask_in[2*M-1:M];
wire [M-1:0] mask_lower = mask_in[  M-1:0];
wire any_lower = |mask_lower;

// The below statement creates a Ripple-Carry chain of xors with the initial
// bit being fed from the right (a 1'b0). The in and out refer to the circuit
// verilator lint_save
// verilator lint_off UNOPTFLAT
wire [M:0] imbalance_in;
wire [M-1:0] imbalance_out = imbalance_in ^ mask_upper ^ mask_lower;
assign imbalance_in = {imbalance_out,1'b0};
// verilator lint_restore

// Priority set sources to Lower sinks when in Balance.
// If currently NOT imbalanced, and lower is 0 and upper 1, Flip and route to Lower
// If currently     imbalanced, and lower is 1 and upper 0, Flip and route to Upper
// You can at most flip M/2 channels
wire [M-1:0] flip_bal = imbalance_in & ~mask_upper &  mask_lower
                     | ~imbalance_in &  mask_upper & ~mask_lower;

// If only single source; Alternate routing to different sink based on time
wire [M-1:0] flip_deal = { M {~any_lower ^ time_state[rl-1]}};
wire [M-1:0] flip_ctl = two_or_more ? flip_bal : flip_deal;

reg [M-1:0] out_mask_upper=0, out_mask_lower=0, data_flip=0;
reg [rl-1:0] recurse_time_state=0;  // upper bit will be ignored
always @(posedge clk) begin
	out_mask_upper <= flip_ctl & mask_lower | ~flip_ctl & mask_upper;
	out_mask_lower <= flip_ctl & mask_upper | ~flip_ctl & mask_lower;
	recurse_time_state <= time_state;
	data_flip <= flip_ctl;  // pipeline
end

// Data goes through one cycle after control
reg [dw*np-1:0] stage=0;
genvar jx;
generate for (jx=0; jx<M; jx=jx+1) begin: ss
always @(posedge clk) begin
	stage[(jx+0+1)*dw-1:(jx+0)*dw] <= data_flip[jx] ? data_in[(jx+M+1)*dw-1:(jx+M)*dw] : data_in[(jx+0+1)*dw-1:(jx+0)*dw];
	stage[(jx+M+1)*dw-1:(jx+M)*dw] <= data_flip[jx] ? data_in[(jx+0+1)*dw-1:(jx+0)*dw] : data_in[(jx+M+1)*dw-1:(jx+M)*dw];
end
end endgenerate

// Recursive step
generate if (rl > 1) begin: halvsies
	banyan #(.rl(rl-1), .dw(dw), .np(np/2)) top(.clk(clk), .time_state(recurse_time_state[rl-2:0]), .mask_in(out_mask_upper),
		.data_in(stage[dw*np-1:dw*np/2]), .data_out(data_out[dw*np-1:dw*np/2]), .mask_out(mask_out[2*M-1:M]));
	banyan #(.rl(rl-1), .dw(dw), .np(np/2)) bot(.clk(clk), .time_state(recurse_time_state[rl-2:0]), .mask_in(out_mask_lower),
		.data_in(stage[dw*np/2-1:    0]), .data_out(data_out[dw*np/2-1:    0]), .mask_out(mask_out[  M-1:0]));
end else begin: passthrough
	// base of recursion
	assign data_out = stage;
	assign mask_out = {out_mask_upper,out_mask_lower};
end endgenerate
endmodule

// =======================================
// Totally combinatorial count of number of bits set in a word
// Uses recursion
module two_set #(
	parameter dw=8
) (
	input [dw-1:0] d,
	output one,  // or more bits of d are set
	output two   // or more bits of d are set
);
wire one_lower, one_upper;
wire two_lower, two_upper;
generate if (dw > 1) begin: split
	two_set #(.dw(   dw/2)) lower(.d(d[dw/2-1  :0]), .one(one_lower), .two(two_lower));
	two_set #(.dw(dw-dw/2)) upper(.d(d[dw-1 :dw/2]), .one(one_upper), .two(two_upper));
	assign one = one_lower | one_upper;
	assign two = two_lower | two_upper | (one_lower & one_upper);
end else begin: passthrough
	// single bit case is trivial
	assign one = d[0];
	assign two = 0;
end endgenerate
endmodule
