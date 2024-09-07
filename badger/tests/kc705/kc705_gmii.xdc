# GMII PHY
set_property -dict {PACKAGE_PIN L20 IOSTANDARD LVCMOS25} [get_ports PHY_RSTN]

set_property -dict {PACKAGE_PIN U27 IOSTANDARD LVCMOS25} [get_ports GMII_RX_CLK]
set_property -dict {PACKAGE_PIN V26 IOSTANDARD LVCMOS25} [get_ports GMII_RX_ER]
set_property -dict {PACKAGE_PIN R28 IOSTANDARD LVCMOS25} [get_ports GMII_RX_DV]
set_property -dict {PACKAGE_PIN U30 IOSTANDARD LVCMOS25} [get_ports {GMII_RXD[0]}]
set_property -dict {PACKAGE_PIN U25 IOSTANDARD LVCMOS25} [get_ports {GMII_RXD[1]}]
set_property -dict {PACKAGE_PIN T25 IOSTANDARD LVCMOS25} [get_ports {GMII_RXD[2]}]
set_property -dict {PACKAGE_PIN U28 IOSTANDARD LVCMOS25} [get_ports {GMII_RXD[3]}]
set_property -dict {PACKAGE_PIN R19 IOSTANDARD LVCMOS25} [get_ports {GMII_RXD[4]}]
set_property -dict {PACKAGE_PIN T27 IOSTANDARD LVCMOS25} [get_ports {GMII_RXD[5]}]
set_property -dict {PACKAGE_PIN T26 IOSTANDARD LVCMOS25} [get_ports {GMII_RXD[6]}]
set_property -dict {PACKAGE_PIN T28 IOSTANDARD LVCMOS25} [get_ports {GMII_RXD[7]}]

set_property -dict {PACKAGE_PIN K30 IOSTANDARD LVCMOS25} [get_ports GMII_GTX_CLK]
set_property -dict {PACKAGE_PIN M28 IOSTANDARD LVCMOS25} [get_ports GMII_TX_CLK]
set_property -dict {PACKAGE_PIN N29 IOSTANDARD LVCMOS25} [get_ports GMII_TX_ER]
set_property -dict {PACKAGE_PIN M27 IOSTANDARD LVCMOS25} [get_ports GMII_TX_EN]
set_property -dict {PACKAGE_PIN N27 IOSTANDARD LVCMOS25} [get_ports {GMII_TXD[0]}]
set_property -dict {PACKAGE_PIN N25 IOSTANDARD LVCMOS25} [get_ports {GMII_TXD[1]}]
set_property -dict {PACKAGE_PIN M29 IOSTANDARD LVCMOS25} [get_ports {GMII_TXD[2]}]
set_property -dict {PACKAGE_PIN L28 IOSTANDARD LVCMOS25} [get_ports {GMII_TXD[3]}]
set_property -dict {PACKAGE_PIN J26 IOSTANDARD LVCMOS25} [get_ports {GMII_TXD[4]}]
set_property -dict {PACKAGE_PIN K26 IOSTANDARD LVCMOS25} [get_ports {GMII_TXD[5]}]
set_property -dict {PACKAGE_PIN L30 IOSTANDARD LVCMOS25} [get_ports {GMII_TXD[6]}]
set_property -dict {PACKAGE_PIN J28 IOSTANDARD LVCMOS25} [get_ports {GMII_TXD[7]}]

# https://adaptivesupport.amd.com/s/article/53092
set_property IOB TRUE [get_ports GMII_TXD[*]]
set_property IOB TRUE [get_ports GMII_TX_EN]
set_property IOB TRUE [get_ports GMII_RXD[*]]
set_property IOB TRUE [get_ports GMII_RX_DV]

# Rx clock constraint
create_clock -period 8.00 -name phy_rxclk [get_ports GMII_RX_CLK]

# set_property -dict "PACKAGE_PIN W19 IOSTANDARD LVCMOS25" [get_ports GMII_COL]
# set_property -dict "PACKAGE_PIN R30 IOSTANDARD LVCMOS25" [get_ports GMII_CRS]
# set_property -dict "PACKAGE_PIN R23 IOSTANDARD LVCMOS25" [get_ports GMII_MDC]
# set_property -dict "PACKAGE_PIN J21 IOSTANDARD LVCMOS25" [get_ports GMII_MDIO]

# LEDs
set_property -dict {PACKAGE_PIN AB8 IOSTANDARD LVCMOS15} [get_ports {LED[0]}]
set_property -dict {PACKAGE_PIN AA8 IOSTANDARD LVCMOS15} [get_ports {LED[1]}]
set_property -dict {PACKAGE_PIN AC9 IOSTANDARD LVCMOS15} [get_ports {LED[2]}]
set_property -dict {PACKAGE_PIN AB9 IOSTANDARD LVCMOS15} [get_ports {LED[3]}]

# QSPI Flash
set_property -dict {PACKAGE_PIN U19 IOSTANDARD LVCMOS25} [get_ports BOOT_CS_B]
set_property -dict {PACKAGE_PIN P24 IOSTANDARD LVCMOS25} [get_ports BOOT_MOSI]
set_property -dict {PACKAGE_PIN R25 IOSTANDARD LVCMOS25} [get_ports BOOT_MISO]
# U19  QSPI_IC_CS_B
# P24  FLASH_D0
# R25  FLASH_D1
# and the FPGA_CCLK is special, doesn't show up here,
# access is by instantiating the STARTUPE2 primitive

# More-or-less fake attachment to FMC; I have no plans to hook this up
set_property -dict {PACKAGE_PIN AJ21 IOSTANDARD LVCMOS25} [get_ports SCLK]
set_property -dict {PACKAGE_PIN AH21 IOSTANDARD LVCMOS25} [get_ports CSB]
set_property -dict {PACKAGE_PIN AH22 IOSTANDARD LVCMOS25} [get_ports MOSI]

# 200 MHz Clock input
set_property -dict {PACKAGE_PIN AD12 IOSTANDARD LVDS} [get_ports SYSCLK_P]
set_property -dict {PACKAGE_PIN AD11 IOSTANDARD LVDS} [get_ports SYSCLK_N]
create_clock -name sysclk -period 5.00 [get_ports SYSCLK_P]

# Clock groups
set_clock_groups -name async_clks -asynchronous \
-group [get_clocks -include_generated_clocks sysclk] \
-group [get_clocks -include_generated_clocks phy_rxclk]

# CPU_RESET button
set_property -dict {PACKAGE_PIN AB7 IOSTANDARD LVCMOS15} [get_ports RESET]

# Bank 0 setup
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 2.5 [current_design]
