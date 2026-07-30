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
wire tx_clk, tx_clk90, clk62_5;
wire clk_locked;
wire pll_reset = 0;  // or RESET?
wire test_clk;
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

`ifdef MARBLE_MINI
wire clk_out1;
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

`ifdef USE_IDELAYCTRL
assign clk200 = clk_out1;
reg bad_slow_clock=0;
always @(posedge tx_clk) bad_slow_clock <= ~bad_slow_clock;
assign clk62_5 = bad_slow_clock;  // sample-size of two says readout of dna still works
`else
assign clk200 = 0;
assign clk62_5 = clk_out1;  // better tested way to give dna primitive the clock it wants
`endif
`endif

`ifdef MARBLE_V2
xilinx7_clocks #(
    .DIFF_CLKIN("BYPASS"),
    .CLKIN_PERIOD(8),  // REFCLK = 125 MHz
    .MULT     (8),     // 125 MHz X 8 = 1 GHz on-chip VCO
    .DIV0     (16),    // 1 GHz / 16 = 62.5 MHz
    .DIV1     (5)      // 1 GHz / 5 = 200 MHz
) clocks_i(
    .sysclk_p (clk125),
    .sysclk_n (1'b0),
    .reset    (pll_reset),
    .clk_out0 (clk62_5),
    .clk_out1 (clk200),
    .clk_out2 (),
    .clk_out3f(test_clk),  // not buffered, straight from MMCM
    .locked   ()
);
`endif
end
endgenerate

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
localparam C_USE_FIBER = 1;
`else
localparam C_USE_FIBER = 0;
`endif

(* DONT_TOUCH *) wire gmii_tx_clk, gmii_tx_clk90, gmii_rx_clk;
wire gmii_tx_en, gmii_rx_dv;
wire [7:0] gmii_rxd, gmii_txd;
`ifdef MARBLE_V2
// MGT Fiber Ethernet related (Marble only)
localparam GTX_ETHERNET_WI = 20;
wire qsfp1_gt_tx_pll_lock, qsfp1_gt_rx_pll_lock;
wire qsfp1_gt_tx_usr_clk, qsfp1_gt_rx_usr_clk;
(* DONT_TOUCH *) wire qsfp1_gt_rx_out_clk, qsfp1_gt_tx_out_clk;
wire [GTX_ETHERNET_WI-1:0]  qsfp1_gt_rxd, qsfp1_gt_txd;
// No one (in Makefile) cares about extensive simulations yet
// so this can be safely ignored, at least for now
`ifndef BYPASS_REAL_WORK
mgt_eth_clks i_mgt_eth_clks_tx (
   .reset       (~qsfp1_cpll_locked[3]),
   .mgt_out_clk (qsfp1_gt_tx_out_clk),  // From transceiver (125 MHz)
   .gmii_clk    (gmii_tx_clk),         // Buffered 125 MHz
   .gmii_clk90  (gmii_tx_clk90),       // Buffered 125 MHz, 90 deg
   .pll_lock    (qsfp1_gt_tx_pll_lock)
);

mgt_eth_clks i_mgt_eth_clks_rx (
   .reset       (~qsfp1_cpll_locked[3]),
   .mgt_out_clk (qsfp1_gt_rx_out_clk),
   .gmii_clk    (gmii_rx_clk),
   .pll_lock    (qsfp1_gt_rx_pll_lock)
);
assign qsfp1_gt_tx_usr_clk = gmii_tx_clk;
assign qsfp1_gt_rx_usr_clk = gmii_rx_clk;
`endif

// Define Marble clocks using that same i_mgt_eth_clks_tx MMCM,
// so it gets used for both the copper and fiber Ethernet interface.
assign vgmii_tx_clk = gmii_tx_clk;
assign vgmii_tx_clk90 = gmii_tx_clk90;
assign tx_clk = gmii_tx_clk;
assign tx_clk90 = gmii_tx_clk90;

wire [3:0] qsfp1_cpll_locked;
wire [3:0] qsfp1_txrx_resetdone;
// XXX Should this be exposed to the user?
// Maybe not, otherwise one would lose ability to communicate to the board
wire qsfp1_soft_reset_i;
wire qsfp1_sysclk = clk62_5;  // not lb_clk, since that's circular on Marble
assign clk_locked = qsfp1_gt_tx_pll_lock;  // reset Ethernet PHY when FPGA clock glitches

`ifndef SIMULATE
q1_gt_wrap #(
`else
qgt_wrap #(
`endif
   .GT3_WI (GTX_ETHERNET_WI)
)
i_qsfp1_gt_wrap (
   // Common Pins
   .drpclk_in               (qsfp1_sysclk),
   .soft_reset              (qsfp1_soft_reset_i),
   .gtrefclk0               (gtclk0),
   .gtrefclk1               (1'b0),
   `ifndef SIMULATE
   .gt3_refclk0             (gtclk0),
   .gt3_refclk1             (1'b0),
   .gt3_rxoutclk_out        (qsfp1_gt_rx_out_clk),
   .gt3_rxusrclk_in         (qsfp1_gt_rx_usr_clk),
   .gt3_txoutclk_out        (qsfp1_gt_tx_out_clk),
   .gt3_txusrclk_in         (qsfp1_gt_tx_usr_clk),
   .gt3_rxusrrdy_in         (qsfp1_gt_rx_pll_lock),
   .gt3_rxdata_out          (qsfp1_gt_rxd),
   .gt3_txusrrdy_in         (qsfp1_gt_tx_pll_lock),
   .gt3_txdata_in           (qsfp1_gt_txd),
   .gt3_rxn_in              (QSFP1_RX_3_N),
   .gt3_rxp_in              (QSFP1_RX_3_P),
   .gt3_txn_out             (QSFP1_TX_3_N),
   .gt3_txp_out             (QSFP1_TX_3_P),
   .gt3_rxfsm_resetdone_out (),
   .gt3_txfsm_resetdone_out (),
   .gt3_rxbufstatus         (),
   .gt3_txbufstatus         (),
   `endif
   .gt_txrx_resetdone       (qsfp1_txrx_resetdone),
   .gt_cpll_locked          (qsfp1_cpll_locked)
);

`ifdef SIMULATE
`ifdef USE_FIBER
assign QSFP1_TX_3_N = 0;
assign QSFP1_TX_3_P = 0;
`endif
`endif

// -----------------------------------
// Instantiate eth_gtx_hook here
// -----------------------------------
reg  [8:0] an_status_lb_clk;
wire [8:0] an_status_l;
wire [8:0] eth_an_status;
wire [15:0] lacr_rx;

`ifndef BYPASS_REAL_WORK
eth_gtx_hook #(.JUMBO_DW(14), .GTX_DW(20), .DOUBLEBIT(1)) hook(
    .gtx_tx_clk   (qsfp1_gt_tx_usr_clk),
    .gtx_rxd      (qsfp1_gt_rxd),
    .gtx_txd      (qsfp1_gt_txd),

    .gmii_tx_clk  (gmii_tx_clk),
    .gmii_rx_clk  (gmii_rx_clk),

    .an_disable   (1'b0),
    .rx_err_los   (1'b0),
    .an_status_l  (an_status_l),
    .lacr_rx      (lacr_rx),

    .gmii_rxd     (gmii_rxd),
    .gmii_rx_dv   (gmii_rx_dv),
    .gmii_txd     (gmii_txd),
    .gmii_tx_en   (gmii_tx_en)
);
`else
assign an_status_l = 0;
`endif

// Cross quasi-static an_status to lb_clk so it can be read out by Host
// XXX again, not exposed to the user
always @(posedge lb_clk) an_status_lb_clk <= an_status_l;
assign eth_an_status = an_status_lb_clk;
`endif

// Management GMII Switch
wire       mgt_rx_clk, mgt_tx_clk;
wire [7:0] mgt_rxd,    mgt_txd;
wire       mgt_rx_dv,  mgt_tx_en;
wire       mgt_rx_er,  mgt_tx_er;
generate if (C_USE_FIBER == 1) begin : mgt_is_fiber
        assign mgt_rx_clk  = gmii_rx_clk;
        assign mgt_rxd     = gmii_rxd;
        assign mgt_rx_dv   = gmii_rx_dv;
        assign mgt_rx_er   = 1'b0;
        assign mgt_tx_clk  = gmii_tx_clk;
        assign gmii_txd    = mgt_txd;
        assign gmii_tx_en  = mgt_tx_en;
        assign vgmii_txd   = 8'b0;
        assign vgmii_tx_en = 1'b0;
        assign vgmii_tx_er = 1'b0;
    end else begin : mgt_is_copper
        assign mgt_rx_clk  = vgmii_rx_clk;
        assign mgt_rxd     = vgmii_rxd;
        assign mgt_rx_dv   = vgmii_rx_dv;
        assign mgt_rx_er   = vgmii_rx_er;
        assign mgt_tx_clk  = tx_clk;
        assign vgmii_txd   = mgt_txd;
        assign vgmii_tx_en = mgt_tx_en;
        assign vgmii_tx_er = mgt_tx_er;
        assign gmii_txd    = 8'b0;
        assign gmii_tx_en  = 1'b0;
    end
endgenerate

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
	.vgmii_tx_clk(mgt_tx_clk), .vgmii_txd(mgt_txd),
	.vgmii_tx_en(mgt_tx_en), .vgmii_tx_er(mgt_tx_er),
	.vgmii_rx_clk(mgt_rx_clk), .vgmii_rxd(mgt_rxd),
	.vgmii_rx_dv(mgt_rx_dv), .vgmii_rx_er(mgt_rx_er),
	.phy_rstn(PHY_RSTN), .clk_locked(clk_locked), .si570(si570),
	.boot_clk(BOOT_CCLK), .boot_cs(BOOT_CS_B),
	.boot_mosi(BOOT_MOSI), .boot_miso(BOOT_MISO),
	.cfg_d02(CFG_D02), .mmc_int(MMC_INT), .ZEST_PWR_EN(ZEST_PWR_EN),
	.aux_clk(SYSCLK_P), .clk62(clk62_5), .cfg_clk(cfg_clk),
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
