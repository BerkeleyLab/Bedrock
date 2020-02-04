# RGMII PHY
set_property -dict {PACKAGE_PIN V18 IOSTANDARD HSTL_I_18} [get_ports PHY_RSTN]

set_property -dict {PACKAGE_PIN U21 IOSTANDARD HSTL_I_18} [get_ports RGMII_RX_CLK]
set_property -dict {PACKAGE_PIN U14 IOSTANDARD HSTL_I_18} [get_ports RGMII_RX_CTRL]
set_property -dict {PACKAGE_PIN U17 IOSTANDARD HSTL_I_18} [get_ports {RGMII_RXD[0]}]
set_property -dict {PACKAGE_PIN V17 IOSTANDARD HSTL_I_18} [get_ports {RGMII_RXD[1]}]
set_property -dict {PACKAGE_PIN V16 IOSTANDARD HSTL_I_18} [get_ports {RGMII_RXD[2]}]
set_property -dict {PACKAGE_PIN V14 IOSTANDARD HSTL_I_18} [get_ports {RGMII_RXD[3]}]

set_property -dict {PACKAGE_PIN U22 IOSTANDARD HSTL_I_18} [get_ports RGMII_TX_CLK]
set_property -dict {PACKAGE_PIN T15 IOSTANDARD HSTL_I_18} [get_ports RGMII_TX_CTRL]
set_property -dict {PACKAGE_PIN U16 IOSTANDARD HSTL_I_18} [get_ports {RGMII_TXD[0]}]
set_property -dict {PACKAGE_PIN U15 IOSTANDARD HSTL_I_18} [get_ports {RGMII_TXD[1]}]
set_property -dict {PACKAGE_PIN T18 IOSTANDARD HSTL_I_18} [get_ports {RGMII_TXD[2]}]
set_property -dict {PACKAGE_PIN T17 IOSTANDARD HSTL_I_18} [get_ports {RGMII_TXD[3]}]

# https://www.xilinx.com/support/answers/53092.html
set_property IOB TRUE [get_ports {RGMII_TXD[*]}]
set_property IOB TRUE [get_ports RGMII_TX_CTRL]
set_property IOB TRUE [get_ports {RGMII_RXD[*]}]
set_property IOB TRUE [get_ports RGMII_RX_CTRL]

# HSTL_I_18 RGMII Rx pins need this reference definition
set_property INTERNAL_VREF 0.9 [get_iobanks 13]

# Rx clock constraint
create_clock -period 8.00 -name phy_rxclk [get_ports RGMII_RX_CLK]

# QSPI Boot Flash
set_property -dict {PACKAGE_PIN P18 IOSTANDARD LVCMOS33} [get_ports BOOT_CS_B]
set_property -dict {PACKAGE_PIN R14 IOSTANDARD LVCMOS33} [get_ports BOOT_MOSI]
set_property -dict {PACKAGE_PIN R15 IOSTANDARD LVCMOS33} [get_ports BOOT_MISO]
# mapping / net-names according to the schematic
# P18  QSPI_IC_CS_B
# R14  FLASH_D0  DQ0_DI
# R15  FLASH_D1  DQ1_DO
# P14  FLASH_D2  DQ2_WP_B
# N14  FLASH_D3  DW3_HOLD_B
# and the FPGA_CCLK is special, doesn't show up here,
# access is by instantiating the STARTUPE2 primitive

# LEDs
set_property -dict {PACKAGE_PIN M26 IOSTANDARD LVCMOS33} [get_ports {LED[0]}]
set_property -dict {PACKAGE_PIN T24 IOSTANDARD LVCMOS33} [get_ports {LED[1]}]
set_property -dict {PACKAGE_PIN T25 IOSTANDARD LVCMOS33} [get_ports {LED[2]}]
set_property -dict {PACKAGE_PIN R26 IOSTANDARD LVCMOS33} [get_ports {LED[3]}]

# Want actual pins here so the synthesizer doesn't drop the supporting logic;
# I have no short-term plans to exercise these pins in hardware.
# Don't use FMC, or tests can break when you plug in a board!
# R5 = GPIO_SW_W = SCLK
# U6 = GPIO_SW_C = CSB
# U5 = GPIO_SW_E = MOSI
# These signals on the AC701 are "Active High".
# Now tests can just freak out if you start pressing buttons.   :-p
set_property -dict {PACKAGE_PIN R5 IOSTANDARD LVCMOS15} [get_ports SCLK]
set_property -dict {PACKAGE_PIN U6 IOSTANDARD LVCMOS15} [get_ports CSB]
set_property -dict {PACKAGE_PIN U5 IOSTANDARD LVCMOS15} [get_ports MOSI]

# 200 MHz Clock input
set_property -dict {PACKAGE_PIN R3 IOSTANDARD DIFF_SSTL15} [get_ports SYSCLK_P]
set_property -dict {PACKAGE_PIN P3 IOSTANDARD DIFF_SSTL15} [get_ports SYSCLK_N]
create_clock -name sysclk -period 5.00 [get_ports SYSCLK_P]

# Clock groups
set_clock_groups -name async_clks -asynchronous \
-group [get_clocks -include_generated_clocks sysclk] \
-group [get_clocks -include_generated_clocks phy_rxclk]

# CPU_RESET button
set_property -dict {PACKAGE_PIN U4 IOSTANDARD SSTL15} [get_ports RESET]

# Bank 0 setup
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
