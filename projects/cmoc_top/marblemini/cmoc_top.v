module cmoc_top(
	input       GTPREFCLK_P,
	input       GTPREFCLK_N,
	input       SYSCLK_P,

	// RGMII Tx port
	output [3:0] RGMII_TXD,
	output       RGMII_TX_CTRL,
	output       RGMII_TX_CLK,

	// RGMII Rx port
	input [3:0]  RGMII_RXD,
	input       RGMII_RX_CTRL,
	input       RGMII_RX_CLK,

	// SPI boot flash programming port
	// BOOT_CCLK treated specially in 7-series
	output      BOOT_CS_B,
	input       BOOT_MISO,
	output      BOOT_MOSI,
	output      CFG_D02, // hope R209 is DNF

	// One I2C bus, with everything gatewayed through a TCA9548
	output      TWI_SCL,
	inout       TWI_SDA,
	output      TWI_RST,
	input       TWI_INT,

	// SPI pins connected to microcontroller
	input       SCLK,
	input       CSB,
	input       MOSI,
	output      MISO,
	output      MMC_INT,

	// White Rabbit DAC
	output       WR_DAC_SCLK,
	output       WR_DAC_DIN,
	output       WR_DAC1_SYNC,
	output       WR_DAC2_SYNC,

	// UART to USB
	// The RxD and TxD directions are with respect
	// to the USB/UART chip, not the FPGA!
	output       FPGA_RxD,
	input       FPGA_TxD,

	// Reset command to PHY
	output       PHY_RSTN,

	output       VCXO_EN,

	// J15 TMDS 0, 1, 2, CLK
	output [3:0] TMDS_P,
	output [3:0] TMDS_N,

	// Directly attached LEDs
	output LD16,
	output LD17,

	// Physical Pmod
	output [7:0] Pmod1,
	input [7:0] Pmod2
);

`include "marble_features.vh"

wire gtpclk0, gtpclk;
// Gateway GTP refclk to fabric
IBUFDS_GTE2 passi_125(.I(GTPREFCLK_P), .IB(GTPREFCLK_N), .CEB(1'b0), .O(gtpclk0));
// Vivado fails, with egregiously useless error messages,
// if you don't put this BUFG in the chain to the MMCM.
BUFG passg_125(.I(gtpclk0), .O(gtpclk));

wire si570;
assign si570 = 0;

parameter in_phase_tx_clk = 1;
// Standardized interface, hardware-dependent implementation
wire tx_clk, tx_clk90, clk62;
wire clk_locked;
wire pll_reset = 0;  // or RESET?
wire clk_out1;
wire clk200;  // clk200 should be 200MHz +/- 10MHz or 300MHz +/- 10MHz,
// used for calibrating IODELAY cells

// You really want to set this define.
// It's only valid to leave it off when C_USE_RGMII_IDELAY is 0.
// It might be useful to not define it if you're exploring parameter space
// or have problems with the Xilinx DNA readout.
`define USE_IDELAYCTRL

`define USE_GTPCLK
`ifdef USE_GTPCLK
xilinx7_clocks #(
        .DIFF_CLKIN("BYPASS"),
        .CLKIN_PERIOD(8),  // REFCLK = 125 MHz
        .MULT     (8),     // 125 MHz X 8 = 1 GHz on-chip VCO
        .DIV0     (8),       // 1 GHz / 8 = 125 MHz
`ifdef USE_IDELAYCTRL
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
        .locked   (clk_locked)
);
`else
wire SYSCLK_N = 0;
gmii_clock_handle clocks(
	.sysclk_p(SYSCLK_P),
	.sysclk_n(SYSCLK_N),
	.reset(pll_reset),
	.clk_eth(tx_clk),
	.clk_eth_90(tx_clk90),
	.clk_locked(clk_locked)
);
`endif

`ifdef USE_IDELAYCTRL
assign clk200 = clk_out1;
reg bad_slow_clock=0;
always @(posedge tx_clk) bad_slow_clock <= ~bad_slow_clock;
assign clk62 = bad_slow_clock;  // sample-size of two says readout of dna still works
`else
assign clk200 = 0;
assign clk62 = clk_out1;  // better tested way to give dna primitive the clock it wants
`endif

// Double-data-rate conversion
wire vgmii_tx_clk, vgmii_tx_clk90, vgmii_rx_clk;
wire [7:0] vgmii_txd, vgmii_rxd;
wire vgmii_tx_en, vgmii_tx_er, vgmii_rx_dv, vgmii_rx_er;
wire idelay_clk, idelay_ce;
wire [4:0] idelay_value_in, idelay_value_out_ctl, idelay_value_out_data;
gmii_to_rgmii #(
    .use_idelay(C_USE_RGMII_IDELAY),
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
    .idelay_value_in(idelay_value_in),
    .idelay_value_out_ctl(idelay_value_out_ctl),
    .idelay_value_out_data(idelay_value_out_data)
);

wire BOOT_CCLK;
wire cfg_clk;  // Just for fun, so we can measure its frequency
`ifndef SIMULATE
STARTUPE2 set_cclk(.USRCCLKO(BOOT_CCLK), .USRCCLKTS(1'b0), .CFGMCLK(cfg_clk));
`else // !`ifndef SIMULATE
   assign cfg_clk = 0;
   assign BOOT_CCLK = tx_clk;
`endif // !`ifndef SIMULATE

// Placeholders
wire ZEST_PWR_EN;
wire dum_scl, dum_sda;
wire [3:0] ext_config;
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

`ifdef USE_IDELAYCTRL
wire idelayctrl_reset;  // prc pushes this button with software
assign idelayctrl_reset = ext_config[2];  // might be helpful?
`ifndef SIMULATE
    wire idelayctrl_rdy;  // ignored, just like in prc
    (* IODELAY_GROUP = "IODELAY_200" *)
    IDELAYCTRL idelayctrl (.RST(idelayctrl_reset),.REFCLK(clk200),.RDY(idelayctrl_rdy));
`endif
`endif

`ifdef USE_I2CBRIDGE
localparam C_USE_I2CBRIDGE = 1;
`else
localparam C_USE_I2CBRIDGE = 0;
`endif

// vestiges of CERN FMC tester support
wire old_scl1, old_scl2, old_sda1, old_sda2;

wire [7:0] LED;
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
	.LED(LED), .GPS(Pmod2[3:0]), .ext_config(ext_config)
);

`ifndef SIMULATE
defparam base.rtefi.p4_client.engine.seven = 1;
`endif

parameter BUF_AW=13;
assign LD16 = LED[0];
assign LD17 = LED[1];
assign Pmod1 = LED;

// test_marble_family instantiates a "Silly little test pattern generator" for these pins
wire [3:0] tmds_q = 4'b0000;
OBUFDS obuf[0:3] (.I(~ext_config), .O(TMDS_P), .OB(TMDS_N));

// These are meaningful LEDs, one could use them
wire [2:0] D4rgb;
wire [2:0] D5rgb;

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

// Give the network the option of turning off the 20 MHz VCXO
assign VCXO_EN = ~ext_config[1];

endmodule
