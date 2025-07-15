`timescale 1ns / 1ns

// Adapted from (and should replace!) rtefi_pipe_tb.v
// In turn adapted from core/aggregate_tb.v
module hw_test_tb;

parameter [31:0] ip = {8'd192, 8'd168, 8'd7, 8'd6};  // 192.168.7.6
parameter [47:0] mac = 48'h12555500012d;
parameter paw = 11;  // packet (memory) address width, nominal 11
reg clk;
integer cc;
reg trace;
wire continue_sim;
`define LINUX_TUN
`ifdef LINUX_TUN
assign continue_sim = 1;
`else
assign continue_sim = cc<3800;
`endif
initial begin
	$display("Non-checking testbench.  Will always PASS");
	trace = $test$plusargs("trace");
	if ($test$plusargs("vcd")) begin
		$dumpfile("hw_test.vcd");
		$dumpvars(6,hw_test_tb);
	end
	for (cc=0; continue_sim; cc=cc+1) begin
		clk=0; #4;  // 125 MHz * 8bits/cycle -> 1 Gbit/sec
		clk=1; #4;
	end
	$display("PASS");
	$finish(0);
end

// Create flow of packets
wire [7:0] eth_out;
wire eth_out_s;
wire thinking;  // hook to make things run efficiently
`ifdef LINUX_TUN
reg [7:0] eth_in=0, eth_in_=0;
reg eth_in_s=0, eth_in_s_=0;
always @(posedge clk) begin
	if (cc > 4) $tap_io(eth_out, eth_out_s, eth_in_, eth_in_s_, thinking);
	eth_in <= eth_in_;
	eth_in_s <= eth_in_s_;
end
`else
wire eth_in_s;
wire [7:0] eth_in;
// offline takes care of its own argument parsing and file opening
offline offline(.clk(clk), .rx_dv(eth_in_s), .rxd(eth_in));
`endif

// Data path from Verilog to virtual Ethernet bus
wire tx_clk = clk;
wire [7:0] GMII_TXD;  assign eth_out = GMII_TXD;
wire GMII_TX_EN;      assign eth_out_s = GMII_TX_EN;
wire GMII_TX_ER;

// Data path from virtual Ethernet bus to Verilog
wire vgmii_rx_clk = clk;
wire GMII_RX_DV = eth_in_s;
wire [7:0] GMII_RXD = eth_in;
wire GMII_RX_ER = 0;  // Maybe eventually we'll test this

// Potential attachment to MMC; not exercised here
wire SCLK, CSB, MOSI;

// Attachment to SPI boot Flash; not exercised here
wire BOOT_CCLK, BOOT_CS_B, BOOT_MOSI, BOOT_MISO;

// Other
wire RESET = 0;  // not used by hw_test
wire [3:0] LED;
wire clk_locked = 1;
wire PHY_RSTN;

// Real work
hw_test #(.ip(ip), .mac(mac)) vgmii(
	.vgmii_tx_clk(tx_clk), .vgmii_txd(GMII_TXD),
	.vgmii_tx_en(GMII_TX_EN), .vgmii_tx_er(GMII_TX_ER),
	.vgmii_rx_clk(vgmii_rx_clk), .vgmii_rxd(GMII_RXD),
	.vgmii_rx_dv(GMII_RX_DV), .vgmii_rx_er(GMII_RX_ER),
	.phy_rstn(PHY_RSTN), .clk_locked(clk_locked),
	.SCLK(SCLK), .CSB(CSB), .MOSI(MOSI),
	.boot_clk(BOOT_CCLK), .boot_cs(BOOT_CS_B),
	.boot_mosi(BOOT_MOSI), .boot_miso(BOOT_MISO),
	.in_use(thinking),
	.RESET(RESET), .LED(LED)
);

// Initialize some memory
// Otherwise x's leak into the packet, which confuses everyone
// especially the CRC computation.
integer iix;
integer mac_aw=12;
initial begin
	for (iix=0; iix < (1<<mac_aw); iix = iix + 1) begin
		vgmii.rx_mac.pack_mem_l[iix] = 0;
		vgmii.rx_mac.pack_mem_h[iix] = 0;
	end
end

endmodule
