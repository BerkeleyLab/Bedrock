#ETHERNET
set_property -dict "PACKAGE_PIN AJ33 IOSTANDARD LVCMOS18" [get_ports PHY_RESET_LS]
set_property -dict "PACKAGE_PIN AK33 IOSTANDARD LVCMOS18" [get_ports PHY_MDIO_LS]
set_property -dict "PACKAGE_PIN AL31 IOSTANDARD LVCMOS18" [get_ports PHY_INT_LS]
set_property -dict "PACKAGE_PIN AH31 IOSTANDARD LVCMOS18" [get_ports PHY_MDC_LS]
set_property PACKAGE_PIN AH8 [get_ports SGMIICLK_Q0_P]
set_property PACKAGE_PIN AH7 [get_ports SGMIICLK_Q0_N]
set_property PACKAGE_PIN AN2 [get_ports SGMII_TX_P]
set_property PACKAGE_PIN AM8 [get_ports SGMII_RX_P]
set_property PACKAGE_PIN AN1 [get_ports SGMII_TX_N]
set_property PACKAGE_PIN AM7 [get_ports SGMII_RX_N]

# clock constraints
create_clock -period 8.0 -name sgmii_clk [get_ports SGMIICLK_Q0_P]

