// Ultra-stupid layer to define clock domains of signals coming in and out of hw_test
// See cdc_snitch.py
module hw_test_skin(
	// GMII Tx port
	input vgmii_tx_clk,
	output [7:0] vgmii_txd,
	output vgmii_tx_en,
	output vgmii_tx_er,

	// GMII Rx port
	input vgmii_rx_clk,
	input [7:0] vgmii_rxd,
	input vgmii_rx_er,
	input vgmii_rx_dv,

	// Auxiliary I/O and status
	output phy_rstn,
	input clk_locked,

	// SPI pins, which on Marble are a link to the on-board microcontroller
	// and get used to set IP and MAC, among other things.
	input SCLK,
	input CSB,
	input MOSI,
	output MISO,

	// SPI boot flash programming port
	output boot_clk,
	output boot_cs,
	output boot_mosi,
	input boot_miso,

	// Simulation-only; please ignore in synthesis
	output in_use,

	// Something physical
	input RESET,
	output [3:0] LED

);

// vgmii Tx
wire [7:0] vgmii_txd_w;
reg [7:0] vgmii_txd_r=0;
wire vgmii_tx_en_w, vgmii_tx_er_w;
reg vgmii_tx_en_r=0, vgmii_tx_er_r=0;
always @(posedge vgmii_tx_clk) begin
	vgmii_txd_r <= vgmii_txd_w;
	vgmii_tx_en_r <= vgmii_tx_en_w;
	vgmii_tx_er_r <= vgmii_tx_er_w;
end
assign vgmii_txd = vgmii_txd_r;
assign vgmii_tx_en = vgmii_tx_en_r;
assign vgmii_tx_er = vgmii_tx_er_r;

// vgmii Rx
(* magic_cdc *) reg [7:0] vgmii_rxd_r=0;
(* magic_cdc *) reg vgmii_rx_dv_r=0, vgmii_rx_er_r=0;
always @(posedge vgmii_rx_clk) begin
	vgmii_rxd_r <= vgmii_rxd;
	vgmii_rx_dv_r <= vgmii_rx_dv;
	vgmii_rx_er_r <= vgmii_rx_er;
end

// Module under test
hw_test i_hw(
	.vgmii_tx_clk(vgmii_tx_clk), .vgmii_txd(vgmii_txd_w),
	.vgmii_tx_en(vgmii_tx_en_w), .vgmii_tx_er(vgmii_tx_er_w),
	.vgmii_rx_clk(vgmii_rx_clk), .vgmii_rxd(vgmii_rxd_r),
	.vgmii_rx_dv(vgmii_rx_dv_r), .vgmii_rx_er(vgmii_rx_er_r),
	.phy_rstn(phy_rstn), .clk_locked(clk_locked),
	.SCLK(SCLK), .CSB(CSB), .MOSI(MOSI), .MISO(MISO),
	.boot_clk(boot_clk), .boot_cs(boot_cs),
	.boot_mosi(boot_mosi), .boot_miso(boot_miso),
	.in_use(in_use),
	.RESET(RESET), .LED(LED)
);

endmodule
