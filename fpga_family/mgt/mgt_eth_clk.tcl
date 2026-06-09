if { [info exists ::env(DOUBLEBIT)] } {
    set doublebit $::env(DOUBLEBIT)
} else {
    set doublebit 0
}

if { $doublebit == 1 } {
    set clk_freq 125.0
    puts "INFO: Configuring mgt_eth_mmcm for 2.5G (125 MHz)"
} else {
    set clk_freq 62.5
    puts "INFO: Configuring mgt_eth_mmcm for 1.25G (62.5 MHz)"
}

set cfg_dict [list \
   CONFIG.PRIM_IN_FREQ               $clk_freq \
   CONFIG.CLKOUT1_USED               {true} \
   CONFIG.CLKOUT2_USED               {true} \
   CONFIG.CLKOUT3_USED               {true} \
   CONFIG.PRIMARY_PORT               {clk_in} \
   CONFIG.CLK_OUT1_PORT              {mgt_clk} \
   CONFIG.CLK_OUT2_PORT              {gmii_clk} \
   CONFIG.CLK_OUT3_PORT              {gmii_clk90} \
   CONFIG.CLKOUT1_REQUESTED_OUT_FREQ $clk_freq \
   CONFIG.CLKOUT1_REQUESTED_PHASE    {90.0} \
   CONFIG.CLKOUT2_REQUESTED_OUT_FREQ {125.0} \
   CONFIG.CLKOUT3_REQUESTED_OUT_FREQ {125.0} \
   CONFIG.CLKOUT3_REQUESTED_PHASE    {90.0} \
   CONFIG.MMCM_DIVCLK_DIVIDE         {1} \
   CONFIG.NUM_OUT_CLKS               {3} \
]
