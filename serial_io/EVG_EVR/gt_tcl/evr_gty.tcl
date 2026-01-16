if {![info exists REFCLK_FREQ]} {
    error "REFCLK_FREQ not set!!!"
}

if {![string is double -strict $REFCLK_FREQ]} {
    error "REFCLK_FREQ must be a numeric value in MHz, got '$REFCLK_FREQ'"
}
set REFCLK_FREQ [format "%.3f" $REFCLK_FREQ]
puts "REFCLK_FREQ provided: $REFCLK_FREQ MHz"

set CPLL_FBDIV 16
set CPLL_REFCLK_DIV 1
set TXOUT_DIV 10

set LINE_RATE_MHz  [expr {($REFCLK_FREQ * $CPLL_FBDIV / $CPLL_REFCLK_DIV) / $TXOUT_DIV}]
set LINE_RATE_Gbps [expr {$LINE_RATE_MHz * 10.0 / 1000.0}]
set TXPROG_FREQ    [expr {$LINE_RATE_MHz / 2.0}]

puts "----------------------------------------"
puts "GT Wizard Auto Config:"
puts "Refclk: ${REFCLK_FREQ} MHz"
puts "Line Rate (raw): ${LINE_RATE_MHz} MHz"
puts "Line Rate (Gbps, 8B/10B): ${LINE_RATE_Gbps} Gbps"
puts "----------------------------------------"

create_ip -name gtwizard_ultrascale -vendor xilinx.com -library ip -version 1.7 -module_name evr_gt

set_property -dict [list \
    CONFIG.TX_LINE_RATE $LINE_RATE_Gbps \
    CONFIG.TX_PLL_TYPE CPLL \
    CONFIG.TX_REFCLK_FREQUENCY $REFCLK_FREQ \
    CONFIG.TX_DATA_ENCODING 8B10B \
    CONFIG.TX_USER_DATA_WIDTH 16 \
    CONFIG.TX_INT_DATA_WIDTH 20 \
    CONFIG.RX_LINE_RATE $LINE_RATE_Gbps \
    CONFIG.RX_PLL_TYPE CPLL \
    CONFIG.RX_REFCLK_FREQUENCY $REFCLK_FREQ \
    CONFIG.RX_DATA_DECODING 8B10B \
    CONFIG.RX_USER_DATA_WIDTH 16 \
    CONFIG.RX_INT_DATA_WIDTH 20 \
    CONFIG.RX_BUFFER_MODE 0 \
    CONFIG.RX_JTOL_FC 1.4997001 \
    CONFIG.RX_REFCLK_SOURCE {X0Y4 clk1+2} \
    CONFIG.TX_REFCLK_SOURCE {X0Y4 clk1+2} \
    CONFIG.LOCATE_TX_USER_CLOCKING CORE \
    CONFIG.LOCATE_RX_USER_CLOCKING CORE \
    CONFIG.TXPROGDIV_FREQ_SOURCE CPLL \
    CONFIG.TXPROGDIV_FREQ_VAL $TXPROG_FREQ \
    CONFIG.FREERUN_FREQUENCY 100 \
    CONFIG.ENABLE_OPTIONAL_PORTS cplllock_out \
] [get_ips evr_gt]

generate_target all [get_files evr_gt.xci]
