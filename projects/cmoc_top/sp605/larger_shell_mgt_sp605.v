`timescale 1ns / 1ns

module larger_shell_mgt_sp605(
    input SYSCLK_P,
    input SYSCLK_N,
    input REFCLK_P,
    input REFCLK_N,

    input RXP0,
    input RXN0,
    output TXP0,
    output TXN0,
    input SFP0_LOS,
    output IIC_SCL_SFP,
    inout IIC_SDA_SFP,
    output SFP0_TX_DISABLE,
    output SFP0_RATE_SELECT,

    output [3:0] LED
);

// LED[0] rx_clk
// LED[1] arp_activity
// LED[2] rx_activity
// LED[3] tx_activity

parameter ip ={8'd128, 8'd3, 8'd129, 8'd18}; // rflab3.lbl.gov
// First octet of MAC normally ends with binary 00, for OUI unicast.
// Change that to 10 for locally managed unicast.
// See https://en.wikipedia.org/wiki/MAC_address#Address_details
parameter mac=48'h125555000127;
parameter jumbo_dw=14;

// Stupid resets
reg gtp_reset=1, gtp_reset1=1;
always @(posedge tx_clk) begin
    gtp_reset <= gtp_reset1;
    gtp_reset1 <= 0;
end

// ============= Clock setup =============
wire clk_1x_90, clk_2x_0;
wire clk_eth; // not used

// 200 MHz clock in x5, then divide by 12 and 24 to get 83 and 42 MHz for DSP
spartan6_clocks #(
    .clkin_period(5), // SYSCLK = 200MHz
    .plladv_div1(12),
    .plladv_div0(24)
) clocks_i(
    .rst(gtp_reset),
    .sysclk_p(SYSCLK_P),
    .sysclk_n(SYSCLK_N),
    .clk_eth(clk_eth),
    .clk_1x_90(clk_1x_90),
    .clk_2x_0(clk_2x_0)
);

// ============= Ethernet on SFP1 follows ===================
// The two clocks are sourced from gmii_link
wire rx_clk, tx_clk;


wire rxn1, rxp1, txn1, txp1; // not used
wire [9:0] txdata0, rxdata0;
wire [9:0] txdata1, rxdata1;
wire [6:0] rxstatus0, rxstatus1;  // XXX not hooked up?
wire txstatus0, txstatus1;
wire plllkdet, resetdone;
wire RXN1, RXP1, TXN1, TXP1;  // Not used
s6_gtp_wrap s6_gtp_wrap_i(
    .txdata0(txdata0), .txstatus0(txstatus0),
    .rxdata0(rxdata0), .rxstatus0(rxstatus0),
    .txdata1(txdata1), .txstatus1(txstatus1),
    .rxdata1(rxdata1), .rxstatus1(rxstatus1),
    .tx_clk(tx_clk), .rx_clk(rx_clk),
    .plllkdet(plllkdet), .resetdone(resetdone),
    .gtp_reset_i(gtp_reset),
    .refclk_p(REFCLK_P), .refclk_n(REFCLK_N),
    .rxn0(RXN0), .rxp0(RXP0),
    .txn0(TXN0), .txp0(TXP0),
    .rxn1(RXN1), .rxp1(RXP1),
    .txn1(TXN1), .txp1(TXP1)
);

// bridge between serdes and internal GMII
wire [7:0] txd, rxd;
wire tx_en, tx_er, rx_dv;
wire [5:0] link_leds;
wire [15:0] lacr_rx;  // nominally in Rx clock domain, don't sweat it
wire [1:0] an_state_mon;
reg an_bypass=1;  // settable by software
gmii_link glink(
	.RX_CLK(rx_clk),
	.RXD(rxd),
	.RX_DV(rx_dv),
	.GTX_CLK(tx_clk),
	.TXD(txd),
	.TX_EN(tx_en),
	.TX_ER(tx_er),
	.txdata(txdata0), .rxdata(rxdata0),
	.rx_err_los(rxstatus0[4]),
	.an_bypass(an_bypass),
	.lacr_rx(lacr_rx),
	.an_state_mon(an_state_mon),
	.leds(link_leds)
);

wire [7:0] eth_status;

cryomodule_badger #(
    .vmod_mode_count(1),
    .ip(ip), .mac(mac), .jumbo_dw(jumbo_dw)
) cmb(
    .clk1x(clk_1x_90),
    .clk2x(clk_2x_0),
    .gmii_tx_clk(tx_clk),
    .gmii_rx_clk(rx_clk),
    .gmii_rxd(rxd),
    .gmii_rx_dv(rx_dv),
    .gmii_rx_er(1'b0),
    .gmii_txd(txd),
    .gmii_tx_en(tx_en),
    .gmii_tx_er(tx_er),
    .eth_status(eth_status)
);

// ============= Housekeeping follows ===================
// SFP management ports idle for now
assign IIC_SCL_SFP = 1'b1;
assign IIC_SDA_SFP = 1'bz;
assign SFP0_TX_DISABLE = 0;
assign SFP0_RATE_SELECT = 1'b1; // full speed

reg [24:0] c1x_ecnt=0;
always @(posedge clk_1x_90) c1x_ecnt<=c1x_ecnt+1;
wire blink_c1x = c1x_ecnt[24];

reg [25:0] c2x_ecnt=0;
always @(posedge clk_2x_0) c2x_ecnt<=c2x_ecnt+1;
wire blink_c2x = c2x_ecnt[25];

assign LED={eth_status[5:3], eth_status[0]};

endmodule
