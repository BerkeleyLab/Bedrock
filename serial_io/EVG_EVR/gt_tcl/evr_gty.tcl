# Create the IP core
create_ip -name gtwizard_ultrascale -vendor xilinx.com -library ip -version 1.7 -module_name evr_gt

# Configure the IP core parameters
set_property -dict {
    CONFIG.TX_LINE_RATE {2.5}
    CONFIG.TX_PLL_TYPE {CPLL}
    CONFIG.TX_REFCLK_FREQUENCY {156.25}
    CONFIG.TX_DATA_ENCODING {8B10B}
    CONFIG.TX_USER_DATA_WIDTH {16}
    CONFIG.TX_INT_DATA_WIDTH {20}
    CONFIG.RX_LINE_RATE {2.5}
    CONFIG.RX_PLL_TYPE {CPLL}
    CONFIG.RX_REFCLK_FREQUENCY {156.25}
    CONFIG.RX_DATA_DECODING {8B10B}
    CONFIG.RX_USER_DATA_WIDTH {16}
    CONFIG.RX_INT_DATA_WIDTH {20}
    CONFIG.RX_BUFFER_MODE {0}
    CONFIG.RX_JTOL_FC {1.4997001}
    CONFIG.RX_REFCLK_SOURCE {X0Y4 clk1+2}
    CONFIG.TX_REFCLK_SOURCE {X0Y4 clk1+2}
    CONFIG.LOCATE_TX_USER_CLOCKING {CORE}
    CONFIG.LOCATE_RX_USER_CLOCKING {CORE}
    CONFIG.TXPROGDIV_FREQ_SOURCE {CPLL}
    CONFIG.TXPROGDIV_FREQ_VAL {125}
    CONFIG.FREERUN_FREQUENCY {100}
    CONFIG.ENABLE_OPTIONAL_PORTS {cplllock_out}
} [get_ips evr_gt]

# Generate output products for the IP core
generate_target all [get_ips evr_gt]
