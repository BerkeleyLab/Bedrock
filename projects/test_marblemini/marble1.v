// Top level Marble-Mini test build
// Mostly cut-and-paste from rgmii_hw_test.v
module marble1(
	input SYSCLK_P,
	// RGMII Tx port
	output [3:0] RGMII_TXD,
	output RGMII_TX_CTRL,
	output RGMII_TX_CLK,

	// RGMII Rx port
	input [3:0] RGMII_RXD,
	input RGMII_RX_CTRL,
	input RGMII_RX_CLK,

	// Reset command to PHY
	output PHY_RSTN,

	// SPI pins connected to microcontroller
	input SCLK,
	input CSB,
	input MOSI,
	output MISO,
	output MMC_INT,

	// SPI boot flash programming port
	// BOOT_CCLK treated specially in 7-series
	output BOOT_CS_B,
	input  BOOT_MISO,
	output BOOT_MOSI,
	output CFG_D02,  // hope R209 is DNF

	// One I2C bus, everything gatewayed through a TCA9548
	output TWI_SCL,
	inout  TWI_SDA,
	output TWI_RST,
	input  TWI_INT,

	// White Rabbit DAC
	output WR_DAC_SCLK,
	output WR_DAC_DIN,
	output WR_DAC1_SYNC,
	output WR_DAC2_SYNC,

	output VCXO_EN,

	// Zest stuff
	output ZEST_PWR_EN,
	// Something physical
	output [7:0] LED
);

assign VCXO_EN = 1;
wire SYSCLK_N = 0;
parameter in_phase_tx_clk = 1;
// Standardized interface, hardware-dependent implementation
wire tx_clk, tx_clk90;
wire clk_locked;
wire pll_reset = 0;  // or RESET?
gmii_clock_handle clocks(
	.sysclk_p(SYSCLK_P),
	.sysclk_n(SYSCLK_N),
	.reset(pll_reset),
	.clk_eth(tx_clk),
	.clk_eth_90(tx_clk90),
	.clk_locked(clk_locked)
);

// Double-data-rate conversion
wire vgmii_tx_clk, vgmii_tx_clk90, vgmii_rx_clk;
wire [7:0] vgmii_txd, vgmii_rxd;
wire vgmii_tx_en, vgmii_tx_er, vgmii_rx_dv, vgmii_rx_er;
gmii_to_rgmii #(.in_phase_tx_clk(in_phase_tx_clk)) gmii_to_rgmii_i(
	.rgmii_txd(RGMII_TXD),
	.rgmii_tx_ctl(RGMII_TX_CTRL),
	.rgmii_tx_clk(RGMII_TX_CLK),
	.rgmii_rxd(RGMII_RXD),
	.rgmii_rx_ctl(RGMII_RX_CTRL),
	.rgmii_rx_clk(RGMII_RX_CLK),

	.gmii_tx_clk(tx_clk),
	.gmii_tx_clk90(tx_clk90),
	.gmii_txd(vgmii_txd),
	.gmii_tx_en(vgmii_tx_en),
	.gmii_tx_er(vgmii_tx_er),
	.gmii_rxd(vgmii_rxd),
	.gmii_rx_clk(vgmii_rx_clk),
	.gmii_rx_dv(vgmii_rx_dv),
	.gmii_rx_er(vgmii_rx_er)
);

wire BOOT_CCLK;
STARTUPE2 set_cclk(.USRCCLKO(BOOT_CCLK), .USRCCLKTS(1'b0));

// Real, portable implementation
// Consider pulling 3-state drivers out of this
marble_base base(
	.vgmii_tx_clk(tx_clk), .vgmii_txd(vgmii_txd),
	.vgmii_tx_en(vgmii_tx_en), .vgmii_tx_er(vgmii_tx_er),
	.vgmii_rx_clk(vgmii_rx_clk), .vgmii_rxd(vgmii_rxd),
	.vgmii_rx_dv(vgmii_rx_dv), .vgmii_rx_er(vgmii_rx_er),
	.phy_rstn(PHY_RSTN), .clk_locked(clk_locked),
	.boot_clk(BOOT_CCLK), .boot_cs(BOOT_CS_B),
	.boot_mosi(BOOT_MOSI), .boot_miso(BOOT_MISO),
	.cfg_d02(CFG_D02), .mmc_int(MMC_INT), .ZEST_PWR_EN(ZEST_PWR_EN),
	.SCLK(SCLK), .CSB(CSB), .MOSI(MOSI), .MISO(MISO),
	.TWI_SCL(TWI_SCL), .TWI_SDA(TWI_SDA),
	.TWI_RST(TWI_RST), .TWI_INT(TWI_INT),
	.WR_DAC_SCLK(WR_DAC_SCLK), .WR_DAC_DIN(WR_DAC_DIN),
	.WR_DAC1_SYNC(WR_DAC1_SYNC), .WR_DAC2_SYNC(WR_DAC2_SYNC),
	.LED(LED)
);
defparam base.rtefi.p4_client.engine.seven = 1;

endmodule
