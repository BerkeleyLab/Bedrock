module larger_shell_gtx_bmb7_kintex (
//inout [23:0] bus_bmb7_U50,
inout [2:0] bus_bmb7_D4,
//inout [0:0] bus_digitizer_U27,
//inout [23:0] bus_bmb7_U32,
//inout [2:0] bus_bmb7_D5,
inout [18:0] bus_bmb7_U7,
//inout [38:0] bus_digitizer_U4,
//inout [6:0] bus_digitizer_U1,
//inout [26:0] bus_digitizer_U2,
//inout [26:0] bus_digitizer_U3,
inout P2_PWR_EN
);
parameter BUF_AW=13;

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

k7_s6 bmb7_U7(
    .K7_S6_IO_0(bus_bmb7_U7[16]),
    .K7_S6_IO_1(bus_bmb7_U7[5]),
    .K7_S6_IO_2(bus_bmb7_U7[6]),
    .K7_S6_IO_3(bus_bmb7_U7[8]),
    .K7_S6_IO_4(bus_bmb7_U7[3]),
    .K7_S6_IO_5(bus_bmb7_U7[14]),
    .K7_S6_IO_6(bus_bmb7_U7[18]),
    .K7_S6_IO_7(bus_bmb7_U7[9]),
    .K7_S6_IO_8(bus_bmb7_U7[1]),
    .K7_S6_IO_9(bus_bmb7_U7[4]),
    .K7_S6_IO_10(bus_bmb7_U7[12]),
    .K7_S6_IO_11(bus_bmb7_U7[0]),
    .K7_TO_S6_CLK_0(bus_bmb7_U7[11]),
    .K7_TO_S6_CLK_1(bus_bmb7_U7[10]),
    .K7_TO_S6_CLK_2(bus_bmb7_U7[17]),
    .S6_TO_K7_CLK_0(bus_bmb7_U7[7]),
    .S6_TO_K7_CLK_1(bus_bmb7_U7[15]),
    .S6_TO_K7_CLK_2(bus_bmb7_U7[2]),
    .S6_TO_K7_CLK_3(bus_bmb7_U7[13]),
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
    .clk4xout(bmb7_U7_clk4xout)
);

wire clk_1x_90, clk_2x_0, clk_eth, clk_eth_90;

parameter clk2x_div = 7;  // relative to 1200 MHz (on-board oscillator * 6)
clocks #(.mmcm_div0(clk2x_div*2), .mmcm_div1(clk2x_div)) clocks(
//.rst(GLBL_RST),
    .sysclk_buf(bmb7_U7_clk4xout),
    .clk_eth(clk_eth),
    .clk_eth_90(clk_eth_90),
    .clk_1x_90(clk_1x_90),
    .clk_2x_0(clk_2x_0)
);

wire lb_clk=bmb7_U7_clkout;
wire [23:0] lb_addr;
wire [31:0] lb_dout;
wire [31:0] lb_din;
wire lb_strobe, lb_rd;
jxj_gate jxjgate(.clk(lb_clk),
.rx_din(port_50006_word_s6tok7), .rx_stb(port_50006_rx_available), .rx_end(port_50006_rx_complete),
.tx_dout(port_50006_word_k7tos6), .tx_rdy(port_50006_tx_available), .tx_end(port_50006_tx_complete), .tx_stb(port_50006_word_read),
.lb_addr(lb_addr), .lb_dout(lb_dout), .lb_din(lb_din),
.lb_strobe(lb_strobe), .lb_rd(lb_rd)
);

parameter vmod_mode_count=3;
cryomodule #(
    .mode_count(vmod_mode_count)
) cryomodule(
    .clk1x(clk_1x_90),
    .clk2x(clk_2x_0),
    // Local Bus drives both simulator and controller
    // Simulator is in the upper 16K, controller in the lower 16K words.
    .lb_clk(lb_clk),
    .lb_data(lb_dout),
    .lb_addr(lb_addr[16:0]),
    .lb_write(lb_strobe & ~lb_rd),  // single-cycle causes a write // XXX write or strobe?
    .lb_read(lb_strobe & lb_rd),
    .lb_out(lb_din)
);
endmodule
