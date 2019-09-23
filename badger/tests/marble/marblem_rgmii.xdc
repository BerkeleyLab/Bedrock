# RGMII
set_property -dict {PACKAGE_PIN M17 IOSTANDARD LVCMOS25} [get_ports PHY_RSTN]

set_property -dict {PACKAGE_PIN L19 IOSTANDARD LVCMOS25} [get_ports RGMII_RX_CLK]
set_property -dict {PACKAGE_PIN H15 IOSTANDARD LVCMOS25} [get_ports RGMII_RX_CTRL]
set_property -dict {PACKAGE_PIN K13 IOSTANDARD LVCMOS25} [get_ports {RGMII_RXD[0]}]
set_property -dict {PACKAGE_PIN H14 IOSTANDARD LVCMOS25} [get_ports {RGMII_RXD[1]}]
set_property -dict {PACKAGE_PIN J14 IOSTANDARD LVCMOS25} [get_ports {RGMII_RXD[2]}]
set_property -dict {PACKAGE_PIN K14 IOSTANDARD LVCMOS25} [get_ports {RGMII_RXD[3]}]

set_property -dict {PACKAGE_PIN J15 IOSTANDARD LVCMOS25} [get_ports RGMII_TX_CLK]
set_property -dict {PACKAGE_PIN J16 IOSTANDARD LVCMOS25} [get_ports RGMII_TX_CTRL]
set_property -dict {PACKAGE_PIN G15 IOSTANDARD LVCMOS25} [get_ports {RGMII_TXD[0]}]
set_property -dict {PACKAGE_PIN G16 IOSTANDARD LVCMOS25} [get_ports {RGMII_TXD[1]}]
set_property -dict {PACKAGE_PIN G13 IOSTANDARD LVCMOS25} [get_ports {RGMII_TXD[2]}]
set_property -dict {PACKAGE_PIN H13 IOSTANDARD LVCMOS25} [get_ports {RGMII_TXD[3]}]

# https://www.xilinx.com/support/answers/53092.html
set_property IOB TRUE [get_ports RGMII_RX_CTRL]
set_property IOB TRUE [get_ports {RGMII_RXD[*]}]
set_property IOB TRUE [get_ports RGMII_TX_CLK}]
set_property IOB TRUE [get_ports RGMII_TX_CTRL]
set_property IOB TRUE [get_ports {RGMII_TXD[*]}]

#
set_property SLEW FAST [get_ports RGMII_TX_CLK]
set_property SLEW FAST [get_ports RGMII_TX_CTRL]
set_property SLEW FAST [get_ports {RGMII_TXD[*]}]

# Rx clock constraint
create_clock -period 8.00 -name phy_rxclk [get_ports RGMII_RX_CLK]

# QSPI Boot Flash
# CFG_FCS  == BOOT_CS_B
# CFG_MOSI == BOOT_MOSI
# CFG_DIN  == BOOT_MISO
set_property -dict {PACKAGE_PIN T19 IOSTANDARD LVCMOS25} [get_ports BOOT_CS_B]
set_property -dict {PACKAGE_PIN P22 IOSTANDARD LVCMOS25} [get_ports BOOT_MOSI]
set_property -dict {PACKAGE_PIN R22 IOSTANDARD LVCMOS25} [get_ports BOOT_MISO]

# LEDs
# LED[n] == Pmod1_n
set_property -dict {PACKAGE_PIN C18 IOSTANDARD LVCMOS33} [get_ports {LED[0]}]
set_property -dict {PACKAGE_PIN D22 IOSTANDARD LVCMOS33} [get_ports {LED[1]}]
set_property -dict {PACKAGE_PIN E22 IOSTANDARD LVCMOS33} [get_ports {LED[2]}]
set_property -dict {PACKAGE_PIN G21 IOSTANDARD LVCMOS33} [get_ports {LED[3]}]

# MMC microcontroller for configuration - for real!?
# FPGA_SCK  == SCLK
# FPGA_SSEL == CSB
# FPGA_MOSI == MOSI
set_property -dict {PACKAGE_PIN C20 IOSTANDARD LVCMOS33} [get_ports SCLK]
set_property -dict {PACKAGE_PIN D20 IOSTANDARD LVCMOS33} [get_ports CSB]
set_property -dict {PACKAGE_PIN F19 IOSTANDARD LVCMOS33} [get_ports MOSI]
# t_property -dict {PACKAGE_PIN F20 IOSTANDARD LVCMOS33} [get_ports FPGA_MISO]
# t_property -dict {PACKAGE_PIN F18 IOSTANDARD LVCMOS33} [get_ports FPGA_INT]

# 125 MHz from White Rabbit to comes in via MGTREFCLK, we should really
# turn on the GTP and use its TXOUTCLK.
# 20 MHz from Y3 (CLK20_VCXO) is a poor substitute
set_property -dict {PACKAGE_PIN D17 IOSTANDARD LVCMOS33} [get_ports SYSCLK_P]
create_clock -name sysclk -period 50.00 [get_ports SYSCLK_P]

# Clock groups
set_clock_groups -name async_clks -asynchronous \
-group [get_clocks -include_generated_clocks sysclk] \
-group [get_clocks -include_generated_clocks phy_rxclk]

# RESET button, use Pmod1_4
set_property -dict {PACKAGE_PIN D21 IOSTANDARD LVCMOS33} [get_ports RESET]

# 20 MHz VCXO Enable
set_property -dict {PACKAGE_PIN E13 IOSTANDARD LVCMOS33} [get_ports VCXO_EN]

# Bank 0 setup
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
