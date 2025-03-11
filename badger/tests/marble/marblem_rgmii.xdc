# Avnet AUBoard 15P p. 35

# RGMII Rx  p. 35
set_property -dict {PACKAGE_PIN Y15 IOSTANDARD LVCMOS18} [get_ports RGMII_RX_CLK]
set_property -dict {PACKAGE_PIN AA15 IOSTANDARD LVCMOS18} [get_ports RGMII_RX_CTRL]
set_property -dict {PACKAGE_PIN W15 IOSTANDARD LVCMOS18} [get_ports {RGMII_RXD[0]}]
set_property -dict {PACKAGE_PIN W14 IOSTANDARD LVCMOS18} [get_ports {RGMII_RXD[1]}]
set_property -dict {PACKAGE_PIN Y16 IOSTANDARD LVCMOS18} [get_ports {RGMII_RXD[2]}]
set_property -dict {PACKAGE_PIN W16 IOSTANDARD LVCMOS18} [get_ports {RGMII_RXD[3]}]

# RGMII Tx  p. 35
set_property -dict {PACKAGE_PIN AA14 IOSTANDARD LVCMOS18} [get_ports RGMII_TX_CLK]
set_property -dict {PACKAGE_PIN AB14 IOSTANDARD LVCMOS18} [get_ports RGMII_TX_CTRL]
set_property -dict {PACKAGE_PIN W13 IOSTANDARD LVCMOS18} [get_ports {RGMII_TXD[0]}]
set_property -dict {PACKAGE_PIN W12 IOSTANDARD LVCMOS18} [get_ports {RGMII_TXD[1]}]
set_property -dict {PACKAGE_PIN AA13 IOSTANDARD LVCMOS18} [get_ports {RGMII_TXD[2]}]
set_property -dict {PACKAGE_PIN Y13 IOSTANDARD LVCMOS18} [get_ports {RGMII_TXD[3]}]

# QSPI Boot Flash  p. 20, but subsumed by STARTUPE3
# set_property -dict {PACKAGE_PIN AA12 IOSTANDARD LVCMOS18} [get_ports BOOT_CS_B]
# set_property -dict {PACKAGE_PIN AD11 IOSTANDARD LVCMOS18} [get_ports BOOT_MOSI]
# set_property -dict {PACKAGE_PIN AC12 IOSTANDARD LVCMOS18} [get_ports BOOT_MISO]

# Debugging LEDs  p. 41
set_property -dict {PACKAGE_PIN A10 IOSTANDARD LVCMOS33} [get_ports {LED[0]}]
set_property -dict {PACKAGE_PIN B10 IOSTANDARD LVCMOS33} [get_ports {LED[1]}]
set_property -dict {PACKAGE_PIN B11 IOSTANDARD LVCMOS33} [get_ports {LED[2]}]
set_property -dict {PACKAGE_PIN C11 IOSTANDARD LVCMOS33} [get_ports {LED[3]}]

# MMC microcontroller for configuration - for real!?
# MikroE Click  p. 39
set_property -dict {PACKAGE_PIN G11 IOSTANDARD LVCMOS33} [get_ports SCLK]
set_property -dict {PACKAGE_PIN H11 IOSTANDARD LVCMOS33} [get_ports CSB]
set_property -dict {PACKAGE_PIN G9 IOSTANDARD LVCMOS33} [get_ports MOSI]

# 125 MHz from White Rabbit comes in via MGTREFCLK;
# we should really turn on the GTP and use its TXOUTCLK.
# 20 MHz from Y3 is a poor substitute
# 300 MHz differential  p. 21
set_property -dict {PACKAGE_PIN AD21 IOSTANDARD LVCMOS18} [get_ports SYSCLK_P]

# Miscellaneous
set_property -dict {PACKAGE_PIN AC14 IOSTANDARD LVCMOS18} [get_ports PHY_RSTN]
# set_property -dict {PACKAGE_PIN D21 IOSTANDARD LVCMOS33} [get_ports RESET]
# CLICK_PWM - XXX stupid
set_property -dict {PACKAGE_PIN J9 IOSTANDARD LVCMOS33} [get_ports VCXO_EN]


# Special pin properties for RGMII
# Invalid to flag RGMII_RX_CLK as IOB TRUE
# set_property IOB TRUE [get_ports {RGMII_RX_CTRL}]
# set_property IOB TRUE [get_ports {RGMII_RXD*}]
# set_property IOB TRUE [get_ports {RGMII_TX*}]
set_property SLEW FAST [get_ports {RGMII_TX*}]

# Bank 0 setup
set_property CFGBVS GND [current_design]
set_property CONFIG_VOLTAGE 1.8 [current_design]

# Clocks
create_clock -name sys_clk -period 50.00 [get_ports SYSCLK_P]
create_clock -period 8.00 -name rx_clk [get_ports RGMII_RX_CLK]
set_clock_groups -name async_clks -asynchronous \
  -group [get_clocks -include_generated_clocks sys_clk] \
  -group [get_clocks -include_generated_clocks rx_clk]
