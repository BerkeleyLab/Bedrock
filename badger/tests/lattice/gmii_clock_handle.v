// cf. prjtrellis/examples/soc_versa5g/pll.v
module gmii_clock_handle(
        input sysclk_p,  // 100 MHz
	input sysclk_n,  // not used
	input reset,     // not used
        output clk_eth,  // 125 MHz
	output clk_eth_90,  // XXX not implemented
	output clk_locked   // faked
);
wire clki = sysclk_p;
assign clk_locked = 1;

    (* ICP_CURRENT="12" *) (* LPF_RESISTOR="8" *) (* MFG_ENABLE_FILTEROPAMP="1" *) (* MFG_GMCREF_SEL="2" *)
    EHXPLLL #(
        .PLLRST_ENA("DISABLED"),
        .INTFB_WAKE("DISABLED"),
        .STDBY_ENABLE("DISABLED"),
        .DPHASE_SOURCE("DISABLED"),
        .CLKOP_FPHASE(0),
        .CLKOP_CPHASE(11),
        .OUTDIVIDER_MUXA("DIVA"),
        .CLKOP_ENABLE("ENABLED"),
        .CLKOS_ENABLE("ENABLED"),  // drives the feedback path
        // VCO range 400 to 800 MHz
        // phase detector input rated 10 to 400 MHz
        .CLKOP_DIV(4),  // 500 MHz / 4 = 125 MHz CLKOP
        .CLKOS_DIV(5),  // 500 MHz / 5 = 100 MHz CLKOS
        .CLKFB_DIV(1),  // 100 MHz / 1 = 100 MHz at phase detector
        .CLKI_DIV(1),   // 100 MHz / 1 = 100 MHz at phase detector
        // Parameter FEEDBK_PATH configures muxes "Internal Feedback" and
        // "FBKSEL" shown in TN1263 Figure 23.
        // Its valid values within Symbiflow are shown in
        // https://symbiflow.github.io/prjtrellis-db/ECP5/tilehtml/PLL0_UL.html
        // and fuzzers/ECP5/091-pll_config/fuzzer.py
        .FEEDBK_PATH("INT_OS")
    ) pll_i (
        .CLKI(clki),
        .CLKOP(clk_eth),
        .RST(1'b0),
        .STDBY(1'b0),
        .PHASESEL0(1'b0),
        .PHASESEL1(1'b0),
        .PHASEDIR(1'b0),
        .PHASESTEP(1'b0),
        .PLLWAKESYNC(1'b0),
        .ENCLKOP(1'b0)
    );
endmodule
