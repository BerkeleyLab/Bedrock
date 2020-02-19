set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.UNUSEDPIN Pullup [current_design]
set_property CFGBVS GND [current_design]
# set_property CONFIG_VOLTAGE 1.8 [current_design]
# clock constraints
# 300 MHz system clock, moved to project top
# create_clock -name sysclk -period 3.3 [get_ports SYSCLK1_300_P]
# create_clock -name sysclk -period 3.3 [get_ports SYSCLK2_300_P]

# 300 MHz Clock input
set_property PACKAGE_PIN G31      [get_ports "SYSCLK1_300_P"] ;# Bank  50 VCCO - VCC1V2_FPGA - IO_L13P_T2L_N0_GC_QBC_50
set_property IOSTANDARD  DIFF_SSTL12 [get_ports "SYSCLK1_300_P"] ;# Bank  50 VCCO - VCC1V2_FPGA - IO_L13P_T2L_N0_GC_QBC_50
set_property PACKAGE_PIN F31      [get_ports "SYSCLK1_300_N"] ;# Bank  50 VCCO - VCC1V2_FPGA - IO_L13N_T2L_N1_GC_QBC_50
set_property IOSTANDARD  DIFF_SSTL12 [get_ports "SYSCLK1_300_N"] ;# Bank  50 VCCO - VCC1V2_FPGA - IO_L13N_T2L_N1_GC_QBC_50
set_property PACKAGE_PIN G22      [get_ports "SYSCLK2_300_P"] ;# Bank  70 VCCO - VCC1V2_FPGA - IO_L13P_T2L_N0_GC_QBC_70
set_property IOSTANDARD  DIFF_SSTL12 [get_ports "SYSCLK2_300_P"] ;# Bank  70 VCCO - VCC1V2_FPGA - IO_L13P_T2L_N0_GC_QBC_70
set_property PACKAGE_PIN G21      [get_ports "SYSCLK2_300_N"] ;# Bank  70 VCCO - VCC1V2_FPGA - IO_L13N_T2L_N1_GC_QBC_70
set_property IOSTANDARD  DIFF_SSTL12 [get_ports "SYSCLK2_300_N"] ;# Bank  70 VCCO - VCC1V2_FPGA - IO_L13N_T2L_N1_GC_QBC_70
# I2C
set_property PACKAGE_PIN AP18     [get_ports "SYSMON_SCL_LS"] ;# Bank  65 VCCO - VCC1V8_FPGA - IO_L23P_T3U_N8_I2C_SCLK_65
set_property IOSTANDARD  LVCMOS18 [get_ports "SYSMON_SCL_LS"] ;# Bank  65 VCCO - VCC1V8_FPGA - IO_L23P_T3U_N8_I2C_SCLK_65
set_property PACKAGE_PIN AP17     [get_ports "SYSMON_SDA_LS"] ;# Bank  65 VCCO - VCC1V8_FPGA - IO_L23N_T3U_N9_I2C_SDA_65
set_property IOSTANDARD  LVCMOS18 [get_ports "SYSMON_SDA_LS"] ;# Bank  65 VCCO - VCC1V8_FPGA - IO_L23N_T3U_N9_I2C_SDA_65

set_property -dict "PACKAGE_PIN AT32 IOSTANDARD LVCMOS12" [get_ports {GPIO_LED[0]}] ;# Bank  44 VCCO - VCC1V2_FPGA - IO_L19N_T3L_N1_DBC_AD9N_44
set_property -dict "PACKAGE_PIN AV34 IOSTANDARD LVCMOS12" [get_ports {GPIO_LED[1]}] ;# Bank  44 VCCO - VCC1V2_FPGA - IO_T2U_N12_44
set_property -dict "PACKAGE_PIN AY30 IOSTANDARD LVCMOS12" [get_ports {GPIO_LED[2]}] ;# Bank  44 VCCO - VCC1V2_FPGA - IO_T1U_N12_44
set_property -dict "PACKAGE_PIN BB32 IOSTANDARD LVCMOS12" [get_ports {GPIO_LED[3]}] ;# Bank  44 VCCO - VCC1V2_FPGA - IO_L7N_T1L_N1_QBC_AD13N_44
set_property -dict "PACKAGE_PIN BF32 IOSTANDARD LVCMOS12" [get_ports {GPIO_LED[4]}] ;# Bank  44 VCCO - VCC1V2_FPGA - IO_L1N_T0L_N1_DBC_44
set_property -dict "PACKAGE_PIN AV36 IOSTANDARD LVCMOS12" [get_ports {GPIO_LED[5]}] ;# Bank  46 VCCO - VCC1V2_FPGA - IO_L19N_T3L_N1_DBC_AD9N_46
set_property -dict "PACKAGE_PIN AY35 IOSTANDARD LVCMOS12" [get_ports {GPIO_LED[6]}] ;# Bank  46 VCCO - VCC1V2_FPGA - IO_T2U_N12_46
set_property -dict "PACKAGE_PIN BA37 IOSTANDARD LVCMOS12" [get_ports {GPIO_LED[7]}] ;# Bank  46 VCCO - VCC1V2_FPGA - IO_L13N_T2L_N1_GC_QBC_46

set_property PACKAGE_PIN AR14     [get_ports "USER_SMA_CLOCK_P"] ;# Bank  67 VCCO - VADJ_1V8_FPGA - IO_L13P_T2L_N0_GC_QBC_67
set_property IOSTANDARD  LVDS [get_ports "USER_SMA_CLOCK_P"] ;# Bank  67 VCCO - VADJ_1V8_FPGA - IO_L13P_T2L_N0_GC_QBC_67
set_property PACKAGE_PIN AT14     [get_ports "USER_SMA_CLOCK_N"] ;# Bank  67 VCCO - VADJ_1V8_FPGA - IO_L13N_T2L_N1_GC_QBC_67
set_property IOSTANDARD  LVDS [get_ports "USER_SMA_CLOCK_N"] ;# Bank  67 VCCO - VADJ_1V8_FPGA - IO_L13N_T2L_N1_GC_QBC_67

set_property PACKAGE_PIN E36      [get_ports "CPU_RESET"] ;# Bank  49 VCCO - VCC1V2_FPGA - IO_T1U_N12_49
set_property IOSTANDARD  LVCMOS12 [get_ports "CPU_RESET"] ;# Bank  49 VCCO - VCC1V2_FPGA - IO_T1U_N12_49

set_property BITSTREAM.CONFIG.BPI_SYNC_MODE Type1 [current_design]
set_property CONFIG_MODE BPI16 [current_design]
set_property BITSTREAM.CONFIG.EXTMASTERCCLK_EN div-1 [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 33 [current_design]

set_property PACKAGE_PIN BD22     [get_ports "USB_UART_RTS"] ;# Bank  94 VCCO - VCC1V8_FPGA - IO_L2N_T0L_N3_94
set_property IOSTANDARD  LVCMOS18 [get_ports "USB_UART_RTS"] ;# Bank  94 VCCO - VCC1V8_FPGA - IO_L2N_T0L_N3_94
set_property PACKAGE_PIN BC24     [get_ports "USB_UART_TX"] ;# Bank  94 VCCO - VCC1V8_FPGA - IO_T0U_N12_94
set_property IOSTANDARD  LVCMOS18 [get_ports "USB_UART_TX"] ;# Bank  94 VCCO - VCC1V8_FPGA - IO_T0U_N12_94
set_property PACKAGE_PIN BE24     [get_ports "USB_UART_RX"] ;# Bank  94 VCCO - VCC1V8_FPGA - IO_L1P_T0L_N0_DBC_94
set_property IOSTANDARD  LVCMOS18 [get_ports "USB_UART_RX"] ;# Bank  94 VCCO - VCC1V8_FPGA - IO_L1P_T0L_N0_DBC_94
set_property PACKAGE_PIN BF24     [get_ports "USB_UART_CTS"] ;# Bank  94 VCCO - VCC1V8_FPGA - IO_L1N_T0L_N1_DBC_94
set_property IOSTANDARD  LVCMOS18 [get_ports "USB_UART_CTS"] ;# Bank  94 VCCO - VCC1V8_FPGA - IO_L1N_T0L_N1_DBC_94

set_property PACKAGE_PIN BC16     [get_ports "PMOD0_7_LS"] ;# Bank  66 VCCO - VADJ_1V8_FPGA - IO_L20N_T3L_N3_AD1N_66
set_property IOSTANDARD  LVCMOS18 [get_ports "PMOD0_7_LS"] ;# Bank  66 VCCO - VADJ_1V8_FPGA - IO_L20N_T3L_N3_AD1N_66
set_property PACKAGE_PIN AW12     [get_ports "PMOD0_6_LS"] ;# Bank  67 VCCO - VADJ_1V8_FPGA - IO_L2P_T0L_N2_67
set_property IOSTANDARD  LVCMOS18 [get_ports "PMOD0_6_LS"] ;# Bank  67 VCCO - VADJ_1V8_FPGA - IO_L2P_T0L_N2_67
set_property PACKAGE_PIN BF7      [get_ports "PMOD0_5_LS"] ;# Bank  66 VCCO - VADJ_1V8_FPGA - IO_T1U_N12_66
set_property IOSTANDARD  LVCMOS18 [get_ports "PMOD0_5_LS"] ;# Bank  66 VCCO - VADJ_1V8_FPGA - IO_T1U_N12_66
set_property PACKAGE_PIN BC13     [get_ports "PMOD0_4_LS"] ;# Bank  66 VCCO - VADJ_1V8_FPGA - IO_L19N_T3L_N1_DBC_AD9N_66
set_property IOSTANDARD  LVCMOS18 [get_ports "PMOD0_4_LS"] ;# Bank  66 VCCO - VADJ_1V8_FPGA - IO_L19N_T3L_N1_DBC_AD9N_66
set_property PACKAGE_PIN BB16     [get_ports "PMOD0_3_LS"] ;# Bank  66 VCCO - VADJ_1V8_FPGA - IO_L20P_T3L_N2_AD1P_66
set_property IOSTANDARD  LVCMOS18 [get_ports "PMOD0_3_LS"] ;# Bank  66 VCCO - VADJ_1V8_FPGA - IO_L20P_T3L_N2_AD1P_66
set_property PACKAGE_PIN AW16     [get_ports "PMOD0_2_LS"] ;# Bank  67 VCCO - VADJ_1V8_FPGA - IO_T1U_N12_67
set_property IOSTANDARD  LVCMOS18 [get_ports "PMOD0_2_LS"] ;# Bank  67 VCCO - VADJ_1V8_FPGA - IO_T1U_N12_67
set_property PACKAGE_PIN BA10     [get_ports "PMOD0_1_LS"] ;# Bank  66 VCCO - VADJ_1V8_FPGA - IO_T2U_N12_66
set_property IOSTANDARD  LVCMOS18 [get_ports "PMOD0_1_LS"] ;# Bank  66 VCCO - VADJ_1V8_FPGA - IO_T2U_N12_66
set_property PACKAGE_PIN BC14     [get_ports "PMOD0_0_LS"] ;# Bank  66 VCCO - VADJ_1V8_FPGA - IO_L19P_T3L_N0_DBC_AD9P_66
set_property IOSTANDARD  LVCMOS18 [get_ports "PMOD0_0_LS"] ;# Bank  66 VCCO - VADJ_1V8_FPGA - IO_L19P_T3L_N0_DBC_AD9P_66
