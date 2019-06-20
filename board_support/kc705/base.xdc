
set_property CFGBVS VCCO [current_design]
# clock constraints
# 200 MHz system clock, moved to project top
#create_clock -name sysclk -period 5.0 [get_ports SYSCLK_P]

# 200 MHz Clock input
set_property -dict "PACKAGE_PIN AD12 IOSTANDARD LVDS" [get_ports SYSCLK_P]
set_property -dict "PACKAGE_PIN AD11 IOSTANDARD LVDS" [get_ports SYSCLK_N]
# IIC
set_property -dict "PACKAGE_PIN K21 IOSTANDARD LVCMOS25" [get_ports I2C_SCL]
set_property -dict "PACKAGE_PIN L21 IOSTANDARD LVCMOS25" [get_ports I2C_SDA]
set_property -dict "PACKAGE_PIN P23 IOSTANDARD LVCMOS25" [get_ports I2C_MUX_RESET_B]

set_property -dict "PACKAGE_PIN AB8 IOSTANDARD LVCMOS15" [get_ports {GPIO_LED[0]}]
set_property -dict "PACKAGE_PIN AA8 IOSTANDARD LVCMOS15" [get_ports {GPIO_LED[1]}]
set_property -dict "PACKAGE_PIN AC9 IOSTANDARD LVCMOS15" [get_ports {GPIO_LED[2]}]
set_property -dict "PACKAGE_PIN AB9 IOSTANDARD LVCMOS15" [get_ports {GPIO_LED[3]}]
set_property -dict "PACKAGE_PIN AE26 IOSTANDARD LVCMOS25" [get_ports {GPIO_LED[4]}]
set_property -dict "PACKAGE_PIN G19 IOSTANDARD LVCMOS25" [get_ports {GPIO_LED[5]}]
set_property -dict "PACKAGE_PIN E18 IOSTANDARD LVCMOS25" [get_ports {GPIO_LED[6]}]
set_property -dict "PACKAGE_PIN F16 IOSTANDARD LVCMOS25" [get_ports {GPIO_LED[7]}]

# UART
set_property -dict "PACKAGE_PIN L27  IOSTANDARD LVCMOS25" [get_ports UART_RTS]
set_property -dict "PACKAGE_PIN K23  IOSTANDARD LVCMOS25" [get_ports UART_CTS]
set_property -dict "PACKAGE_PIN K24  IOSTANDARD LVCMOS25" [get_ports UART_TX]
set_property -dict "PACKAGE_PIN M19  IOSTANDARD LVCMOS25" [get_ports UART_RX]

# USER SMA
set_property -dict "PACKAGE_PIN Y23 IOSTANDARD LVCMOS25" [get_ports USER_SMA_GPIO_P]
set_property -dict "PACKAGE_PIN Y24 IOSTANDARD LVCMOS25" [get_ports USER_SMA_GPIO_N]

# GPIO LCD
set_property -dict "PACKAGE_PIN Y10  IOSTANDARD LVCMOS15" [get_ports J31_1_LS]
set_property -dict "PACKAGE_PIN AA11 IOSTANDARD LVCMOS15" [get_ports J31_2_LS]
set_property -dict "PACKAGE_PIN AA10 IOSTANDARD LVCMOS15" [get_ports J31_3_LS]
set_property -dict "PACKAGE_PIN AA13 IOSTANDARD LVCMOS15" [get_ports J31_4_LS]
set_property -dict "PACKAGE_PIN Y11  IOSTANDARD LVCMOS15" [get_ports J31_11_LS]
set_property -dict "PACKAGE_PIN AB10 IOSTANDARD LVCMOS15" [get_ports J31_9_LS]
set_property -dict "PACKAGE_PIN AB13 IOSTANDARD LVCMOS15" [get_ports J31_10_LS]

#GPIO ROTARY SW
set_property -dict "PACKAGE_PIN Y25  IOSTANDARD LVCMOS25" [get_ports SW8_6]
set_property -dict "PACKAGE_PIN AA26 IOSTANDARD LVCMOS25" [get_ports SW8_5]
set_property -dict "PACKAGE_PIN Y26  IOSTANDARD LVCMOS25" [get_ports SW8_1]

#GPIO User Pushbuttons
set_property -dict "PACKAGE_PIN G12  IOSTANDARD LVCMOS25" [get_ports GPIO_SW_C]

set_property -dict "PACKAGE_PIN AB7  IOSTANDARD LVCMOS15" [get_ports CPU_RESET]
set_property -dict "PACKAGE_PIN AA12 IOSTANDARD LVCMOS15" [get_ports GPIO_SW_N]
set_property -dict "PACKAGE_PIN AG5  IOSTANDARD LVCMOS15" [get_ports GPIO_SW_E]
set_property -dict "PACKAGE_PIN AB12 IOSTANDARD LVCMOS15" [get_ports GPIO_SW_S]
set_property -dict "PACKAGE_PIN AC6  IOSTANDARD LVCMOS15" [get_ports GPIO_SW_W]

set_property -dict "PACKAGE_PIN Y29  IOSTANDARD LVCMOS25" [get_ports {GPIO_DIP_SW[0]}]
set_property -dict "PACKAGE_PIN W29  IOSTANDARD LVCMOS25" [get_ports {GPIO_DIP_SW[1]}]
set_property -dict "PACKAGE_PIN AA28 IOSTANDARD LVCMOS25" [get_ports {GPIO_DIP_SW[2]}]
set_property -dict "PACKAGE_PIN Y28  IOSTANDARD LVCMOS25" [get_ports {GPIO_DIP_SW[3]}]
