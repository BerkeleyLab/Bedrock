

# RGMII Rx
set_property -dict {PACKAGE_PIN L19 IOSTANDARD LVCMOS25} [get_ports RGMII_RX_CLK]
set_property -dict {PACKAGE_PIN H15 IOSTANDARD LVCMOS25} [get_ports RGMII_RX_CTRL]
set_property -dict {PACKAGE_PIN K13 IOSTANDARD LVCMOS25} [get_ports {RGMII_RXD[0]}]
set_property -dict {PACKAGE_PIN H14 IOSTANDARD LVCMOS25} [get_ports {RGMII_RXD[1]}]
set_property -dict {PACKAGE_PIN J14 IOSTANDARD LVCMOS25} [get_ports {RGMII_RXD[2]}]
set_property -dict {PACKAGE_PIN K14 IOSTANDARD LVCMOS25} [get_ports {RGMII_RXD[3]}]

# RGMII Tx
set_property -dict {PACKAGE_PIN J15 IOSTANDARD LVCMOS25} [get_ports RGMII_TX_CLK]
set_property -dict {PACKAGE_PIN J16 IOSTANDARD LVCMOS25} [get_ports RGMII_TX_CTRL]
set_property -dict {PACKAGE_PIN G15 IOSTANDARD LVCMOS25} [get_ports {RGMII_TXD[0]}]
set_property -dict {PACKAGE_PIN G16 IOSTANDARD LVCMOS25} [get_ports {RGMII_TXD[1]}]
set_property -dict {PACKAGE_PIN G13 IOSTANDARD LVCMOS25} [get_ports {RGMII_TXD[2]}]
set_property -dict {PACKAGE_PIN H13 IOSTANDARD LVCMOS25} [get_ports {RGMII_TXD[3]}]

# QSPI Boot Flash
set_property -dict {PACKAGE_PIN T19 IOSTANDARD LVCMOS25} [get_ports BOOT_CS_B]
set_property -dict {PACKAGE_PIN P22 IOSTANDARD LVCMOS25} [get_ports BOOT_MOSI]
set_property -dict {PACKAGE_PIN R22 IOSTANDARD LVCMOS25} [get_ports BOOT_MISO]

# Debugging LEDs
set_property -dict {PACKAGE_PIN C18 IOSTANDARD LVCMOS33} [get_ports {LED[0]}]
set_property -dict {PACKAGE_PIN D22 IOSTANDARD LVCMOS33} [get_ports {LED[1]}]
set_property -dict {PACKAGE_PIN E22 IOSTANDARD LVCMOS33} [get_ports {LED[2]}]
set_property -dict {PACKAGE_PIN G21 IOSTANDARD LVCMOS33} [get_ports {LED[3]}]

# MMC microcontroller for configuration - for real!?
set_property -dict {PACKAGE_PIN C20 IOSTANDARD LVCMOS33} [get_ports SCLK]
set_property -dict {PACKAGE_PIN D20 IOSTANDARD LVCMOS33} [get_ports CSB]
set_property -dict {PACKAGE_PIN F19 IOSTANDARD LVCMOS33} [get_ports MOSI]

# 125 MHz from White Rabbit comes in via MGTREFCLK;
# we should really turn on the GTP and use its TXOUTCLK.
# 20 MHz from Y3 is a poor substitute
set_property -dict {PACKAGE_PIN D17 IOSTANDARD LVCMOS33} [get_ports SYSCLK_P]

# Miscellaneous
set_property -dict {PACKAGE_PIN M17 IOSTANDARD LVCMOS25} [get_ports PHY_RSTN]
set_property -dict {PACKAGE_PIN D21 IOSTANDARD LVCMOS33} [get_ports RESET]
set_property -dict {PACKAGE_PIN E13 IOSTANDARD LVCMOS33} [get_ports VCXO_EN]


# Special pin properties for RGMII
# Invalid to flag RGMII_RX_CLK as IOB TRUE
set_property IOB TRUE [get_ports {RGMII_RX_CTRL}]
set_property IOB TRUE [get_ports {RGMII_RXD*}]
set_property IOB TRUE [get_ports {RGMII_TX*}]
set_property SLEW FAST [get_ports {RGMII_TX*}]

# Bank 0 setup
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]

# Clocks
create_clock -name sys_clk -period 50.00 [get_ports SYSCLK_P]
create_clock -period 8.00 -name rx_clk [get_ports RGMII_RX_CLK]
set_clock_groups -name async_clks -asynchronous \
  -group [get_clocks -include_generated_clocks sys_clk] \
  -group [get_clocks -include_generated_clocks rx_clk]
