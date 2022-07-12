# clock constraints
create_clock -period 8.0 -name phy_rxclk [get_ports PHY_RXCLK]
#set_max_delay -from [get_clocks PHY_RXCLK] -to [get_clocks pll_clk_0] 4.2

set_property -dict "PACKAGE_PIN U27 IOSTANDARD LVCMOS25" [get_ports PHY_RXCLK]
set_property -dict "PACKAGE_PIN U30 IOSTANDARD LVCMOS25" [get_ports {PHY_RXD[0]}]
set_property -dict "PACKAGE_PIN U25 IOSTANDARD LVCMOS25" [get_ports {PHY_RXD[1]}]
set_property -dict "PACKAGE_PIN T25 IOSTANDARD LVCMOS25" [get_ports {PHY_RXD[2]}]
set_property -dict "PACKAGE_PIN U28 IOSTANDARD LVCMOS25" [get_ports {PHY_RXD[3]}]
set_property -dict "PACKAGE_PIN R19 IOSTANDARD LVCMOS25" [get_ports {PHY_RXD[4]}]
set_property -dict "PACKAGE_PIN T27 IOSTANDARD LVCMOS25" [get_ports {PHY_RXD[5]}]
set_property -dict "PACKAGE_PIN T26 IOSTANDARD LVCMOS25" [get_ports {PHY_RXD[6]}]
set_property -dict "PACKAGE_PIN T28 IOSTANDARD LVCMOS25" [get_ports {PHY_RXD[7]}]
set_property -dict "PACKAGE_PIN V26 IOSTANDARD LVCMOS25" [get_ports PHY_RXER]
set_property -dict "PACKAGE_PIN R28 IOSTANDARD LVCMOS25" [get_ports PHY_RXCTL_RXDV]
set_property -dict "PACKAGE_PIN M28 IOSTANDARD LVCMOS25" [get_ports PHY_TXCLK]
set_property -dict "PACKAGE_PIN N27 IOSTANDARD LVCMOS25" [get_ports {PHY_TXD[0]}]
set_property -dict "PACKAGE_PIN N25 IOSTANDARD LVCMOS25" [get_ports {PHY_TXD[1]}]
set_property -dict "PACKAGE_PIN M29 IOSTANDARD LVCMOS25" [get_ports {PHY_TXD[2]}]
set_property -dict "PACKAGE_PIN L28 IOSTANDARD LVCMOS25" [get_ports {PHY_TXD[3]}]
set_property -dict "PACKAGE_PIN J26 IOSTANDARD LVCMOS25" [get_ports {PHY_TXD[4]}]
set_property -dict "PACKAGE_PIN K26 IOSTANDARD LVCMOS25" [get_ports {PHY_TXD[5]}]
set_property -dict "PACKAGE_PIN L30 IOSTANDARD LVCMOS25" [get_ports {PHY_TXD[6]}]
set_property -dict "PACKAGE_PIN J28 IOSTANDARD LVCMOS25" [get_ports {PHY_TXD[7]}]
set_property -dict "PACKAGE_PIN N29 IOSTANDARD LVCMOS25" [get_ports PHY_TXER]
set_property -dict "PACKAGE_PIN K30 IOSTANDARD LVCMOS25" [get_ports PHY_TXC_GTXCLK]
set_property -dict "PACKAGE_PIN M27 IOSTANDARD LVCMOS25" [get_ports PHY_TXCTL_TXEN]
set_property -dict "PACKAGE_PIN L20 IOSTANDARD LVCMOS25" [get_ports PHY_RESET_B]
set_property -dict "PACKAGE_PIN W19 IOSTANDARD LVCMOS25" [get_ports PHY_COL]
set_property -dict "PACKAGE_PIN R30 IOSTANDARD LVCMOS25" [get_ports PHY_CRS]
#set_property -dict "PACKAGE_PIN N30 IOSTANDARD LVCMOS25" [get_ports PHY_INT]
set_property -dict "PACKAGE_PIN R23 IOSTANDARD LVCMOS25" [get_ports PHY_MDC]
set_property -dict "PACKAGE_PIN J21 IOSTANDARD LVCMOS25" [get_ports PHY_MDIO]