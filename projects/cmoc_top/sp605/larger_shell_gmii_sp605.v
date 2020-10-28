`timescale 1ns / 1ns

module larger_shell_gmii_sp605(
    input SYSCLK_P,
    input SYSCLK_N,

    output [7:0] GMII_TXD,
    output GMII_TX_EN,
    output GMII_TX_ER,
    output GMII_GTX_CLK,
    input GMII_TX_CLK, // not used

    input [7:0] GMII_RXD,
    input GMII_RX_ER,
    input GMII_RX_DV,
    input GMII_RX_CLK,
    output PHY_RSTN,

    output [3:0] LED
);

// LED[0] blink_rx
// LED[1] arp_activity
// LED[2] rx_activity
// LED[3] tx_activity

//parameter ip ={8'd128, 8'd3, 8'd128, 8'd172}; // lrd3.lbl.gov
parameter ip ={8'd192, 8'd168, 8'd19, 8'd19}; // lrd3.lbl.gov
// First octet of MAC normally ends with binary 00, for OUI unicast.
// Change that to 10 for locally managed unicast.
// See https://en.wikipedia.org/wiki/MAC_address#Address_details
parameter mac=48'h125555000126;
parameter jumbo_dw=14;

assign PHY_RSTN=1'b1;

wire clk_1x_90, clk_2x_0;
wire clk_eth;

// GMII_GTK_CLK output pin is what actually drives the PHY for Tx
`ifdef SIMULATE
assign GMII_GTX_CLK = clk_eth;
`else
ODDR2 GTXCLK_OUT(
    .Q(GMII_GTX_CLK),
    .C0(clk_eth),
    .C1(~clk_eth),
    .CE(1'b1),
    .D0(1'b1),
    .D1(1'b0),
    .R(1'b0),
    .S(1'b0)
);
`endif

// 200 MHz clock in x5, then divide by 12 and 24 to get 83 and 42 MHz for DSP
spartan6_clocks #(
    .clkin_period(5), // SYSCLK = 200MHz
    .plladv_div1(12),
    .plladv_div0(24)
) clocks_i(
    .rst(1'b0),
    .sysclk_p(SYSCLK_P),
    .sysclk_n(SYSCLK_N),
    .clk_eth(clk_eth),
    .clk_1x_90(clk_1x_90),
    .clk_2x_0(clk_2x_0)
);

wire [7:0] eth_status;

cryomodule_badger #(
    .cavity_count(1),
    .vmod_mode_count(1),
    .ip(ip), .mac(mac), .jumbo_dw(jumbo_dw)
) cmb_i(
    .clk1x(clk_1x_90),
    .clk2x(clk_2x_0),
    .gmii_tx_clk(clk_eth),
    .gmii_rx_clk(GMII_RX_CLK),
    .gmii_rxd(GMII_RXD),
    .gmii_rx_dv(GMII_RX_DV),
    .gmii_rx_er(GMII_RX_ER),
    .gmii_txd(GMII_TXD),
    .gmii_tx_en(GMII_TX_EN),
    .gmii_tx_er(GMII_TX_ER),
    .eth_status(eth_status),
    .eth_cfg_clk(1'b0),
    .eth_cfg_set(10'b0)
);

reg [24:0] c1x_ecnt=0;
always @(posedge clk_1x_90) c1x_ecnt<=c1x_ecnt+1;
wire blink_c1x = c1x_ecnt[24];

reg [25:0] c2x_ecnt=0;
always @(posedge clk_2x_0) c2x_ecnt<=c2x_ecnt+1;
wire blink_c2x = c2x_ecnt[25];

assign LED={eth_status[5:3], eth_status[0]};

endmodule
