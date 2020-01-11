// Note: BMB7 vR1 is only supported
module oscope_top(
	input GTPREFCLK_P,
	input GTPREFCLK_N,
	input SYSCLK_P,

	// RGMII
	output [3:0] RGMII_TXD,
	output RGMII_TX_CTRL,
	output RGMII_TX_CLK,
	input [3:0] RGMII_RXD,
	input RGMII_RX_CTRL,
	input RGMII_RX_CLK,

	// Reset command to PHY
	output PHY_RSTN,

	output VCXO_EN,

	output [7:0] LED,

	inout [0:0] bus_bmb7_J28,
	inout [0:0] bus_bmb7_J4,
	inout [0:0] bus_digitizer_U27,
	inout [38:0] bus_digitizer_U4,
	inout [6:0] bus_digitizer_U1,
	inout [26:0] bus_digitizer_U2,
	inout [26:0] bus_digitizer_U3,
	inout [3:0] bus_digitizer_U15,
	inout [4:0] bus_digitizer_U18,
	inout [7:0] bus_digitizer_J17,
	inout [7:0] bus_digitizer_J18,
	inout [1:0] bus_digitizer_U33U1
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
wire TWI_SCL, TWI_SDA;

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

wire U1_clkuwire_in,U1_datauwire_inout,U1_leuwire_in;
wire U1_clkout3;
lmk01801 digitizer_U1(
	.CLKOUT3_INV(bus_digitizer_U1[0]),
	.CLKOUT3(bus_digitizer_U1[4]),
	.CLKUWIRE(bus_digitizer_U4[26]),
	.DATAUWIRE(bus_digitizer_U4[0]),
	.LEUWIRE(bus_digitizer_U1[5]),
	.DATAUWIRE_IN(1'b0),  // unused?
	.clkuwire_in(U1_clkuwire_in),
	.datauwire_inout(U1_datauwire_inout),
	.leuwire_in(U1_leuwire_in),
	.clkout(U1_clkout3)
);

wire idelayctrl_rdy;
wire idelayctrl_reset;
`ifndef SIMULATE
	IDELAYCTRL idelayctrl (.RST(idelayctrl_reset),.REFCLK(clk200),.RDY(idelayctrl_rdy));
`endif

wire U2_csb_in,U2_sclk_in,U2_sdio_inout;
wire U3_csb_in,U3_sclk_in,U3_sdio_inout;
wire [63:0] U2_dout,U3_dout;
wire U2_clk_div_bufr,U3_clk_div_bufr;
wire U2_clk_div_bufg,U3_clk_div_bufg;
wire U2_dco_clk_out,U3_dco_clk_out;
wire [39:0] U2_idelay_value_in;
wire [39:0] U3_idelay_value_in;
wire [39:0] U2_idelay_value_out;
wire [39:0] U3_idelay_value_out;
wire [7:0] U2_bitslip;
wire [7:0] U3_bitslip;
wire [7:0] U2_idelay_ld;
wire [7:0] U3_idelay_ld;
wire U2_pdwn,U3_pdwn;
wire U2_iserdes_reset,U3_iserdes_reset;
wire U2_clk_reset,U3_clk_reset;
wire mmcm_reset, mmcm_locked;
wire U2_sdi,U2_sdo,U2_sdio_as_i;
wire U3_sdi,U3_sdo,U3_sdio_as_i;
wire U2_mmcm_psclk, U2_mmcm_psen, U2_mmcm_psincdec, U2_mmcm_psdone;

ad9653 #(.FLIP_D(8'b11111111),.FLIP_DCO(1'b1),.FLIP_FRAME(1'b1),.BANK_CNT(1)) digitizer_U2(
	.D0NA(bus_digitizer_U2[16]),
	.D0NB(bus_digitizer_U2[13]),
	.D0NC(bus_digitizer_U2[23]),
	.D0ND(bus_digitizer_U2[25]),
	.D0PA(bus_digitizer_U2[20]),
	.D0PB(bus_digitizer_U2[18]),
	.D0PC(bus_digitizer_U2[24]),
	.D0PD(bus_digitizer_U2[19]),
	.D1NA(bus_digitizer_U2[14]),
	.D1NB(bus_digitizer_U2[4]),
	.D1NC(bus_digitizer_U2[26]),
	.D1ND(bus_digitizer_U2[11]),
	.D1PA(bus_digitizer_U2[17]),
	.D1PB(bus_digitizer_U2[8]),
	.D1PC(bus_digitizer_U2[5]),
	.D1PD(bus_digitizer_U2[12]),
	.DCON(bus_digitizer_U2[9]),
	.DCOP(bus_digitizer_U2[15]),
	.FCON(bus_digitizer_U2[10]),
	.FCOP(bus_digitizer_U2[6]),
	.PDWN(bus_digitizer_U3[10]),
	.SYNC(bus_digitizer_U3[21]),
	.CSB(bus_digitizer_U2[22]),
	.SCLK(bus_digitizer_U4[26]),
	.SDIO(bus_digitizer_U4[1]),

	.csb_in(U2_csb_in),.sclk_in(U2_sclk_in),
	//.sdio_inout(U2_sdio_inout),
	.sdi(U2_sdi),
	.sdo(U2_sdo),
	.sdio_as_i(U2_sdio_as_i),
	.clk_reset(U2_clk_reset),
	.mmcm_reset(mmcm_reset),
	.mmcm_locked(mmcm_locked),
	.mmcm_psclk(U2_mmcm_psclk),
	.mmcm_psen(U2_mmcm_psen),
	.mmcm_psincdec(U2_mmcm_psincdec),
	.mmcm_psdone(U2_mmcm_psdone),
	.iserdes_reset(U2_iserdes_reset),
	.bitslip(U2_bitslip),
	.idelay_ce(8'b0),
	.dout(U2_dout),
	.clk_div_bufr(U2_clk_div_bufr),
	.clk_div_bufg(U2_clk_div_bufg),
	.clk_div_in(U2_clk_div_bufr),
	.dco_clk_out(U2_dco_clk_out),
	.dco_clk_in(U2_dco_clk_out),
	.idelay_value_in(U2_idelay_value_in),
	.idelay_value_out(U2_idelay_value_out),
	.idelay_ld(U2_idelay_ld),
	.pdwn_in(U2_pdwn)
);

wire U3_mmcm_psclk, U3_mmcm_psen, U3_mmcm_psincdec, U3_mmcm_psdone;

ad9653 #(.FLIP_D(8'b11111111),.FLIP_DCO(1'b1),.FLIP_FRAME(1'b1),.BANK_CNT(2),.BANK_SEL({2'b0,2'b0,2'b0,2'b0,2'b1,2'b1,2'b1,2'b1})) digitizer_U3(
	.D0NA(bus_digitizer_U3[16]),
	.D0NB(bus_digitizer_U3[13]),
	.D0NC(bus_digitizer_U3[12]),
	.D0ND(bus_digitizer_U3[7]),
	.D0PA(bus_digitizer_U3[18]),
	.D0PB(bus_digitizer_U3[25]),
	.D0PC(bus_digitizer_U3[19]),
	.D0PD(bus_digitizer_U3[9]),
	.D1NA(bus_digitizer_U3[5]),
	.D1NB(bus_digitizer_U3[6]),
	.D1NC(bus_digitizer_U3[3]),
	.D1ND(bus_digitizer_U3[26]),
	.D1PA(bus_digitizer_U3[8]),
	.D1PB(bus_digitizer_U3[23]),
	.D1PC(bus_digitizer_U3[22]),
	.D1PD(bus_digitizer_U3[14]),
	.DCON(bus_digitizer_U3[4]),
	.DCOP(bus_digitizer_U3[24]),
	.FCON(bus_digitizer_U3[15]),
	.FCOP(bus_digitizer_U3[20]),
	.PDWN(bus_digitizer_U3[10]),
	.SYNC(bus_digitizer_U3[21]),
	.CSB(bus_digitizer_U3[11]),
	.SCLK(bus_digitizer_U4[26]),
	.SDIO(),//bus_digitizer_U4[1]),
	.csb_in(U3_csb_in),.sclk_in(U3_sclk_in),
	//.sdio_inout(U3_sdio_inout),
	.sdi(U3_sdi),
	.sdo(U3_sdo),
	.sdio_as_i(U3_sdio_as_i),
	.clk_reset(U3_clk_reset),
	.mmcm_reset(mmcm_reset),
	.mmcm_psclk(U3_mmcm_psclk),
	.mmcm_psen(U3_mmcm_psen),
	.mmcm_psincdec(U3_mmcm_psincdec),
	.mmcm_psdone(U3_mmcm_psdone),
	.iserdes_reset({U2_iserdes_reset,U3_iserdes_reset}),
	.bitslip(U3_bitslip),//[15:8]),
	.idelay_ce(8'b0),
	.dout(U3_dout),
	.clk_div_bufr(U3_clk_div_bufr),
	.clk_div_bufg(U3_clk_div_bufg),
	.clk_div_in({U2_clk_div_bufr,U3_clk_div_bufr}),
	.dco_clk_out(U3_dco_clk_out),
	.dco_clk_in({U2_dco_clk_out,U3_dco_clk_out}),
	.idelay_value_in(U3_idelay_value_in),
	.idelay_value_out(U3_idelay_value_out),
	.idelay_ld(U3_idelay_ld),
	.pdwn_in(U3_pdwn)
);

wire U4_csb_in,U4_sclk_in,U4_sdo_out,U4_sdio_inout;
wire U4_dco_clk_out,U4_dci,U4_reset;
wire [13:0] U4_data_i,U4_data_q;

ad9781 digitizer_U4(
	.D0N(bus_digitizer_U4[7]),
	.D0P(bus_digitizer_U4[25]),
	.D1N(bus_digitizer_U4[34]),
	.D1P(bus_digitizer_U4[14]),
	.D2N(bus_digitizer_U4[5]),
	.D2P(bus_digitizer_U4[16]),
	.D3N(bus_digitizer_U4[11]),
	.D3P(bus_digitizer_U4[33]),
	.D4N(bus_digitizer_U4[15]),
	.D4P(bus_digitizer_U4[36]),
	.D5N(bus_digitizer_U4[18]),
	.D5P(bus_digitizer_U4[20]),
	.D6N(bus_digitizer_U4[4]),
	.D6P(bus_digitizer_U4[27]),
	.D7N(bus_digitizer_U4[21]),
	.D7P(bus_digitizer_U4[3]),
	.D8N(bus_digitizer_U4[24]),
	.D8P(bus_digitizer_U4[30]),
	.D9N(bus_digitizer_U4[32]),
	.D9P(bus_digitizer_U4[35]),
	.D10N(bus_digitizer_U4[28]),
	.D10P(bus_digitizer_U4[9]),
	.D11N(bus_digitizer_U4[22]),
	.D11P(bus_digitizer_U4[38]),
	.D12N(bus_digitizer_U4[6]),
	.D12P(bus_digitizer_U4[23]),
	.D13N(bus_digitizer_U4[17]),
	.D13P(bus_digitizer_U4[31]),
	.DCIN(bus_digitizer_U4[10]),
	.DCIP(bus_digitizer_U4[29]),
	.DCON(bus_digitizer_U4[37]),
	.DCOP(bus_digitizer_U4[13]),
	.RESET(bus_digitizer_U4[8]),
	.CSB(bus_digitizer_U4[19]),
	.SCLK(bus_digitizer_U4[26]),
	.SDIO(bus_digitizer_U4[0]),
	.SDO(bus_digitizer_U4[12]),
	.csb_in(U4_csb_in),
	.sclk_in(U4_sclk_in),
	.sdo_out(U4_sdo_out),
	.sdio_inout(U4_sdio_inout),
	.data_i(U4_data_i),
	.data_q(U4_data_q),
	.dco_clk_out(U4_dco_clk_out),
	.dci(U4_dci),
	.reset_in(U4_reset)
);

wire J4_pout;
wire J28_pout;
assign J4_pout = bus_bmb7_J4[0];
assign J28_pout = bus_bmb7_J28[0];

wire [2:0] D4rgb;
wire [2:0] D5rgb;

assign bus_bmb7_D4 = D4rgb;
assign bus_bmb7_D5 = D5rgb;

wire U27dir;

assign bus_digitizer_U27 = U27dir;

// pin    EN is    IO_L7N_T1_32 bank  32 bus_digitizer_U33U1[1]  AA15
// pin  SYNC is    IO_L7P_T1_32 bank  32 bus_digitizer_U33U1[0]  AA14
wire U33U1_pwr_sync,U33U1_pwr_en;
assign bus_digitizer_U33U1[0] = U33U1_pwr_sync;
assign bus_digitizer_U33U1[1] = U33U1_pwr_en;

wire [15:0] U15_spi_addr,U15_spi_data,U15_sdo_addr,U15_spi_rdbk;
wire U15_clk,U15_spi_start,U15_spi_read,U15_spi_ready,U15_sdio_as_sdo;
wire U15_sclk_in,U15_mosi_in,U15_ssb_in;
wire U15_ss_in,U15_miso_out;
wire U15_sclk_out,U15_mosi_out,U15_ssb_out;
amc7823
`ifdef POLL_WITH_LLSPI
	#(.SPIMODE("passthrough"))
`else
	#(.SPIMODE("chain"))
`endif

digitizer_U15(
	.ss(bus_digitizer_U15[2]),
	.miso(bus_digitizer_U15[1]),
	.mosi(U15_mosi_out),
	.sclk(U15_sclk_out),
	.clk(U15_clk),
	.spi_start(U15_spi_start),
	.spi_addr(U15_spi_addr),
	.spi_read(U15_spi_read),
	.spi_data(U15_spi_data),
	.sdo_addr(U15_sdo_addr),
	.spi_rdbk(U15_spi_rdbk),
	.spi_ready(U15_spi_ready),
	.sdio_as_sdo(U15_sdio_as_sdo),
	.sclk_in(U15_sclk_in),
	.mosi_in(U15_mosi_in),
	.ss_in(U15_ss_in),
	.miso_out(U15_miso_out),
	.spi_ssb_in(U15_ssb_in),
	.spi_ssb_out(U15_ssb_out)
);

wire [7:0] U18_spi_addr,U18_sdo_addr;
wire [23:0] U18_spi_data,U18_spi_rdbk;
wire U18_clkin,U18_spi_start,U18_spi_read,U18_spi_ready,U18_sdio_as_sdo;
wire U18_sclk_in,U18_mosi_in,U18_ssb_in;
wire U18_ss_in,U18_miso_out;
wire U18_ssb_out;

ad7794
`ifdef POLL_WITH_LLSPI
	#(.SPIMODE("passthrough"))
`else
	#(.SPIMODE("chain"))
`endif
digitizer_U18(
	.CLK(bus_digitizer_U18[0]),
	.CS(bus_digitizer_U18[2]),
	.DIN(U18_mosi_out),
	.DOUT_RDY(bus_digitizer_U18[1]),
	.SCLK(U18_sclk_out),
	.clkin(U18_clkin),
	.spi_start(U18_spi_start),
	.spi_addr(U18_spi_addr),
	.spi_read(U18_spi_read),
	.spi_data(U18_spi_data),
	.sdo_addr(U18_sdo_addr),
	.spi_rdbk(U18_spi_rdbk),
	.spi_ready(U18_spi_ready),
	.sdio_as_sdo(U18_sdio_as_sdo),
	.sclk_in(U18_sclk_in),
	.mosi_in(U18_mosi_in),
	.ss_in(U18_ss_in),
	.miso_out(U18_miso_out),
	.spi_ssb_in(U18_ssb_in),
	.spi_ssb_out(U18_ssb_out),
	.adcclk(U18_clk_in)
);

// Here's the real work
application_top application_top(
	.lb_clk(lb_clk),
	.lb_write(lb_strobe & ~lb_rd),
	.lb_strobe(lb_strobe),
	.lb_rd(lb_rd),
	.lb_addr(lb_addr),
	.lb_data(lb_data_out),
	.lb_din(lb_din),
	.clk200(clk200),
	.idelayctrl_rdy(idelayctrl_rdy),
	.idelayctrl_reset(idelayctrl_reset),
	.U2_dout(U2_dout),
	.U3_dout(U3_dout),
	.U2_clk_div_bufg(U2_clk_div_bufg),
	.U3_clk_div_bufg(U3_clk_div_bufg),
	.U2_clk_div_bufr(U2_clk_div_bufr),
	.U3_clk_div_bufr(U3_clk_div_bufr),
	.U2_dco_clk_out(U2_dco_clk_out),
	.U3_dco_clk_out(U3_dco_clk_out),
	.U2_idelay_value_in(U2_idelay_value_in),
	.U3_idelay_value_in(U3_idelay_value_in),
	.U2_idelay_value_out(U2_idelay_value_out),
	.U3_idelay_value_out(U3_idelay_value_out),
	.U2_bitslip(U2_bitslip),
	.U3_bitslip(U3_bitslip),
	.U2_idelay_ld(U2_idelay_ld),
	.U3_idelay_ld(U3_idelay_ld),
	.U2_pdwn(U2_pdwn),
	.U3_pdwn(U3_pdwn),
	.U2_iserdes_reset(U2_iserdes_reset),
	.U3_iserdes_reset(U3_iserdes_reset),
	.U2_clk_reset(U2_clk_reset),
	.U3_clk_reset(U3_clk_reset),
	.mmcm_reset(mmcm_reset),
	.mmcm_locked(mmcm_locked),
	.U2_mmcm_psclk(U2_mmcm_psclk),
	.U2_mmcm_psen(U2_mmcm_psen),
	.U2_mmcm_psincdec(U2_mmcm_psincdec),
	.U2_mmcm_psdone(U2_mmcm_psdone),
	.U3_mmcm_psclk(U3_mmcm_psclk),
	.U3_mmcm_psen(U3_mmcm_psen),
	.U3_mmcm_psincdec(U3_mmcm_psincdec),
	.U3_mmcm_psdone(U3_mmcm_psdone),
	.U1_clkout3(U1_clkout3),
	.U4_dco_clk_out(U4_dco_clk_out),
	.U4_dci(U4_dci),
	.U4_reset(U4_reset),
	.U4_data_i(U4_data_i),
	.U4_data_q(U4_data_q),
	.D4rgb(D4rgb),
	.D5rgb(D5rgb),
	.U27dir(U27dir),

	.J17_pmod_4321({ bus_digitizer_J17[5], bus_digitizer_J17[4],
			 bus_digitizer_J17[3], bus_digitizer_J17[6] }),
	.J17_pmod_a987({ bus_digitizer_J17[1], bus_digitizer_J17[0],
			 bus_digitizer_J17[2], bus_digitizer_J17[7] }),
	.J18_pmod_4321({ bus_digitizer_J18[6], bus_digitizer_J18[5],
			 bus_digitizer_J18[1], bus_digitizer_J18[2] }),
	.J18_pmod_a987({ bus_digitizer_J18[4], bus_digitizer_J18[7],
			 bus_digitizer_J18[0], bus_digitizer_J18[3] }),
	.U15_clk(U15_clk),
	.U15_spi_start(U15_spi_start),
	.U15_spi_addr(U15_spi_addr),
	.U15_spi_read(U15_spi_read),
	.U15_spi_data(U15_spi_data),
	.U15_sdo_addr(U15_sdo_addr),
	.U15_spi_rdbk(U15_spi_rdbk),
	.U15_spi_ready(U15_spi_ready),
	.U15_sdio_as_sdo(U15_sdio_as_sdo),
	.U15_sclk_in(U15_sclk_in),
	.U15_mosi_in(U15_mosi_in),
	.U15_ssb_in(U15_ssb_in),
	.U15_sclk_out(U15_sclk_out),
	.U15_mosi_out(U15_mosi_out),
	.U15_ssb_out(U15_ssb_out),

	.U18_clkin(U18_clkin),
	.U18_spi_start(U18_spi_start),
	.U18_spi_addr(U18_spi_addr),
	.U18_spi_read(U18_spi_read),
	.U18_spi_data(U18_spi_data),
	.U18_sdo_addr(U18_sdo_addr),
	.U18_spi_rdbk(U18_spi_rdbk),
	.U18_spi_ready(U18_spi_ready),
	.U18_sdio_as_sdo(U18_sdio_as_sdo),
	.U18_sclk_in(U18_sclk_in),
	.U18_mosi_in(U18_mosi_in),
	.U18_miso_out(U18_miso_out),
	.U18_ss_in(U18_ss_in),
	.U18_ssb_in(U18_ssb_in),
	.U18_clk_in(U18_clk_in),
	.U18_sclk_out(U18_sclk_out),
	.U18_mosi_out(U18_mosi_out),
	.U18_ssb_out(U18_ssb_out),
	.U15_U18_sclk(U15_U18_sclk),
	.U15_U18_mosi(U15_U18_mosi),
	.U15_miso_out(U15_miso_out),
	.U15_ss_in(U15_ss_in),
	.U33U1_pwr_sync(U33U1_pwr_sync),
	.U33U1_pwr_en(U33U1_pwr_en),
	.U4_csb_in(U4_csb_in),
	.U4_sclk_in(U4_sclk_in),
	.U4_sdo_out(U4_sdo_out),
	.U4_sdio_inout(U4_sdio_inout),
	.U1_clkuwire_in(U1_clkuwire_in),
	.U1_datauwire_inout(U1_datauwire_inout),
	.U1_leuwire_in(U1_leuwire_in),
	.U2_csb_in(U2_csb_in),
	.U2_sclk_in(U2_sclk_in),
	//,.U2_sdio_inout(U2_sdio_inout)
	.U2_sdi(U2_sdi),
	.U2_sdo(U2_sdo),
	.U2_sdio_as_i(U2_sdio_as_i),
	.U3_csb_in(U3_csb_in),
	.U3_sclk_in(U3_sclk_in),
	//,.U3_sdio_inout(U3_sdio_inout)
	.U3_sdi(U3_sdi),
	.U3_sdo(U3_sdo),
	.U3_sdio_as_i(U3_sdio_as_i)
);

endmodule
