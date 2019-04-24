set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.UNUSEDPIN Pullup [current_design]
set_property CFGBVS GND [current_design]
set_property CONFIG_VOLTAGE 1.8 [current_design]
# clock constraints
# 200 MHz system clock, moved to project top
# create_clock -name sysclk -period 5.0 [get_ports SYSCLK_P]

# 200 MHz Clock input
set_property -dict "PACKAGE_PIN E19 IOSTANDARD LVDS" [get_ports SYSCLK_P]
set_property -dict "PACKAGE_PIN E18 IOSTANDARD LVDS" [get_ports SYSCLK_N]
# I2C
set_property -dict "PACKAGE_PIN AT35 IOSTANDARD LVCMOS18" [get_ports I2C_SCL]
set_property -dict "PACKAGE_PIN AU32 IOSTANDARD LVCMOS18" [get_ports I2C_SDA]
set_property -dict "PACKAGE_PIN AY42 IOSTANDARD LVCMOS18" [get_ports I2C_MUX_RESET_B]

set_property -dict "PACKAGE_PIN AM39 IOSTANDARD LVCMOS18" [get_ports {GPIO_LED[0]}]
set_property -dict "PACKAGE_PIN AN39 IOSTANDARD LVCMOS18" [get_ports {GPIO_LED[1]}]
set_property -dict "PACKAGE_PIN AR37 IOSTANDARD LVCMOS18" [get_ports {GPIO_LED[2]}]
set_property -dict "PACKAGE_PIN AT37 IOSTANDARD LVCMOS18" [get_ports {GPIO_LED[3]}]
set_property -dict "PACKAGE_PIN AR35 IOSTANDARD LVCMOS18" [get_ports {GPIO_LED[4]}]
set_property -dict "PACKAGE_PIN AP41 IOSTANDARD LVCMOS18" [get_ports {GPIO_LED[5]}]
set_property -dict "PACKAGE_PIN AP42 IOSTANDARD LVCMOS18" [get_ports {GPIO_LED[6]}]
set_property -dict "PACKAGE_PIN AU39 IOSTANDARD LVCMOS18" [get_ports {GPIO_LED[7]}]

# USER SMA
set_property -dict "PACKAGE_PIN AN31 IOSTANDARD LVCMOS18" [get_ports USER_SMA_GPIO_P]
set_property -dict "PACKAGE_PIN AP31 IOSTANDARD LVCMOS18" [get_ports USER_SMA_GPIO_N]

# GPIO User Pushbuttons
set_property -dict "PACKAGE_PIN AV40 IOSTANDARD LVCMOS18" [get_ports CPU_RESET]
# set_property -dict "PACKAGE_PIN AP40 IOSTANDARD LVCMOS18" [get_ports GPIO_SW_S]
# set_property -dict "PACKAGE_PIN AR40 IOSTANDARD LVCMOS18" [get_ports GPIO_SW_N]
# set_property -dict "PACKAGE_PIN AV39 IOSTANDARD LVCMOS18" [get_ports GPIO_SW_C]
# set_property -dict "PACKAGE_PIN AU38 IOSTANDARD LVCMOS18" [get_ports GPIO_SW_E]
# set_property -dict "PACKAGE_PIN AW40 IOSTANDARD LVCMOS18" [get_ports GPIO_SW_W]

# set_property -dict "PACKAGE_PIN AV30 IOSTANDARD LVCMOS18" [get_ports {GPIO_DIP_SW[0]}]
# set_property -dict "PACKAGE_PIN AY33 IOSTANDARD LVCMOS18" [get_ports {GPIO_DIP_SW[1]}]
# set_property -dict "PACKAGE_PIN BA31 IOSTANDARD LVCMOS18" [get_ports {GPIO_DIP_SW[2]}]
# set_property -dict "PACKAGE_PIN BA32 IOSTANDARD LVCMOS18" [get_ports {GPIO_DIP_SW[3]}]
# set_property -dict "PACKAGE_PIN AW30 IOSTANDARD LVCMOS18" [get_ports {GPIO_DIP_SW[4]}]
# set_property -dict "PACKAGE_PIN AY30 IOSTANDARD LVCMOS18" [get_ports {GPIO_DIP_SW[5]}]
# set_property -dict "PACKAGE_PIN BA30 IOSTANDARD LVCMOS18" [get_ports {GPIO_DIP_SW[6]}]
# set_property -dict "PACKAGE_PIN BB31 IOSTANDARD LVCMOS18" [get_ports {GPIO_DIP_SW[7]}]

# FAN
# set_property -dict "PACKAGE_PIN BA37 IOSTANDARD LVCMOS18" [get_ports SM_FAN_PWM]
# set_property -dict "PACKAGE_PIN BB37 IOSTANDARD LVCMOS18" [get_ports SM_FAN_TACH]

# XADC
# set_property -dict "PACKAGE_PIN AN38 IOSTANDARD LVCMOS18" [get_ports XADC_VAUX0P_R]
# set_property -dict "PACKAGE_PIN AP38 IOSTANDARD LVCMOS18" [get_ports XADC_VAUX0N_R]
# set_property -dict "PACKAGE_PIN AM41 IOSTANDARD LVCMOS18" [get_ports XADC_VAUX8P_R]
# set_property -dict "PACKAGE_PIN AM42 IOSTANDARD LVCMOS18" [get_ports XADC_VAUX8N_R]
# set_property -dict "PACKAGE_PIN BA21 IOSTANDARD LVCMOS18" [get_ports {XADC_GPIO[0]}]
# set_property -dict "PACKAGE_PIN BB21 IOSTANDARD LVCMOS18" [get_ports {XADC_GPIO[1]}]
# set_property -dict "PACKAGE_PIN BB24 IOSTANDARD LVCMOS18" [get_ports {XADC_GPIO[2]}]
# set_property -dict "PACKAGE_PIN BB23 IOSTANDARD LVCMOS18" [get_ports {XADC_GPIO[3]}]

# BPI Flash
# https://www.xilinx.com/support/documentation/boards_and_kits/vc707/2014_4/xtp207-vc707-pcie-c-2014-4.pdf
set_property BITSTREAM.CONFIG.BPI_SYNC_MODE Type1 [current_design]
set_property CONFIG_MODE BPI16 [current_design]
set_property BITSTREAM.CONFIG.EXTMASTERCCLK_EN div-1 [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 33 [current_design]
#set_property -dict "PACKAGE_PIN AP37 IOSTANDARD LVCMOS18" [get_ports FPGA_EMCCLK]

# UART
# Note: reversed UART TX/RX port name from ug885, from FPGA point of view
# UG885 Table 1-20
set_property -dict "PACKAGE_PIN AU36 IOSTANDARD LVCMOS18" [get_ports UART_TX]
set_property -dict "PACKAGE_PIN AU33 IOSTANDARD LVCMOS18" [get_ports UART_RX]
set_property -dict "PACKAGE_PIN AT32 IOSTANDARD LVCMOS18" [get_ports UART_CTS]
set_property -dict "PACKAGE_PIN AR34 IOSTANDARD LVCMOS18" [get_ports UART_RTS]

# LCD
# set_property -dict "PACKAGE_PIN AN41 IOSTANDARD LVCMOS18" [get_ports LCD_RS_LS]
# set_property -dict "PACKAGE_PIN AT40 IOSTANDARD LVCMOS18" [get_ports LCD_E_LS]
# set_property -dict "PACKAGE_PIN AR42 IOSTANDARD LVCMOS18" [get_ports LCD_RW_LS]
# set_property -dict "PACKAGE_PIN AT42 IOSTANDARD LVCMOS18" [get_ports LCD_DB4_LS]
# set_property -dict "PACKAGE_PIN AR38 IOSTANDARD LVCMOS18" [get_ports LCD_DB5_LS]
# set_property -dict "PACKAGE_PIN AR39 IOSTANDARD LVCMOS18" [get_ports LCD_DB6_LS]
# set_property -dict "PACKAGE_PIN AN40 IOSTANDARD LVCMOS18" [get_ports LCD_DB7_LS]
