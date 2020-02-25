// GMII Hardware Test
// mostly just instantiates hw_test
// Can support different boards by plugging in different implementations
// of a clock support module.
// So far:  SP605 and KC705
module gmii_hw_test(
	// 200 MHz typical
	input SYSCLK_P,
	input SYSCLK_N,

	// GMII Tx port
	output [7:0] GMII_TXD,
	output GMII_TX_EN,
	output GMII_TX_ER,
	output GMII_GTX_CLK,
	input GMII_TX_CLK, // not used

	// GMII Rx port
	input [7:0] GMII_RXD,
	input GMII_RX_ER,
	input GMII_RX_DV,
	input GMII_RX_CLK,

	// Reset command to PHY
	output PHY_RSTN,

	// SPI pins, can give access to configuration
	input SCLK,
	input CSB,
	input MOSI,

	// SPI boot flash programming port
`ifndef CHIP_FAMILY_7SERIES
	output BOOT_CCLK,
`endif
	output BOOT_CS_B,
	input  BOOT_MISO,
	output BOOT_MOSI,

	// Something physical
	input RESET,
	output [3:0] LED
);

// Standardized interface, hardware-dependent implementation
wire rx_clk = GMII_RX_CLK;
wire tx_clk;
wire clk_locked;
gmii_clock_handle clocks(
	.sysclk_p(SYSCLK_P),
	.sysclk_n(SYSCLK_N),
	.reset(RESET),
	.clk_eth(tx_clk),
	.clk_pin(GMII_GTX_CLK),  // output pin to PHY
	.clk_locked(clk_locked)
);

// Nothing fancy here, right?
wire vgmii_rx_clk;
buf rx_clk_in(vgmii_rx_clk, GMII_RX_CLK);

`ifdef CHIP_FAMILY_7SERIES
wire BOOT_CCLK;
// See XAPP1081 p.25: 7 Series FPGAs Access to the SPI Clock
// and UG470 p. 90: STARTUPE2 Primitive
STARTUPE2 set_cclk(.USRCCLKO(BOOT_CCLK), .USRCCLKTS(1'b0));
defparam vgmii.rtefi.p4_client.engine.seven = 1;
`endif

// Set to 1 for SP605 testing
defparam vgmii.rtefi.p4_client.engine.xc6slx = 0;

// Real work
hw_test vgmii(
	.vgmii_tx_clk(tx_clk), .vgmii_txd(GMII_TXD),
	.vgmii_tx_en(GMII_TX_EN), .vgmii_tx_er(GMII_TX_ER),
	.vgmii_rx_clk(vgmii_rx_clk), .vgmii_rxd(GMII_RXD),
	.vgmii_rx_dv(GMII_RX_DV), .vgmii_rx_er(GMII_RX_ER),
	.phy_rstn(PHY_RSTN), .clk_locked(clk_locked),
	.SCLK(SCLK), .CSB(CSB), .MOSI(MOSI),
	.boot_clk(BOOT_CCLK), .boot_cs(BOOT_CS_B),
	.boot_mosi(BOOT_MOSI), .boot_miso(BOOT_MISO),
	.RESET(RESET), .LED(LED)
);

endmodule
