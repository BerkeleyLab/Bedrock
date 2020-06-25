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
	inout [11:0] bus_digitizer_J19,
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


wire J4_pout;
wire J28_pout;
assign J4_pout = bus_bmb7_J4[0];
assign J28_pout = bus_bmb7_J28[0];

wire [2:0] D4rgb;
wire [2:0] D5rgb;

assign LEDS = {D4rgb, D5rgb};

wire lb_clk=bmb7_U7_clkout;

// Generate localbus based on link to Spartan
wire [23:0] lb_addr;
wire [31:0] lb_dout;
wire [31:0] lb_din;
wire lb_strobe, lb_rd;
jxj_gate jxjgate(
	.clk(lb_clk),
	.rx_din(port_50006_word_s6tok7), .rx_stb(port_50006_rx_available), .rx_end(port_50006_rx_complete),
	.tx_dout(port_50006_word_k7tos6), .tx_rdy(port_50006_tx_available), .tx_end(port_50006_tx_complete), .tx_stb(port_50006_word_read),
	.lb_addr(lb_addr), .lb_dout(lb_dout), .lb_din(lb_din),
	.lb_strobe(lb_strobe), .lb_rd(lb_rd)
);
wire lb_write = lb_strobe & ~lb_rd;
wire [31:0] lb_data = lb_dout;

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

wire clk200=bmb7_U7_clk4xout;

zest_wrap #(.u15_u18_spi_mode("chain"))  i_zest_wrap (
	.clk_200  (clk200),
	.zif      (zif.carrier),
	.zif_cfg  (zif_cfg.slave)
);

// Here's the real work
application_top application_top(
	//,.lb_clk(lb_clk)
	//,.llspi_we(llspi_we)
	//,.llspi_re(llspi_re)
	//,.llspi_status(llspi_status)
	//,.llspi_result(llspi_result)
	//,.host_din(host_din)
	//,.adc_sdio_dir(adc_sdio_dir)
	.lb_clk(lb_clk),
	.lb_write(lb_write),
	.lb_strobe(lb_strobe),
	.lb_rd(lb_rd),
	.lb_addr(lb_addr),
	.lb_data(lb_dout),
	.lb_din(lb_din),
	.clk200(clk200),
	.zif_cfg(zif_cfg.master)
);

endmodule
