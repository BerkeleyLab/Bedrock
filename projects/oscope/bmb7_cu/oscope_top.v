// Note: BMB7 vR1 is only supported
module oscope_top(
	output [5:0] LEDS,
	inout [18:0] bus_bmb7_U7,
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
	inout [1:0]  bus_digitizer_U33U1
);

wire bmb7_U7_clkout;
wire bmb7_U7_clk4xout;
wire [7:0] port_50006_word_k7tos6;
wire [7:0] port_50007_word_k7tos6;
wire [7:0] port_50007_word_s6tok7;
wire [7:0] port_50006_word_s6tok7;
wire port_50006_tx_available,port_50006_tx_complete;
wire port_50007_tx_available,port_50007_tx_complete;
wire port_50006_rx_available,port_50006_rx_complete;
wire port_50007_rx_available,port_50007_rx_complete;
wire port_50006_word_read;
wire port_50007_word_read;
wire s6_to_k7_clk_out;

// ====== BMB7 version, includes pre-2018 QF2-pre Spartan
k7_s6 bmb7_U7(
	.K7_S6_IO_0(bus_bmb7_U7[0]),
	.K7_S6_IO_1(bus_bmb7_U7[1]),
	.K7_S6_IO_10(bus_bmb7_U7[2]),
	.K7_S6_IO_11(bus_bmb7_U7[3]),
	.K7_S6_IO_2(bus_bmb7_U7[4]),
	.K7_S6_IO_3(bus_bmb7_U7[5]),
	.K7_S6_IO_4(bus_bmb7_U7[6]),
	.K7_S6_IO_5(bus_bmb7_U7[7]),
	.K7_S6_IO_6(bus_bmb7_U7[8]),
	.K7_S6_IO_7(bus_bmb7_U7[9]),
	.K7_S6_IO_8(bus_bmb7_U7[10]),
	.K7_S6_IO_9(bus_bmb7_U7[11]),
	.K7_TO_S6_CLK_0(bus_bmb7_U7[12]),
	.K7_TO_S6_CLK_1(bus_bmb7_U7[13]),
	.K7_TO_S6_CLK_2(bus_bmb7_U7[14]),
	.S6_TO_K7_CLK_0(bus_bmb7_U7[15]),
	.S6_TO_K7_CLK_1(bus_bmb7_U7[16]),
	.S6_TO_K7_CLK_2(bus_bmb7_U7[17]),
	.S6_TO_K7_CLK_3(bus_bmb7_U7[18]),
	.port_50006_word_k7tos6(port_50006_word_k7tos6),
	.port_50006_word_s6tok7(port_50006_word_s6tok7),
	.port_50006_tx_available(port_50006_tx_available),
	.port_50006_tx_complete(port_50006_tx_complete),
	.port_50006_rx_available(port_50006_rx_available),
	.port_50006_rx_complete(port_50006_rx_complete),
	.port_50006_word_read(port_50006_word_read),
	.port_50007_word_k7tos6(port_50007_word_k7tos6),
	.port_50007_word_s6tok7(port_50007_word_s6tok7),
	.port_50007_tx_available(port_50007_tx_available),
	.port_50007_tx_complete(port_50007_tx_complete),
	.port_50007_rx_available(port_50007_rx_available),
	.port_50007_rx_complete(port_50007_rx_complete),
	.port_50007_word_read(port_50007_word_read),
	.clkout(bmb7_U7_clkout),
	.clk4xout(bmb7_U7_clk4xout),
	.s6_to_k7_clk_out(s6_to_k7_clk_out)
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

wire clk200; // clk200 should be 200MHz +/- 10MHz or 300MHz +/- 10MHz
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

assign LEDS = {D4rgb, D5rgb};

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
	.bmb7_U7_clkout(bmb7_U7_clkout),
	.bmb7_U7_clk4xout(bmb7_U7_clk4xout),
	.port_50006_word_k7tos6(port_50006_word_k7tos6),
	.port_50007_word_k7tos6(port_50007_word_k7tos6),
	.port_50007_word_s6tok7(port_50007_word_s6tok7),
	.port_50006_word_s6tok7(port_50006_word_s6tok7),
	.port_50006_tx_available(port_50006_tx_available),
	.port_50006_tx_complete(port_50006_tx_complete),
	.port_50007_tx_available(port_50007_tx_available),
	.port_50007_tx_complete(port_50007_tx_complete),
	.port_50006_rx_available(port_50006_rx_available),
	.port_50006_rx_complete(port_50006_rx_complete),
	.port_50007_rx_available(port_50007_rx_available),
	.port_50007_rx_complete(port_50007_rx_complete),
	.port_50006_word_read(port_50006_word_read),
	.port_50007_word_read(port_50007_word_read),
	.s6_to_k7_clk_out(s6_to_k7_clk_out),
	//,.lb_clk(lb_clk)
	//,.llspi_we(llspi_we)
	//,.llspi_re(llspi_re)
	//,.llspi_status(llspi_status)
	//,.llspi_result(llspi_result)
	//,.host_din(host_din)
	//,.adc_sdio_dir(adc_sdio_dir)
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
