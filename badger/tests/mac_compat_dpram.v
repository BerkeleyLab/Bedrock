
// memory and control signals are handled external to
// mac_subset.v in this branch
// That breaks all the testbenches, which have been designed for integrated memory
// This is just a compatibility file, containing memory and behaving in a way
// the testbenches expect, to get them working again.

module mac_compat_dpram #(
	parameter mac_aw=10
) (
	// interface to the testbench
	input host_clk,
	input [mac_aw:0] host_waddr,
	input host_write,
	input [15:0] host_wdata,
	// interface to the mac_subset
	input tx_clk,
	input [mac_aw - 1: 0] host_raddr,
	output reg [15:0] host_rdata,
	output reg [mac_aw - 1: 0] buf_start_addr,
	output reg tx_mac_start
);

initial begin
	host_rdata = 0;
	tx_mac_start = 0;
end

// Dual-port RAM for TX-Mac. P1: testbench input, P2: mac_subset
reg [15:0] host_mem[0:(1<<mac_aw)-1];
wire host_dpram_write = host_write & ~host_waddr[mac_aw];
always @(posedge host_clk) if (host_dpram_write)
	host_mem[host_waddr[mac_aw-1:0]] <= host_wdata;
always @(posedge tx_clk) host_rdata <= host_mem[host_raddr];

// Writing the start address triggers sending
wire host_start_write = host_write & host_waddr[mac_aw];
always @(posedge host_clk) begin
	if (host_start_write & ~host_waddr[0]) buf_start_addr <= host_wdata;
	if (host_start_write) tx_mac_start <= ~host_waddr[0];
end

endmodule // mac_compat_dpram
