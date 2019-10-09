###############################################################################
### AC701 - xc7k160tffg676-2

set_property CONFIG_VOLTAGE  3.3 [current_design]
set_property CFGBVS VCCO [current_design]

## 200 MHz Clock input
set_property -dict "PACKAGE_PIN R3 IOSTANDARD LVDS_25" [get_ports {SYS_CLK_P}]
set_property -dict "PACKAGE_PIN P3 IOSTANDARD LVDS_25" [get_ports {SYS_CLK_N}]
create_clock -name sysclk_fast -period 5.0 [get_ports SYS_CLK_P]

set_property -dict "PACKAGE_PIN P16 IOSTANDARD LVCMOS33" [get_ports {REF_CLK}]
create_clock -name refclk -period 11.11 [get_ports REF_CLK]

# LEDs
set_property -dict "PACKAGE_PIN M26 IOSTANDARD LVCMOS33" [get_ports {LED[0]}]
set_property -dict "PACKAGE_PIN T24 IOSTANDARD LVCMOS33" [get_ports {LED[1]}]
set_property -dict "PACKAGE_PIN T25 IOSTANDARD LVCMOS33" [get_ports {LED[2]}]
set_property -dict "PACKAGE_PIN R26 IOSTANDARD LVCMOS33" [get_ports {LED[3]}]

set_property -dict "PACKAGE_PIN U4 IOSTANDARD LVCMOS15" [get_ports {RESET}]

# UG471 page 50
set_property INTERNAL_VREF 0.90 [get_banks BANK13]
