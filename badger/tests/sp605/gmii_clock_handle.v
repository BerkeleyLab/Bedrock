// SP605 variant of this module
module gmii_clock_handle(
	input sysclk_p,
	input sysclk_n,
	input reset,
	output clk_eth,  // 125 MHz
	output clk_eth_90,
	output clk_pin,  // output pin to PHY
	output clk_locked
);

// 200 MHz clock in x5, then divide by 8 to get clk_eth (tx_clk)
spartan6_clocks #(
	.clkin_period(5), // SYSCLK = 200MHz
	.plladv_div1(12),
	.plladv_div0(24)
) clocks_i(
	.rst(reset),
	.sysclk_p(sysclk_p),
	.sysclk_n(sysclk_n),
	.clk_eth(clk_eth),
	.pll_lock(clk_locked)
);

assign clk_eth_90 = 1'bz;  // RGMII not supported!

// GMII_GTK_CLK output pin is what actually drives the PHY for Tx
ODDR2 GTXCLK_OUT(
	.Q(clk_pin),
	.C0(clk_eth),
	.C1(~clk_eth),
	.CE(1'b1),
	.D0(1'b1),
	.D1(1'b0),
	.R(1'b0),
	.S(1'b0)
);

endmodule
