# Obsidian
# https://github.com/BerkeleyLab/Obsidian
# compare and contrast the contents of this file with
# https://github.com/litex-hub/litex-boards/blob/master/litex_boards/platforms/berkeleylab_obsidian.py

# RGMII PHY
set_property -dict {PACKAGE_PIN A13 IOSTANDARD LVCMOS33} [get_ports PHY_RSTN]

set_property -dict {PACKAGE_PIN E13 IOSTANDARD LVCMOS33} [get_ports RGMII_RX_CLK]
set_property -dict {PACKAGE_PIN D16 IOSTANDARD LVCMOS33} [get_ports RGMII_RX_CTRL]
set_property -dict {PACKAGE_PIN B16 IOSTANDARD LVCMOS33} [get_ports {RGMII_RXD[0]}]
set_property -dict {PACKAGE_PIN C16 IOSTANDARD LVCMOS33} [get_ports {RGMII_RXD[1]}]
set_property -dict {PACKAGE_PIN D14 IOSTANDARD LVCMOS33} [get_ports {RGMII_RXD[2]}]
set_property -dict {PACKAGE_PIN C13 IOSTANDARD LVCMOS33} [get_ports {RGMII_RXD[3]}]

set_property -dict {PACKAGE_PIN D15 IOSTANDARD LVCMOS33} [get_ports RGMII_TX_CLK]
set_property -dict {PACKAGE_PIN A17 IOSTANDARD LVCMOS33} [get_ports RGMII_TX_CTRL]
set_property -dict {PACKAGE_PIN B17 IOSTANDARD LVCMOS33} [get_ports {RGMII_TXD[0]}]
set_property -dict {PACKAGE_PIN E16 IOSTANDARD LVCMOS33} [get_ports {RGMII_TXD[1]}]
set_property -dict {PACKAGE_PIN E17 IOSTANDARD LVCMOS33} [get_ports {RGMII_TXD[2]}]
set_property -dict {PACKAGE_PIN D18 IOSTANDARD LVCMOS33} [get_ports {RGMII_TXD[3]}]

# https://adaptivesupport.amd.com/s/article/53092?language=en_US
set_property IOB TRUE [get_ports {RGMII_TXD[*]}]
set_property IOB TRUE [get_ports RGMII_TX_CTRL]
set_property IOB TRUE [get_ports {RGMII_RXD[*]}]
set_property IOB TRUE [get_ports RGMII_RX_CTRL]

# Rx clock constraint
create_clock -period 8.00 -name phy_rxclk [get_ports RGMII_RX_CLK]

# QSPI Boot Flash
set_property -dict {PACKAGE_PIN L15 IOSTANDARD LVCMOS33} [get_ports BOOT_CS_B]
set_property -dict {PACKAGE_PIN K16 IOSTANDARD LVCMOS33} [get_ports BOOT_MOSI]
set_property -dict {PACKAGE_PIN L17 IOSTANDARD LVCMOS33} [get_ports BOOT_MISO]
# FPGA_CCLK is special, and doesn't show up here;
# access is accomplished by instantiating the STARTUPE2 primitive

# LEDs
set_property -dict {PACKAGE_PIN M16 IOSTANDARD LVCMOS33} [get_ports {LED[0]}]
set_property -dict {PACKAGE_PIN N17 IOSTANDARD LVCMOS33} [get_ports {LED[1]}]
set_property -dict {PACKAGE_PIN R18 IOSTANDARD LVCMOS33} [get_ports {LED[2]}]
set_property -dict {PACKAGE_PIN U16 IOSTANDARD LVCMOS33} [get_ports {LED[3]}]
# LED_0 connects to PMOD1_0
# LED_1 connects to PMOD1_1
# LED_2 connects to PMOD1_2
# LED_3 connects to PMOD1_3
# To gain access to these blinkenlights, it's suggested to plug in a
# usual Diglent PmodLED to the top half of J4 (a.k.a. PMOD1).

# Possible connection to supervisory microcontroller
# Want actual pins here so the synthesizer doesn't drop the supporting logic;
# I have no short-term plans to exercise these pins in hardware.
# See projects/test_marble_family to demo that feature.
# SCLK connects to PMOD1_4
# CSB  connects to PMOD1_5
# MOSI connects to PMOD1_6
set_property -dict {PACKAGE_PIN M17 IOSTANDARD LVCMOS33} [get_ports SCLK]
set_property -dict {PACKAGE_PIN N18 IOSTANDARD LVCMOS33} [get_ports CSB]
set_property -dict {PACKAGE_PIN P18 IOSTANDARD LVCMOS33} [get_ports MOSI]

# 125 MHz from White Rabbit comes in via MGTREFCLK;
# we should really turn on the GTP and use its TXOUTCLK.
# 20 MHz CLK20_VCXO from Y3 is a poor substitute
set_property -dict {PACKAGE_PIN D13 IOSTANDARD LVCMOS33} [get_ports SYSCLK_P]
create_clock -name sys_clk -period 50.00 [get_ports SYSCLK_P]
# this property setting is correct: the CLK20_VCXO pin is only used for its _frequency_, not as a phase
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets SYSCLK_P]

# Miscellaneous
# Accidentally unavailable; substitute PMOD1_7, and trust that the
# unconnected Y3-2 will float high (R176 should help)
set_property -dict {PACKAGE_PIN V17 IOSTANDARD LVCMOS33} [get_ports VCXO_EN]
# RESET not actually used in gateware or available on hardware
# Assign it to PMOD2_0 anyway
set_property -dict {PACKAGE_PIN T18 IOSTANDARD LVCMOS33} [get_ports RESET]

# Clock groups
set_clock_groups -name async_clks -asynchronous \
-group [get_clocks -include_generated_clocks sys_clk] \
-group [get_clocks -include_generated_clocks phy_rxclk]

# Bank 0 setup
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
