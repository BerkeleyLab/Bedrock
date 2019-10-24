// Baseline/provisional/experimental Rx MAC,
// ties to functionality in pbuf_writer.v
//
// 11-bit host_raddr for dpram addressing.
// Packet memory appears to host as 16 bits wide,
// so 4 kBytes overall.
module base_rx_mac (
	// Host side of Rx MAC memory
	input host_clk,
	input [10:0] host_raddr,
	output reg [15:0] host_rdata,
	// port to Rx MAC memory
	input rx_clk,
	input [7:0] rx_mac_d,
	input [11:0] rx_mac_a,
	input rx_mac_wen,
	// port to Rx MAC packet selector
	output rx_mac_accept,
	input [7:0] rx_mac_status_d,
	input rx_mac_status_s
);
initial host_rdata=0;

// Dual-port RAM
localparam aw=11;
reg [7:0] pack_mem_l[0:(1<<aw)-1];
reg [7:0] pack_mem_h[0:(1<<aw)-1];
// Write from Ethernet, 8-bit port and therefore aw+1 address bits coming in
wire a_lsb = rx_mac_a[0];
wire [aw-1:0] a_msb = rx_mac_a[aw:1];
always @(posedge rx_clk) if (rx_mac_wen) begin
	if (a_lsb) pack_mem_l[a_msb] <= rx_mac_d;
	else       pack_mem_h[a_msb] <= rx_mac_d;
end
// Read from host
wire [aw-1:0] raddr = host_raddr;
always @(posedge host_clk) host_rdata <= {pack_mem_h[raddr], pack_mem_l[raddr]};

// Accept valid IP packets addressed to us, that won't be handled by fabric.
// See comments regarding status_vec in scanner.v.
reg rx_mac_accept_r=0;
always @(posedge rx_clk) if (rx_mac_status_s)
	rx_mac_accept_r <= rx_mac_status_d[4:0] == 5'b11100;
assign rx_mac_accept = rx_mac_accept_r;

endmodule
