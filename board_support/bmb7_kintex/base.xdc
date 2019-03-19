###############################################################################
### BMB7 R1
## S6_TO_K7_CLK_1
set_property -dict "PACKAGE_PIN E10 IOSTANDARD LVCMOS33" [get_ports EXT_CLK]

#create_clock -name clk_master -period 20.0 [get_ports EXT_CLK]
set_property CFGBVS VCCO [current_design]

##########################   LEDs   #######################################

# Reversed to match board
# "led top r"
set_property -dict "PACKAGE_PIN L19 IOSTANDARD LVCMOS33" [get_ports {LEDS[0]}]
# "led top g"
set_property -dict "PACKAGE_PIN L18 IOSTANDARD LVCMOS33" [get_ports {LEDS[1]}]
# "led top b"
set_property -dict "PACKAGE_PIN L20 IOSTANDARD LVCMOS33" [get_ports {LEDS[2]}]
# "led bottom r"
set_property -dict "PACKAGE_PIN M17 IOSTANDARD LVCMOS33" [get_ports {LEDS[3]}]
# "led bottom g"
set_property -dict "PACKAGE_PIN L17 IOSTANDARD LVCMOS33" [get_ports {LEDS[4]}]
# "led bottom b"
set_property -dict "PACKAGE_PIN M16 IOSTANDARD LVCMOS33" [get_ports {LEDS[5]}]
