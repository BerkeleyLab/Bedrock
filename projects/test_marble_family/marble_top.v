// Top level Marble-Mini and Marble v2 test build
// Mostly cut-and-paste from rgmii_hw_test.v

`include "marble_features_defs.vh"
// At least one Marble v1.4 board _needs_ this option set
// to get reliable Ethernet operation.  Need more data.
`define DEBUG_RGMII

module marble_top(
	input GTPREFCLK_P,
	input GTPREFCLK_N,
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

	// FMC stuff
	inout [33:0] FMC1_LA_P,
	inout [33:0] FMC1_LA_N,
	inout [33:0] FMC2_LA_P,
	inout [33:0] FMC2_LA_N,
	// output ZEST_PWR_EN,

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

wire gtpclk0, gtpclk;
// Gateway GTP refclk to fabric
IBUFDS_GTE2 passi_125(.I(GTPREFCLK_P), .IB(GTPREFCLK_N), .CEB(1'b0), .O(gtpclk0));
// Vivado fails, with egregiously useless error messages,
// if you don't put this BUFG in the chain to the MMCM.
BUFG passg_125(.I(gtpclk0), .O(gtpclk));

wire si570;
`ifdef USE_SI570
// Single-ended clock derived from programmable xtal oscillator
ds_clk_buf #(
   .GTX (1))
i_ds_gtrefclk1 (
   .clk_p   (GTREFCLK_P),
   .clk_n   (GTREFCLK_N),
   .clk_out (si570)
);
`else
assign si570 = 0;
`endif

parameter in_phase_tx_clk = 1;
// Standardized interface, hardware-dependent implementation
wire tx_clk, tx_clk90, clk62;
wire clk_locked;
wire pll_reset = 0;  // or RESET?
wire test_clk;
wire clk_out1;
wire clk200;  // clk200 should be 200MHz +/- 10MHz or 300MHz +/- 10MHz,
// used for calibrating IODELAY cells

`ifdef USE_GTPCLK
xilinx7_clocks #(
	.DIFF_CLKIN("BYPASS"),
	.CLKIN_PERIOD(8),  // REFCLK = 125 MHz
	.MULT     (8),     // 125 MHz X 8 = 1 GHz on-chip VCO
	.DIV0     (8),     // 1 GHz / 8 = 125 MHz
`ifdef DEBUG_RGMII
       .DIV1     (5)     // 1 GHz / 5 = 200 MHz
`else
	.DIV1     (16)     // 1 GHz / 16 = 62.5 MHz
`endif
) clocks_i(
	.sysclk_p (gtpclk),
	.sysclk_n (1'b0),
	.reset    (pll_reset),
	.clk_out0 (tx_clk),
	.clk_out1 (clk_out1),
	.clk_out2 (tx_clk90),
	.clk_out3f(test_clk),  // not buffered, straight from MMCM
	.locked   (clk_locked)
);
`else
// this configuration is probably bit-rotted
wire SYSCLK_N = 0;
gmii_clock_handle clocks(
	.sysclk_p(SYSCLK_P),
	.sysclk_n(SYSCLK_N),
	.reset(pll_reset),
	.clk_eth(tx_clk),
	.clk_eth_90(tx_clk90),
	.clk_locked(clk_locked)
);
assign test_clk=0;
`endif
`ifdef DEBUG_RGMII
assign clk200 = clk_out1;
reg bad_slow_clock=0;
always @(posedge tx_clk) bad_slow_clock <= ~bad_slow_clock;
assign clk62 = bad_slow_clock;  // sample-size of one says readout of dna still works
`else
assign clk200 = 0;
assign clk62 = clk_out1;
`endif

// Double-data-rate conversion
wire vgmii_tx_clk, vgmii_tx_clk90, vgmii_rx_clk;
wire [7:0] vgmii_txd, vgmii_rxd;
wire vgmii_tx_en, vgmii_tx_er, vgmii_rx_dv, vgmii_rx_er;
wire idelay_clk, idelay_ce;
wire [4:0] idelay_value_in;
gmii_to_rgmii #(
`ifdef DEBUG_RGMII
	.use_idelay(1),
`endif
	.in_phase_tx_clk(in_phase_tx_clk)
) gmii_to_rgmii_i(
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
	.gmii_rx_er(vgmii_rx_er),

	.clk_div(idelay_clk),
	.idelay_ce(idelay_ce),
	.idelay_value_in(idelay_value_in)
);

wire BOOT_CCLK;
wire cfg_clk;  // Just for fun, so we can measure its frequency
`ifndef SIMULATE
STARTUPE2 set_cclk(.USRCCLKO(BOOT_CCLK), .USRCCLKTS(1'b0), .CFGMCLK(cfg_clk));
`else
assign cfg_clk = 0;
`endif

// Placeholders
wire ZEST_PWR_EN;
wire dum_scl, dum_sda;
wire [3:0] ext_config;

`ifdef DEBUG_RGMII
wire idelayctrl_reset;  // prc pushes this button with software
assign idelayctrl_reset = ext_config[2];  // might be helpful?
`ifndef SIMULATE
	wire idelayctrl_rdy;  // ignored, just like in prc
	(* IODELAY_GROUP = "IODELAY_200" *)
	IDELAYCTRL idelayctrl (.RST(idelayctrl_reset),.REFCLK(clk200),.RDY(idelayctrl_rdy));
`endif
`endif

// Placeholders for possible IDELAY control inside gmii_to_rgmii
assign idelay_clk = 0;
assign idelay_ce = 0;
assign idelay_value_in = 0;

`ifdef USE_I2CBRIDGE
localparam C_USE_I2CBRIDGE = 1;
`else
localparam C_USE_I2CBRIDGE = 0;
`endif
`ifdef MMC_CTRACE
localparam C_MMC_CTRACE = 1;
`else
localparam C_MMC_CTRACE = 0;
`endif

wire [7:0] leds;
// Real, portable implementation
// Consider pulling 3-state drivers out of this
marble_base #(
	.USE_I2CBRIDGE(C_USE_I2CBRIDGE),
	.MMC_CTRACE(C_MMC_CTRACE),
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
	.twi_scl({dum_scl, FMC2_LA_P[2], FMC1_LA_P[2], TWI_SCL}),
	.twi_sda({dum_sda, FMC2_LA_N[2], FMC1_LA_N[2], TWI_SDA}),
	.fmc_test({
		FMC2_LA_P[33:3], FMC2_LA_P[1:0],
		FMC2_LA_N[33:3], FMC2_LA_N[1:0],
		FMC1_LA_P[33:3], FMC1_LA_P[1:0],
		FMC1_LA_N[33:3], FMC1_LA_N[1:0]}),
	.TWI_RST(TWI_RST), .TWI_INT(TWI_INT),
	.WR_DAC_SCLK(WR_DAC_SCLK), .WR_DAC_DIN(WR_DAC_DIN),
	.WR_DAC1_SYNC(WR_DAC1_SYNC), .WR_DAC2_SYNC(WR_DAC2_SYNC),
	.GPS(Pmod2[3:0]), .ext_config(ext_config), .LED(leds)
);
`ifndef SIMULATE
// Verilator can't handle this, says
//   Unsupported: defparam with more than one dot
defparam base.rtefi.p4_client.engine.seven = 1;
`endif
assign Pmod1 = leds;
assign LD16 = leds[0];
assign LD17 = leds[1];

`ifdef MARBLE_MINI
// TMDS test pattern generation
wire tmds_enable = ext_config[0];
tmds_test tmds_test(.clk(test_clk), .enable(tmds_enable),
	.tmds_p(TMDS_P), .tmds_n(TMDS_N));
`endif

// Give the network the option of turning off the 20 MHz VCXO
assign VCXO_EN = ~ext_config[1];

endmodule
