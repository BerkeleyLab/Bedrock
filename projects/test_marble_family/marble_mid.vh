// Only Marble V2 has DDR ref clk
wire ddrrefclk_unbuf, ddrrefclk;
generate
if (C_CARRIER_REV == "v2") begin
IBUFDS ddri_125(.I(DDR_REF_CLK_P), .IB(DDR_REF_CLK_N), .O(ddrrefclk_unbuf));
// Vivado fails, with egregiously useless error messages,
// if you don't put this BUFG in the chain to the MMCM.
BUFG ddrg_125(.I(ddrrefclk_unbuf), .O(ddrrefclk));
end
endgenerate

// For Marblemini, GTREFCLKs are routed directly to MGTCLK pins,
// so using them does not depend on the clock switch configuration
// either
wire gtclk0, gtclk;
// Gateway GT refclk to fabric
IBUFDS_GTE2 passi_125(.I(GTREFCLK_P), .IB(GTREFCLK_N), .CEB(1'b0), .O(gtclk0));
// Vivado fails, with egregiously useless error messages,
// if you don't put this BUFG in the chain to the MMCM.
BUFG passg_125(.I(gtclk0), .O(gtclk));

wire si570;
`ifdef USE_SI570
// Single-ended clock derived from programmable xtal oscillator
ds_clk_buf #(
	.GTX (1))
i_ds_gtrefclk1 (
	.clk_p   (SIREFCLK_P),
	.clk_n   (SIREFCLK_N),
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

// You really want to set this define.
// It's only valid to leave it off when C_USE_RGMII_IDELAY is 0.
// It might be useful to not define it if you're exploring parameter space
// or have problems with the Xilinx DNA readout.
`define USE_IDELAYCTRL

// Sanity check for C_SYSCLK_SRC
generate
if (C_SYSCLK_SRC != "gt_ref_clk" &&
    C_SYSCLK_SRC != "ddr_ref_clk" &&
    C_SYSCLK_SRC != "sys_clk") begin
    C_SYSCLK_SRC_parameter_has_an_invalid_value bad_1();
end
endgenerate

// If using ddr_ref_clk it must be a v2
generate
if (C_SYSCLK_SRC == "ddr_ref_clk" &&
    C_CARRIER_REV != "v2") begin
    C_SYSCLK_SRC_ddr_ref_clk_can_only_be_used_with_a_Marble_v2 bad_2();
end
endgenerate

generate
// this configuration is probably bit-rotted
if (C_SYSCLK_SRC == "sys_clk") begin
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
end
else begin

wire clk125;
// Use GTREFCLK_P
if (C_SYSCLK_SRC == "gt_ref_clk") begin
assign clk125 = gtclk;
end
// Use DDR_REF_CLK_P, preferred because it does not depend
// on the ADN4600 clock switch configuration. Only available
// on Marble v2
else if (C_SYSCLK_SRC == "ddr_ref_clk") begin
assign clk125 = ddrrefclk;
end

xilinx7_clocks #(
	.DIFF_CLKIN("BYPASS"),
	.CLKIN_PERIOD(8),  // REFCLK = 125 MHz
	.MULT     (8),     // 125 MHz X 8 = 1 GHz on-chip VCO
	.DIV0     (8),     // 1 GHz / 8 = 125 MHz
`ifdef USE_IDELAYCTRL
	.DIV1     (5)     // 1 GHz / 5 = 200 MHz
`else
	.DIV1     (16)     // 1 GHz / 16 = 62.5 MHz
`endif
) clocks_i(
	.sysclk_p (clk125),
	.sysclk_n (1'b0),
	.reset    (pll_reset),
	.clk_out0 (tx_clk),
	.clk_out1 (clk_out1),
	.clk_out2 (tx_clk90),
	.clk_out3f(test_clk),  // not buffered, straight from MMCM
	.locked   (clk_locked)
);
end
endgenerate

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
`else
assign cfg_clk = 0;
`endif

// Placeholders
wire ZEST_PWR_EN;
wire dum_scl, dum_sda;
wire [3:0] ext_config;
wire [7:0] leds;
wire [2:0] ps_sync;

// vestiges of CERN FMC tester support
wire old_scl1, old_scl2, old_sda1, old_sda2;

`ifdef USE_IDELAYCTRL
wire idelayctrl_reset;  // prc pushes this button with software
assign idelayctrl_reset = ext_config[2];  // might be helpful?
`ifndef SIMULATE
	wire idelayctrl_rdy;  // ignored, just like in prc
	(* IODELAY_GROUP = "IODELAY_200" *)
	IDELAYCTRL idelayctrl (.RST(idelayctrl_reset),.REFCLK(clk200),.RDY(idelayctrl_rdy));
`endif
`endif

// Placeholders for possible IDELAY control inside gmii_to_rgmii
assign idelay_ce = 0;
assign idelay_clk = 0;
assign idelay_value_in = 0;

// Maybe this cruft could be eliminated if the corresponding yaml defs
// were rejiggered to be parameters.
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

`ifdef GPS_CTRACE
localparam C_GPS_CTRACE = 1;
`else
localparam C_GPS_CTRACE = 0;
`endif

`ifdef USE_FIBER
localparam C_USER_FIBER = 1;
`else
localparam C_USER_FIBER = 0;
`endif

// Real, portable implementation
// Consider pulling 3-state drivers out of this
marble_base #(
	.USE_I2CBRIDGE(C_USE_I2CBRIDGE),
	.MMC_CTRACE(C_MMC_CTRACE),
	.GPS_CTRACE(C_GPS_CTRACE),
	.default_enable_rx(C_DEFAULT_ENABLE_RX),
	.use_ddr_pps(1),
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
	.TWI_RST(TWI_RST), .TWI_INT(TWI_INT),
	.WR_DAC_SCLK(WR_DAC_SCLK), .WR_DAC_DIN(WR_DAC_DIN),
	.WR_DAC1_SYNC(WR_DAC1_SYNC), .WR_DAC2_SYNC(WR_DAC2_SYNC),
	.GPS(Pmod2[3:0]), .ext_config(ext_config), .ps_sync(ps_sync), .LED(leds)
);

`ifndef SIMULATE
// Verilator can't handle this, says
//   Unsupported: defparam with more than one dot
defparam base.rtefi.p4_client.engine.seven = 1;
`endif

// Let Pmod float by default for golden bitfile use-case
wire enable_pmod_out = ext_config[3];
assign Pmod1 = enable_pmod_out ? leds : 8'bzzzzzzzz;
assign LD16 = leds[0];
assign LD17 = leds[1];

`ifdef MARBLE_MINI
// TMDS test pattern generation
wire tmds_enable = ext_config[0];
tmds_test tmds_test(.clk(test_clk), .enable(tmds_enable),
	.tmds_p(TMDS_P), .tmds_n(TMDS_N));
`endif
`ifdef MARBLE_V2
assign LTM_CLKIN = ps_sync;
`endif

// Give the network the option of turning off the 20 MHz VCXO
assign VCXO_EN = ~ext_config[1];
