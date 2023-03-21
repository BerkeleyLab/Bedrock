set_property CONFIG_VOLTAGE  3.3 [current_design]

# Differential 50MHz system clock
set_property IOSTANDARD LVDS_25 [get_ports {sys_clk_p}]
set_property PACKAGE_PIN G11    [get_ports {sys_clk_p}]

set_property IOSTANDARD LVDS_25 [get_ports {sys_clk_n}]
set_property PACKAGE_PIN F10    [get_ports {sys_clk_n}]

# interface to Spartan
# 1N
set_property IOSTANDARD LVDS_25 [get_ports {kintex_data_out_p}]
set_property PACKAGE_PIN J11    [get_ports {kintex_data_out_p}]
# 1P
set_property IOSTANDARD LVDS_25 [get_ports {kintex_data_out_n}]
set_property PACKAGE_PIN J10    [get_ports {kintex_data_out_n}]
# 2P
set_property IOSTANDARD LVDS_25 [get_ports {kintex_data_in_p}]
set_property PACKAGE_PIN J13    [get_ports {kintex_data_in_p}]
set_property DIFF_TERM TRUE     [get_ports {kintex_data_in_p}]
# 2N
set_property IOSTANDARD LVDS_25 [get_ports {kintex_data_in_n}]
set_property PACKAGE_PIN H13    [get_ports {kintex_data_in_n}]
set_property DIFF_TERM TRUE     [get_ports {kintex_data_in_n}]

set_property DRIVE 4 [get_ports kintex_rx_locked]
set_property IOSTANDARD LVCMOS25 [get_ports kintex_rx_locked]
set_property PACKAGE_PIN F14 [get_ports kintex_rx_locked]

#create_clock -name clk_master -period 20.0 [get_ports EXT_CLK]
set_property CFGBVS VCCO [current_design]

##########################   LEDs   #######################################

set_property -dict "PACKAGE_PIN M16 IOSTANDARD LVCMOS25" [get_ports {LEDS[0]}]
set_property -dict "PACKAGE_PIN K15 IOSTANDARD LVCMOS25" [get_ports {LEDS[1]}]
