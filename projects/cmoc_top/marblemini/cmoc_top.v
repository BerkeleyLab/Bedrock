`include "marble_features_defs.vh"

module cmoc_top(
	input GTPREFCLK_P,
	input GTPREFCLK_N,
`ifdef MARBLE_V2
	input DDR_REF_CLK_P,
	input DDR_REF_CLK_N,
`endif
	input SYSCLK_P,

	// SI570 clock inputs
	`ifdef USE_SI570
	input GTREFCLK_P,
	input GTREFCLK_N,
	`endif

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
	inout  TWI_SCL,
	inout  TWI_SDA,
	inout  TWI_RST,
	input  TWI_INT,

	// White Rabbit DAC
	output WR_DAC_SCLK,
	output WR_DAC_DIN,
	output WR_DAC1_SYNC,
	output WR_DAC2_SYNC,

	// UART to USB
	// The RxD and TxD directions are with respect
	// to the USB/UART chip, not the FPGA!
	output FPGA_RxD,
	input FPGA_TxD,

	output VCXO_EN,

`ifdef MARBLE_V2
	// Special for LTM4673 synchronization -- untested
	output [2:0] LTM_CLKIN,
`endif

`ifdef MARBLE_MINI
	// J15 TMDS 0, 1, 2, CLK
	output [3:0] TMDS_P,
	output [3:0] TMDS_N,
`endif

	// Directly attached LEDs
	output LD16,
	output LD17,

	// Physical Pmod, may be used as LEDs
	output [7:0] Pmod1,  // feel free to change to inout, if you attach to something other than LEDs
	input [7:0] Pmod2
);

`include "marble_features_params.vh"

wire lb_clk, lb_strobe, lb_rd, lb_write, lb_rd_valid;
wire [23:0] lb_addr;
wire [31:0] lb_data_out;
wire [31:0] lb_din;

wire [33:0] FMC1_LA_P;
wire [33:0] FMC1_LA_N;
wire [33:0] FMC2_LA_P;
wire [33:0] FMC2_LA_N;
wire [1:0] FMC1_CK_P;
wire [1:0] FMC1_CK_N;
wire [1:0] FMC2_CK_P;
wire [1:0] FMC2_CK_N;
wire [23:0] FMC2_HA_P;
wire [23:0] FMC2_HA_N;

`include "marble_mid.vh"

// Maybe this cruft could be eliminated if the corresponding yaml defs
// were rejiggered to be parameters.
`ifdef USE_I2CBRIDGE
localparam C_USE_I2CBRIDGE = 1;
`else
localparam C_USE_I2CBRIDGE = 0;
`endif

// Real, portable implementation
// Consider pulling 3-state drivers out of this
marble_base #(
    .USE_I2CBRIDGE(C_USE_I2CBRIDGE),
    .default_enable_rx(C_DEFAULT_ENABLE_RX),
    .misc_config_default(C_MISC_CONFIG_DEFAULT)
) base(
	.vgmii_tx_clk(tx_clk), .vgmii_txd(vgmii_txd),
	.vgmii_tx_en(vgmii_tx_en), .vgmii_tx_er(vgmii_tx_er),
	.vgmii_rx_clk(vgmii_rx_clk), .vgmii_rxd(vgmii_rxd),
	.vgmii_rx_dv(vgmii_rx_dv), .vgmii_rx_er(vgmii_rx_er),
	.phy_rstn(PHY_RSTN), .clk_locked(clk_locked), .si570(si570),
	.boot_clk(BOOT_CCLK), .boot_cs(BOOT_CS_B),
	.boot_mosi(BOOT_MOSI), .boot_miso(BOOT_MISO),
	.cfg_d02(CFG_D02), .mmc_int(MMC_INT), .ZEST_PWR_EN(ZEST_PWR_EN),
	.aux_clk(SYSCLK_P), .clk62(clk62), .cfg_clk(cfg_clk),
	.SCLK(SCLK), .CSB(CSB), .MOSI(MOSI), .MISO(MISO),
	.FPGA_RxD(FPGA_RxD), .FPGA_TxD(FPGA_TxD),
	.twi_scl({dum_scl, old_scl1, old_scl2, TWI_SCL}),
	.twi_sda({dum_sda, old_sda1, old_sda2, TWI_SDA}),
	.TWI_RST(TWI_RST), .TWI_INT(TWI_INT),
	.lb_clk(lb_clk),
	.lb_addr(lb_addr),
	.lb_strobe(lb_strobe),
	.lb_rd(lb_rd),
	.lb_write(lb_write),
	.lb_rd_valid(lb_rd_valid),
	.lb_data_out(lb_data_out),
	.lb_data_in(lb_din),
	.fmc_test({
		FMC2_HA_P, FMC2_HA_N, FMC2_CK_P, FMC2_CK_N, FMC2_LA_P, FMC2_LA_N,
		FMC1_CK_P, FMC1_CK_N, FMC1_LA_P, FMC1_LA_N}),
	.WR_DAC_SCLK(WR_DAC_SCLK), .WR_DAC_DIN(WR_DAC_DIN),
	.WR_DAC1_SYNC(WR_DAC1_SYNC), .WR_DAC2_SYNC(WR_DAC2_SYNC),
	.GPS(Pmod2[3:0]), .ext_config(ext_config), .ps_sync(ps_sync), .LED(leds)
);

parameter BUF_AW=13;
wire clk_1x_90, clk_2x_0, clk_eth, clk_eth_90;
parameter clk2x_div = 5;  // relative to 750 MHz (tx_clk * 6)
clocks #(.mmcm_div0(clk2x_div*2), .mmcm_div1(clk2x_div)) clocks(
    .rst(1'b0),
    .sysclk_buf(tx_clk),
    .clk_eth(clk_eth),
    .clk_eth_90(clk_eth_90),
    .clk_1x_90(clk_1x_90),
    .clk_2x_0(clk_2x_0)
);

parameter vmod_mode_count=3;
cryomodule #(
    .mode_count(vmod_mode_count),
    .use_config_rom(0)
) cryomodule(
    .clk1x(clk_1x_90),
    .clk2x(clk_2x_0),
    // Local Bus drives both simulator and controller
    // Simulator is in the upper 16K, controller in the lower 16K words.
    .lb_clk(lb_clk),
    .lb_data(lb_data_out),
    .lb_addr(lb_addr[16:0]),
    .lb_write(lb_write),  // single-cycle causes a write // XXX write or strobe?
    .lb_read(lb_rd),
    .lb_out(lb_din)
);

endmodule
