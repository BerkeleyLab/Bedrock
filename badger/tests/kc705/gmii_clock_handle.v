// KC705 variant of this module
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
xilinx7_clocks #(
	.CLKIN_PERIOD(5), // SYSCLK = 200MHz
	.MULT     (5),  // 200 MHz X 5 = 1 GHz
	.DIV0     (8),  // 1 GHz / 8 = 125 MHz
	.DIV1     (5)   // 1 GHz / 5 = 200 MHz
) clocks_i(
	.sysclk_p (sysclk_p),
	.sysclk_n (sysclk_n),
	.reset    (reset),
	.clk_out0 (clk_eth),
	.clk_out2 (clk_eth_90),
	.locked   (clk_locked)
);

// GMII_GTK_CLK output pin is what actually drives the PHY for Tx
ODDR GTXCLK_OUT(
	.Q(clk_pin),
	.C(clk_eth),
	.CE(1'b1),
	.D1(1'b1),
	.D2(1'b0),
	.R(1'b0),
	.S(1'b0)
);

endmodule
