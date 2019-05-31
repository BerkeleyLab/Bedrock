# XDC File for KC705
##################################

# 200 MHz Clock input
set_property -dict "PACKAGE_PIN AD12 IOSTANDARD LVDS" [get_ports SYSCLK_P]
set_property -dict "PACKAGE_PIN AD11 IOSTANDARD LVDS" [get_ports SYSCLK_N]
create_clock -name sysclk -period 5.0 [get_ports SYSCLK_P]
set_property CFGBVS VCCO [current_design]

# CPU_RESET button
set_property -dict "PACKAGE_PIN AB7  IOSTANDARD LVCMOS15" [get_ports CPU_RESET]

# GPIO_LED
set_property -dict "PACKAGE_PIN AB8  IOSTANDARD LVCMOS15" [get_ports {GPIO_LED[0]}]
set_property -dict "PACKAGE_PIN AA8  IOSTANDARD LVCMOS15" [get_ports {GPIO_LED[1]}]
set_property -dict "PACKAGE_PIN AC9  IOSTANDARD LVCMOS15" [get_ports {GPIO_LED[2]}]
set_property -dict "PACKAGE_PIN AB9  IOSTANDARD LVCMOS15" [get_ports {GPIO_LED[3]}]
set_property -dict "PACKAGE_PIN AE26 IOSTANDARD LVCMOS25" [get_ports {GPIO_LED[4]}]
set_property -dict "PACKAGE_PIN G19  IOSTANDARD LVCMOS25" [get_ports {GPIO_LED[5]}]
set_property -dict "PACKAGE_PIN E18  IOSTANDARD LVCMOS25" [get_ports {GPIO_LED[6]}]
set_property -dict "PACKAGE_PIN F16  IOSTANDARD LVCMOS25" [get_ports {GPIO_LED[7]}]

# UART, UG810 Table 1-20
set_property -dict "PACKAGE_PIN L27  IOSTANDARD LVCMOS25" [get_ports UART_RTS]
set_property -dict "PACKAGE_PIN K23  IOSTANDARD LVCMOS25" [get_ports UART_CTS]
set_property -dict "PACKAGE_PIN K24  IOSTANDARD LVCMOS25" [get_ports UART_TX]
set_property -dict "PACKAGE_PIN M19  IOSTANDARD LVCMOS25" [get_ports UART_RX]

# IIC
set_property -dict "PACKAGE_PIN K21 IOSTANDARD LVCMOS25" [get_ports I2C_SCL]
set_property -dict "PACKAGE_PIN L21 IOSTANDARD LVCMOS25" [get_ports I2C_SDA]
set_property -dict "PACKAGE_PIN P23 IOSTANDARD LVCMOS25" [get_ports I2C_MUX_RESET_B]

# LCD
set_property -dict "PACKAGE_PIN AA13 IOSTANDARD LVCMOS15" [get_ports LCD_DB4_LS]
set_property -dict "PACKAGE_PIN AA10 IOSTANDARD LVCMOS15" [get_ports LCD_DB5_LS]
set_property -dict "PACKAGE_PIN AA11 IOSTANDARD LVCMOS15" [get_ports LCD_DB6_LS]
set_property -dict "PACKAGE_PIN Y10  IOSTANDARD LVCMOS15" [get_ports LCD_DB7_LS]
set_property -dict "PACKAGE_PIN AB13 IOSTANDARD LVCMOS15" [get_ports LCD_RW_LS]
set_property -dict "PACKAGE_PIN Y11  IOSTANDARD LVCMOS15" [get_ports LCD_RS_LS]
set_property -dict "PACKAGE_PIN AB10 IOSTANDARD LVCMOS15" [get_ports LCD_E_LS]
