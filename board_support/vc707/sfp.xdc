#SFP
set_property PACKAGE_PIN AP33 [get_ports SFP_TX_DISABLE]
set_property IOSTANDARD LVCMOS18 [get_ports SFP_TX_DISABLE]
set_property PACKAGE_PIN BB38 [get_ports SFP_LOS_LS]
set_property IOSTANDARD LVCMOS18 [get_ports SFP_LOS_LS]
set_property PACKAGE_PIN AM4 [get_ports SFP_TX_P]
set_property PACKAGE_PIN AL6 [get_ports SFP_RX_P]
set_property PACKAGE_PIN AM3 [get_ports SFP_TX_N]
set_property PACKAGE_PIN AL5 [get_ports SFP_RX_N]

set_property PACKAGE_PIN AH8 [get_ports SGMIICLK_Q0_P]
set_property PACKAGE_PIN AH7 [get_ports SGMIICLK_Q0_N]

# clock constraints
create_clock -period 8.0 -name sgmii_clk [get_ports SGMIICLK_Q0_P]

