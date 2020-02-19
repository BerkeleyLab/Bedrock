#ETHERNET
set_property PACKAGE_PIN AV24     [get_ports "PHY_MDIO_LS"] ;# Bank  84 VCCO - VCC1V8_FPGA - IO_L16N_T2U_N7_QBC_AD3N_84
set_property IOSTANDARD  LVCMOS18 [get_ports "PHY_MDIO_LS"] ;# Bank  84 VCCO - VCC1V8_FPGA - IO_L16N_T2U_N7_QBC_AD3N_84
set_property PACKAGE_PIN AU21     [get_ports "PHY_RESET_LS"] ;# Bank  84 VCCO - VCC1V8_FPGA - IO_L15P_T2L_N4_AD11P_84
set_property IOSTANDARD  LVCMOS18 [get_ports "PHY_RESET_LS"] ;# Bank  84 VCCO - VCC1V8_FPGA - IO_L15P_T2L_N4_AD11P_84
set_property PACKAGE_PIN AV21     [get_ports "PHY_MDC_LS"] ;# Bank  84 VCCO - VCC1V8_FPGA - IO_L15N_T2L_N5_AD11N_84
set_property IOSTANDARD  LVCMOS18 [get_ports "PHY_MDC_LS"] ;# Bank  84 VCCO - VCC1V8_FPGA - IO_L15N_T2L_N5_AD11N_84
set_property PACKAGE_PIN AT21     [get_ports "PHY_INT_LS"] ;# Bank  84 VCCO - VCC1V8_FPGA - IO_T2U_N12_84
set_property IOSTANDARD  LVCMOS18 [get_ports "PHY_INT_LS"] ;# Bank  84 VCCO - VCC1V8_FPGA - IO_T2U_N12_84
set_property PACKAGE_PIN AR24     [get_ports "SGMII_RX_P"] ;# Bank  84 VCCO - VCC1V8_FPGA - IO_L18P_T2U_N10_AD2P_84
set_property IOSTANDARD  DIFF_HSTL_I_18 [get_ports "SGMII_RX_P"] ;# Bank  84 VCCO - VCC1V8_FPGA - IO_L18P_T2U_N10_AD2P_84
set_property PACKAGE_PIN AT24     [get_ports "SGMII_RX_N"] ;# Bank  84 VCCO - VCC1V8_FPGA - IO_L18N_T2U_N11_AD2N_84
set_property IOSTANDARD  DIFF_HSTL_I_18 [get_ports "SGMII_RX_N"] ;# Bank  84 VCCO - VCC1V8_FPGA - IO_L18N_T2U_N11_AD2N_84
set_property PACKAGE_PIN AR23     [get_ports "SGMII_TX_P"] ;# Bank  84 VCCO - VCC1V8_FPGA - IO_L17P_T2U_N8_AD10P_84
set_property IOSTANDARD  DIFF_HSTL_I_18 [get_ports "SGMII_TX_P"] ;# Bank  84 VCCO - VCC1V8_FPGA - IO_L17P_T2U_N8_AD10P_84
set_property PACKAGE_PIN AR22     [get_ports "SGMII_TX_N"] ;# Bank  84 VCCO - VCC1V8_FPGA - IO_L17N_T2U_N9_AD10N_84
set_property IOSTANDARD  DIFF_HSTL_I_18 [get_ports "SGMII_TX_N"] ;# Bank  84 VCCO - VCC1V8_FPGA - IO_L17N_T2U_N9_AD10N_84
set_property PACKAGE_PIN AT22     [get_ports "SGMIICLK_P"] ;# Bank  84 VCCO - VCC1V8_FPGA - IO_L13P_T2L_N0_GC_QBC_84
set_property IOSTANDARD  LVDS_25 [get_ports "SGMIICLK_P"] ;# Bank  84 VCCO - VCC1V8_FPGA - IO_L13P_T2L_N0_GC_QBC_84
set_property PACKAGE_PIN AU22     [get_ports "SGMIICLK_N"] ;# Bank  84 VCCO - VCC1V8_FPGA - IO_L13N_T2L_N1_GC_QBC_84
set_property IOSTANDARD  LVDS_25 [get_ports "SGMIICLK_N"] ;# Bank  84 VCCO - VCC1V8_FPGA - IO_L13N_T2L_N1_GC_QBC_84

# clock constraints
create_clock -period 8.0 -name sgmii_clk [get_ports SGMIICLK_P]

