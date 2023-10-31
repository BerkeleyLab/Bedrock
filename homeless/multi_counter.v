// Single-clock-domain multi-channel counter
// No restrictions on how often the "inc" port is high.
// Reads go through dpram, so are delayed one cycle.
// Reads are passive, so don't need an enable.
`timescale 1ns / 1ns

module multi_counter #(
	parameter aw=4,  // 2**aw counters, non-resettable
	parameter dw=16  // bit-width of each counter
) (
	input clk,
	input inc,  // increment the counter specified by inc_addr
	input [aw-1:0] inc_addr,
	input [aw-1:0] read_addr,  // local bus address
	output [dw-1:0] read_data
);

// First dpram: increment on-demand
// Start by creating one-cycle-delayed controls,
// that will be time-aligned with old_plus_1.
reg inc_r=0;
always @(posedge clk) inc_r <= inc;
reg [aw-1:0] inc_addr_r=0;
always @(posedge clk) inc_addr_r <= inc_addr;
// Logic for the add-one block
wire [dw-1:0] old;
wire [dw-1:0] old_plus_1 = old+1;
// Actually instantiate dpram
dpram #(.aw(aw), .dw(dw)) incr(
	.clka(clk), .clkb(clk),
	.addra(inc_addr_r), .dina(old_plus_1), .wena(inc_r),
	.addrb(inc_addr), .doutb(old)
);

// Second dpram: mirror so host can read values
dpram #(.aw(aw), .dw(dw)) mirror(
	.clka(clk), .clkb(clk),
	.addra(inc_addr_r), .dina(old_plus_1), .wena(inc_r),
	.addrb(read_addr), .doutb(read_data)
);

// For simulation purposes, we have to assume both dpram intances
// have their memory plane initialized to zero.

endmodule
