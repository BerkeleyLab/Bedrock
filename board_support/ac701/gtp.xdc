set_property -dict "PACKAGE_PIN AA13" [get_ports {MGTREFCLK0_P}]
set_property -dict "PACKAGE_PIN AB13" [get_ports {MGTREFCLK0_N}]
set_property -dict "PACKAGE_PIN AA11" [get_ports {MGTREFCLK1_P}]
set_property -dict "PACKAGE_PIN AB11" [get_ports {MGTREFCLK1_N}]
create_clock -period 8.000 -name MGTREFCLK0_P -waveform {0.000 4.000} [get_ports MGTREFCLK0_P]

set_property -dict "PACKAGE_PIN C24 IOSTANDARD LVCMOS25" [get_ports {MGTREFCLK0_SEL1}]
set_property -dict "PACKAGE_PIN B26 IOSTANDARD LVCMOS25" [get_ports {MGTREFCLK0_SEL0}]



set_property -dict "PACKAGE_PIN C24 IOSTANDARD LVCMOS25" [get_ports {MGTREFCLK0_SEL1}]
set_property -dict "PACKAGE_PIN B26 IOSTANDARD LVCMOS25" [get_ports {MGTREFCLK0_SEL0}]

# QUAD 213
set_property PACKAGE_PIN AC10 [get_ports {SFP_TXP}]
set_property PACKAGE_PIN AD10 [get_ports {SFP_TXN}]
set_property PACKAGE_PIN AC12 [get_ports {SFP_RXP}]
set_property PACKAGE_PIN AD12 [get_ports {SFP_RXN}]
