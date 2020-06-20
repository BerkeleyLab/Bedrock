// Note: BMB7 vR1 is only supported
module oscope_top(
	input 	     GTPREFCLK_P,
	input 	     GTPREFCLK_N,
	input 	     SYSCLK_P,

	// RGMII
	output [3:0] RGMII_TXD,
	output 	     RGMII_TX_CTRL,
	output 	     RGMII_TX_CLK,
	input [3:0]  RGMII_RXD,
	input 	     RGMII_RX_CTRL,
	input 	     RGMII_RX_CLK,

	// SPI boot flash programming port
	// BOOT_CCLK treated specially in 7-series
	output 	     BOOT_CS_B,
	input 	     BOOT_MISO,
	output 	     BOOT_MOSI,
	output 	     CFG_D02, // hope R209 is DNF

	// One I2C bus, everything gatewayed through a TCA9548
	output 	     TWI_SCL,
	inout 	     TWI_SDA,
	output 	     TWI_RST,
	input 	     TWI_INT,

	// SPI pins connected to microcontroller
	input 	     SCLK,
	input 	     CSB,
	input 	     MOSI,
	output 	     MISO,
	output 	     MMC_INT,

	// White Rabbit DAC
	output 	     WR_DAC_SCLK,
	output 	     WR_DAC_DIN,
	output 	     WR_DAC1_SYNC,
	output 	     WR_DAC2_SYNC,

	// UART to USB
	// The RxD and TxD directions are with respect
	// to the USB/UART chip, not the FPGA!
	output 	     FPGA_RxD,
	input 	     FPGA_TxD,

	// Reset command to PHY
	output 	     PHY_RSTN,

	output 	     VCXO_EN,

	output [7:0] LED,

	inout [0:0]  bus_bmb7_J28,
	inout [0:0]  bus_bmb7_J4,
	inout [0:0]  bus_digitizer_U27,
	inout [38:0] bus_digitizer_U4,
	inout [6:0]  bus_digitizer_U1,
	inout [26:0] bus_digitizer_U2,
	inout [26:0] bus_digitizer_U3,
	inout [3:0]  bus_digitizer_U15,
	inout [4:0]  bus_digitizer_U18,
	inout [7:0]  bus_digitizer_J17,
	inout [7:0]  bus_digitizer_J18,
	inout [11:0] bus_digitizer_J19,
	inout [1:0]  bus_digitizer_U33U1
);


assign VCXO_EN = 1;
wire gtpclk0, gtpclk;
// Gateway GTP refclk to fabric
IBUFDS_GTE2 passi_125(.I(GTPREFCLK_P), .IB(GTPREFCLK_N), .CEB(1'b0), .O(gtpclk0));
// Vivado fails, with egregiously useless error messages,
// if you don't put this BUFG in the chain to the MMCM.
BUFG passg_125(.I(gtpclk0), .O(gtpclk));

parameter in_phase_tx_clk = 1;
// Standardized interface, hardware-dependent implementation
wire tx_clk, tx_clk90;
wire clk_locked;
wire pll_reset = 0;  // or RESET?

(* dont_touch = "true" *)
wire clk200; // clk200 should be 200MHz +/- 10MHz or 300MHz +/- 10MHz

`define USE_GTPCLK
`ifdef USE_GTPCLK
xilinx7_clocks #(
        .DIFF_CLKIN("BYPASS"),
        .CLKIN_PERIOD(8),  // REFCLK = 125 MHz
        .MULT     (8),     // 125 MHz X 8 = 1 GHz on-chip VCO
        .DIV0     (8),       // 1 GHz / 8 = 125 MHz
        .DIV1     (5)       // 1 GHz / 5 = 200 MHz
) clocks_i(
        .sysclk_p (gtpclk),
        .sysclk_n (1'b0),
        .reset    (pll_reset),
        .clk_out0 (tx_clk),
        .clk_out1 (clk200),
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
`ifndef SIMULATE
STARTUPE2 set_cclk(.USRCCLKO(BOOT_CCLK), .USRCCLKTS(1'b0));
`else // !`ifndef SIMULATE
   assign BOOT_CCLK = tx_clk;
`endif // !`ifndef SIMULATE

// Placeholders
wire ZEST_PWR_EN;
wire dum_scl, dum_sda;
wire lb_clk, lb_strobe, lb_rd, lb_write, lb_rd_valid;
wire [23:0] lb_addr;
wire [31:0] lb_data_out;
wire [31:0] lb_din;

wire [33:0] FMC1_LA_P;
wire [33:0] FMC1_LA_N;
wire [33:0] FMC2_LA_P;
wire [33:0] FMC2_LA_N;

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
	.aux_clk(SYSCLK_P), .GPS(4'b0),
	.SCLK(SCLK), .CSB(CSB), .MOSI(MOSI), .MISO(MISO),
	.FPGA_RxD(FPGA_RxD), .FPGA_TxD(FPGA_TxD),
`ifdef USE_I2CBRIDGE
	.twi_scl({dum_scl, FMC2_LA_P[2] , FMC1_LA_P[2], TWI_SCL}),
	.twi_sda({dum_sda, FMC2_LA_N[2], FMC1_LA_N[2], TWI_SDA}),
	.TWI_RST(TWI_RST), .TWI_INT(TWI_INT),
`endif
        .lb_clk(lb_clk),
        .lb_addr(lb_addr),
        .lb_strobe(lb_strobe),
        .lb_rd(lb_rd),
        .lb_write(lb_write),
        .lb_rd_valid(lb_rd_valid),
        .lb_data_out(lb_data_out),
        .lb_data_in(lb_din),
	.fmc_test({
		FMC2_LA_P[33:3], FMC2_LA_P[1:0],
		FMC2_LA_N[33:3], FMC2_LA_N[1:0],
		FMC1_LA_P[33:3], FMC1_LA_P[1:0],
		FMC1_LA_N[33:3], FMC1_LA_N[1:0]}),
	.WR_DAC_SCLK(WR_DAC_SCLK), .WR_DAC_DIN(WR_DAC_DIN),
	.WR_DAC1_SYNC(WR_DAC1_SYNC), .WR_DAC2_SYNC(WR_DAC2_SYNC),
	.LED(LED)
);
// TODO: Removing the SPI flash for now
//defparam base.rtefi.p4_client.engine.seven = 1;

parameter BUF_AW=13;

// Zest peripherals interface

zest_cfg_if zif_cfg();

zest_if zif (
	.U27   (bus_digitizer_U27),
	.U4    (bus_digitizer_U4),
	.U1    (bus_digitizer_U1),
	.U2    (bus_digitizer_U2),
	.U3    (bus_digitizer_U3),
	.U15   (bus_digitizer_U15),
	.U18   (bus_digitizer_U18),
	.J17   (bus_digitizer_J17),
	.J18   (bus_digitizer_J18),
	.J19   (bus_digitizer_J19),
	.U33U1 (bus_digitizer_U33U1)
);

zest_wrap #(.u15_u18_spi_mode("chain"))  i_zest_wrap (
	.clk_200  (clk200),
	.zif      (zif.carrier),
	.zif_cfg  (zif_cfg.slave)
);

// Choose between llspi and spi_master to drive U15 and U18
//`define POLL_WITH_LLSPI
wire U18_sclk_out, U18_mosi_out;  //  to  application_top
wire U15_U18_sclk, U15_U18_mosi;  // from application_top
assign bus_digitizer_U18[3] = U15_U18_mosi;
assign bus_digitizer_U18[4] = U15_U18_sclk;
wire U18_clk_in;  // from application_top (for 64kHz or 128kHz CLK pin)
//`ifdef POLL_WITH_LLSPI
//assign bus_digitizer_U18[0] = U18_clk_in;
//`endif

wire J4_pout;
wire J28_pout;
assign J4_pout = bus_bmb7_J4[0];
assign J28_pout = bus_bmb7_J28[0];

// These are meaningful LEDs, one could use them
wire [2:0] D4rgb;
wire [2:0] D5rgb;

wire U27dir;

// Here's the real work
application_top application_top(
	.lb_clk(lb_clk),
	.lb_write(lb_write),
	.lb_strobe(lb_strobe),
	.lb_rd(lb_rd),
	.lb_addr(lb_addr),
	.lb_data(lb_data_out),
	.lb_din(lb_din),
	.clk200(clk200),
	.zif_cfg(zif_cfg.master)
);

endmodule
