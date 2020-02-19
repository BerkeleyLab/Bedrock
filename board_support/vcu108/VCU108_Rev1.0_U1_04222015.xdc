#Other net   PACKAGE_PIN AE17     - GND                       Bank   0 - DXN
#Other net   PACKAGE_PIN AB18     - FPGA_SYSMON_VCC           Bank   0 - VCCADC
#Other net   PACKAGE_PIN AB17     - SYSMON_AGND               Bank   0 - GNDADC
#Other net   PACKAGE_PIN AE18     - GND                       Bank   0 - DXP
#Other net   PACKAGE_PIN AD18     - SYSMON_AGND               Bank   0 - VREFP
#Other net   PACKAGE_PIN AC17     - SYSMON_AGND               Bank   0 - VREFN
#Other net   PACKAGE_PIN AC18     - SYSMON_VP                 Bank   0 - VP
#Other net   PACKAGE_PIN AD17     - SYSMON_VN                 Bank   0 - VN
#Other net   PACKAGE_PIN U10      - FPGA_M0                   Bank   0 - M0_0
#Other net   PACKAGE_PIN Y11      - FPGA_M1                   Bank   0 - M1_0
#Other net   PACKAGE_PIN AC12     - FPGA_INIT_B               Bank   0 - INIT_B_0
#Other net   PACKAGE_PIN W11      - FPGA_M2                   Bank   0 - M2_0
#Other net   PACKAGE_PIN AB11     - GND                       Bank   0 - CFGBVS_0
#Other net   PACKAGE_PIN AD12     - 4N2787                    Bank   0 - PUDC_B_0
#Other net   PACKAGE_PIN AG12     - 4N3559                    Bank   0 - POR_OVERRIDE
#Other net   PACKAGE_PIN AE12     - FPGA_DONE                 Bank   0 - DONE_0
#Other net   PACKAGE_PIN AH11     - FPGA_PROG_B               Bank   0 - PROGRAM_B_0
#Other net   PACKAGE_PIN AD13     - FPGA_TDO_FMC_TDI          Bank   0 - TDO_0
#Other net   PACKAGE_PIN AD15     - JTAG_TDI                  Bank   0 - TDI_0
#Other net   PACKAGE_PIN AJ11     - BPI_FLASH_CE_B            Bank   0 - RDWR_FCS_B_0
#Other net   PACKAGE_PIN AM11     - BPI_FLASH_D2              Bank   0 - D02_0
#Other net   PACKAGE_PIN AP11     - BPI_FLASH_D0              Bank   0 - D00_MOSI_0
#Other net   PACKAGE_PIN AL11     - BPI_FLASH_D3              Bank   0 - D03_0
#Other net   PACKAGE_PIN AN11     - BPI_FLASH_D1              Bank   0 - D01_DIN_0
#Other net   PACKAGE_PIN AF15     - JTAG_TMS                  Bank   0 - TMS_0
#Other net   PACKAGE_PIN AF13     - FPGA_CCLK                 Bank   0 - CCLK_0
#Other net   PACKAGE_PIN AE13     - JTAG_TCK                  Bank   0 - TCK_0
#Other net   PACKAGE_PIN AT11     - FPGA_VBATT                Bank   0 - VBATT
set_property PACKAGE_PIN AN30     [get_ports "DDR4_C2_DQ29"] ;# Bank  44 VCCO - VCC1V2_FPGA - IO_L24P_T3U_N10_44
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C2_DQ29"] ;# Bank  44 VCCO - VCC1V2_FPGA - IO_L24P_T3U_N10_44
set_property PACKAGE_PIN AN31     [get_ports "DDR4_C2_DQ31"] ;# Bank  44 VCCO - VCC1V2_FPGA - IO_L24N_T3U_N11_44
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C2_DQ31"] ;# Bank  44 VCCO - VCC1V2_FPGA - IO_L24N_T3U_N11_44
#set_property PACKAGE_PIN AR29     [get_ports "5N6824"] ;# Bank  44 VCCO - VCC1V2_FPGA - IO_T3U_N12_44
#set_property IOSTANDARD  LVCMOSxx [get_ports "5N6824"] ;# Bank  44 VCCO - VCC1V2_FPGA - IO_T3U_N12_44
set_property PACKAGE_PIN AP30     [get_ports "DDR4_C2_DQ30"] ;# Bank  44 VCCO - VCC1V2_FPGA - IO_L23P_T3U_N8_44
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C2_DQ30"] ;# Bank  44 VCCO - VCC1V2_FPGA - IO_L23P_T3U_N8_44
set_property PACKAGE_PIN AR30     [get_ports "DDR4_C2_DQ28"] ;# Bank  44 VCCO - VCC1V2_FPGA - IO_L23N_T3U_N9_44
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C2_DQ28"] ;# Bank  44 VCCO - VCC1V2_FPGA - IO_L23N_T3U_N9_44
set_property PACKAGE_PIN AP31     [get_ports "DDR4_C2_DQS3_T"] ;# Bank  44 VCCO - VCC1V2_FPGA - IO_L22P_T3U_N6_DBC_AD0P_44
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C2_DQS3_T"] ;# Bank  44 VCCO - VCC1V2_FPGA - IO_L22P_T3U_N6_DBC_AD0P_44
set_property PACKAGE_PIN AP32     [get_ports "DDR4_C2_DQS3_C"] ;# Bank  44 VCCO - VCC1V2_FPGA - IO_L22N_T3U_N7_DBC_AD0N_44
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C2_DQS3_C"] ;# Bank  44 VCCO - VCC1V2_FPGA - IO_L22N_T3U_N7_DBC_AD0N_44
set_property PACKAGE_PIN AT29     [get_ports "DDR4_C2_DQ24"] ;# Bank  44 VCCO - VCC1V2_FPGA - IO_L21P_T3L_N4_AD8P_44
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C2_DQ24"] ;# Bank  44 VCCO - VCC1V2_FPGA - IO_L21P_T3L_N4_AD8P_44
set_property PACKAGE_PIN AT30     [get_ports "DDR4_C2_DQ26"] ;# Bank  44 VCCO - VCC1V2_FPGA - IO_L21N_T3L_N5_AD8N_44
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C2_DQ26"] ;# Bank  44 VCCO - VCC1V2_FPGA - IO_L21N_T3L_N5_AD8N_44
set_property PACKAGE_PIN AR33     [get_ports "DDR4_C2_DQ27"] ;# Bank  44 VCCO - VCC1V2_FPGA - IO_L20P_T3L_N2_AD1P_44
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C2_DQ27"] ;# Bank  44 VCCO - VCC1V2_FPGA - IO_L20P_T3L_N2_AD1P_44
set_property PACKAGE_PIN AT34     [get_ports "DDR4_C2_DQ25"] ;# Bank  44 VCCO - VCC1V2_FPGA - IO_L20N_T3L_N3_AD1N_44
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C2_DQ25"] ;# Bank  44 VCCO - VCC1V2_FPGA - IO_L20N_T3L_N3_AD1N_44
set_property PACKAGE_PIN AR32     [get_ports "DDR4_C2_DM3"] ;# Bank  44 VCCO - VCC1V2_FPGA - IO_L19P_T3L_N0_DBC_AD9P_44
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C2_DM3"] ;# Bank  44 VCCO - VCC1V2_FPGA - IO_L19P_T3L_N0_DBC_AD9P_44
set_property PACKAGE_PIN AT32     [get_ports "GPIO_LED_0_LS"] ;# Bank  44 VCCO - VCC1V2_FPGA - IO_L19N_T3L_N1_DBC_AD9N_44
set_property IOSTANDARD  LVCMOS12 [get_ports "GPIO_LED_0_LS"] ;# Bank  44 VCCO - VCC1V2_FPGA - IO_L19N_T3L_N1_DBC_AD9N_44
set_property PACKAGE_PIN AU31     [get_ports "DDR4_C2_DQ20"] ;# Bank  44 VCCO - VCC1V2_FPGA - IO_L18P_T2U_N10_AD2P_44
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C2_DQ20"] ;# Bank  44 VCCO - VCC1V2_FPGA - IO_L18P_T2U_N10_AD2P_44
set_property PACKAGE_PIN AV31     [get_ports "DDR4_C2_DQ17"] ;# Bank  44 VCCO - VCC1V2_FPGA - IO_L18N_T2U_N11_AD2N_44
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C2_DQ17"] ;# Bank  44 VCCO - VCC1V2_FPGA - IO_L18N_T2U_N11_AD2N_44
set_property PACKAGE_PIN AT31     [get_ports "DDR4_C2_DQ16"] ;# Bank  44 VCCO - VCC1V2_FPGA - IO_L17P_T2U_N8_AD10P_44
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C2_DQ16"] ;# Bank  44 VCCO - VCC1V2_FPGA - IO_L17P_T2U_N8_AD10P_44
set_property PACKAGE_PIN AU32     [get_ports "DDR4_C2_DQ21"] ;# Bank  44 VCCO - VCC1V2_FPGA - IO_L17N_T2U_N9_AD10N_44
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C2_DQ21"] ;# Bank  44 VCCO - VCC1V2_FPGA - IO_L17N_T2U_N9_AD10N_44
set_property PACKAGE_PIN AU29     [get_ports "DDR4_C2_DQS2_T"] ;# Bank  44 VCCO - VCC1V2_FPGA - IO_L16P_T2U_N6_QBC_AD3P_44
set_property IOSTANDARD  DIFF_POD12 [get_ports "DDR4_C2_DQS2_T"] ;# Bank  44 VCCO - VCC1V2_FPGA - IO_L16P_T2U_N6_QBC_AD3P_44
set_property PACKAGE_PIN AV29     [get_ports "DDR4_C2_DQS2_C"] ;# Bank  44 VCCO - VCC1V2_FPGA - IO_L16N_T2U_N7_QBC_AD3N_44
set_property IOSTANDARD  DIFF_POD12 [get_ports "DDR4_C2_DQS2_C"] ;# Bank  44 VCCO - VCC1V2_FPGA - IO_L16N_T2U_N7_QBC_AD3N_44
set_property PACKAGE_PIN AU33     [get_ports "DDR4_C2_DQ19"] ;# Bank  44 VCCO - VCC1V2_FPGA - IO_L15P_T2L_N4_AD11P_44
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C2_DQ19"] ;# Bank  44 VCCO - VCC1V2_FPGA - IO_L15P_T2L_N4_AD11P_44
set_property PACKAGE_PIN AU34     [get_ports "DDR4_C2_DQ23"] ;# Bank  44 VCCO - VCC1V2_FPGA - IO_L15N_T2L_N5_AD11N_44
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C2_DQ23"] ;# Bank  44 VCCO - VCC1V2_FPGA - IO_L15N_T2L_N5_AD11N_44
set_property PACKAGE_PIN AV30     [get_ports "DDR4_C2_DQ18"] ;# Bank  44 VCCO - VCC1V2_FPGA - IO_L14P_T2L_N2_GC_44
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C2_DQ18"] ;# Bank  44 VCCO - VCC1V2_FPGA - IO_L14P_T2L_N2_GC_44
set_property PACKAGE_PIN AW30     [get_ports "DDR4_C2_DQ22"] ;# Bank  44 VCCO - VCC1V2_FPGA - IO_L14N_T2L_N3_GC_44
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C2_DQ22"] ;# Bank  44 VCCO - VCC1V2_FPGA - IO_L14N_T2L_N3_GC_44
set_property PACKAGE_PIN AV34     [get_ports "GPIO_LED_1_LS"] ;# Bank  44 VCCO - VCC1V2_FPGA - IO_T2U_N12_44
set_property IOSTANDARD  LVCMOS12 [get_ports "GPIO_LED_1_LS"] ;# Bank  44 VCCO - VCC1V2_FPGA - IO_T2U_N12_44
set_property PACKAGE_PIN AV33     [get_ports "DDR4_C2_DM2"] ;# Bank  44 VCCO - VCC1V2_FPGA - IO_L13P_T2L_N0_GC_QBC_44
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C2_DM2"] ;# Bank  44 VCCO - VCC1V2_FPGA - IO_L13P_T2L_N0_GC_QBC_44
#set_property PACKAGE_PIN AW33     [get_ports "5N7226"] ;# Bank  44 VCCO - VCC1V2_FPGA - IO_L13N_T2L_N1_GC_QBC_44
#set_property IOSTANDARD  LVCMOSxx [get_ports "5N7226"] ;# Bank  44 VCCO - VCC1V2_FPGA - IO_L13N_T2L_N1_GC_QBC_44
set_property PACKAGE_PIN AY32     [get_ports "DDR4_C2_DQ14"] ;# Bank  44 VCCO - VCC1V2_FPGA - IO_L12P_T1U_N10_GC_44
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C2_DQ14"] ;# Bank  44 VCCO - VCC1V2_FPGA - IO_L12P_T1U_N10_GC_44
set_property PACKAGE_PIN AY33     [get_ports "DDR4_C2_DQ9"] ;# Bank  44 VCCO - VCC1V2_FPGA - IO_L12N_T1U_N11_GC_44
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C2_DQ9"] ;# Bank  44 VCCO - VCC1V2_FPGA - IO_L12N_T1U_N11_GC_44
set_property PACKAGE_PIN AY30     [get_ports "GPIO_LED_2_LS"] ;# Bank  44 VCCO - VCC1V2_FPGA - IO_T1U_N12_44
set_property IOSTANDARD  LVCMOS12 [get_ports "GPIO_LED_2_LS"] ;# Bank  44 VCCO - VCC1V2_FPGA - IO_T1U_N12_44
set_property PACKAGE_PIN AW31     [get_ports "DDR4_C2_DQ11"] ;# Bank  44 VCCO - VCC1V2_FPGA - IO_L11P_T1U_N8_GC_44
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C2_DQ11"] ;# Bank  44 VCCO - VCC1V2_FPGA - IO_L11P_T1U_N8_GC_44
set_property PACKAGE_PIN AW32     [get_ports "DDR4_C2_DQ12"] ;# Bank  44 VCCO - VCC1V2_FPGA - IO_L11N_T1U_N9_GC_44
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C2_DQ12"] ;# Bank  44 VCCO - VCC1V2_FPGA - IO_L11N_T1U_N9_GC_44
set_property PACKAGE_PIN AY34     [get_ports "DDR4_C2_DQS1_T"] ;# Bank  44 VCCO - VCC1V2_FPGA - IO_L10P_T1U_N6_QBC_AD4P_44
set_property IOSTANDARD  DIFF_POD12 [get_ports "DDR4_C2_DQS1_T"] ;# Bank  44 VCCO - VCC1V2_FPGA - IO_L10P_T1U_N6_QBC_AD4P_44
set_property PACKAGE_PIN BA34     [get_ports "DDR4_C2_DQS1_C"] ;# Bank  44 VCCO - VCC1V2_FPGA - IO_L10N_T1U_N7_QBC_AD4N_44
set_property IOSTANDARD  DIFF_POD12 [get_ports "DDR4_C2_DQS1_C"] ;# Bank  44 VCCO - VCC1V2_FPGA - IO_L10N_T1U_N7_QBC_AD4N_44
set_property PACKAGE_PIN BA30     [get_ports "DDR4_C2_DQ10"] ;# Bank  44 VCCO - VCC1V2_FPGA - IO_L9P_T1L_N4_AD12P_44
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C2_DQ10"] ;# Bank  44 VCCO - VCC1V2_FPGA - IO_L9P_T1L_N4_AD12P_44
set_property PACKAGE_PIN BA31     [get_ports "DDR4_C2_DQ8"] ;# Bank  44 VCCO - VCC1V2_FPGA - IO_L9N_T1L_N5_AD12N_44
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C2_DQ8"] ;# Bank  44 VCCO - VCC1V2_FPGA - IO_L9N_T1L_N5_AD12N_44
set_property PACKAGE_PIN BA32     [get_ports "DDR4_C2_DQ15"] ;# Bank  44 VCCO - VCC1V2_FPGA - IO_L8P_T1L_N2_AD5P_44
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C2_DQ15"] ;# Bank  44 VCCO - VCC1V2_FPGA - IO_L8P_T1L_N2_AD5P_44
set_property PACKAGE_PIN BB33     [get_ports "DDR4_C2_DQ13"] ;# Bank  44 VCCO - VCC1V2_FPGA - IO_L8N_T1L_N3_AD5N_44
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C2_DQ13"] ;# Bank  44 VCCO - VCC1V2_FPGA - IO_L8N_T1L_N3_AD5N_44
set_property PACKAGE_PIN BB31     [get_ports "DDR4_C2_DM1"] ;# Bank  44 VCCO - VCC1V2_FPGA - IO_L7P_T1L_N0_QBC_AD13P_44
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C2_DM1"] ;# Bank  44 VCCO - VCC1V2_FPGA - IO_L7P_T1L_N0_QBC_AD13P_44
set_property PACKAGE_PIN BB32     [get_ports "GPIO_LED_3_LS"] ;# Bank  44 VCCO - VCC1V2_FPGA - IO_L7N_T1L_N1_QBC_AD13N_44
set_property IOSTANDARD  LVCMOS12 [get_ports "GPIO_LED_3_LS"] ;# Bank  44 VCCO - VCC1V2_FPGA - IO_L7N_T1L_N1_QBC_AD13N_44
set_property PACKAGE_PIN BC31     [get_ports "DDR4_C2_DQ7"] ;# Bank  44 VCCO - VCC1V2_FPGA - IO_L6P_T0U_N10_AD6P_44
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C2_DQ7"] ;# Bank  44 VCCO - VCC1V2_FPGA - IO_L6P_T0U_N10_AD6P_44
set_property PACKAGE_PIN BD31     [get_ports "DDR4_C2_DQ4"] ;# Bank  44 VCCO - VCC1V2_FPGA - IO_L6N_T0U_N11_AD6N_44
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C2_DQ4"] ;# Bank  44 VCCO - VCC1V2_FPGA - IO_L6N_T0U_N11_AD6N_44
set_property PACKAGE_PIN BC33     [get_ports "DDR4_C2_DQ5"] ;# Bank  44 VCCO - VCC1V2_FPGA - IO_L5P_T0U_N8_AD14P_44
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C2_DQ5"] ;# Bank  44 VCCO - VCC1V2_FPGA - IO_L5P_T0U_N8_AD14P_44
set_property PACKAGE_PIN BD33     [get_ports "DDR4_C2_DQ3"] ;# Bank  44 VCCO - VCC1V2_FPGA - IO_L5N_T0U_N9_AD14N_44
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C2_DQ3"] ;# Bank  44 VCCO - VCC1V2_FPGA - IO_L5N_T0U_N9_AD14N_44
set_property PACKAGE_PIN BF30     [get_ports "DDR4_C2_DQS0_T"] ;# Bank  44 VCCO - VCC1V2_FPGA - IO_L4P_T0U_N6_DBC_AD7P_44
set_property IOSTANDARD  DIFF_POD12 [get_ports "DDR4_C2_DQS0_T"] ;# Bank  44 VCCO - VCC1V2_FPGA - IO_L4P_T0U_N6_DBC_AD7P_44
set_property PACKAGE_PIN BF31     [get_ports "DDR4_C2_DQS0_C"] ;# Bank  44 VCCO - VCC1V2_FPGA - IO_L4N_T0U_N7_DBC_AD7N_44
set_property IOSTANDARD  DIFF_POD12 [get_ports "DDR4_C2_DQS0_C"] ;# Bank  44 VCCO - VCC1V2_FPGA - IO_L4N_T0U_N7_DBC_AD7N_44
set_property PACKAGE_PIN BD32     [get_ports "DDR4_C2_DQ6"] ;# Bank  44 VCCO - VCC1V2_FPGA - IO_L3P_T0L_N4_AD15P_44
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C2_DQ6"] ;# Bank  44 VCCO - VCC1V2_FPGA - IO_L3P_T0L_N4_AD15P_44
set_property PACKAGE_PIN BE33     [get_ports "DDR4_C2_DQ1"] ;# Bank  44 VCCO - VCC1V2_FPGA - IO_L3N_T0L_N5_AD15N_44
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C2_DQ1"] ;# Bank  44 VCCO - VCC1V2_FPGA - IO_L3N_T0L_N5_AD15N_44
set_property PACKAGE_PIN BD30     [get_ports "DDR4_C2_DQ2"] ;# Bank  44 VCCO - VCC1V2_FPGA - IO_L2P_T0L_N2_44
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C2_DQ2"] ;# Bank  44 VCCO - VCC1V2_FPGA - IO_L2P_T0L_N2_44
set_property PACKAGE_PIN BE30     [get_ports "DDR4_C2_DQ0"] ;# Bank  44 VCCO - VCC1V2_FPGA - IO_L2N_T0L_N3_44
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C2_DQ0"] ;# Bank  44 VCCO - VCC1V2_FPGA - IO_L2N_T0L_N3_44
#set_property PACKAGE_PIN BC30     [get_ports "VRP_44"] ;# Bank  44 VCCO - VCC1V2_FPGA - IO_T0U_N12_VRP_44
#set_property IOSTANDARD  LVCMOSxx [get_ports "VRP_44"] ;# Bank  44 VCCO - VCC1V2_FPGA - IO_T0U_N12_VRP_44
set_property PACKAGE_PIN BE32     [get_ports "DDR4_C2_DM0"] ;# Bank  44 VCCO - VCC1V2_FPGA - IO_L1P_T0L_N0_DBC_44
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C2_DM0"] ;# Bank  44 VCCO - VCC1V2_FPGA - IO_L1P_T0L_N0_DBC_44
set_property PACKAGE_PIN BF32     [get_ports "GPIO_LED_4_LS"] ;# Bank  44 VCCO - VCC1V2_FPGA - IO_L1N_T0L_N1_DBC_44
set_property IOSTANDARD  LVCMOS12 [get_ports "GPIO_LED_4_LS"] ;# Bank  44 VCCO - VCC1V2_FPGA - IO_L1N_T0L_N1_DBC_44
set_property PACKAGE_PIN AL27     [get_ports "DDR4_C2_A14_WE_B"] ;# Bank  45 VCCO - VCC1V2_FPGA - IO_L24P_T3U_N10_45
set_property IOSTANDARD  SSTL12_DCI [get_ports "DDR4_C2_A14_WE_B"] ;# Bank  45 VCCO - VCC1V2_FPGA - IO_L24P_T3U_N10_45
set_property PACKAGE_PIN AM27     [get_ports "DDR4_C2_A0"] ;# Bank  45 VCCO - VCC1V2_FPGA - IO_L24N_T3U_N11_45
set_property IOSTANDARD  SSTL12_DCI [get_ports "DDR4_C2_A0"] ;# Bank  45 VCCO - VCC1V2_FPGA - IO_L24N_T3U_N11_45
set_property PACKAGE_PIN AN25     [get_ports "DDR4_C2_A2"] ;# Bank  45 VCCO - VCC1V2_FPGA - IO_T3U_N12_45
set_property IOSTANDARD  SSTL12_DCI [get_ports "DDR4_C2_A2"] ;# Bank  45 VCCO - VCC1V2_FPGA - IO_T3U_N12_45
set_property PACKAGE_PIN AP25     [get_ports "DDR4_C2_A8"] ;# Bank  45 VCCO - VCC1V2_FPGA - IO_L23P_T3U_N8_45
set_property IOSTANDARD  SSTL12_DCI [get_ports "DDR4_C2_A8"] ;# Bank  45 VCCO - VCC1V2_FPGA - IO_L23P_T3U_N8_45
set_property PACKAGE_PIN AP26     [get_ports "DDR4_C2_A10"] ;# Bank  45 VCCO - VCC1V2_FPGA - IO_L23N_T3U_N9_45
set_property IOSTANDARD  SSTL12_DCI [get_ports "DDR4_C2_A10"] ;# Bank  45 VCCO - VCC1V2_FPGA - IO_L23N_T3U_N9_45
set_property PACKAGE_PIN AM28     [get_ports "DDR4_C2_A16_RAS_B"] ;# Bank  45 VCCO - VCC1V2_FPGA - IO_L22P_T3U_N6_DBC_AD0P_45
set_property IOSTANDARD  SSTL12_DCI [get_ports "DDR4_C2_A16_RAS_B"] ;# Bank  45 VCCO - VCC1V2_FPGA - IO_L22P_T3U_N6_DBC_AD0P_45
set_property PACKAGE_PIN AN28     [get_ports "DDR4_C2_A11"] ;# Bank  45 VCCO - VCC1V2_FPGA - IO_L22N_T3U_N7_DBC_AD0N_45
set_property IOSTANDARD  SSTL12_DCI [get_ports "DDR4_C2_A11"] ;# Bank  45 VCCO - VCC1V2_FPGA - IO_L22N_T3U_N7_DBC_AD0N_45
set_property PACKAGE_PIN AP27     [get_ports "DDR4_C2_A15_CAS_B"] ;# Bank  45 VCCO - VCC1V2_FPGA - IO_L21P_T3L_N4_AD8P_45
set_property IOSTANDARD  SSTL12_DCI [get_ports "DDR4_C2_A15_CAS_B"] ;# Bank  45 VCCO - VCC1V2_FPGA - IO_L21P_T3L_N4_AD8P_45
set_property PACKAGE_PIN AP28     [get_ports "DDR4_C2_A13"] ;# Bank  45 VCCO - VCC1V2_FPGA - IO_L21N_T3L_N5_AD8N_45
set_property IOSTANDARD  SSTL12_DCI [get_ports "DDR4_C2_A13"] ;# Bank  45 VCCO - VCC1V2_FPGA - IO_L21N_T3L_N5_AD8N_45
set_property PACKAGE_PIN AM26     [get_ports "DDR4_C2_A9"] ;# Bank  45 VCCO - VCC1V2_FPGA - IO_L20P_T3L_N2_AD1P_45
set_property IOSTANDARD  SSTL12_DCI [get_ports "DDR4_C2_A9"] ;# Bank  45 VCCO - VCC1V2_FPGA - IO_L20P_T3L_N2_AD1P_45
set_property PACKAGE_PIN AN26     [get_ports "DDR4_C2_A3"] ;# Bank  45 VCCO - VCC1V2_FPGA - IO_L20N_T3L_N3_AD1N_45
set_property IOSTANDARD  SSTL12_DCI [get_ports "DDR4_C2_A3"] ;# Bank  45 VCCO - VCC1V2_FPGA - IO_L20N_T3L_N3_AD1N_45
set_property PACKAGE_PIN AR27     [get_ports "DDR4_C2_A12"] ;# Bank  45 VCCO - VCC1V2_FPGA - IO_L19P_T3L_N0_DBC_AD9P_45
set_property IOSTANDARD  SSTL12_DCI [get_ports "DDR4_C2_A12"] ;# Bank  45 VCCO - VCC1V2_FPGA - IO_L19P_T3L_N0_DBC_AD9P_45
set_property PACKAGE_PIN AR28     [get_ports "DDR4_C2_A7"] ;# Bank  45 VCCO - VCC1V2_FPGA - IO_L19N_T3L_N1_DBC_AD9N_45
set_property IOSTANDARD  SSTL12_DCI [get_ports "DDR4_C2_A7"] ;# Bank  45 VCCO - VCC1V2_FPGA - IO_L19N_T3L_N1_DBC_AD9N_45
set_property PACKAGE_PIN AR25     [get_ports "DDR4_C2_A4"] ;# Bank  45 VCCO - VCC1V2_FPGA - IO_L18P_T2U_N10_AD2P_45
set_property IOSTANDARD  SSTL12_DCI [get_ports "DDR4_C2_A4"] ;# Bank  45 VCCO - VCC1V2_FPGA - IO_L18P_T2U_N10_AD2P_45
set_property PACKAGE_PIN AT25     [get_ports "DDR4_C2_A1"] ;# Bank  45 VCCO - VCC1V2_FPGA - IO_L18N_T2U_N11_AD2N_45
set_property IOSTANDARD  SSTL12_DCI [get_ports "DDR4_C2_A1"] ;# Bank  45 VCCO - VCC1V2_FPGA - IO_L18N_T2U_N11_AD2N_45
set_property PACKAGE_PIN AU27     [get_ports "DDR4_C2_A6"] ;# Bank  45 VCCO - VCC1V2_FPGA - IO_L17P_T2U_N8_AD10P_45
set_property IOSTANDARD  SSTL12_DCI [get_ports "DDR4_C2_A6"] ;# Bank  45 VCCO - VCC1V2_FPGA - IO_L17P_T2U_N8_AD10P_45
set_property PACKAGE_PIN AU28     [get_ports "DDR4_C2_A5"] ;# Bank  45 VCCO - VCC1V2_FPGA - IO_L17N_T2U_N9_AD10N_45
set_property IOSTANDARD  SSTL12_DCI [get_ports "DDR4_C2_A5"] ;# Bank  45 VCCO - VCC1V2_FPGA - IO_L17N_T2U_N9_AD10N_45
set_property PACKAGE_PIN AT26     [get_ports "DDR4_C2_CK_T"] ;# Bank  45 VCCO - VCC1V2_FPGA - IO_L16P_T2U_N6_QBC_AD3P_45
set_property IOSTANDARD  DIFF_SSTL2_DCI [get_ports "DDR4_C2_CK_T"] ;# Bank  45 VCCO - VCC1V2_FPGA - IO_L16P_T2U_N6_QBC_AD3P_45
set_property PACKAGE_PIN AT27     [get_ports "DDR4_C2_CK_C"] ;# Bank  45 VCCO - VCC1V2_FPGA - IO_L16N_T2U_N7_QBC_AD3N_45
set_property IOSTANDARD  DIFF_SSTL2_DCI [get_ports "DDR4_C2_CK_C"] ;# Bank  45 VCCO - VCC1V2_FPGA - IO_L16N_T2U_N7_QBC_AD3N_45
set_property PACKAGE_PIN AV28     [get_ports "DDR4_C2_BG0"] ;# Bank  45 VCCO - VCC1V2_FPGA - IO_L15P_T2L_N4_AD11P_45
set_property IOSTANDARD  SSTL12_DCI [get_ports "DDR4_C2_BG0"] ;# Bank  45 VCCO - VCC1V2_FPGA - IO_L15P_T2L_N4_AD11P_45
set_property PACKAGE_PIN AW28     [get_ports "DDR4_C2_ACT_B"] ;# Bank  45 VCCO - VCC1V2_FPGA - IO_L15N_T2L_N5_AD11N_45
set_property IOSTANDARD  SSTL12_DCI [get_ports "DDR4_C2_ACT_B"] ;# Bank  45 VCCO - VCC1V2_FPGA - IO_L15N_T2L_N5_AD11N_45
set_property PACKAGE_PIN AU26     [get_ports "DDR4_C2_BA0"] ;# Bank  45 VCCO - VCC1V2_FPGA - IO_L14P_T2L_N2_GC_45
set_property IOSTANDARD  SSTL12_DCI [get_ports "DDR4_C2_BA0"] ;# Bank  45 VCCO - VCC1V2_FPGA - IO_L14P_T2L_N2_GC_45
set_property PACKAGE_PIN AV26     [get_ports "DDR4_C2_BA1"] ;# Bank  45 VCCO - VCC1V2_FPGA - IO_L14N_T2L_N3_GC_45
set_property IOSTANDARD  SSTL12_DCI [get_ports "DDR4_C2_BA1"] ;# Bank  45 VCCO - VCC1V2_FPGA - IO_L14N_T2L_N3_GC_45
set_property PACKAGE_PIN AV25     [get_ports "DDR4_C2_ALERT_B"] ;# Bank  45 VCCO - VCC1V2_FPGA - IO_T2U_N12_45
set_property IOSTANDARD  SSTL12_DCI [get_ports "DDR4_C2_ALERT_B"] ;# Bank  45 VCCO - VCC1V2_FPGA - IO_T2U_N12_45
set_property PACKAGE_PIN AW26     [get_ports "DDR4_C2_CS_B"] ;# Bank  45 VCCO - VCC1V2_FPGA - IO_L13P_T2L_N0_GC_QBC_45
set_property IOSTANDARD  SSTL12_DCI [get_ports "DDR4_C2_CS_B"] ;# Bank  45 VCCO - VCC1V2_FPGA - IO_L13P_T2L_N0_GC_QBC_45
set_property PACKAGE_PIN AW27     [get_ports "GPIO_SW_C"] ;# Bank  45 VCCO - VCC1V2_FPGA - IO_L13N_T2L_N1_GC_QBC_45
set_property IOSTANDARD  LVCMOS12 [get_ports "GPIO_SW_C"] ;# Bank  45 VCCO - VCC1V2_FPGA - IO_L13N_T2L_N1_GC_QBC_45
set_property PACKAGE_PIN BA27     [get_ports "DDR4_C2_DQ74"] ;# Bank  45 VCCO - VCC1V2_FPGA - IO_L12P_T1U_N10_GC_45
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C2_DQ74"] ;# Bank  45 VCCO - VCC1V2_FPGA - IO_L12P_T1U_N10_GC_45
set_property PACKAGE_PIN BB27     [get_ports "DDR4_C2_DQ77"] ;# Bank  45 VCCO - VCC1V2_FPGA - IO_L12N_T1U_N11_GC_45
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C2_DQ77"] ;# Bank  45 VCCO - VCC1V2_FPGA - IO_L12N_T1U_N11_GC_45
set_property PACKAGE_PIN AY29     [get_ports "DDR4_C2_CKE"] ;# Bank  45 VCCO - VCC1V2_FPGA - IO_T1U_N12_45
set_property IOSTANDARD  SSTL12_DCI [get_ports "DDR4_C2_CKE"] ;# Bank  45 VCCO - VCC1V2_FPGA - IO_T1U_N12_45
set_property PACKAGE_PIN AY27     [get_ports "DDR4_C2_DQ72"] ;# Bank  45 VCCO - VCC1V2_FPGA - IO_L11P_T1U_N8_GC_45
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C2_DQ72"] ;# Bank  45 VCCO - VCC1V2_FPGA - IO_L11P_T1U_N8_GC_45
set_property PACKAGE_PIN AY28     [get_ports "DDR4_C2_DQ76"] ;# Bank  45 VCCO - VCC1V2_FPGA - IO_L11N_T1U_N9_GC_45
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C2_DQ76"] ;# Bank  45 VCCO - VCC1V2_FPGA - IO_L11N_T1U_N9_GC_45
set_property PACKAGE_PIN BA26     [get_ports "DDR4_C2_DQS9_T"] ;# Bank  45 VCCO - VCC1V2_FPGA - IO_L10P_T1U_N6_QBC_AD4P_45
set_property IOSTANDARD  DIFF_POD12 [get_ports "DDR4_C2_DQS9_T"] ;# Bank  45 VCCO - VCC1V2_FPGA - IO_L10P_T1U_N6_QBC_AD4P_45
set_property PACKAGE_PIN BB26     [get_ports "DDR4_C2_DQS9_C"] ;# Bank  45 VCCO - VCC1V2_FPGA - IO_L10N_T1U_N7_QBC_AD4N_45
set_property IOSTANDARD  DIFF_POD12 [get_ports "DDR4_C2_DQS9_C"] ;# Bank  45 VCCO - VCC1V2_FPGA - IO_L10N_T1U_N7_QBC_AD4N_45
set_property PACKAGE_PIN BB28     [get_ports "DDR4_C2_DQ75"] ;# Bank  45 VCCO - VCC1V2_FPGA - IO_L9P_T1L_N4_AD12P_45
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C2_DQ75"] ;# Bank  45 VCCO - VCC1V2_FPGA - IO_L9P_T1L_N4_AD12P_45
set_property PACKAGE_PIN BC28     [get_ports "DDR4_C2_DQ79"] ;# Bank  45 VCCO - VCC1V2_FPGA - IO_L9N_T1L_N5_AD12N_45
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C2_DQ79"] ;# Bank  45 VCCO - VCC1V2_FPGA - IO_L9N_T1L_N5_AD12N_45
set_property PACKAGE_PIN BC25     [get_ports "DDR4_C2_DQ78"] ;# Bank  45 VCCO - VCC1V2_FPGA - IO_L8P_T1L_N2_AD5P_45
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C2_DQ78"] ;# Bank  45 VCCO - VCC1V2_FPGA - IO_L8P_T1L_N2_AD5P_45
set_property PACKAGE_PIN BC26     [get_ports "DDR4_C2_DQ73"] ;# Bank  45 VCCO - VCC1V2_FPGA - IO_L8N_T1L_N3_AD5N_45
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C2_DQ73"] ;# Bank  45 VCCO - VCC1V2_FPGA - IO_L8N_T1L_N3_AD5N_45
set_property PACKAGE_PIN BA29     [get_ports "DDR4_C2_DM9"] ;# Bank  45 VCCO - VCC1V2_FPGA - IO_L7P_T1L_N0_QBC_AD13P_45
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C2_DM9"] ;# Bank  45 VCCO - VCC1V2_FPGA - IO_L7P_T1L_N0_QBC_AD13P_45
set_property PACKAGE_PIN BB29     [get_ports "DDR4_C2_ODT"] ;# Bank  45 VCCO - VCC1V2_FPGA - IO_L7N_T1L_N1_QBC_AD13N_45
set_property IOSTANDARD  SSTL12_DCI [get_ports "DDR4_C2_ODT"] ;# Bank  45 VCCO - VCC1V2_FPGA - IO_L7N_T1L_N1_QBC_AD13N_45
set_property PACKAGE_PIN BD25     [get_ports "DDR4_C2_DQ64"] ;# Bank  45 VCCO - VCC1V2_FPGA - IO_L6P_T0U_N10_AD6P_45
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C2_DQ64"] ;# Bank  45 VCCO - VCC1V2_FPGA - IO_L6P_T0U_N10_AD6P_45
set_property PACKAGE_PIN BD26     [get_ports "DDR4_C2_DQ65"] ;# Bank  45 VCCO - VCC1V2_FPGA - IO_L6N_T0U_N11_AD6N_45
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C2_DQ65"] ;# Bank  45 VCCO - VCC1V2_FPGA - IO_L6N_T0U_N11_AD6N_45
set_property PACKAGE_PIN BD27     [get_ports "DDR4_C2_DQ66"] ;# Bank  45 VCCO - VCC1V2_FPGA - IO_L5P_T0U_N8_AD14P_45
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C2_DQ66"] ;# Bank  45 VCCO - VCC1V2_FPGA - IO_L5P_T0U_N8_AD14P_45
set_property PACKAGE_PIN BE27     [get_ports "DDR4_C2_DQ67"] ;# Bank  45 VCCO - VCC1V2_FPGA - IO_L5N_T0U_N9_AD14N_45
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C2_DQ67"] ;# Bank  45 VCCO - VCC1V2_FPGA - IO_L5N_T0U_N9_AD14N_45
set_property PACKAGE_PIN BE25     [get_ports "DDR4_C2_DQS8_T"] ;# Bank  45 VCCO - VCC1V2_FPGA - IO_L4P_T0U_N6_DBC_AD7P_45
set_property IOSTANDARD  DIFF_POD12 [get_ports "DDR4_C2_DQS8_T"] ;# Bank  45 VCCO - VCC1V2_FPGA - IO_L4P_T0U_N6_DBC_AD7P_45
set_property PACKAGE_PIN BF25     [get_ports "DDR4_C2_DQS8_C"] ;# Bank  45 VCCO - VCC1V2_FPGA - IO_L4N_T0U_N7_DBC_AD7N_45
set_property IOSTANDARD  DIFF_POD12 [get_ports "DDR4_C2_DQS8_C"] ;# Bank  45 VCCO - VCC1V2_FPGA - IO_L4N_T0U_N7_DBC_AD7N_45
set_property PACKAGE_PIN BD28     [get_ports "DDR4_C2_DQ68"] ;# Bank  45 VCCO - VCC1V2_FPGA - IO_L3P_T0L_N4_AD15P_45
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C2_DQ68"] ;# Bank  45 VCCO - VCC1V2_FPGA - IO_L3P_T0L_N4_AD15P_45
set_property PACKAGE_PIN BE28     [get_ports "DDR4_C2_DQ69"] ;# Bank  45 VCCO - VCC1V2_FPGA - IO_L3N_T0L_N5_AD15N_45
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C2_DQ69"] ;# Bank  45 VCCO - VCC1V2_FPGA - IO_L3N_T0L_N5_AD15N_45
set_property PACKAGE_PIN BF26     [get_ports "DDR4_C2_DQ70"] ;# Bank  45 VCCO - VCC1V2_FPGA - IO_L2P_T0L_N2_45
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C2_DQ70"] ;# Bank  45 VCCO - VCC1V2_FPGA - IO_L2P_T0L_N2_45
set_property PACKAGE_PIN BF27     [get_ports "DDR4_C2_DQ71"] ;# Bank  45 VCCO - VCC1V2_FPGA - IO_L2N_T0L_N3_45
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C2_DQ71"] ;# Bank  45 VCCO - VCC1V2_FPGA - IO_L2N_T0L_N3_45
#set_property PACKAGE_PIN BC29     [get_ports "VRP_45"] ;# Bank  45 VCCO - VCC1V2_FPGA - IO_T0U_N12_VRP_45
#set_property IOSTANDARD  LVCMOSxx [get_ports "VRP_45"] ;# Bank  45 VCCO - VCC1V2_FPGA - IO_T0U_N12_VRP_45
set_property PACKAGE_PIN BE29     [get_ports "DDR4_C2_DM8"] ;# Bank  45 VCCO - VCC1V2_FPGA - IO_L1P_T0L_N0_DBC_45
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C2_DM8"] ;# Bank  45 VCCO - VCC1V2_FPGA - IO_L1P_T0L_N0_DBC_45
set_property PACKAGE_PIN BF29     [get_ports "DDR4_C2_PAR"] ;# Bank  45 VCCO - VCC1V2_FPGA - IO_L1N_T0L_N1_DBC_45
set_property IOSTANDARD  SSTL12_DCI [get_ports "DDR4_C2_PAR"] ;# Bank  45 VCCO - VCC1V2_FPGA - IO_L1N_T0L_N1_DBC_45
set_property PACKAGE_PIN AV38     [get_ports "DDR4_C2_DQ56"] ;# Bank  46 VCCO - VCC1V2_FPGA - IO_L24P_T3U_N10_46
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C2_DQ56"] ;# Bank  46 VCCO - VCC1V2_FPGA - IO_L24P_T3U_N10_46
set_property PACKAGE_PIN AV39     [get_ports "DDR4_C2_DQ63"] ;# Bank  46 VCCO - VCC1V2_FPGA - IO_L24N_T3U_N11_46
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C2_DQ63"] ;# Bank  46 VCCO - VCC1V2_FPGA - IO_L24N_T3U_N11_46
#set_property PACKAGE_PIN AU37     [get_ports "6N3480"] ;# Bank  46 VCCO - VCC1V2_FPGA - IO_T3U_N12_46
#set_property IOSTANDARD  LVCMOSxx [get_ports "6N3480"] ;# Bank  46 VCCO - VCC1V2_FPGA - IO_T3U_N12_46
set_property PACKAGE_PIN AU38     [get_ports "DDR4_C2_DQ57"] ;# Bank  46 VCCO - VCC1V2_FPGA - IO_L23P_T3U_N8_46
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C2_DQ57"] ;# Bank  46 VCCO - VCC1V2_FPGA - IO_L23P_T3U_N8_46
set_property PACKAGE_PIN AU39     [get_ports "DDR4_C2_DQ58"] ;# Bank  46 VCCO - VCC1V2_FPGA - IO_L23N_T3U_N9_46
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C2_DQ58"] ;# Bank  46 VCCO - VCC1V2_FPGA - IO_L23N_T3U_N9_46
set_property PACKAGE_PIN AW37     [get_ports "DDR4_C2_DQS7_T"] ;# Bank  46 VCCO - VCC1V2_FPGA - IO_L22P_T3U_N6_DBC_AD0P_46
set_property IOSTANDARD  DIFF_POD12 [get_ports "DDR4_C2_DQS7_T"] ;# Bank  46 VCCO - VCC1V2_FPGA - IO_L22P_T3U_N6_DBC_AD0P_46
set_property PACKAGE_PIN AW38     [get_ports "DDR4_C2_DQS7_C"] ;# Bank  46 VCCO - VCC1V2_FPGA - IO_L22N_T3U_N7_DBC_AD0N_46
set_property IOSTANDARD  DIFF_POD12 [get_ports "DDR4_C2_DQS7_C"] ;# Bank  46 VCCO - VCC1V2_FPGA - IO_L22N_T3U_N7_DBC_AD0N_46
set_property PACKAGE_PIN AU40     [get_ports "DDR4_C2_DQ60"] ;# Bank  46 VCCO - VCC1V2_FPGA - IO_L21P_T3L_N4_AD8P_46
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C2_DQ60"] ;# Bank  46 VCCO - VCC1V2_FPGA - IO_L21P_T3L_N4_AD8P_46
set_property PACKAGE_PIN AV40     [get_ports "DDR4_C2_DQ61"] ;# Bank  46 VCCO - VCC1V2_FPGA - IO_L21N_T3L_N5_AD8N_46
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C2_DQ61"] ;# Bank  46 VCCO - VCC1V2_FPGA - IO_L21N_T3L_N5_AD8N_46
set_property PACKAGE_PIN AW35     [get_ports "DDR4_C2_DQ59"] ;# Bank  46 VCCO - VCC1V2_FPGA - IO_L20P_T3L_N2_AD1P_46
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C2_DQ59"] ;# Bank  46 VCCO - VCC1V2_FPGA - IO_L20P_T3L_N2_AD1P_46
set_property PACKAGE_PIN AW36     [get_ports "DDR4_C2_DQ62"] ;# Bank  46 VCCO - VCC1V2_FPGA - IO_L20N_T3L_N3_AD1N_46
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C2_DQ62"] ;# Bank  46 VCCO - VCC1V2_FPGA - IO_L20N_T3L_N3_AD1N_46
set_property PACKAGE_PIN AV35     [get_ports "DDR4_C2_DM7"] ;# Bank  46 VCCO - VCC1V2_FPGA - IO_L19P_T3L_N0_DBC_AD9P_46
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C2_DM7"] ;# Bank  46 VCCO - VCC1V2_FPGA - IO_L19P_T3L_N0_DBC_AD9P_46
set_property PACKAGE_PIN AV36     [get_ports "GPIO_LED_5_LS"] ;# Bank  46 VCCO - VCC1V2_FPGA - IO_L19N_T3L_N1_DBC_AD9N_46
set_property IOSTANDARD  LVCMOS12 [get_ports "GPIO_LED_5_LS"] ;# Bank  46 VCCO - VCC1V2_FPGA - IO_L19N_T3L_N1_DBC_AD9N_46
set_property PACKAGE_PIN AY38     [get_ports "DDR4_C2_DQ51"] ;# Bank  46 VCCO - VCC1V2_FPGA - IO_L18P_T2U_N10_AD2P_46
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C2_DQ51"] ;# Bank  46 VCCO - VCC1V2_FPGA - IO_L18P_T2U_N10_AD2P_46
set_property PACKAGE_PIN AY39     [get_ports "DDR4_C2_DQ50"] ;# Bank  46 VCCO - VCC1V2_FPGA - IO_L18N_T2U_N11_AD2N_46
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C2_DQ50"] ;# Bank  46 VCCO - VCC1V2_FPGA - IO_L18N_T2U_N11_AD2N_46
set_property PACKAGE_PIN AW40     [get_ports "DDR4_C2_DQ48"] ;# Bank  46 VCCO - VCC1V2_FPGA - IO_L17P_T2U_N8_AD10P_46
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C2_DQ48"] ;# Bank  46 VCCO - VCC1V2_FPGA - IO_L17P_T2U_N8_AD10P_46
set_property PACKAGE_PIN AY40     [get_ports "DDR4_C2_DQ52"] ;# Bank  46 VCCO - VCC1V2_FPGA - IO_L17N_T2U_N9_AD10N_46
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C2_DQ52"] ;# Bank  46 VCCO - VCC1V2_FPGA - IO_L17N_T2U_N9_AD10N_46
set_property PACKAGE_PIN BA35     [get_ports "DDR4_C2_DQS6_T"] ;# Bank  46 VCCO - VCC1V2_FPGA - IO_L16P_T2U_N6_QBC_AD3P_46
set_property IOSTANDARD  DIFF_POD12 [get_ports "DDR4_C2_DQS6_T"] ;# Bank  46 VCCO - VCC1V2_FPGA - IO_L16P_T2U_N6_QBC_AD3P_46
set_property PACKAGE_PIN BA36     [get_ports "DDR4_C2_DQS6_C"] ;# Bank  46 VCCO - VCC1V2_FPGA - IO_L16N_T2U_N7_QBC_AD3N_46
set_property IOSTANDARD  DIFF_POD12 [get_ports "DDR4_C2_DQS6_C"] ;# Bank  46 VCCO - VCC1V2_FPGA - IO_L16N_T2U_N7_QBC_AD3N_46
set_property PACKAGE_PIN BA39     [get_ports "DDR4_C2_DQ53"] ;# Bank  46 VCCO - VCC1V2_FPGA - IO_L15P_T2L_N4_AD11P_46
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C2_DQ53"] ;# Bank  46 VCCO - VCC1V2_FPGA - IO_L15P_T2L_N4_AD11P_46
set_property PACKAGE_PIN BA40     [get_ports "DDR4_C2_DQ49"] ;# Bank  46 VCCO - VCC1V2_FPGA - IO_L15N_T2L_N5_AD11N_46
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C2_DQ49"] ;# Bank  46 VCCO - VCC1V2_FPGA - IO_L15N_T2L_N5_AD11N_46
set_property PACKAGE_PIN BB36     [get_ports "DDR4_C2_DQ54"] ;# Bank  46 VCCO - VCC1V2_FPGA - IO_L14P_T2L_N2_GC_46
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C2_DQ54"] ;# Bank  46 VCCO - VCC1V2_FPGA - IO_L14P_T2L_N2_GC_46
set_property PACKAGE_PIN BB37     [get_ports "DDR4_C2_DQ55"] ;# Bank  46 VCCO - VCC1V2_FPGA - IO_L14N_T2L_N3_GC_46
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C2_DQ55"] ;# Bank  46 VCCO - VCC1V2_FPGA - IO_L14N_T2L_N3_GC_46
set_property PACKAGE_PIN AY35     [get_ports "GPIO_LED_6_LS"] ;# Bank  46 VCCO - VCC1V2_FPGA - IO_T2U_N12_46
set_property IOSTANDARD  LVCMOS12 [get_ports "GPIO_LED_6_LS"] ;# Bank  46 VCCO - VCC1V2_FPGA - IO_T2U_N12_46
set_property PACKAGE_PIN AY37     [get_ports "DDR4_C2_DM6"] ;# Bank  46 VCCO - VCC1V2_FPGA - IO_L13P_T2L_N0_GC_QBC_46
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C2_DM6"] ;# Bank  46 VCCO - VCC1V2_FPGA - IO_L13P_T2L_N0_GC_QBC_46
set_property PACKAGE_PIN BA37     [get_ports "GPIO_LED_7_LS"] ;# Bank  46 VCCO - VCC1V2_FPGA - IO_L13N_T2L_N1_GC_QBC_46
set_property IOSTANDARD  LVCMOS12 [get_ports "GPIO_LED_7_LS"] ;# Bank  46 VCCO - VCC1V2_FPGA - IO_L13N_T2L_N1_GC_QBC_46
set_property PACKAGE_PIN BC38     [get_ports "DDR4_C2_DQ47"] ;# Bank  46 VCCO - VCC1V2_FPGA - IO_L12P_T1U_N10_GC_46
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C2_DQ47"] ;# Bank  46 VCCO - VCC1V2_FPGA - IO_L12P_T1U_N10_GC_46
set_property PACKAGE_PIN BD38     [get_ports "DDR4_C2_DQ42"] ;# Bank  46 VCCO - VCC1V2_FPGA - IO_L12N_T1U_N11_GC_46
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C2_DQ42"] ;# Bank  46 VCCO - VCC1V2_FPGA - IO_L12N_T1U_N11_GC_46
set_property PACKAGE_PIN BC40     [get_ports "GPIO_DIP_SW0"] ;# Bank  46 VCCO - VCC1V2_FPGA - IO_T1U_N12_46
set_property IOSTANDARD  LVCMOS12 [get_ports "GPIO_DIP_SW0"] ;# Bank  46 VCCO - VCC1V2_FPGA - IO_T1U_N12_46
set_property PACKAGE_PIN BB38     [get_ports "DDR4_C2_DQ44"] ;# Bank  46 VCCO - VCC1V2_FPGA - IO_L11P_T1U_N8_GC_46
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C2_DQ44"] ;# Bank  46 VCCO - VCC1V2_FPGA - IO_L11P_T1U_N8_GC_46
set_property PACKAGE_PIN BB39     [get_ports "DDR4_C2_DQ45"] ;# Bank  46 VCCO - VCC1V2_FPGA - IO_L11N_T1U_N9_GC_46
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C2_DQ45"] ;# Bank  46 VCCO - VCC1V2_FPGA - IO_L11N_T1U_N9_GC_46
set_property PACKAGE_PIN BE39     [get_ports "DDR4_C2_DQS5_T"] ;# Bank  46 VCCO - VCC1V2_FPGA - IO_L10P_T1U_N6_QBC_AD4P_46
set_property IOSTANDARD  DIFF_POD12 [get_ports "DDR4_C2_DQS5_T"] ;# Bank  46 VCCO - VCC1V2_FPGA - IO_L10P_T1U_N6_QBC_AD4P_46
set_property PACKAGE_PIN BF39     [get_ports "DDR4_C2_DQS5_C"] ;# Bank  46 VCCO - VCC1V2_FPGA - IO_L10N_T1U_N7_QBC_AD4N_46
set_property IOSTANDARD  DIFF_POD12 [get_ports "DDR4_C2_DQS5_C"] ;# Bank  46 VCCO - VCC1V2_FPGA - IO_L10N_T1U_N7_QBC_AD4N_46
set_property PACKAGE_PIN BC39     [get_ports "DDR4_C2_DQ46"] ;# Bank  46 VCCO - VCC1V2_FPGA - IO_L9P_T1L_N4_AD12P_46
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C2_DQ46"] ;# Bank  46 VCCO - VCC1V2_FPGA - IO_L9P_T1L_N4_AD12P_46
set_property PACKAGE_PIN BD40     [get_ports "DDR4_C2_DQ43"] ;# Bank  46 VCCO - VCC1V2_FPGA - IO_L9N_T1L_N5_AD12N_46
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C2_DQ43"] ;# Bank  46 VCCO - VCC1V2_FPGA - IO_L9N_T1L_N5_AD12N_46
set_property PACKAGE_PIN BD37     [get_ports "DDR4_C2_DQ40"] ;# Bank  46 VCCO - VCC1V2_FPGA - IO_L8P_T1L_N2_AD5P_46
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C2_DQ40"] ;# Bank  46 VCCO - VCC1V2_FPGA - IO_L8P_T1L_N2_AD5P_46
set_property PACKAGE_PIN BE38     [get_ports "DDR4_C2_DQ41"] ;# Bank  46 VCCO - VCC1V2_FPGA - IO_L8N_T1L_N3_AD5N_46
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C2_DQ41"] ;# Bank  46 VCCO - VCC1V2_FPGA - IO_L8N_T1L_N3_AD5N_46
set_property PACKAGE_PIN BE40     [get_ports "DDR4_C2_DM5"] ;# Bank  46 VCCO - VCC1V2_FPGA - IO_L7P_T1L_N0_QBC_AD13P_46
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C2_DM5"] ;# Bank  46 VCCO - VCC1V2_FPGA - IO_L7P_T1L_N0_QBC_AD13P_46
set_property PACKAGE_PIN BF40     [get_ports "DDR4_C2_RESET_B"] ;# Bank  46 VCCO - VCC1V2_FPGA - IO_L7N_T1L_N1_QBC_AD13N_46
set_property IOSTANDARD  LVCMOS12 [get_ports "DDR4_C2_RESET_B"] ;# Bank  46 VCCO - VCC1V2_FPGA - IO_L7N_T1L_N1_QBC_AD13N_46
set_property PACKAGE_PIN BF36     [get_ports "DDR4_C2_DQ33"] ;# Bank  46 VCCO - VCC1V2_FPGA - IO_L6P_T0U_N10_AD6P_46
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C2_DQ33"] ;# Bank  46 VCCO - VCC1V2_FPGA - IO_L6P_T0U_N10_AD6P_46
set_property PACKAGE_PIN BF37     [get_ports "DDR4_C2_DQ38"] ;# Bank  46 VCCO - VCC1V2_FPGA - IO_L6N_T0U_N11_AD6N_46
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C2_DQ38"] ;# Bank  46 VCCO - VCC1V2_FPGA - IO_L6N_T0U_N11_AD6N_46
set_property PACKAGE_PIN BD36     [get_ports "DDR4_C2_DQ37"] ;# Bank  46 VCCO - VCC1V2_FPGA - IO_L5P_T0U_N8_AD14P_46
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C2_DQ37"] ;# Bank  46 VCCO - VCC1V2_FPGA - IO_L5P_T0U_N8_AD14P_46
set_property PACKAGE_PIN BE37     [get_ports "DDR4_C2_DQ35"] ;# Bank  46 VCCO - VCC1V2_FPGA - IO_L5N_T0U_N9_AD14N_46
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C2_DQ35"] ;# Bank  46 VCCO - VCC1V2_FPGA - IO_L5N_T0U_N9_AD14N_46
set_property PACKAGE_PIN BE35     [get_ports "DDR4_C2_DQS4_T"] ;# Bank  46 VCCO - VCC1V2_FPGA - IO_L4P_T0U_N6_DBC_AD7P_46
set_property IOSTANDARD  DIFF_POD12 [get_ports "DDR4_C2_DQS4_T"] ;# Bank  46 VCCO - VCC1V2_FPGA - IO_L4P_T0U_N6_DBC_AD7P_46
set_property PACKAGE_PIN BF35     [get_ports "DDR4_C2_DQS4_C"] ;# Bank  46 VCCO - VCC1V2_FPGA - IO_L4N_T0U_N7_DBC_AD7N_46
set_property IOSTANDARD  DIFF_POD12 [get_ports "DDR4_C2_DQS4_C"] ;# Bank  46 VCCO - VCC1V2_FPGA - IO_L4N_T0U_N7_DBC_AD7N_46
set_property PACKAGE_PIN BC35     [get_ports "DDR4_C2_DQ34"] ;# Bank  46 VCCO - VCC1V2_FPGA - IO_L3P_T0L_N4_AD15P_46
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C2_DQ34"] ;# Bank  46 VCCO - VCC1V2_FPGA - IO_L3P_T0L_N4_AD15P_46
set_property PACKAGE_PIN BC36     [get_ports "DDR4_C2_DQ39"] ;# Bank  46 VCCO - VCC1V2_FPGA - IO_L3N_T0L_N5_AD15N_46
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C2_DQ39"] ;# Bank  46 VCCO - VCC1V2_FPGA - IO_L3N_T0L_N5_AD15N_46
set_property PACKAGE_PIN BE34     [get_ports "DDR4_C2_DQ36"] ;# Bank  46 VCCO - VCC1V2_FPGA - IO_L2P_T0L_N2_46
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C2_DQ36"] ;# Bank  46 VCCO - VCC1V2_FPGA - IO_L2P_T0L_N2_46
set_property PACKAGE_PIN BF34     [get_ports "DDR4_C2_DQ32"] ;# Bank  46 VCCO - VCC1V2_FPGA - IO_L2N_T0L_N3_46
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C2_DQ32"] ;# Bank  46 VCCO - VCC1V2_FPGA - IO_L2N_T0L_N3_46
#set_property PACKAGE_PIN BB34     [get_ports "VRP_46"] ;# Bank  46 VCCO - VCC1V2_FPGA - IO_T0U_N12_VRP_46
#set_property IOSTANDARD  LVCMOSxx [get_ports "VRP_46"] ;# Bank  46 VCCO - VCC1V2_FPGA - IO_T0U_N12_VRP_46
set_property PACKAGE_PIN BC34     [get_ports "DDR4_C2_DM4"] ;# Bank  46 VCCO - VCC1V2_FPGA - IO_L1P_T0L_N0_DBC_46
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C2_DM4"] ;# Bank  46 VCCO - VCC1V2_FPGA - IO_L1P_T0L_N0_DBC_46
#set_property PACKAGE_PIN BD35     [get_ports "6N3735"] ;# Bank  46 VCCO - VCC1V2_FPGA - IO_L1N_T0L_N1_DBC_46
#set_property IOSTANDARD  LVCMOSxx [get_ports "6N3735"] ;# Bank  46 VCCO - VCC1V2_FPGA - IO_L1N_T0L_N1_DBC_46
set_property PACKAGE_PIN AG32     [get_ports "FMC_HPC1_LA33_P"] ;# Bank  47 VCCO - VADJ_1V8_FPGA - IO_L24P_T3U_N10_47
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC1_LA33_P"] ;# Bank  47 VCCO - VADJ_1V8_FPGA - IO_L24P_T3U_N10_47
set_property PACKAGE_PIN AG33     [get_ports "FMC_HPC1_LA33_N"] ;# Bank  47 VCCO - VADJ_1V8_FPGA - IO_L24N_T3U_N11_47
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC1_LA33_N"] ;# Bank  47 VCCO - VADJ_1V8_FPGA - IO_L24N_T3U_N11_47
set_property PACKAGE_PIN AH30     [get_ports "HDMI_R_D13"] ;# Bank  47 VCCO - VADJ_1V8_FPGA - IO_T3U_N12_47
set_property IOSTANDARD  LVCMOS18 [get_ports "HDMI_R_D13"] ;# Bank  47 VCCO - VADJ_1V8_FPGA - IO_T3U_N12_47
set_property PACKAGE_PIN AG31     [get_ports "FMC_HPC1_LA32_P"] ;# Bank  47 VCCO - VADJ_1V8_FPGA - IO_L23P_T3U_N8_47
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC1_LA32_P"] ;# Bank  47 VCCO - VADJ_1V8_FPGA - IO_L23P_T3U_N8_47
set_property PACKAGE_PIN AH31     [get_ports "FMC_HPC1_LA32_N"] ;# Bank  47 VCCO - VADJ_1V8_FPGA - IO_L23N_T3U_N9_47
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC1_LA32_N"] ;# Bank  47 VCCO - VADJ_1V8_FPGA - IO_L23N_T3U_N9_47
set_property PACKAGE_PIN AG34     [get_ports "QSFP_RECCLK_P"] ;# Bank  47 VCCO - VADJ_1V8_FPGA - IO_L22P_T3U_N6_DBC_AD0P_47
set_property IOSTANDARD  LVDS [get_ports "QSFP_RECCLK_P"] ;# Bank  47 VCCO - VADJ_1V8_FPGA - IO_L22P_T3U_N6_DBC_AD0P_47
set_property PACKAGE_PIN AH35     [get_ports "QSFP_RECCLK_N"] ;# Bank  47 VCCO - VADJ_1V8_FPGA - IO_L22N_T3U_N7_DBC_AD0N_47
set_property IOSTANDARD  LVDS [get_ports "QSFP_RECCLK_N"] ;# Bank  47 VCCO - VADJ_1V8_FPGA - IO_L22N_T3U_N7_DBC_AD0N_47
set_property PACKAGE_PIN AH33     [get_ports "HDMI_R_D12"] ;# Bank  47 VCCO - VADJ_1V8_FPGA - IO_L21P_T3L_N4_AD8P_47
set_property IOSTANDARD  LVCMOS18 [get_ports "HDMI_R_D12"] ;# Bank  47 VCCO - VADJ_1V8_FPGA - IO_L21P_T3L_N4_AD8P_47
set_property PACKAGE_PIN AH34     [get_ports "HDMI_R_DE"] ;# Bank  47 VCCO - VADJ_1V8_FPGA - IO_L21N_T3L_N5_AD8N_47
set_property IOSTANDARD  LVCMOS18 [get_ports "HDMI_R_DE"] ;# Bank  47 VCCO - VADJ_1V8_FPGA - IO_L21N_T3L_N5_AD8N_47
set_property PACKAGE_PIN AJ35     [get_ports "HDMI_R_SPDIF"] ;# Bank  47 VCCO - VADJ_1V8_FPGA - IO_L20P_T3L_N2_AD1P_47
set_property IOSTANDARD  LVCMOS18 [get_ports "HDMI_R_SPDIF"] ;# Bank  47 VCCO - VADJ_1V8_FPGA - IO_L20P_T3L_N2_AD1P_47
set_property PACKAGE_PIN AJ36     [get_ports "HDMI_SPDIF_OUT_LS"] ;# Bank  47 VCCO - VADJ_1V8_FPGA - IO_L20N_T3L_N3_AD1N_47
set_property IOSTANDARD  LVCMOS18 [get_ports "HDMI_SPDIF_OUT_LS"] ;# Bank  47 VCCO - VADJ_1V8_FPGA - IO_L20N_T3L_N3_AD1N_47
set_property PACKAGE_PIN AJ33     [get_ports "HDMI_INT"] ;# Bank  47 VCCO - VADJ_1V8_FPGA - IO_L19P_T3L_N0_DBC_AD9P_47
set_property IOSTANDARD  LVCMOS18 [get_ports "HDMI_INT"] ;# Bank  47 VCCO - VADJ_1V8_FPGA - IO_L19P_T3L_N0_DBC_AD9P_47
set_property PACKAGE_PIN AK33     [get_ports "HDMI_R_CLK"] ;# Bank  47 VCCO - VADJ_1V8_FPGA - IO_L19N_T3L_N1_DBC_AD9N_47
set_property IOSTANDARD  LVCMOS18 [get_ports "HDMI_R_CLK"] ;# Bank  47 VCCO - VADJ_1V8_FPGA - IO_L19N_T3L_N1_DBC_AD9N_47
set_property PACKAGE_PIN AK29     [get_ports "HDMI_R_HSYNC"] ;# Bank  47 VCCO - VADJ_1V8_FPGA - IO_L18P_T2U_N10_AD2P_47
set_property IOSTANDARD  LVCMOS18 [get_ports "HDMI_R_HSYNC"] ;# Bank  47 VCCO - VADJ_1V8_FPGA - IO_L18P_T2U_N10_AD2P_47
set_property PACKAGE_PIN AK30     [get_ports "HDMI_R_VSYNC"] ;# Bank  47 VCCO - VADJ_1V8_FPGA - IO_L18N_T2U_N11_AD2N_47
set_property IOSTANDARD  LVCMOS18 [get_ports "HDMI_R_VSYNC"] ;# Bank  47 VCCO - VADJ_1V8_FPGA - IO_L18N_T2U_N11_AD2N_47
set_property PACKAGE_PIN AJ30     [get_ports "FMC_HPC1_LA30_P"] ;# Bank  47 VCCO - VADJ_1V8_FPGA - IO_L17P_T2U_N8_AD10P_47
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC1_LA30_P"] ;# Bank  47 VCCO - VADJ_1V8_FPGA - IO_L17P_T2U_N8_AD10P_47
set_property PACKAGE_PIN AJ31     [get_ports "FMC_HPC1_LA30_N"] ;# Bank  47 VCCO - VADJ_1V8_FPGA - IO_L17N_T2U_N9_AD10N_47
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC1_LA30_N"] ;# Bank  47 VCCO - VADJ_1V8_FPGA - IO_L17N_T2U_N9_AD10N_47
set_property PACKAGE_PIN AL30     [get_ports "FMC_HPC1_LA22_P"] ;# Bank  47 VCCO - VADJ_1V8_FPGA - IO_L16P_T2U_N6_QBC_AD3P_47
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC1_LA22_P"] ;# Bank  47 VCCO - VADJ_1V8_FPGA - IO_L16P_T2U_N6_QBC_AD3P_47
set_property PACKAGE_PIN AL31     [get_ports "FMC_HPC1_LA22_N"] ;# Bank  47 VCCO - VADJ_1V8_FPGA - IO_L16N_T2U_N7_QBC_AD3N_47
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC1_LA22_N"] ;# Bank  47 VCCO - VADJ_1V8_FPGA - IO_L16N_T2U_N7_QBC_AD3N_47
set_property PACKAGE_PIN AL29     [get_ports "FMC_HPC1_LA26_P"] ;# Bank  47 VCCO - VADJ_1V8_FPGA - IO_L15P_T2L_N4_AD11P_47
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC1_LA26_P"] ;# Bank  47 VCCO - VADJ_1V8_FPGA - IO_L15P_T2L_N4_AD11P_47
set_property PACKAGE_PIN AM29     [get_ports "FMC_HPC1_LA26_N"] ;# Bank  47 VCCO - VADJ_1V8_FPGA - IO_L15N_T2L_N5_AD11N_47
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC1_LA26_N"] ;# Bank  47 VCCO - VADJ_1V8_FPGA - IO_L15N_T2L_N5_AD11N_47
set_property PACKAGE_PIN AJ32     [get_ports "FMC_HPC1_LA17_CC_P"] ;# Bank  47 VCCO - VADJ_1V8_FPGA - IO_L14P_T2L_N2_GC_47
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC1_LA17_CC_P"] ;# Bank  47 VCCO - VADJ_1V8_FPGA - IO_L14P_T2L_N2_GC_47
set_property PACKAGE_PIN AK32     [get_ports "FMC_HPC1_LA17_CC_N"] ;# Bank  47 VCCO - VADJ_1V8_FPGA - IO_L14N_T2L_N3_GC_47
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC1_LA17_CC_N"] ;# Bank  47 VCCO - VADJ_1V8_FPGA - IO_L14N_T2L_N3_GC_47
set_property PACKAGE_PIN AM31     [get_ports "HDMI_R_D15"] ;# Bank  47 VCCO - VADJ_1V8_FPGA - IO_T2U_N12_47
set_property IOSTANDARD  LVCMOS18 [get_ports "HDMI_R_D15"] ;# Bank  47 VCCO - VADJ_1V8_FPGA - IO_T2U_N12_47
set_property PACKAGE_PIN AL32     [get_ports "FMC_HPC1_LA18_CC_P"] ;# Bank  47 VCCO - VADJ_1V8_FPGA - IO_L13P_T2L_N0_GC_QBC_47
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC1_LA18_CC_P"] ;# Bank  47 VCCO - VADJ_1V8_FPGA - IO_L13P_T2L_N0_GC_QBC_47
set_property PACKAGE_PIN AM32     [get_ports "FMC_HPC1_LA18_CC_N"] ;# Bank  47 VCCO - VADJ_1V8_FPGA - IO_L13N_T2L_N1_GC_QBC_47
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC1_LA18_CC_N"] ;# Bank  47 VCCO - VADJ_1V8_FPGA - IO_L13N_T2L_N1_GC_QBC_47
set_property PACKAGE_PIN AM33     [get_ports "HDMI_R_D14"] ;# Bank  47 VCCO - VADJ_1V8_FPGA - IO_L12P_T1U_N10_GC_47
set_property IOSTANDARD  LVCMOS18 [get_ports "HDMI_R_D14"] ;# Bank  47 VCCO - VADJ_1V8_FPGA - IO_L12P_T1U_N10_GC_47
set_property PACKAGE_PIN AM34     [get_ports "HDMI_R_D16"] ;# Bank  47 VCCO - VADJ_1V8_FPGA - IO_L12N_T1U_N11_GC_47
set_property IOSTANDARD  LVCMOS18 [get_ports "HDMI_R_D16"] ;# Bank  47 VCCO - VADJ_1V8_FPGA - IO_L12N_T1U_N11_GC_47
set_property PACKAGE_PIN AK35     [get_ports "HDMI_R_D17"] ;# Bank  47 VCCO - VADJ_1V8_FPGA - IO_T1U_N12_47
set_property IOSTANDARD  LVCMOS18 [get_ports "HDMI_R_D17"] ;# Bank  47 VCCO - VADJ_1V8_FPGA - IO_T1U_N12_47
set_property PACKAGE_PIN AK34     [get_ports "FMC_HPC1_CLK1_M2C_P"] ;# Bank  47 VCCO - VADJ_1V8_FPGA - IO_L11P_T1U_N8_GC_47
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC1_CLK1_M2C_P"] ;# Bank  47 VCCO - VADJ_1V8_FPGA - IO_L11P_T1U_N8_GC_47
set_property PACKAGE_PIN AL34     [get_ports "FMC_HPC1_CLK1_M2C_N"] ;# Bank  47 VCCO - VADJ_1V8_FPGA - IO_L11N_T1U_N9_GC_47
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC1_CLK1_M2C_N"] ;# Bank  47 VCCO - VADJ_1V8_FPGA - IO_L11N_T1U_N9_GC_47
set_property PACKAGE_PIN AN33     [get_ports "FMC_HPC1_LA23_P"] ;# Bank  47 VCCO - VADJ_1V8_FPGA - IO_L10P_T1U_N6_QBC_AD4P_47
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC1_LA23_P"] ;# Bank  47 VCCO - VADJ_1V8_FPGA - IO_L10P_T1U_N6_QBC_AD4P_47
set_property PACKAGE_PIN AP33     [get_ports "FMC_HPC1_LA23_N"] ;# Bank  47 VCCO - VADJ_1V8_FPGA - IO_L10N_T1U_N7_QBC_AD4N_47
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC1_LA23_N"] ;# Bank  47 VCCO - VADJ_1V8_FPGA - IO_L10N_T1U_N7_QBC_AD4N_47
set_property PACKAGE_PIN AM36     [get_ports "FMC_HPC1_LA24_P"] ;# Bank  47 VCCO - VADJ_1V8_FPGA - IO_L9P_T1L_N4_AD12P_47
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC1_LA24_P"] ;# Bank  47 VCCO - VADJ_1V8_FPGA - IO_L9P_T1L_N4_AD12P_47
set_property PACKAGE_PIN AN36     [get_ports "FMC_HPC1_LA24_N"] ;# Bank  47 VCCO - VADJ_1V8_FPGA - IO_L9N_T1L_N5_AD12N_47
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC1_LA24_N"] ;# Bank  47 VCCO - VADJ_1V8_FPGA - IO_L9N_T1L_N5_AD12N_47
set_property PACKAGE_PIN AN34     [get_ports "FMC_HPC1_LA31_P"] ;# Bank  47 VCCO - VADJ_1V8_FPGA - IO_L8P_T1L_N2_AD5P_47
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC1_LA31_P"] ;# Bank  47 VCCO - VADJ_1V8_FPGA - IO_L8P_T1L_N2_AD5P_47
set_property PACKAGE_PIN AN35     [get_ports "FMC_HPC1_LA31_N"] ;# Bank  47 VCCO - VADJ_1V8_FPGA - IO_L8N_T1L_N3_AD5N_47
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC1_LA31_N"] ;# Bank  47 VCCO - VADJ_1V8_FPGA - IO_L8N_T1L_N3_AD5N_47
set_property PACKAGE_PIN AL35     [get_ports "FMC_HPC1_LA28_P"] ;# Bank  47 VCCO - VADJ_1V8_FPGA - IO_L7P_T1L_N0_QBC_AD13P_47
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC1_LA28_P"] ;# Bank  47 VCCO - VADJ_1V8_FPGA - IO_L7P_T1L_N0_QBC_AD13P_47
set_property PACKAGE_PIN AL36     [get_ports "FMC_HPC1_LA28_N"] ;# Bank  47 VCCO - VADJ_1V8_FPGA - IO_L7N_T1L_N1_QBC_AD13N_47
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC1_LA28_N"] ;# Bank  47 VCCO - VADJ_1V8_FPGA - IO_L7N_T1L_N1_QBC_AD13N_47
set_property PACKAGE_PIN AR37     [get_ports "FMC_HPC1_LA20_P"] ;# Bank  47 VCCO - VADJ_1V8_FPGA - IO_L6P_T0U_N10_AD6P_47
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC1_LA20_P"] ;# Bank  47 VCCO - VADJ_1V8_FPGA - IO_L6P_T0U_N10_AD6P_47
set_property PACKAGE_PIN AT37     [get_ports "FMC_HPC1_LA20_N"] ;# Bank  47 VCCO - VADJ_1V8_FPGA - IO_L6N_T0U_N11_AD6N_47
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC1_LA20_N"] ;# Bank  47 VCCO - VADJ_1V8_FPGA - IO_L6N_T0U_N11_AD6N_47
set_property PACKAGE_PIN AP36     [get_ports "FMC_HPC1_LA25_P"] ;# Bank  47 VCCO - VADJ_1V8_FPGA - IO_L5P_T0U_N8_AD14P_47
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC1_LA25_P"] ;# Bank  47 VCCO - VADJ_1V8_FPGA - IO_L5P_T0U_N8_AD14P_47
set_property PACKAGE_PIN AP37     [get_ports "FMC_HPC1_LA25_N"] ;# Bank  47 VCCO - VADJ_1V8_FPGA - IO_L5N_T0U_N9_AD14N_47
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC1_LA25_N"] ;# Bank  47 VCCO - VADJ_1V8_FPGA - IO_L5N_T0U_N9_AD14N_47
set_property PACKAGE_PIN AT39     [get_ports "FMC_HPC1_LA19_P"] ;# Bank  47 VCCO - VADJ_1V8_FPGA - IO_L4P_T0U_N6_DBC_AD7P_47
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC1_LA19_P"] ;# Bank  47 VCCO - VADJ_1V8_FPGA - IO_L4P_T0U_N6_DBC_AD7P_47
set_property PACKAGE_PIN AT40     [get_ports "FMC_HPC1_LA19_N"] ;# Bank  47 VCCO - VADJ_1V8_FPGA - IO_L4N_T0U_N7_DBC_AD7N_47
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC1_LA19_N"] ;# Bank  47 VCCO - VADJ_1V8_FPGA - IO_L4N_T0U_N7_DBC_AD7N_47
set_property PACKAGE_PIN AP35     [get_ports "FMC_HPC1_LA27_P"] ;# Bank  47 VCCO - VADJ_1V8_FPGA - IO_L3P_T0L_N4_AD15P_47
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC1_LA27_P"] ;# Bank  47 VCCO - VADJ_1V8_FPGA - IO_L3P_T0L_N4_AD15P_47
set_property PACKAGE_PIN AR35     [get_ports "FMC_HPC1_LA27_N"] ;# Bank  47 VCCO - VADJ_1V8_FPGA - IO_L3N_T0L_N5_AD15N_47
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC1_LA27_N"] ;# Bank  47 VCCO - VADJ_1V8_FPGA - IO_L3N_T0L_N5_AD15N_47
set_property PACKAGE_PIN AT35     [get_ports "FMC_HPC1_LA21_P"] ;# Bank  47 VCCO - VADJ_1V8_FPGA - IO_L2P_T0L_N2_47
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC1_LA21_P"] ;# Bank  47 VCCO - VADJ_1V8_FPGA - IO_L2P_T0L_N2_47
set_property PACKAGE_PIN AT36     [get_ports "FMC_HPC1_LA21_N"] ;# Bank  47 VCCO - VADJ_1V8_FPGA - IO_L2N_T0L_N3_47
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC1_LA21_N"] ;# Bank  47 VCCO - VADJ_1V8_FPGA - IO_L2N_T0L_N3_47
#set_property PACKAGE_PIN AR34     [get_ports "VRP_47"] ;# Bank  47 VCCO - VADJ_1V8_FPGA - IO_T0U_N12_VRP_47
#set_property IOSTANDARD  LVCMOSxx [get_ports "VRP_47"] ;# Bank  47 VCCO - VADJ_1V8_FPGA - IO_T0U_N12_VRP_47
set_property PACKAGE_PIN AP38     [get_ports "FMC_HPC1_LA29_P"] ;# Bank  47 VCCO - VADJ_1V8_FPGA - IO_L1P_T0L_N0_DBC_47
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC1_LA29_P"] ;# Bank  47 VCCO - VADJ_1V8_FPGA - IO_L1P_T0L_N0_DBC_47
set_property PACKAGE_PIN AR38     [get_ports "FMC_HPC1_LA29_N"] ;# Bank  47 VCCO - VADJ_1V8_FPGA - IO_L1N_T0L_N1_DBC_47
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC1_LA29_N"] ;# Bank  47 VCCO - VADJ_1V8_FPGA - IO_L1N_T0L_N1_DBC_47
set_property PACKAGE_PIN M35      [get_ports "FMC_HPC1_LA08_P"] ;# Bank  48 VCCO - VADJ_1V8_FPGA - IO_L24P_T3U_N10_48
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC1_LA08_P"] ;# Bank  48 VCCO - VADJ_1V8_FPGA - IO_L24P_T3U_N10_48
set_property PACKAGE_PIN L35      [get_ports "FMC_HPC1_LA08_N"] ;# Bank  48 VCCO - VADJ_1V8_FPGA - IO_L24N_T3U_N11_48
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC1_LA08_N"] ;# Bank  48 VCCO - VADJ_1V8_FPGA - IO_L24N_T3U_N11_48
#set_property PACKAGE_PIN K36      [get_ports "7N3527"] ;# Bank  48 VCCO - VADJ_1V8_FPGA - IO_T3U_N12_48
#set_property IOSTANDARD  LVCMOSxx [get_ports "7N3527"] ;# Bank  48 VCCO - VADJ_1V8_FPGA - IO_T3U_N12_48
set_property PACKAGE_PIN N32      [get_ports "FMC_HPC1_LA10_P"] ;# Bank  48 VCCO - VADJ_1V8_FPGA - IO_L23P_T3U_N8_48
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC1_LA10_P"] ;# Bank  48 VCCO - VADJ_1V8_FPGA - IO_L23P_T3U_N8_48
set_property PACKAGE_PIN M32      [get_ports "FMC_HPC1_LA10_N"] ;# Bank  48 VCCO - VADJ_1V8_FPGA - IO_L23N_T3U_N9_48
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC1_LA10_N"] ;# Bank  48 VCCO - VADJ_1V8_FPGA - IO_L23N_T3U_N9_48
set_property PACKAGE_PIN N33      [get_ports "FMC_HPC1_LA02_P"] ;# Bank  48 VCCO - VADJ_1V8_FPGA - IO_L22P_T3U_N6_DBC_AD0P_48
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC1_LA02_P"] ;# Bank  48 VCCO - VADJ_1V8_FPGA - IO_L22P_T3U_N6_DBC_AD0P_48
set_property PACKAGE_PIN M33      [get_ports "FMC_HPC1_LA02_N"] ;# Bank  48 VCCO - VADJ_1V8_FPGA - IO_L22N_T3U_N7_DBC_AD0N_48
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC1_LA02_N"] ;# Bank  48 VCCO - VADJ_1V8_FPGA - IO_L22N_T3U_N7_DBC_AD0N_48
set_property PACKAGE_PIN L33      [get_ports "FMC_HPC1_LA14_P"] ;# Bank  48 VCCO - VADJ_1V8_FPGA - IO_L21P_T3L_N4_AD8P_48
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC1_LA14_P"] ;# Bank  48 VCCO - VADJ_1V8_FPGA - IO_L21P_T3L_N4_AD8P_48
set_property PACKAGE_PIN K33      [get_ports "FMC_HPC1_LA14_N"] ;# Bank  48 VCCO - VADJ_1V8_FPGA - IO_L21N_T3L_N5_AD8N_48
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC1_LA14_N"] ;# Bank  48 VCCO - VADJ_1V8_FPGA - IO_L21N_T3L_N5_AD8N_48
set_property PACKAGE_PIN N34      [get_ports "FMC_HPC1_LA03_P"] ;# Bank  48 VCCO - VADJ_1V8_FPGA - IO_L20P_T3L_N2_AD1P_48
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC1_LA03_P"] ;# Bank  48 VCCO - VADJ_1V8_FPGA - IO_L20P_T3L_N2_AD1P_48
set_property PACKAGE_PIN N35      [get_ports "FMC_HPC1_LA03_N"] ;# Bank  48 VCCO - VADJ_1V8_FPGA - IO_L20N_T3L_N3_AD1N_48
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC1_LA03_N"] ;# Bank  48 VCCO - VADJ_1V8_FPGA - IO_L20N_T3L_N3_AD1N_48
set_property PACKAGE_PIN L34      [get_ports "FMC_HPC1_LA07_P"] ;# Bank  48 VCCO - VADJ_1V8_FPGA - IO_L19P_T3L_N0_DBC_AD9P_48
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC1_LA07_P"] ;# Bank  48 VCCO - VADJ_1V8_FPGA - IO_L19P_T3L_N0_DBC_AD9P_48
set_property PACKAGE_PIN K34      [get_ports "FMC_HPC1_LA07_N"] ;# Bank  48 VCCO - VADJ_1V8_FPGA - IO_L19N_T3L_N1_DBC_AD9N_48
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC1_LA07_N"] ;# Bank  48 VCCO - VADJ_1V8_FPGA - IO_L19N_T3L_N1_DBC_AD9N_48
set_property PACKAGE_PIN N38      [get_ports "FMC_HPC1_LA05_P"] ;# Bank  48 VCCO - VADJ_1V8_FPGA - IO_L18P_T2U_N10_AD2P_48
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC1_LA05_P"] ;# Bank  48 VCCO - VADJ_1V8_FPGA - IO_L18P_T2U_N10_AD2P_48
set_property PACKAGE_PIN M38      [get_ports "FMC_HPC1_LA05_N"] ;# Bank  48 VCCO - VADJ_1V8_FPGA - IO_L18N_T2U_N11_AD2N_48
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC1_LA05_N"] ;# Bank  48 VCCO - VADJ_1V8_FPGA - IO_L18N_T2U_N11_AD2N_48
set_property PACKAGE_PIN M36      [get_ports "FMC_HPC1_LA09_P"] ;# Bank  48 VCCO - VADJ_1V8_FPGA - IO_L17P_T2U_N8_AD10P_48
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC1_LA09_P"] ;# Bank  48 VCCO - VADJ_1V8_FPGA - IO_L17P_T2U_N8_AD10P_48
set_property PACKAGE_PIN L36      [get_ports "FMC_HPC1_LA09_N"] ;# Bank  48 VCCO - VADJ_1V8_FPGA - IO_L17N_T2U_N9_AD10N_48
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC1_LA09_N"] ;# Bank  48 VCCO - VADJ_1V8_FPGA - IO_L17N_T2U_N9_AD10N_48
set_property PACKAGE_PIN P37      [get_ports "FMC_HPC1_LA06_P"] ;# Bank  48 VCCO - VADJ_1V8_FPGA - IO_L16P_T2U_N6_QBC_AD3P_48
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC1_LA06_P"] ;# Bank  48 VCCO - VADJ_1V8_FPGA - IO_L16P_T2U_N6_QBC_AD3P_48
set_property PACKAGE_PIN N37      [get_ports "FMC_HPC1_LA06_N"] ;# Bank  48 VCCO - VADJ_1V8_FPGA - IO_L16N_T2U_N7_QBC_AD3N_48
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC1_LA06_N"] ;# Bank  48 VCCO - VADJ_1V8_FPGA - IO_L16N_T2U_N7_QBC_AD3N_48
set_property PACKAGE_PIN M37      [get_ports "FMC_HPC1_LA04_P"] ;# Bank  48 VCCO - VADJ_1V8_FPGA - IO_L15P_T2L_N4_AD11P_48
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC1_LA04_P"] ;# Bank  48 VCCO - VADJ_1V8_FPGA - IO_L15P_T2L_N4_AD11P_48
set_property PACKAGE_PIN L38      [get_ports "FMC_HPC1_LA04_N"] ;# Bank  48 VCCO - VADJ_1V8_FPGA - IO_L15N_T2L_N5_AD11N_48
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC1_LA04_N"] ;# Bank  48 VCCO - VADJ_1V8_FPGA - IO_L15N_T2L_N5_AD11N_48
set_property PACKAGE_PIN P35      [get_ports "FMC_HPC1_LA01_CC_P"] ;# Bank  48 VCCO - VADJ_1V8_FPGA - IO_L14P_T2L_N2_GC_48
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC1_LA01_CC_P"] ;# Bank  48 VCCO - VADJ_1V8_FPGA - IO_L14P_T2L_N2_GC_48
set_property PACKAGE_PIN P36      [get_ports "FMC_HPC1_LA01_CC_N"] ;# Bank  48 VCCO - VADJ_1V8_FPGA - IO_L14N_T2L_N3_GC_48
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC1_LA01_CC_N"] ;# Bank  48 VCCO - VADJ_1V8_FPGA - IO_L14N_T2L_N3_GC_48
set_property PACKAGE_PIN R36      [get_ports "HDMI_R_D0"] ;# Bank  48 VCCO - VADJ_1V8_FPGA - IO_T2U_N12_48
set_property IOSTANDARD  LVCMOS18 [get_ports "HDMI_R_D0"] ;# Bank  48 VCCO - VADJ_1V8_FPGA - IO_T2U_N12_48
set_property PACKAGE_PIN R34      [get_ports "HDMI_R_D1"] ;# Bank  48 VCCO - VADJ_1V8_FPGA - IO_L13P_T2L_N0_GC_QBC_48
set_property IOSTANDARD  LVCMOS18 [get_ports "HDMI_R_D1"] ;# Bank  48 VCCO - VADJ_1V8_FPGA - IO_L13P_T2L_N0_GC_QBC_48
set_property PACKAGE_PIN P34      [get_ports "HDMI_R_D2"] ;# Bank  48 VCCO - VADJ_1V8_FPGA - IO_L13N_T2L_N1_GC_QBC_48
set_property IOSTANDARD  LVCMOS18 [get_ports "HDMI_R_D2"] ;# Bank  48 VCCO - VADJ_1V8_FPGA - IO_L13N_T2L_N1_GC_QBC_48
set_property PACKAGE_PIN T33      [get_ports "FMC_HPC1_LA00_CC_P"] ;# Bank  48 VCCO - VADJ_1V8_FPGA - IO_L12P_T1U_N10_GC_48
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC1_LA00_CC_P"] ;# Bank  48 VCCO - VADJ_1V8_FPGA - IO_L12P_T1U_N10_GC_48
set_property PACKAGE_PIN R33      [get_ports "FMC_HPC1_LA00_CC_N"] ;# Bank  48 VCCO - VADJ_1V8_FPGA - IO_L12N_T1U_N11_GC_48
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC1_LA00_CC_N"] ;# Bank  48 VCCO - VADJ_1V8_FPGA - IO_L12N_T1U_N11_GC_48
set_property PACKAGE_PIN V30      [get_ports "HDMI_R_D3"] ;# Bank  48 VCCO - VADJ_1V8_FPGA - IO_T1U_N12_48
set_property IOSTANDARD  LVCMOS18 [get_ports "HDMI_R_D3"] ;# Bank  48 VCCO - VADJ_1V8_FPGA - IO_T1U_N12_48
set_property PACKAGE_PIN R32      [get_ports "FMC_HPC1_CLK0_M2C_P"] ;# Bank  48 VCCO - VADJ_1V8_FPGA - IO_L11P_T1U_N8_GC_48
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC1_CLK0_M2C_P"] ;# Bank  48 VCCO - VADJ_1V8_FPGA - IO_L11P_T1U_N8_GC_48
set_property PACKAGE_PIN P32      [get_ports "FMC_HPC1_CLK0_M2C_N"] ;# Bank  48 VCCO - VADJ_1V8_FPGA - IO_L11N_T1U_N9_GC_48
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC1_CLK0_M2C_N"] ;# Bank  48 VCCO - VADJ_1V8_FPGA - IO_L11N_T1U_N9_GC_48
set_property PACKAGE_PIN R31      [get_ports "FMC_HPC1_LA12_P"] ;# Bank  48 VCCO - VADJ_1V8_FPGA - IO_L10P_T1U_N6_QBC_AD4P_48
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC1_LA12_P"] ;# Bank  48 VCCO - VADJ_1V8_FPGA - IO_L10P_T1U_N6_QBC_AD4P_48
set_property PACKAGE_PIN P31      [get_ports "FMC_HPC1_LA12_N"] ;# Bank  48 VCCO - VADJ_1V8_FPGA - IO_L10N_T1U_N7_QBC_AD4N_48
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC1_LA12_N"] ;# Bank  48 VCCO - VADJ_1V8_FPGA - IO_L10N_T1U_N7_QBC_AD4N_48
set_property PACKAGE_PIN Y31      [get_ports "FMC_HPC1_LA11_P"] ;# Bank  48 VCCO - VADJ_1V8_FPGA - IO_L9P_T1L_N4_AD12P_48
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC1_LA11_P"] ;# Bank  48 VCCO - VADJ_1V8_FPGA - IO_L9P_T1L_N4_AD12P_48
set_property PACKAGE_PIN W31      [get_ports "FMC_HPC1_LA11_N"] ;# Bank  48 VCCO - VADJ_1V8_FPGA - IO_L9N_T1L_N5_AD12N_48
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC1_LA11_N"] ;# Bank  48 VCCO - VADJ_1V8_FPGA - IO_L9N_T1L_N5_AD12N_48
set_property PACKAGE_PIN U31      [get_ports "FMC_HPC1_LA16_P"] ;# Bank  48 VCCO - VADJ_1V8_FPGA - IO_L8P_T1L_N2_AD5P_48
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC1_LA16_P"] ;# Bank  48 VCCO - VADJ_1V8_FPGA - IO_L8P_T1L_N2_AD5P_48
set_property PACKAGE_PIN U32      [get_ports "FMC_HPC1_LA16_N"] ;# Bank  48 VCCO - VADJ_1V8_FPGA - IO_L8N_T1L_N3_AD5N_48
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC1_LA16_N"] ;# Bank  48 VCCO - VADJ_1V8_FPGA - IO_L8N_T1L_N3_AD5N_48
set_property PACKAGE_PIN T30      [get_ports "FMC_HPC1_LA13_P"] ;# Bank  48 VCCO - VADJ_1V8_FPGA - IO_L7P_T1L_N0_QBC_AD13P_48
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC1_LA13_P"] ;# Bank  48 VCCO - VADJ_1V8_FPGA - IO_L7P_T1L_N0_QBC_AD13P_48
set_property PACKAGE_PIN T31      [get_ports "FMC_HPC1_LA13_N"] ;# Bank  48 VCCO - VADJ_1V8_FPGA - IO_L7N_T1L_N1_QBC_AD13N_48
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC1_LA13_N"] ;# Bank  48 VCCO - VADJ_1V8_FPGA - IO_L7N_T1L_N1_QBC_AD13N_48
set_property PACKAGE_PIN T34      [get_ports "FMC_HPC1_LA15_P"] ;# Bank  48 VCCO - VADJ_1V8_FPGA - IO_L6P_T0U_N10_AD6P_48
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC1_LA15_P"] ;# Bank  48 VCCO - VADJ_1V8_FPGA - IO_L6P_T0U_N10_AD6P_48
set_property PACKAGE_PIN T35      [get_ports "FMC_HPC1_LA15_N"] ;# Bank  48 VCCO - VADJ_1V8_FPGA - IO_L6N_T0U_N11_AD6N_48
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC1_LA15_N"] ;# Bank  48 VCCO - VADJ_1V8_FPGA - IO_L6N_T0U_N11_AD6N_48
set_property PACKAGE_PIN V33      [get_ports "HDMI_R_D4"] ;# Bank  48 VCCO - VADJ_1V8_FPGA - IO_L5P_T0U_N8_AD14P_48
set_property IOSTANDARD  LVCMOS18 [get_ports "HDMI_R_D4"] ;# Bank  48 VCCO - VADJ_1V8_FPGA - IO_L5P_T0U_N8_AD14P_48
set_property PACKAGE_PIN V34      [get_ports "HDMI_R_D5"] ;# Bank  48 VCCO - VADJ_1V8_FPGA - IO_L5N_T0U_N9_AD14N_48
set_property IOSTANDARD  LVCMOS18 [get_ports "HDMI_R_D5"] ;# Bank  48 VCCO - VADJ_1V8_FPGA - IO_L5N_T0U_N9_AD14N_48
set_property PACKAGE_PIN U35      [get_ports "HDMI_R_D6"] ;# Bank  48 VCCO - VADJ_1V8_FPGA - IO_L4P_T0U_N6_DBC_AD7P_48
set_property IOSTANDARD  LVCMOS18 [get_ports "HDMI_R_D6"] ;# Bank  48 VCCO - VADJ_1V8_FPGA - IO_L4P_T0U_N6_DBC_AD7P_48
set_property PACKAGE_PIN T36      [get_ports "HDMI_R_D7"] ;# Bank  48 VCCO - VADJ_1V8_FPGA - IO_L4N_T0U_N7_DBC_AD7N_48
set_property IOSTANDARD  LVCMOS18 [get_ports "HDMI_R_D7"] ;# Bank  48 VCCO - VADJ_1V8_FPGA - IO_L4N_T0U_N7_DBC_AD7N_48
set_property PACKAGE_PIN Y34      [get_ports "HDMI_R_D8"] ;# Bank  48 VCCO - VADJ_1V8_FPGA - IO_L3P_T0L_N4_AD15P_48
set_property IOSTANDARD  LVCMOS18 [get_ports "HDMI_R_D8"] ;# Bank  48 VCCO - VADJ_1V8_FPGA - IO_L3P_T0L_N4_AD15P_48
set_property PACKAGE_PIN W34      [get_ports "HDMI_R_D9"] ;# Bank  48 VCCO - VADJ_1V8_FPGA - IO_L3N_T0L_N5_AD15N_48
set_property IOSTANDARD  LVCMOS18 [get_ports "HDMI_R_D9"] ;# Bank  48 VCCO - VADJ_1V8_FPGA - IO_L3N_T0L_N5_AD15N_48
set_property PACKAGE_PIN V32      [get_ports "HDMI_R_D10"] ;# Bank  48 VCCO - VADJ_1V8_FPGA - IO_L2P_T0L_N2_48
set_property IOSTANDARD  LVCMOS18 [get_ports "HDMI_R_D10"] ;# Bank  48 VCCO - VADJ_1V8_FPGA - IO_L2P_T0L_N2_48
set_property PACKAGE_PIN U33      [get_ports "HDMI_R_D11"] ;# Bank  48 VCCO - VADJ_1V8_FPGA - IO_L2N_T0L_N3_48
set_property IOSTANDARD  LVCMOS18 [get_ports "HDMI_R_D11"] ;# Bank  48 VCCO - VADJ_1V8_FPGA - IO_L2N_T0L_N3_48
#set_property PACKAGE_PIN Y33      [get_ports "VRP_48"] ;# Bank  48 VCCO - VADJ_1V8_FPGA - IO_T0U_N12_VRP_48
#set_property IOSTANDARD  LVCMOSxx [get_ports "VRP_48"] ;# Bank  48 VCCO - VADJ_1V8_FPGA - IO_T0U_N12_VRP_48
set_property PACKAGE_PIN Y32      [get_ports "CFP2_RECCLK_P"] ;# Bank  48 VCCO - VADJ_1V8_FPGA - IO_L1P_T0L_N0_DBC_48
set_property IOSTANDARD  LVDS [get_ports "CFP2_RECCLK_P"] ;# Bank  48 VCCO - VADJ_1V8_FPGA - IO_L1P_T0L_N0_DBC_48
set_property PACKAGE_PIN W32      [get_ports "CFP2_RECCLK_N"] ;# Bank  48 VCCO - VADJ_1V8_FPGA - IO_L1N_T0L_N1_DBC_48
set_property IOSTANDARD  LVDS [get_ports "CFP2_RECCLK_N"] ;# Bank  48 VCCO - VADJ_1V8_FPGA - IO_L1N_T0L_N1_DBC_48
set_property PACKAGE_PIN A34      [get_ports "DDR4_C1_DQ25"] ;# Bank  49 VCCO - VCC1V2_FPGA - IO_L24P_T3U_N10_49
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C1_DQ25"] ;# Bank  49 VCCO - VCC1V2_FPGA - IO_L24P_T3U_N10_49
set_property PACKAGE_PIN A35      [get_ports "DDR4_C1_DQ27"] ;# Bank  49 VCCO - VCC1V2_FPGA - IO_L24N_T3U_N11_49
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C1_DQ27"] ;# Bank  49 VCCO - VCC1V2_FPGA - IO_L24N_T3U_N11_49
#set_property PACKAGE_PIN D36      [get_ports "5329N1260"] ;# Bank  49 VCCO - VCC1V2_FPGA - IO_T3U_N12_49
#set_property IOSTANDARD  LVCMOSxx [get_ports "5329N1260"] ;# Bank  49 VCCO - VCC1V2_FPGA - IO_T3U_N12_49
set_property PACKAGE_PIN B35      [get_ports "DDR4_C1_DQ30"] ;# Bank  49 VCCO - VCC1V2_FPGA - IO_L23P_T3U_N8_49
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C1_DQ30"] ;# Bank  49 VCCO - VCC1V2_FPGA - IO_L23P_T3U_N8_49
set_property PACKAGE_PIN A36      [get_ports "DDR4_C1_DQ28"] ;# Bank  49 VCCO - VCC1V2_FPGA - IO_L23N_T3U_N9_49
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C1_DQ28"] ;# Bank  49 VCCO - VCC1V2_FPGA - IO_L23N_T3U_N9_49
set_property PACKAGE_PIN B36      [get_ports "DDR4_C1_DQS3_T"] ;# Bank  49 VCCO - VCC1V2_FPGA - IO_L22P_T3U_N6_DBC_AD0P_49
set_property IOSTANDARD  DIFF_POD12 [get_ports "DDR4_C1_DQS3_T"] ;# Bank  49 VCCO - VCC1V2_FPGA - IO_L22P_T3U_N6_DBC_AD0P_49
set_property PACKAGE_PIN B37      [get_ports "DDR4_C1_DQS3_C"] ;# Bank  49 VCCO - VCC1V2_FPGA - IO_L22N_T3U_N7_DBC_AD0N_49
set_property IOSTANDARD  DIFF_POD12 [get_ports "DDR4_C1_DQS3_C"] ;# Bank  49 VCCO - VCC1V2_FPGA - IO_L22N_T3U_N7_DBC_AD0N_49
set_property PACKAGE_PIN D34      [get_ports "DDR4_C1_DQ26"] ;# Bank  49 VCCO - VCC1V2_FPGA - IO_L21P_T3L_N4_AD8P_49
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C1_DQ26"] ;# Bank  49 VCCO - VCC1V2_FPGA - IO_L21P_T3L_N4_AD8P_49
set_property PACKAGE_PIN C34      [get_ports "DDR4_C1_DQ24"] ;# Bank  49 VCCO - VCC1V2_FPGA - IO_L21N_T3L_N5_AD8N_49
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C1_DQ24"] ;# Bank  49 VCCO - VCC1V2_FPGA - IO_L21N_T3L_N5_AD8N_49
set_property PACKAGE_PIN D35      [get_ports "DDR4_C1_DQ31"] ;# Bank  49 VCCO - VCC1V2_FPGA - IO_L20P_T3L_N2_AD1P_49
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C1_DQ31"] ;# Bank  49 VCCO - VCC1V2_FPGA - IO_L20P_T3L_N2_AD1P_49
set_property PACKAGE_PIN C35      [get_ports "DDR4_C1_DQ29"] ;# Bank  49 VCCO - VCC1V2_FPGA - IO_L20N_T3L_N3_AD1N_49
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C1_DQ29"] ;# Bank  49 VCCO - VCC1V2_FPGA - IO_L20N_T3L_N3_AD1N_49
set_property PACKAGE_PIN D37      [get_ports "DDR4_C1_DM3"] ;# Bank  49 VCCO - VCC1V2_FPGA - IO_L19P_T3L_N0_DBC_AD9P_49
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C1_DM3"] ;# Bank  49 VCCO - VCC1V2_FPGA - IO_L19P_T3L_N0_DBC_AD9P_49
set_property PACKAGE_PIN C37      [get_ports "GPIO_DIP_SW2"] ;# Bank  49 VCCO - VCC1V2_FPGA - IO_L19N_T3L_N1_DBC_AD9N_49
set_property IOSTANDARD  LVCMOS12 [get_ports "GPIO_DIP_SW2"] ;# Bank  49 VCCO - VCC1V2_FPGA - IO_L19N_T3L_N1_DBC_AD9N_49
set_property PACKAGE_PIN B38      [get_ports "DDR4_C1_DQ21"] ;# Bank  49 VCCO - VCC1V2_FPGA - IO_L18P_T2U_N10_AD2P_49
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C1_DQ21"] ;# Bank  49 VCCO - VCC1V2_FPGA - IO_L18P_T2U_N10_AD2P_49
set_property PACKAGE_PIN A38      [get_ports "DDR4_C1_DQ17"] ;# Bank  49 VCCO - VCC1V2_FPGA - IO_L18N_T2U_N11_AD2N_49
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C1_DQ17"] ;# Bank  49 VCCO - VCC1V2_FPGA - IO_L18N_T2U_N11_AD2N_49
set_property PACKAGE_PIN D40      [get_ports "DDR4_C1_DQ19"] ;# Bank  49 VCCO - VCC1V2_FPGA - IO_L17P_T2U_N8_AD10P_49
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C1_DQ19"] ;# Bank  49 VCCO - VCC1V2_FPGA - IO_L17P_T2U_N8_AD10P_49
set_property PACKAGE_PIN C40      [get_ports "DDR4_C1_DQ23"] ;# Bank  49 VCCO - VCC1V2_FPGA - IO_L17N_T2U_N9_AD10N_49
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C1_DQ23"] ;# Bank  49 VCCO - VCC1V2_FPGA - IO_L17N_T2U_N9_AD10N_49
set_property PACKAGE_PIN A39      [get_ports "DDR4_C1_DQS2_T"] ;# Bank  49 VCCO - VCC1V2_FPGA - IO_L16P_T2U_N6_QBC_AD3P_49
set_property IOSTANDARD  DIFF_POD12 [get_ports "DDR4_C1_DQS2_T"] ;# Bank  49 VCCO - VCC1V2_FPGA - IO_L16P_T2U_N6_QBC_AD3P_49
set_property PACKAGE_PIN A40      [get_ports "DDR4_C1_DQS2_C"] ;# Bank  49 VCCO - VCC1V2_FPGA - IO_L16N_T2U_N7_QBC_AD3N_49
set_property IOSTANDARD  DIFF_POD12 [get_ports "DDR4_C1_DQS2_C"] ;# Bank  49 VCCO - VCC1V2_FPGA - IO_L16N_T2U_N7_QBC_AD3N_49
set_property PACKAGE_PIN C39      [get_ports "DDR4_C1_DQ16"] ;# Bank  49 VCCO - VCC1V2_FPGA - IO_L15P_T2L_N4_AD11P_49
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C1_DQ16"] ;# Bank  49 VCCO - VCC1V2_FPGA - IO_L15P_T2L_N4_AD11P_49
set_property PACKAGE_PIN B40      [get_ports "DDR4_C1_DQ18"] ;# Bank  49 VCCO - VCC1V2_FPGA - IO_L15N_T2L_N5_AD11N_49
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C1_DQ18"] ;# Bank  49 VCCO - VCC1V2_FPGA - IO_L15N_T2L_N5_AD11N_49
set_property PACKAGE_PIN E37      [get_ports "DDR4_C1_DQ22"] ;# Bank  49 VCCO - VCC1V2_FPGA - IO_L14P_T2L_N2_GC_49
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C1_DQ22"] ;# Bank  49 VCCO - VCC1V2_FPGA - IO_L14P_T2L_N2_GC_49
set_property PACKAGE_PIN E38      [get_ports "DDR4_C1_DQ20"] ;# Bank  49 VCCO - VCC1V2_FPGA - IO_L14N_T2L_N3_GC_49
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C1_DQ20"] ;# Bank  49 VCCO - VCC1V2_FPGA - IO_L14N_T2L_N3_GC_49
set_property PACKAGE_PIN C38      [get_ports "GPIO_DIP_SW3"] ;# Bank  49 VCCO - VCC1V2_FPGA - IO_T2U_N12_49
set_property IOSTANDARD  LVCMOS12 [get_ports "GPIO_DIP_SW3"] ;# Bank  49 VCCO - VCC1V2_FPGA - IO_T2U_N12_49
set_property PACKAGE_PIN E39      [get_ports "DDR4_C1_DM2"] ;# Bank  49 VCCO - VCC1V2_FPGA - IO_L13P_T2L_N0_GC_QBC_49
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C1_DM2"] ;# Bank  49 VCCO - VCC1V2_FPGA - IO_L13P_T2L_N0_GC_QBC_49
#set_property PACKAGE_PIN D39      [get_ports "5329N1286"] ;# Bank  49 VCCO - VCC1V2_FPGA - IO_L13N_T2L_N1_GC_QBC_49
#set_property IOSTANDARD  LVCMOSxx [get_ports "5329N1286"] ;# Bank  49 VCCO - VCC1V2_FPGA - IO_L13N_T2L_N1_GC_QBC_49
set_property PACKAGE_PIN G36      [get_ports "DDR4_C1_DQ14"] ;# Bank  49 VCCO - VCC1V2_FPGA - IO_L12P_T1U_N10_GC_49
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C1_DQ14"] ;# Bank  49 VCCO - VCC1V2_FPGA - IO_L12P_T1U_N10_GC_49
set_property PACKAGE_PIN G37      [get_ports "DDR4_C1_DQ12"] ;# Bank  49 VCCO - VCC1V2_FPGA - IO_L12N_T1U_N11_GC_49
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C1_DQ12"] ;# Bank  49 VCCO - VCC1V2_FPGA - IO_L12N_T1U_N11_GC_49
set_property PACKAGE_PIN E36      [get_ports "CPU_RESET"] ;# Bank  49 VCCO - VCC1V2_FPGA - IO_T1U_N12_49
set_property IOSTANDARD  LVCMOS12 [get_ports "CPU_RESET"] ;# Bank  49 VCCO - VCC1V2_FPGA - IO_T1U_N12_49
set_property PACKAGE_PIN F35      [get_ports "DDR4_C1_DQ10"] ;# Bank  49 VCCO - VCC1V2_FPGA - IO_L11P_T1U_N8_GC_49
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C1_DQ10"] ;# Bank  49 VCCO - VCC1V2_FPGA - IO_L11P_T1U_N8_GC_49
set_property PACKAGE_PIN F36      [get_ports "DDR4_C1_DQ8"] ;# Bank  49 VCCO - VCC1V2_FPGA - IO_L11N_T1U_N9_GC_49
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C1_DQ8"] ;# Bank  49 VCCO - VCC1V2_FPGA - IO_L11N_T1U_N9_GC_49
set_property PACKAGE_PIN H34      [get_ports "DDR4_C1_DQS1_T"] ;# Bank  49 VCCO - VCC1V2_FPGA - IO_L10P_T1U_N6_QBC_AD4P_49
set_property IOSTANDARD  DIFF_POD12 [get_ports "DDR4_C1_DQS1_T"] ;# Bank  49 VCCO - VCC1V2_FPGA - IO_L10P_T1U_N6_QBC_AD4P_49
set_property PACKAGE_PIN G35      [get_ports "DDR4_C1_DQS1_C"] ;# Bank  49 VCCO - VCC1V2_FPGA - IO_L10N_T1U_N7_QBC_AD4N_49
set_property IOSTANDARD  DIFF_POD12 [get_ports "DDR4_C1_DQS1_C"] ;# Bank  49 VCCO - VCC1V2_FPGA - IO_L10N_T1U_N7_QBC_AD4N_49
set_property PACKAGE_PIN J36      [get_ports "DDR4_C1_DQ9"] ;# Bank  49 VCCO - VCC1V2_FPGA - IO_L9P_T1L_N4_AD12P_49
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C1_DQ9"] ;# Bank  49 VCCO - VCC1V2_FPGA - IO_L9P_T1L_N4_AD12P_49
set_property PACKAGE_PIN H37      [get_ports "DDR4_C1_DQ15"] ;# Bank  49 VCCO - VCC1V2_FPGA - IO_L9N_T1L_N5_AD12N_49
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C1_DQ15"] ;# Bank  49 VCCO - VCC1V2_FPGA - IO_L9N_T1L_N5_AD12N_49
set_property PACKAGE_PIN J35      [get_ports "DDR4_C1_DQ11"] ;# Bank  49 VCCO - VCC1V2_FPGA - IO_L8P_T1L_N2_AD5P_49
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C1_DQ11"] ;# Bank  49 VCCO - VCC1V2_FPGA - IO_L8P_T1L_N2_AD5P_49
set_property PACKAGE_PIN H35      [get_ports "DDR4_C1_DQ13"] ;# Bank  49 VCCO - VCC1V2_FPGA - IO_L8N_T1L_N3_AD5N_49
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C1_DQ13"] ;# Bank  49 VCCO - VCC1V2_FPGA - IO_L8N_T1L_N3_AD5N_49
set_property PACKAGE_PIN F34      [get_ports "DDR4_C1_DM1"] ;# Bank  49 VCCO - VCC1V2_FPGA - IO_L7P_T1L_N0_QBC_AD13P_49
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C1_DM1"] ;# Bank  49 VCCO - VCC1V2_FPGA - IO_L7P_T1L_N0_QBC_AD13P_49
set_property PACKAGE_PIN E34      [get_ports "GPIO_SW_N"] ;# Bank  49 VCCO - VCC1V2_FPGA - IO_L7N_T1L_N1_QBC_AD13N_49
set_property IOSTANDARD  LVCMOS12 [get_ports "GPIO_SW_N"] ;# Bank  49 VCCO - VCC1V2_FPGA - IO_L7N_T1L_N1_QBC_AD13N_49
set_property PACKAGE_PIN F38      [get_ports "DDR4_C1_DQ2"] ;# Bank  49 VCCO - VCC1V2_FPGA - IO_L6P_T0U_N10_AD6P_49
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C1_DQ2"] ;# Bank  49 VCCO - VCC1V2_FPGA - IO_L6P_T0U_N10_AD6P_49
set_property PACKAGE_PIN F39      [get_ports "DDR4_C1_DQ6"] ;# Bank  49 VCCO - VCC1V2_FPGA - IO_L6N_T0U_N11_AD6N_49
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C1_DQ6"] ;# Bank  49 VCCO - VCC1V2_FPGA - IO_L6N_T0U_N11_AD6N_49
set_property PACKAGE_PIN K37      [get_ports "DDR4_C1_DQ4"] ;# Bank  49 VCCO - VCC1V2_FPGA - IO_L5P_T0U_N8_AD14P_49
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C1_DQ4"] ;# Bank  49 VCCO - VCC1V2_FPGA - IO_L5P_T0U_N8_AD14P_49
set_property PACKAGE_PIN J37      [get_ports "DDR4_C1_DQ0"] ;# Bank  49 VCCO - VCC1V2_FPGA - IO_L5N_T0U_N9_AD14N_49
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C1_DQ0"] ;# Bank  49 VCCO - VCC1V2_FPGA - IO_L5N_T0U_N9_AD14N_49
set_property PACKAGE_PIN H38      [get_ports "DDR4_C1_DQS0_T"] ;# Bank  49 VCCO - VCC1V2_FPGA - IO_L4P_T0U_N6_DBC_AD7P_49
set_property IOSTANDARD  DIFF_POD12 [get_ports "DDR4_C1_DQS0_T"] ;# Bank  49 VCCO - VCC1V2_FPGA - IO_L4P_T0U_N6_DBC_AD7P_49
set_property PACKAGE_PIN G38      [get_ports "DDR4_C1_DQS0_C"] ;# Bank  49 VCCO - VCC1V2_FPGA - IO_L4N_T0U_N7_DBC_AD7N_49
set_property IOSTANDARD  DIFF_POD12 [get_ports "DDR4_C1_DQS0_C"] ;# Bank  49 VCCO - VCC1V2_FPGA - IO_L4N_T0U_N7_DBC_AD7N_49
set_property PACKAGE_PIN G40      [get_ports "DDR4_C1_DQ5"] ;# Bank  49 VCCO - VCC1V2_FPGA - IO_L3P_T0L_N4_AD15P_49
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C1_DQ5"] ;# Bank  49 VCCO - VCC1V2_FPGA - IO_L3P_T0L_N4_AD15P_49
set_property PACKAGE_PIN F40      [get_ports "DDR4_C1_DQ7"] ;# Bank  49 VCCO - VCC1V2_FPGA - IO_L3N_T0L_N5_AD15N_49
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C1_DQ7"] ;# Bank  49 VCCO - VCC1V2_FPGA - IO_L3N_T0L_N5_AD15N_49
set_property PACKAGE_PIN H39      [get_ports "DDR4_C1_DQ3"] ;# Bank  49 VCCO - VCC1V2_FPGA - IO_L2P_T0L_N2_49
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C1_DQ3"] ;# Bank  49 VCCO - VCC1V2_FPGA - IO_L2P_T0L_N2_49
set_property PACKAGE_PIN H40      [get_ports "DDR4_C1_DQ1"] ;# Bank  49 VCCO - VCC1V2_FPGA - IO_L2N_T0L_N3_49
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C1_DQ1"] ;# Bank  49 VCCO - VCC1V2_FPGA - IO_L2N_T0L_N3_49
#set_property PACKAGE_PIN K38      [get_ports "VRP_49"] ;# Bank  49 VCCO - VCC1V2_FPGA - IO_T0U_N12_VRP_49
#set_property IOSTANDARD  LVCMOSxx [get_ports "VRP_49"] ;# Bank  49 VCCO - VCC1V2_FPGA - IO_T0U_N12_VRP_49
set_property PACKAGE_PIN J39      [get_ports "DDR4_C1_DM0"] ;# Bank  49 VCCO - VCC1V2_FPGA - IO_L1P_T0L_N0_DBC_49
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C1_DM0"] ;# Bank  49 VCCO - VCC1V2_FPGA - IO_L1P_T0L_N0_DBC_49
set_property PACKAGE_PIN J40      [get_ports "DDR4_C1_ALERT_B"] ;# Bank  49 VCCO - VCC1V2_FPGA - IO_L1N_T0L_N1_DBC_49
set_property IOSTANDARD  SSTL12_DCI [get_ports "DDR4_C1_ALERT_B"] ;# Bank  49 VCCO - VCC1V2_FPGA - IO_L1N_T0L_N1_DBC_49
set_property PACKAGE_PIN D29      [get_ports "DDR4_C1_A14_WE_B"] ;# Bank  50 VCCO - VCC1V2_FPGA - IO_L24P_T3U_N10_50
set_property IOSTANDARD  SSTL12_DCI [get_ports "DDR4_C1_A14_WE_B"] ;# Bank  50 VCCO - VCC1V2_FPGA - IO_L24P_T3U_N10_50
set_property PACKAGE_PIN C29      [get_ports "DDR4_C1_A6"] ;# Bank  50 VCCO - VCC1V2_FPGA - IO_L24N_T3U_N11_50
set_property IOSTANDARD  SSTL12_DCI [get_ports "DDR4_C1_A6"] ;# Bank  50 VCCO - VCC1V2_FPGA - IO_L24N_T3U_N11_50
set_property PACKAGE_PIN A29      [get_ports "DDR4_C1_A5"] ;# Bank  50 VCCO - VCC1V2_FPGA - IO_T3U_N12_50
set_property IOSTANDARD  SSTL12_DCI [get_ports "DDR4_C1_A5"] ;# Bank  50 VCCO - VCC1V2_FPGA - IO_T3U_N12_50
set_property PACKAGE_PIN C30      [get_ports "DDR4_C1_A0"] ;# Bank  50 VCCO - VCC1V2_FPGA - IO_L23P_T3U_N8_50
set_property IOSTANDARD  SSTL12_DCI [get_ports "DDR4_C1_A0"] ;# Bank  50 VCCO - VCC1V2_FPGA - IO_L23P_T3U_N8_50
set_property PACKAGE_PIN B30      [get_ports "DDR4_C1_A2"] ;# Bank  50 VCCO - VCC1V2_FPGA - IO_L23N_T3U_N9_50
set_property IOSTANDARD  SSTL12_DCI [get_ports "DDR4_C1_A2"] ;# Bank  50 VCCO - VCC1V2_FPGA - IO_L23N_T3U_N9_50
set_property PACKAGE_PIN A30      [get_ports "DDR4_C1_A8"] ;# Bank  50 VCCO - VCC1V2_FPGA - IO_L22P_T3U_N6_DBC_AD0P_50
set_property IOSTANDARD  SSTL12_DCI [get_ports "DDR4_C1_A8"] ;# Bank  50 VCCO - VCC1V2_FPGA - IO_L22P_T3U_N6_DBC_AD0P_50
set_property PACKAGE_PIN A31      [get_ports "DDR4_C1_A10"] ;# Bank  50 VCCO - VCC1V2_FPGA - IO_L22N_T3U_N7_DBC_AD0N_50
set_property IOSTANDARD  SSTL12_DCI [get_ports "DDR4_C1_A10"] ;# Bank  50 VCCO - VCC1V2_FPGA - IO_L22N_T3U_N7_DBC_AD0N_50
set_property PACKAGE_PIN B33      [get_ports "DDR4_C1_A16_RAS_B"] ;# Bank  50 VCCO - VCC1V2_FPGA - IO_L21P_T3L_N4_AD8P_50
set_property IOSTANDARD  SSTL12_DCI [get_ports "DDR4_C1_A16_RAS_B"] ;# Bank  50 VCCO - VCC1V2_FPGA - IO_L21P_T3L_N4_AD8P_50
set_property PACKAGE_PIN A33      [get_ports "DDR4_C1_A11"] ;# Bank  50 VCCO - VCC1V2_FPGA - IO_L21N_T3L_N5_AD8N_50
set_property IOSTANDARD  SSTL12_DCI [get_ports "DDR4_C1_A11"] ;# Bank  50 VCCO - VCC1V2_FPGA - IO_L21N_T3L_N5_AD8N_50
set_property PACKAGE_PIN B31      [get_ports "DDR4_C1_A15_CAS_B"] ;# Bank  50 VCCO - VCC1V2_FPGA - IO_L20P_T3L_N2_AD1P_50
set_property IOSTANDARD  SSTL12_DCI [get_ports "DDR4_C1_A15_CAS_B"] ;# Bank  50 VCCO - VCC1V2_FPGA - IO_L20P_T3L_N2_AD1P_50
set_property PACKAGE_PIN B32      [get_ports "DDR4_C1_A13"] ;# Bank  50 VCCO - VCC1V2_FPGA - IO_L20N_T3L_N3_AD1N_50
set_property IOSTANDARD  SSTL12_DCI [get_ports "DDR4_C1_A13"] ;# Bank  50 VCCO - VCC1V2_FPGA - IO_L20N_T3L_N3_AD1N_50
set_property PACKAGE_PIN C32      [get_ports "DDR4_C1_A9"] ;# Bank  50 VCCO - VCC1V2_FPGA - IO_L19P_T3L_N0_DBC_AD9P_50
set_property IOSTANDARD  SSTL12_DCI [get_ports "DDR4_C1_A9"] ;# Bank  50 VCCO - VCC1V2_FPGA - IO_L19P_T3L_N0_DBC_AD9P_50
set_property PACKAGE_PIN C33      [get_ports "DDR4_C1_A3"] ;# Bank  50 VCCO - VCC1V2_FPGA - IO_L19N_T3L_N1_DBC_AD9N_50
set_property IOSTANDARD  SSTL12_DCI [get_ports "DDR4_C1_A3"] ;# Bank  50 VCCO - VCC1V2_FPGA - IO_L19N_T3L_N1_DBC_AD9N_50
set_property PACKAGE_PIN F29      [get_ports "DDR4_C1_A12"] ;# Bank  50 VCCO - VCC1V2_FPGA - IO_L18P_T2U_N10_AD2P_50
set_property IOSTANDARD  SSTL12_DCI [get_ports "DDR4_C1_A12"] ;# Bank  50 VCCO - VCC1V2_FPGA - IO_L18P_T2U_N10_AD2P_50
set_property PACKAGE_PIN E29      [get_ports "DDR4_C1_A7"] ;# Bank  50 VCCO - VCC1V2_FPGA - IO_L18N_T2U_N11_AD2N_50
set_property IOSTANDARD  SSTL12_DCI [get_ports "DDR4_C1_A7"] ;# Bank  50 VCCO - VCC1V2_FPGA - IO_L18N_T2U_N11_AD2N_50
set_property PACKAGE_PIN E32      [get_ports "DDR4_C1_A4"] ;# Bank  50 VCCO - VCC1V2_FPGA - IO_L17P_T2U_N8_AD10P_50
set_property IOSTANDARD  SSTL12_DCI [get_ports "DDR4_C1_A4"] ;# Bank  50 VCCO - VCC1V2_FPGA - IO_L17P_T2U_N8_AD10P_50
set_property PACKAGE_PIN D32      [get_ports "DDR4_C1_A1"] ;# Bank  50 VCCO - VCC1V2_FPGA - IO_L17N_T2U_N9_AD10N_50
set_property IOSTANDARD  SSTL12_DCI [get_ports "DDR4_C1_A1"] ;# Bank  50 VCCO - VCC1V2_FPGA - IO_L17N_T2U_N9_AD10N_50
set_property PACKAGE_PIN E31      [get_ports "DDR4_C1_CK_T"] ;# Bank  50 VCCO - VCC1V2_FPGA - IO_L16P_T2U_N6_QBC_AD3P_50
set_property IOSTANDARD  DIFF_SSTL12_DCI [get_ports "DDR4_C1_CK_T"] ;# Bank  50 VCCO - VCC1V2_FPGA - IO_L16P_T2U_N6_QBC_AD3P_50
set_property PACKAGE_PIN D31      [get_ports "DDR4_C1_CK_C"] ;# Bank  50 VCCO - VCC1V2_FPGA - IO_L16N_T2U_N7_QBC_AD3N_50
set_property IOSTANDARD  DIFF_SSTL12_DCI [get_ports "DDR4_C1_CK_C"] ;# Bank  50 VCCO - VCC1V2_FPGA - IO_L16N_T2U_N7_QBC_AD3N_50
set_property PACKAGE_PIN F33      [get_ports "DDR4_C1_BG0"] ;# Bank  50 VCCO - VCC1V2_FPGA - IO_L15P_T2L_N4_AD11P_50
set_property IOSTANDARD  SSTL12_DCI [get_ports "DDR4_C1_BG0"] ;# Bank  50 VCCO - VCC1V2_FPGA - IO_L15P_T2L_N4_AD11P_50
set_property PACKAGE_PIN E33      [get_ports "DDR4_C1_ACT_B"] ;# Bank  50 VCCO - VCC1V2_FPGA - IO_L15N_T2L_N5_AD11N_50
set_property IOSTANDARD  SSTL12_DCI [get_ports "DDR4_C1_ACT_B"] ;# Bank  50 VCCO - VCC1V2_FPGA - IO_L15N_T2L_N5_AD11N_50
set_property PACKAGE_PIN G30      [get_ports "DDR4_C1_BA0"] ;# Bank  50 VCCO - VCC1V2_FPGA - IO_L14P_T2L_N2_GC_50
set_property IOSTANDARD  SSTL12_DCI [get_ports "DDR4_C1_BA0"] ;# Bank  50 VCCO - VCC1V2_FPGA - IO_L14P_T2L_N2_GC_50
set_property PACKAGE_PIN F30      [get_ports "DDR4_C1_BA1"] ;# Bank  50 VCCO - VCC1V2_FPGA - IO_L14N_T2L_N3_GC_50
set_property IOSTANDARD  SSTL12_DCI [get_ports "DDR4_C1_BA1"] ;# Bank  50 VCCO - VCC1V2_FPGA - IO_L14N_T2L_N3_GC_50
set_property PACKAGE_PIN D30      [get_ports "DDR4_C1_CS_B"] ;# Bank  50 VCCO - VCC1V2_FPGA - IO_T2U_N12_50
set_property IOSTANDARD  SSTL12_DCI [get_ports "DDR4_C1_CS_B"] ;# Bank  50 VCCO - VCC1V2_FPGA - IO_T2U_N12_50
set_property PACKAGE_PIN G31      [get_ports "SYSCLK1_300_P"] ;# Bank  50 VCCO - VCC1V2_FPGA - IO_L13P_T2L_N0_GC_QBC_50
set_property IOSTANDARD  DIFF_SSTL12 [get_ports "SYSCLK1_300_P"] ;# Bank  50 VCCO - VCC1V2_FPGA - IO_L13P_T2L_N0_GC_QBC_50
set_property PACKAGE_PIN F31      [get_ports "SYSCLK1_300_N"] ;# Bank  50 VCCO - VCC1V2_FPGA - IO_L13N_T2L_N1_GC_QBC_50
set_property IOSTANDARD  DIFF_SSTL12 [get_ports "SYSCLK1_300_N"] ;# Bank  50 VCCO - VCC1V2_FPGA - IO_L13N_T2L_N1_GC_QBC_50
set_property PACKAGE_PIN H32      [get_ports "DDR4_C1_DQ75"] ;# Bank  50 VCCO - VCC1V2_FPGA - IO_L12P_T1U_N10_GC_50
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C1_DQ75"] ;# Bank  50 VCCO - VCC1V2_FPGA - IO_L12P_T1U_N10_GC_50
set_property PACKAGE_PIN G32      [get_ports "DDR4_C1_DQ79"] ;# Bank  50 VCCO - VCC1V2_FPGA - IO_L12N_T1U_N11_GC_50
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C1_DQ79"] ;# Bank  50 VCCO - VCC1V2_FPGA - IO_L12N_T1U_N11_GC_50
set_property PACKAGE_PIN K29      [get_ports "DDR4_C1_CKE"] ;# Bank  50 VCCO - VCC1V2_FPGA - IO_T1U_N12_50
set_property IOSTANDARD  SSTL12_DCI [get_ports "DDR4_C1_CKE"] ;# Bank  50 VCCO - VCC1V2_FPGA - IO_T1U_N12_50
set_property PACKAGE_PIN H29      [get_ports "DDR4_C1_DQ74"] ;# Bank  50 VCCO - VCC1V2_FPGA - IO_L11P_T1U_N8_GC_50
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C1_DQ74"] ;# Bank  50 VCCO - VCC1V2_FPGA - IO_L11P_T1U_N8_GC_50
set_property PACKAGE_PIN H30      [get_ports "DDR4_C1_DQ72"] ;# Bank  50 VCCO - VCC1V2_FPGA - IO_L11N_T1U_N9_GC_50
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C1_DQ72"] ;# Bank  50 VCCO - VCC1V2_FPGA - IO_L11N_T1U_N9_GC_50
set_property PACKAGE_PIN H33      [get_ports "DDR4_C1_DQS9_T"] ;# Bank  50 VCCO - VCC1V2_FPGA - IO_L10P_T1U_N6_QBC_AD4P_50
set_property IOSTANDARD  DIFF_POD12 [get_ports "DDR4_C1_DQS9_T"] ;# Bank  50 VCCO - VCC1V2_FPGA - IO_L10P_T1U_N6_QBC_AD4P_50
set_property PACKAGE_PIN G33      [get_ports "DDR4_C1_DQS9_C"] ;# Bank  50 VCCO - VCC1V2_FPGA - IO_L10N_T1U_N7_QBC_AD4N_50
set_property IOSTANDARD  DIFF_POD12 [get_ports "DDR4_C1_DQS9_C"] ;# Bank  50 VCCO - VCC1V2_FPGA - IO_L10N_T1U_N7_QBC_AD4N_50
set_property PACKAGE_PIN J29      [get_ports "DDR4_C1_DQ76"] ;# Bank  50 VCCO - VCC1V2_FPGA - IO_L9P_T1L_N4_AD12P_50
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C1_DQ76"] ;# Bank  50 VCCO - VCC1V2_FPGA - IO_L9P_T1L_N4_AD12P_50
set_property PACKAGE_PIN J30      [get_ports "DDR4_C1_DQ78"] ;# Bank  50 VCCO - VCC1V2_FPGA - IO_L9N_T1L_N5_AD12N_50
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C1_DQ78"] ;# Bank  50 VCCO - VCC1V2_FPGA - IO_L9N_T1L_N5_AD12N_50
set_property PACKAGE_PIN K32      [get_ports "DDR4_C1_DQ77"] ;# Bank  50 VCCO - VCC1V2_FPGA - IO_L8P_T1L_N2_AD5P_50
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C1_DQ77"] ;# Bank  50 VCCO - VCC1V2_FPGA - IO_L8P_T1L_N2_AD5P_50
set_property PACKAGE_PIN J32      [get_ports "DDR4_C1_DQ73"] ;# Bank  50 VCCO - VCC1V2_FPGA - IO_L8N_T1L_N3_AD5N_50
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C1_DQ73"] ;# Bank  50 VCCO - VCC1V2_FPGA - IO_L8N_T1L_N3_AD5N_50
set_property PACKAGE_PIN K31      [get_ports "DDR4_C1_DM9"] ;# Bank  50 VCCO - VCC1V2_FPGA - IO_L7P_T1L_N0_QBC_AD13P_50
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C1_DM9"] ;# Bank  50 VCCO - VCC1V2_FPGA - IO_L7P_T1L_N0_QBC_AD13P_50
set_property PACKAGE_PIN J31      [get_ports "DDR4_C1_ODT"] ;# Bank  50 VCCO - VCC1V2_FPGA - IO_L7N_T1L_N1_QBC_AD13N_50
set_property IOSTANDARD  SSTL12_DCI [get_ports "DDR4_C1_ODT"] ;# Bank  50 VCCO - VCC1V2_FPGA - IO_L7N_T1L_N1_QBC_AD13N_50
set_property PACKAGE_PIN L29      [get_ports "DDR4_C1_DQ67"] ;# Bank  50 VCCO - VCC1V2_FPGA - IO_L6P_T0U_N10_AD6P_50
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C1_DQ67"] ;# Bank  50 VCCO - VCC1V2_FPGA - IO_L6P_T0U_N10_AD6P_50
set_property PACKAGE_PIN L30      [get_ports "DDR4_C1_DQ71"] ;# Bank  50 VCCO - VCC1V2_FPGA - IO_L6N_T0U_N11_AD6N_50
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C1_DQ71"] ;# Bank  50 VCCO - VCC1V2_FPGA - IO_L6N_T0U_N11_AD6N_50
set_property PACKAGE_PIN N28      [get_ports "DDR4_C1_DQ69"] ;# Bank  50 VCCO - VCC1V2_FPGA - IO_L5P_T0U_N8_AD14P_50
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C1_DQ69"] ;# Bank  50 VCCO - VCC1V2_FPGA - IO_L5P_T0U_N8_AD14P_50
set_property PACKAGE_PIN N29      [get_ports "DDR4_C1_DQ64"] ;# Bank  50 VCCO - VCC1V2_FPGA - IO_L5N_T0U_N9_AD14N_50
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C1_DQ64"] ;# Bank  50 VCCO - VCC1V2_FPGA - IO_L5N_T0U_N9_AD14N_50
set_property PACKAGE_PIN N30      [get_ports "DDR4_C1_DQS8_T"] ;# Bank  50 VCCO - VCC1V2_FPGA - IO_L4P_T0U_N6_DBC_AD7P_50
set_property IOSTANDARD  DIFF_POD12 [get_ports "DDR4_C1_DQS8_T"] ;# Bank  50 VCCO - VCC1V2_FPGA - IO_L4P_T0U_N6_DBC_AD7P_50
set_property PACKAGE_PIN M30      [get_ports "DDR4_C1_DQS8_C"] ;# Bank  50 VCCO - VCC1V2_FPGA - IO_L4N_T0U_N7_DBC_AD7N_50
set_property IOSTANDARD  DIFF_POD12 [get_ports "DDR4_C1_DQS8_C"] ;# Bank  50 VCCO - VCC1V2_FPGA - IO_L4N_T0U_N7_DBC_AD7N_50
set_property PACKAGE_PIN P29      [get_ports "DDR4_C1_DQ66"] ;# Bank  50 VCCO - VCC1V2_FPGA - IO_L3P_T0L_N4_AD15P_50
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C1_DQ66"] ;# Bank  50 VCCO - VCC1V2_FPGA - IO_L3P_T0L_N4_AD15P_50
set_property PACKAGE_PIN P30      [get_ports "DDR4_C1_DQ68"] ;# Bank  50 VCCO - VCC1V2_FPGA - IO_L3N_T0L_N5_AD15N_50
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C1_DQ68"] ;# Bank  50 VCCO - VCC1V2_FPGA - IO_L3N_T0L_N5_AD15N_50
set_property PACKAGE_PIN M31      [get_ports "DDR4_C1_DQ65"] ;# Bank  50 VCCO - VCC1V2_FPGA - IO_L2P_T0L_N2_50
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C1_DQ65"] ;# Bank  50 VCCO - VCC1V2_FPGA - IO_L2P_T0L_N2_50
set_property PACKAGE_PIN L31      [get_ports "DDR4_C1_DQ70"] ;# Bank  50 VCCO - VCC1V2_FPGA - IO_L2N_T0L_N3_50
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C1_DQ70"] ;# Bank  50 VCCO - VCC1V2_FPGA - IO_L2N_T0L_N3_50
#set_property PACKAGE_PIN T29      [get_ports "VRP_50"] ;# Bank  50 VCCO - VCC1V2_FPGA - IO_T0U_N12_VRP_50
#set_property IOSTANDARD  LVCMOSxx [get_ports "VRP_50"] ;# Bank  50 VCCO - VCC1V2_FPGA - IO_T0U_N12_VRP_50
set_property PACKAGE_PIN R28      [get_ports "DDR4_C1_DM8"] ;# Bank  50 VCCO - VCC1V2_FPGA - IO_L1P_T0L_N0_DBC_50
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C1_DM8"] ;# Bank  50 VCCO - VCC1V2_FPGA - IO_L1P_T0L_N0_DBC_50
set_property PACKAGE_PIN R29      [get_ports "DDR4_C1_PAR"] ;# Bank  50 VCCO - VCC1V2_FPGA - IO_L1N_T0L_N1_DBC_50
set_property IOSTANDARD  SSTL12_DCI [get_ports "DDR4_C1_PAR"] ;# Bank  50 VCCO - VCC1V2_FPGA - IO_L1N_T0L_N1_DBC_50
set_property PACKAGE_PIN C25      [get_ports "DDR4_C1_DQ62"] ;# Bank  51 VCCO - VCC1V2_FPGA - IO_L24P_T3U_N10_51
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C1_DQ62"] ;# Bank  51 VCCO - VCC1V2_FPGA - IO_L24P_T3U_N10_51
set_property PACKAGE_PIN B25      [get_ports "DDR4_C1_DQ58"] ;# Bank  51 VCCO - VCC1V2_FPGA - IO_L24N_T3U_N11_51
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C1_DQ58"] ;# Bank  51 VCCO - VCC1V2_FPGA - IO_L24N_T3U_N11_51
#set_property PACKAGE_PIN A25      [get_ports "30N637"] ;# Bank  51 VCCO - VCC1V2_FPGA - IO_T3U_N12_51
#set_property IOSTANDARD  LVCMOSxx [get_ports "30N637"] ;# Bank  51 VCCO - VCC1V2_FPGA - IO_T3U_N12_51
set_property PACKAGE_PIN D25      [get_ports "DDR4_C1_DQ60"] ;# Bank  51 VCCO - VCC1V2_FPGA - IO_L23P_T3U_N8_51
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C1_DQ60"] ;# Bank  51 VCCO - VCC1V2_FPGA - IO_L23P_T3U_N8_51
set_property PACKAGE_PIN D26      [get_ports "DDR4_C1_DQ63"] ;# Bank  51 VCCO - VCC1V2_FPGA - IO_L23N_T3U_N9_51
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C1_DQ63"] ;# Bank  51 VCCO - VCC1V2_FPGA - IO_L23N_T3U_N9_51
set_property PACKAGE_PIN B26      [get_ports "DDR4_C1_DQS7_T"] ;# Bank  51 VCCO - VCC1V2_FPGA - IO_L22P_T3U_N6_DBC_AD0P_51
set_property IOSTANDARD  DIFF_POD12 [get_ports "DDR4_C1_DQS7_T"] ;# Bank  51 VCCO - VCC1V2_FPGA - IO_L22P_T3U_N6_DBC_AD0P_51
set_property PACKAGE_PIN A26      [get_ports "DDR4_C1_DQS7_C"] ;# Bank  51 VCCO - VCC1V2_FPGA - IO_L22N_T3U_N7_DBC_AD0N_51
set_property IOSTANDARD  DIFF_POD12 [get_ports "DDR4_C1_DQS7_C"] ;# Bank  51 VCCO - VCC1V2_FPGA - IO_L22N_T3U_N7_DBC_AD0N_51
set_property PACKAGE_PIN C27      [get_ports "DDR4_C1_DQ61"] ;# Bank  51 VCCO - VCC1V2_FPGA - IO_L21P_T3L_N4_AD8P_51
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C1_DQ61"] ;# Bank  51 VCCO - VCC1V2_FPGA - IO_L21P_T3L_N4_AD8P_51
set_property PACKAGE_PIN B27      [get_ports "DDR4_C1_DQ59"] ;# Bank  51 VCCO - VCC1V2_FPGA - IO_L21N_T3L_N5_AD8N_51
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C1_DQ59"] ;# Bank  51 VCCO - VCC1V2_FPGA - IO_L21N_T3L_N5_AD8N_51
set_property PACKAGE_PIN B28      [get_ports "DDR4_C1_DQ56"] ;# Bank  51 VCCO - VCC1V2_FPGA - IO_L20P_T3L_N2_AD1P_51
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C1_DQ56"] ;# Bank  51 VCCO - VCC1V2_FPGA - IO_L20P_T3L_N2_AD1P_51
set_property PACKAGE_PIN A28      [get_ports "DDR4_C1_DQ57"] ;# Bank  51 VCCO - VCC1V2_FPGA - IO_L20N_T3L_N3_AD1N_51
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C1_DQ57"] ;# Bank  51 VCCO - VCC1V2_FPGA - IO_L20N_T3L_N3_AD1N_51
set_property PACKAGE_PIN D27      [get_ports "DDR4_C1_DM7"] ;# Bank  51 VCCO - VCC1V2_FPGA - IO_L19P_T3L_N0_DBC_AD9P_51
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C1_DM7"] ;# Bank  51 VCCO - VCC1V2_FPGA - IO_L19P_T3L_N0_DBC_AD9P_51
set_property PACKAGE_PIN C28      [get_ports "SI5328_INT_ALM_LS"] ;# Bank  51 VCCO - VCC1V2_FPGA - IO_L19N_T3L_N1_DBC_AD9N_51
set_property IOSTANDARD  LVCMOS12 [get_ports "SI5328_INT_ALM_LS"] ;# Bank  51 VCCO - VCC1V2_FPGA - IO_L19N_T3L_N1_DBC_AD9N_51
set_property PACKAGE_PIN G25      [get_ports "DDR4_C1_DQ54"] ;# Bank  51 VCCO - VCC1V2_FPGA - IO_L18P_T2U_N10_AD2P_51
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C1_DQ54"] ;# Bank  51 VCCO - VCC1V2_FPGA - IO_L18P_T2U_N10_AD2P_51
set_property PACKAGE_PIN F25      [get_ports "DDR4_C1_DQ52"] ;# Bank  51 VCCO - VCC1V2_FPGA - IO_L18N_T2U_N11_AD2N_51
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C1_DQ52"] ;# Bank  51 VCCO - VCC1V2_FPGA - IO_L18N_T2U_N11_AD2N_51
set_property PACKAGE_PIN E26      [get_ports "DDR4_C1_DQ50"] ;# Bank  51 VCCO - VCC1V2_FPGA - IO_L17P_T2U_N8_AD10P_51
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C1_DQ50"] ;# Bank  51 VCCO - VCC1V2_FPGA - IO_L17P_T2U_N8_AD10P_51
set_property PACKAGE_PIN E27      [get_ports "DDR4_C1_DQ48"] ;# Bank  51 VCCO - VCC1V2_FPGA - IO_L17N_T2U_N9_AD10N_51
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C1_DQ48"] ;# Bank  51 VCCO - VCC1V2_FPGA - IO_L17N_T2U_N9_AD10N_51
set_property PACKAGE_PIN H28      [get_ports "DDR4_C1_DQS6_T"] ;# Bank  51 VCCO - VCC1V2_FPGA - IO_L16P_T2U_N6_QBC_AD3P_51
set_property IOSTANDARD  DIFF_POD12 [get_ports "DDR4_C1_DQS6_T"] ;# Bank  51 VCCO - VCC1V2_FPGA - IO_L16P_T2U_N6_QBC_AD3P_51
set_property PACKAGE_PIN G28      [get_ports "DDR4_C1_DQS6_C"] ;# Bank  51 VCCO - VCC1V2_FPGA - IO_L16N_T2U_N7_QBC_AD3N_51
set_property IOSTANDARD  DIFF_POD12 [get_ports "DDR4_C1_DQS6_C"] ;# Bank  51 VCCO - VCC1V2_FPGA - IO_L16N_T2U_N7_QBC_AD3N_51
set_property PACKAGE_PIN F28      [get_ports "DDR4_C1_DQ53"] ;# Bank  51 VCCO - VCC1V2_FPGA - IO_L15P_T2L_N4_AD11P_51
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C1_DQ53"] ;# Bank  51 VCCO - VCC1V2_FPGA - IO_L15P_T2L_N4_AD11P_51
set_property PACKAGE_PIN E28      [get_ports "DDR4_C1_DQ49"] ;# Bank  51 VCCO - VCC1V2_FPGA - IO_L15N_T2L_N5_AD11N_51
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C1_DQ49"] ;# Bank  51 VCCO - VCC1V2_FPGA - IO_L15N_T2L_N5_AD11N_51
set_property PACKAGE_PIN H27      [get_ports "DDR4_C1_DQ51"] ;# Bank  51 VCCO - VCC1V2_FPGA - IO_L14P_T2L_N2_GC_51
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C1_DQ51"] ;# Bank  51 VCCO - VCC1V2_FPGA - IO_L14P_T2L_N2_GC_51
set_property PACKAGE_PIN G27      [get_ports "DDR4_C1_DQ55"] ;# Bank  51 VCCO - VCC1V2_FPGA - IO_L14N_T2L_N3_GC_51
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C1_DQ55"] ;# Bank  51 VCCO - VCC1V2_FPGA - IO_L14N_T2L_N3_GC_51
set_property PACKAGE_PIN H25      [get_ports "SYSMON_MUX_ADDR0_LS"] ;# Bank  51 VCCO - VCC1V2_FPGA - IO_T2U_N12_51
set_property IOSTANDARD  LVCMOS12 [get_ports "SYSMON_MUX_ADDR0_LS"] ;# Bank  51 VCCO - VCC1V2_FPGA - IO_T2U_N12_51
set_property PACKAGE_PIN G26      [get_ports "DDR4_C1_DM6"] ;# Bank  51 VCCO - VCC1V2_FPGA - IO_L13P_T2L_N0_GC_QBC_51
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C1_DM6"] ;# Bank  51 VCCO - VCC1V2_FPGA - IO_L13P_T2L_N0_GC_QBC_51
set_property PACKAGE_PIN F26      [get_ports "SYSMON_MUX_ADDR1_LS"] ;# Bank  51 VCCO - VCC1V2_FPGA - IO_L13N_T2L_N1_GC_QBC_51
set_property IOSTANDARD  LVCMOS12 [get_ports "SYSMON_MUX_ADDR1_LS"] ;# Bank  51 VCCO - VCC1V2_FPGA - IO_L13N_T2L_N1_GC_QBC_51
set_property PACKAGE_PIN K27      [get_ports "DDR4_C1_DQ40"] ;# Bank  51 VCCO - VCC1V2_FPGA - IO_L12P_T1U_N10_GC_51
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C1_DQ40"] ;# Bank  51 VCCO - VCC1V2_FPGA - IO_L12P_T1U_N10_GC_51
set_property PACKAGE_PIN J27      [get_ports "DDR4_C1_DQ42"] ;# Bank  51 VCCO - VCC1V2_FPGA - IO_L12N_T1U_N11_GC_51
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C1_DQ42"] ;# Bank  51 VCCO - VCC1V2_FPGA - IO_L12N_T1U_N11_GC_51
set_property PACKAGE_PIN J25      [get_ports "SYSMON_MUX_ADDR2_LS"] ;# Bank  51 VCCO - VCC1V2_FPGA - IO_T1U_N12_51
set_property IOSTANDARD  LVCMOS12 [get_ports "SYSMON_MUX_ADDR2_LS"] ;# Bank  51 VCCO - VCC1V2_FPGA - IO_T1U_N12_51
set_property PACKAGE_PIN K26      [get_ports "DDR4_C1_DQ44"] ;# Bank  51 VCCO - VCC1V2_FPGA - IO_L11P_T1U_N8_GC_51
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C1_DQ44"] ;# Bank  51 VCCO - VCC1V2_FPGA - IO_L11P_T1U_N8_GC_51
set_property PACKAGE_PIN J26      [get_ports "DDR4_C1_DQ46"] ;# Bank  51 VCCO - VCC1V2_FPGA - IO_L11N_T1U_N9_GC_51
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C1_DQ46"] ;# Bank  51 VCCO - VCC1V2_FPGA - IO_L11N_T1U_N9_GC_51
set_property PACKAGE_PIN L24      [get_ports "DDR4_C1_DQS5_T"] ;# Bank  51 VCCO - VCC1V2_FPGA - IO_L10P_T1U_N6_QBC_AD4P_51
set_property IOSTANDARD  DIFF_POD12 [get_ports "DDR4_C1_DQS5_T"] ;# Bank  51 VCCO - VCC1V2_FPGA - IO_L10P_T1U_N6_QBC_AD4P_51
set_property PACKAGE_PIN L25      [get_ports "DDR4_C1_DQS5_C"] ;# Bank  51 VCCO - VCC1V2_FPGA - IO_L10N_T1U_N7_QBC_AD4N_51
set_property IOSTANDARD  DIFF_POD12 [get_ports "DDR4_C1_DQS5_C"] ;# Bank  51 VCCO - VCC1V2_FPGA - IO_L10N_T1U_N7_QBC_AD4N_51
set_property PACKAGE_PIN L28      [get_ports "DDR4_C1_DQ47"] ;# Bank  51 VCCO - VCC1V2_FPGA - IO_L9P_T1L_N4_AD12P_51
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C1_DQ47"] ;# Bank  51 VCCO - VCC1V2_FPGA - IO_L9P_T1L_N4_AD12P_51
set_property PACKAGE_PIN K28      [get_ports "DDR4_C1_DQ43"] ;# Bank  51 VCCO - VCC1V2_FPGA - IO_L9N_T1L_N5_AD12N_51
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C1_DQ43"] ;# Bank  51 VCCO - VCC1V2_FPGA - IO_L9N_T1L_N5_AD12N_51
set_property PACKAGE_PIN M25      [get_ports "DDR4_C1_DQ45"] ;# Bank  51 VCCO - VCC1V2_FPGA - IO_L8P_T1L_N2_AD5P_51
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C1_DQ45"] ;# Bank  51 VCCO - VCC1V2_FPGA - IO_L8P_T1L_N2_AD5P_51
set_property PACKAGE_PIN L26      [get_ports "DDR4_C1_DQ41"] ;# Bank  51 VCCO - VCC1V2_FPGA - IO_L8N_T1L_N3_AD5N_51
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C1_DQ41"] ;# Bank  51 VCCO - VCC1V2_FPGA - IO_L8N_T1L_N3_AD5N_51
set_property PACKAGE_PIN M27      [get_ports "DDR4_C1_DM5"] ;# Bank  51 VCCO - VCC1V2_FPGA - IO_L7P_T1L_N0_QBC_AD13P_51
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C1_DM5"] ;# Bank  51 VCCO - VCC1V2_FPGA - IO_L7P_T1L_N0_QBC_AD13P_51
set_property PACKAGE_PIN M28      [get_ports "DDR4_C1_RESET_B"] ;# Bank  51 VCCO - VCC1V2_FPGA - IO_L7N_T1L_N1_QBC_AD13N_51
set_property IOSTANDARD  LVCMOS12 [get_ports "DDR4_C1_RESET_B"] ;# Bank  51 VCCO - VCC1V2_FPGA - IO_L7N_T1L_N1_QBC_AD13N_51
set_property PACKAGE_PIN P24      [get_ports "DDR4_C1_DQ36"] ;# Bank  51 VCCO - VCC1V2_FPGA - IO_L6P_T0U_N10_AD6P_51
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C1_DQ36"] ;# Bank  51 VCCO - VCC1V2_FPGA - IO_L6P_T0U_N10_AD6P_51
set_property PACKAGE_PIN N24      [get_ports "DDR4_C1_DQ34"] ;# Bank  51 VCCO - VCC1V2_FPGA - IO_L6N_T0U_N11_AD6N_51
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C1_DQ34"] ;# Bank  51 VCCO - VCC1V2_FPGA - IO_L6N_T0U_N11_AD6N_51
set_property PACKAGE_PIN P26      [get_ports "DDR4_C1_DQ37"] ;# Bank  51 VCCO - VCC1V2_FPGA - IO_L5P_T0U_N8_AD14P_51
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C1_DQ37"] ;# Bank  51 VCCO - VCC1V2_FPGA - IO_L5P_T0U_N8_AD14P_51
set_property PACKAGE_PIN N27      [get_ports "DDR4_C1_DQ32"] ;# Bank  51 VCCO - VCC1V2_FPGA - IO_L5N_T0U_N9_AD14N_51
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C1_DQ32"] ;# Bank  51 VCCO - VCC1V2_FPGA - IO_L5N_T0U_N9_AD14N_51
set_property PACKAGE_PIN P25      [get_ports "DDR4_C1_DQS4_T"] ;# Bank  51 VCCO - VCC1V2_FPGA - IO_L4P_T0U_N6_DBC_AD7P_51
set_property IOSTANDARD  DIFF_POD12 [get_ports "DDR4_C1_DQS4_T"] ;# Bank  51 VCCO - VCC1V2_FPGA - IO_L4P_T0U_N6_DBC_AD7P_51
set_property PACKAGE_PIN N25      [get_ports "DDR4_C1_DQS4_C"] ;# Bank  51 VCCO - VCC1V2_FPGA - IO_L4N_T0U_N7_DBC_AD7N_51
set_property IOSTANDARD  DIFF_POD12 [get_ports "DDR4_C1_DQS4_C"] ;# Bank  51 VCCO - VCC1V2_FPGA - IO_L4N_T0U_N7_DBC_AD7N_51
set_property PACKAGE_PIN R27      [get_ports "DDR4_C1_DQ33"] ;# Bank  51 VCCO - VCC1V2_FPGA - IO_L3P_T0L_N4_AD15P_51
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C1_DQ33"] ;# Bank  51 VCCO - VCC1V2_FPGA - IO_L3P_T0L_N4_AD15P_51
set_property PACKAGE_PIN P27      [get_ports "DDR4_C1_DQ38"] ;# Bank  51 VCCO - VCC1V2_FPGA - IO_L3N_T0L_N5_AD15N_51
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C1_DQ38"] ;# Bank  51 VCCO - VCC1V2_FPGA - IO_L3N_T0L_N5_AD15N_51
set_property PACKAGE_PIN T24      [get_ports "DDR4_C1_DQ39"] ;# Bank  51 VCCO - VCC1V2_FPGA - IO_L2P_T0L_N2_51
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C1_DQ39"] ;# Bank  51 VCCO - VCC1V2_FPGA - IO_L2P_T0L_N2_51
set_property PACKAGE_PIN R24      [get_ports "DDR4_C1_DQ35"] ;# Bank  51 VCCO - VCC1V2_FPGA - IO_L2N_T0L_N3_51
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C1_DQ35"] ;# Bank  51 VCCO - VCC1V2_FPGA - IO_L2N_T0L_N3_51
#set_property PACKAGE_PIN M26      [get_ports "VRP_51"] ;# Bank  51 VCCO - VCC1V2_FPGA - IO_T0U_N12_VRP_51
#set_property IOSTANDARD  LVCMOSxx [get_ports "VRP_51"] ;# Bank  51 VCCO - VCC1V2_FPGA - IO_T0U_N12_VRP_51
set_property PACKAGE_PIN T26      [get_ports "DDR4_C1_DM4"] ;# Bank  51 VCCO - VCC1V2_FPGA - IO_L1P_T0L_N0_DBC_51
set_property IOSTANDARD  POD12_DCI [get_ports "DDR4_C1_DM4"] ;# Bank  51 VCCO - VCC1V2_FPGA - IO_L1P_T0L_N0_DBC_51
#set_property PACKAGE_PIN R26      [get_ports "30N650"] ;# Bank  51 VCCO - VCC1V2_FPGA - IO_L1N_T0L_N1_DBC_51
#set_property IOSTANDARD  LVCMOSxx [get_ports "30N650"] ;# Bank  51 VCCO - VCC1V2_FPGA - IO_L1N_T0L_N1_DBC_51
set_property PACKAGE_PIN AL20     [get_ports "FPGA_EMCCLK"] ;# Bank  65 VCCO - VCC1V8_FPGA - IO_L24P_T3U_N10_EMCCLK_65
set_property IOSTANDARD  LVCMOS18 [get_ports "FPGA_EMCCLK"] ;# Bank  65 VCCO - VCC1V8_FPGA - IO_L24P_T3U_N10_EMCCLK_65
set_property PACKAGE_PIN AL19     [get_ports "FMC_HPC0_PRSNT_M2C_B_LS"] ;# Bank  65 VCCO - VCC1V8_FPGA - IO_L24N_T3U_N11_DOUT_CSO_B_65
set_property IOSTANDARD  LVCMOS18 [get_ports "FMC_HPC0_PRSNT_M2C_B_LS"] ;# Bank  65 VCCO - VCC1V8_FPGA - IO_L24N_T3U_N11_DOUT_CSO_B_65
set_property PACKAGE_PIN AM17     [get_ports "PCIE_PERST_LS"] ;# Bank  65 VCCO - VCC1V8_FPGA - IO_T3U_N12_PERSTN0_65
set_property IOSTANDARD  LVCMOS18 [get_ports "PCIE_PERST_LS"] ;# Bank  65 VCCO - VCC1V8_FPGA - IO_T3U_N12_PERSTN0_65
set_property PACKAGE_PIN AP18     [get_ports "SYSMON_SCL_LS"] ;# Bank  65 VCCO - VCC1V8_FPGA - IO_L23P_T3U_N8_I2C_SCLK_65
set_property IOSTANDARD  LVCMOS18 [get_ports "SYSMON_SCL_LS"] ;# Bank  65 VCCO - VCC1V8_FPGA - IO_L23P_T3U_N8_I2C_SCLK_65
set_property PACKAGE_PIN AP17     [get_ports "SYSMON_SDA_LS"] ;# Bank  65 VCCO - VCC1V8_FPGA - IO_L23N_T3U_N9_I2C_SDA_65
set_property IOSTANDARD  LVCMOS18 [get_ports "SYSMON_SDA_LS"] ;# Bank  65 VCCO - VCC1V8_FPGA - IO_L23N_T3U_N9_I2C_SDA_65
set_property PACKAGE_PIN AM19     [get_ports "BPI_FLASH_D4"] ;# Bank  65 VCCO - VCC1V8_FPGA - IO_L22P_T3U_N6_DBC_AD0P_D04_65
set_property IOSTANDARD  LVCMOS18 [get_ports "BPI_FLASH_D4"] ;# Bank  65 VCCO - VCC1V8_FPGA - IO_L22P_T3U_N6_DBC_AD0P_D04_65
set_property PACKAGE_PIN AM18     [get_ports "BPI_FLASH_D5"] ;# Bank  65 VCCO - VCC1V8_FPGA - IO_L22N_T3U_N7_DBC_AD0N_D05_65
set_property IOSTANDARD  LVCMOS18 [get_ports "BPI_FLASH_D5"] ;# Bank  65 VCCO - VCC1V8_FPGA - IO_L22N_T3U_N7_DBC_AD0N_D05_65
set_property PACKAGE_PIN AN20     [get_ports "BPI_FLASH_D6"] ;# Bank  65 VCCO - VCC1V8_FPGA - IO_L21P_T3L_N4_AD8P_D06_65
set_property IOSTANDARD  LVCMOS18 [get_ports "BPI_FLASH_D6"] ;# Bank  65 VCCO - VCC1V8_FPGA - IO_L21P_T3L_N4_AD8P_D06_65
set_property PACKAGE_PIN AP20     [get_ports "BPI_FLASH_D7"] ;# Bank  65 VCCO - VCC1V8_FPGA - IO_L21N_T3L_N5_AD8N_D07_65
set_property IOSTANDARD  LVCMOS18 [get_ports "BPI_FLASH_D7"] ;# Bank  65 VCCO - VCC1V8_FPGA - IO_L21N_T3L_N5_AD8N_D07_65
set_property PACKAGE_PIN AN19     [get_ports "BPI_FLASH_D8"] ;# Bank  65 VCCO - VCC1V8_FPGA - IO_L20P_T3L_N2_AD1P_D08_65
set_property IOSTANDARD  LVCMOS18 [get_ports "BPI_FLASH_D8"] ;# Bank  65 VCCO - VCC1V8_FPGA - IO_L20P_T3L_N2_AD1P_D08_65
set_property PACKAGE_PIN AN18     [get_ports "BPI_FLASH_D9"] ;# Bank  65 VCCO - VCC1V8_FPGA - IO_L20N_T3L_N3_AD1N_D09_65
set_property IOSTANDARD  LVCMOS18 [get_ports "BPI_FLASH_D9"] ;# Bank  65 VCCO - VCC1V8_FPGA - IO_L20N_T3L_N3_AD1N_D09_65
set_property PACKAGE_PIN AR18     [get_ports "BPI_FLASH_D10"] ;# Bank  65 VCCO - VCC1V8_FPGA - IO_L19P_T3L_N0_DBC_AD9P_D10_65
set_property IOSTANDARD  LVCMOS18 [get_ports "BPI_FLASH_D10"] ;# Bank  65 VCCO - VCC1V8_FPGA - IO_L19P_T3L_N0_DBC_AD9P_D10_65
set_property PACKAGE_PIN AR17     [get_ports "BPI_FLASH_D11"] ;# Bank  65 VCCO - VCC1V8_FPGA - IO_L19N_T3L_N1_DBC_AD9N_D11_65
set_property IOSTANDARD  LVCMOS18 [get_ports "BPI_FLASH_D11"] ;# Bank  65 VCCO - VCC1V8_FPGA - IO_L19N_T3L_N1_DBC_AD9N_D11_65
set_property PACKAGE_PIN AT20     [get_ports "BPI_FLASH_D12"] ;# Bank  65 VCCO - VCC1V8_FPGA - IO_L18P_T2U_N10_AD2P_D12_65
set_property IOSTANDARD  LVCMOS18 [get_ports "BPI_FLASH_D12"] ;# Bank  65 VCCO - VCC1V8_FPGA - IO_L18P_T2U_N10_AD2P_D12_65
set_property PACKAGE_PIN AT19     [get_ports "BPI_FLASH_D13"] ;# Bank  65 VCCO - VCC1V8_FPGA - IO_L18N_T2U_N11_AD2N_D13_65
set_property IOSTANDARD  LVCMOS18 [get_ports "BPI_FLASH_D13"] ;# Bank  65 VCCO - VCC1V8_FPGA - IO_L18N_T2U_N11_AD2N_D13_65
set_property PACKAGE_PIN AT17     [get_ports "BPI_FLASH_D14"] ;# Bank  65 VCCO - VCC1V8_FPGA - IO_L17P_T2U_N8_AD10P_D14_65
set_property IOSTANDARD  LVCMOS18 [get_ports "BPI_FLASH_D14"] ;# Bank  65 VCCO - VCC1V8_FPGA - IO_L17P_T2U_N8_AD10P_D14_65
set_property PACKAGE_PIN AU17     [get_ports "BPI_FLASH_D15"] ;# Bank  65 VCCO - VCC1V8_FPGA - IO_L17N_T2U_N9_AD10N_D15_65
set_property IOSTANDARD  LVCMOS18 [get_ports "BPI_FLASH_D15"] ;# Bank  65 VCCO - VCC1V8_FPGA - IO_L17N_T2U_N9_AD10N_D15_65
set_property PACKAGE_PIN AR20     [get_ports "BPI_FLASH_A0"] ;# Bank  65 VCCO - VCC1V8_FPGA - IO_L16P_T2U_N6_QBC_AD3P_A00_D16_65
set_property IOSTANDARD  LVCMOS18 [get_ports "BPI_FLASH_A0"] ;# Bank  65 VCCO - VCC1V8_FPGA - IO_L16P_T2U_N6_QBC_AD3P_A00_D16_65
set_property PACKAGE_PIN AR19     [get_ports "BPI_FLASH_A1"] ;# Bank  65 VCCO - VCC1V8_FPGA - IO_L16N_T2U_N7_QBC_AD3N_A01_D17_65
set_property IOSTANDARD  LVCMOS18 [get_ports "BPI_FLASH_A1"] ;# Bank  65 VCCO - VCC1V8_FPGA - IO_L16N_T2U_N7_QBC_AD3N_A01_D17_65
set_property PACKAGE_PIN AV20     [get_ports "BPI_FLASH_A2"] ;# Bank  65 VCCO - VCC1V8_FPGA - IO_L15P_T2L_N4_AD11P_A02_D18_65
set_property IOSTANDARD  LVCMOS18 [get_ports "BPI_FLASH_A2"] ;# Bank  65 VCCO - VCC1V8_FPGA - IO_L15P_T2L_N4_AD11P_A02_D18_65
set_property PACKAGE_PIN AW20     [get_ports "BPI_FLASH_A3"] ;# Bank  65 VCCO - VCC1V8_FPGA - IO_L15N_T2L_N5_AD11N_A03_D19_65
set_property IOSTANDARD  LVCMOS18 [get_ports "BPI_FLASH_A3"] ;# Bank  65 VCCO - VCC1V8_FPGA - IO_L15N_T2L_N5_AD11N_A03_D19_65
set_property PACKAGE_PIN AU19     [get_ports "BPI_FLASH_A4"] ;# Bank  65 VCCO - VCC1V8_FPGA - IO_L14P_T2L_N2_GC_A04_D20_65
set_property IOSTANDARD  LVCMOS18 [get_ports "BPI_FLASH_A4"] ;# Bank  65 VCCO - VCC1V8_FPGA - IO_L14P_T2L_N2_GC_A04_D20_65
set_property PACKAGE_PIN AU18     [get_ports "BPI_FLASH_A5"] ;# Bank  65 VCCO - VCC1V8_FPGA - IO_L14N_T2L_N3_GC_A05_D21_65
set_property IOSTANDARD  LVCMOS18 [get_ports "BPI_FLASH_A5"] ;# Bank  65 VCCO - VCC1V8_FPGA - IO_L14N_T2L_N3_GC_A05_D21_65
set_property PACKAGE_PIN AW17     [get_ports "BPI_FLASH_ADV"] ;# Bank  65 VCCO - VCC1V8_FPGA - IO_T2U_N12_CSI_ADV_B_65
set_property IOSTANDARD  LVCMOS18 [get_ports "BPI_FLASH_ADV"] ;# Bank  65 VCCO - VCC1V8_FPGA - IO_T2U_N12_CSI_ADV_B_65
set_property PACKAGE_PIN AV19     [get_ports "BPI_FLASH_A6"] ;# Bank  65 VCCO - VCC1V8_FPGA - IO_L13P_T2L_N0_GC_QBC_A06_D22_65
set_property IOSTANDARD  LVCMOS18 [get_ports "BPI_FLASH_A6"] ;# Bank  65 VCCO - VCC1V8_FPGA - IO_L13P_T2L_N0_GC_QBC_A06_D22_65
set_property PACKAGE_PIN AV18     [get_ports "BPI_FLASH_A7"] ;# Bank  65 VCCO - VCC1V8_FPGA - IO_L13N_T2L_N1_GC_QBC_A07_D23_65
set_property IOSTANDARD  LVCMOS18 [get_ports "BPI_FLASH_A7"] ;# Bank  65 VCCO - VCC1V8_FPGA - IO_L13N_T2L_N1_GC_QBC_A07_D23_65
set_property PACKAGE_PIN AW18     [get_ports "BPI_FLASH_A8"] ;# Bank  65 VCCO - VCC1V8_FPGA - IO_L12P_T1U_N10_GC_A08_D24_65
set_property IOSTANDARD  LVCMOS18 [get_ports "BPI_FLASH_A8"] ;# Bank  65 VCCO - VCC1V8_FPGA - IO_L12P_T1U_N10_GC_A08_D24_65
set_property PACKAGE_PIN AY18     [get_ports "BPI_FLASH_A9"] ;# Bank  65 VCCO - VCC1V8_FPGA - IO_L12N_T1U_N11_GC_A09_D25_65
set_property IOSTANDARD  LVCMOS18 [get_ports "BPI_FLASH_A9"] ;# Bank  65 VCCO - VCC1V8_FPGA - IO_L12N_T1U_N11_GC_A09_D25_65
set_property PACKAGE_PIN AY17     [get_ports "PCIE_WAKE_B_LS"] ;# Bank  65 VCCO - VCC1V8_FPGA - IO_T1U_N12_PERSTN1_65
set_property IOSTANDARD  LVCMOS18 [get_ports "PCIE_WAKE_B_LS"] ;# Bank  65 VCCO - VCC1V8_FPGA - IO_T1U_N12_PERSTN1_65
set_property PACKAGE_PIN AY19     [get_ports "BPI_FLASH_A10"] ;# Bank  65 VCCO - VCC1V8_FPGA - IO_L11P_T1U_N8_GC_A10_D26_65
set_property IOSTANDARD  LVCMOS18 [get_ports "BPI_FLASH_A10"] ;# Bank  65 VCCO - VCC1V8_FPGA - IO_L11P_T1U_N8_GC_A10_D26_65
set_property PACKAGE_PIN BA19     [get_ports "BPI_FLASH_A11"] ;# Bank  65 VCCO - VCC1V8_FPGA - IO_L11N_T1U_N9_GC_A11_D27_65
set_property IOSTANDARD  LVCMOS18 [get_ports "BPI_FLASH_A11"] ;# Bank  65 VCCO - VCC1V8_FPGA - IO_L11N_T1U_N9_GC_A11_D27_65
set_property PACKAGE_PIN BA17     [get_ports "BPI_FLASH_A12"] ;# Bank  65 VCCO - VCC1V8_FPGA - IO_L10P_T1U_N6_QBC_AD4P_A12_D28_65
set_property IOSTANDARD  LVCMOS18 [get_ports "BPI_FLASH_A12"] ;# Bank  65 VCCO - VCC1V8_FPGA - IO_L10P_T1U_N6_QBC_AD4P_A12_D28_65
set_property PACKAGE_PIN BB17     [get_ports "BPI_FLASH_A13"] ;# Bank  65 VCCO - VCC1V8_FPGA - IO_L10N_T1U_N7_QBC_AD4N_A13_D29_65
set_property IOSTANDARD  LVCMOS18 [get_ports "BPI_FLASH_A13"] ;# Bank  65 VCCO - VCC1V8_FPGA - IO_L10N_T1U_N7_QBC_AD4N_A13_D29_65
set_property PACKAGE_PIN BB19     [get_ports "BPI_FLASH_A14"] ;# Bank  65 VCCO - VCC1V8_FPGA - IO_L9P_T1L_N4_AD12P_A14_D30_65
set_property IOSTANDARD  LVCMOS18 [get_ports "BPI_FLASH_A14"] ;# Bank  65 VCCO - VCC1V8_FPGA - IO_L9P_T1L_N4_AD12P_A14_D30_65
set_property PACKAGE_PIN BC19     [get_ports "BPI_FLASH_A15"] ;# Bank  65 VCCO - VCC1V8_FPGA - IO_L9N_T1L_N5_AD12N_A15_D31_65
set_property IOSTANDARD  LVCMOS18 [get_ports "BPI_FLASH_A15"] ;# Bank  65 VCCO - VCC1V8_FPGA - IO_L9N_T1L_N5_AD12N_A15_D31_65
set_property PACKAGE_PIN BB18     [get_ports "BPI_FLASH_A16"] ;# Bank  65 VCCO - VCC1V8_FPGA - IO_L8P_T1L_N2_AD5P_A16_65
set_property IOSTANDARD  LVCMOS18 [get_ports "BPI_FLASH_A16"] ;# Bank  65 VCCO - VCC1V8_FPGA - IO_L8P_T1L_N2_AD5P_A16_65
set_property PACKAGE_PIN BC18     [get_ports "BPI_FLASH_A17"] ;# Bank  65 VCCO - VCC1V8_FPGA - IO_L8N_T1L_N3_AD5N_A17_65
set_property IOSTANDARD  LVCMOS18 [get_ports "BPI_FLASH_A17"] ;# Bank  65 VCCO - VCC1V8_FPGA - IO_L8N_T1L_N3_AD5N_A17_65
set_property PACKAGE_PIN AY20     [get_ports "BPI_FLASH_A18"] ;# Bank  65 VCCO - VCC1V8_FPGA - IO_L7P_T1L_N0_QBC_AD13P_A18_65
set_property IOSTANDARD  LVCMOS18 [get_ports "BPI_FLASH_A18"] ;# Bank  65 VCCO - VCC1V8_FPGA - IO_L7P_T1L_N0_QBC_AD13P_A18_65
set_property PACKAGE_PIN BA20     [get_ports "BPI_FLASH_A19"] ;# Bank  65 VCCO - VCC1V8_FPGA - IO_L7N_T1L_N1_QBC_AD13N_A19_65
set_property IOSTANDARD  LVCMOS18 [get_ports "BPI_FLASH_A19"] ;# Bank  65 VCCO - VCC1V8_FPGA - IO_L7N_T1L_N1_QBC_AD13N_A19_65
set_property PACKAGE_PIN BD18     [get_ports "BPI_FLASH_A20"] ;# Bank  65 VCCO - VCC1V8_FPGA - IO_L6P_T0U_N10_AD6P_A20_65
set_property IOSTANDARD  LVCMOS18 [get_ports "BPI_FLASH_A20"] ;# Bank  65 VCCO - VCC1V8_FPGA - IO_L6P_T0U_N10_AD6P_A20_65
set_property PACKAGE_PIN BD17     [get_ports "BPI_FLASH_A21"] ;# Bank  65 VCCO - VCC1V8_FPGA - IO_L6N_T0U_N11_AD6N_A21_65
set_property IOSTANDARD  LVCMOS18 [get_ports "BPI_FLASH_A21"] ;# Bank  65 VCCO - VCC1V8_FPGA - IO_L6N_T0U_N11_AD6N_A21_65
set_property PACKAGE_PIN BC20     [get_ports "BPI_FLASH_A22"] ;# Bank  65 VCCO - VCC1V8_FPGA - IO_L5P_T0U_N8_AD14P_A22_65
set_property IOSTANDARD  LVCMOS18 [get_ports "BPI_FLASH_A22"] ;# Bank  65 VCCO - VCC1V8_FPGA - IO_L5P_T0U_N8_AD14P_A22_65
set_property PACKAGE_PIN BD20     [get_ports "BPI_FLASH_A23"] ;# Bank  65 VCCO - VCC1V8_FPGA - IO_L5N_T0U_N9_AD14N_A23_65
set_property IOSTANDARD  LVCMOS18 [get_ports "BPI_FLASH_A23"] ;# Bank  65 VCCO - VCC1V8_FPGA - IO_L5N_T0U_N9_AD14N_A23_65
#set_property PACKAGE_PIN BE18     [get_ports "8N7164"] ;# Bank  65 VCCO - VCC1V8_FPGA - IO_L4P_T0U_N6_DBC_AD7P_A24_65
#set_property IOSTANDARD  LVCMOSxx [get_ports "8N7164"] ;# Bank  65 VCCO - VCC1V8_FPGA - IO_L4P_T0U_N6_DBC_AD7P_A24_65
set_property PACKAGE_PIN BE17     [get_ports "SM_FAN_TACH"] ;# Bank  65 VCCO - VCC1V8_FPGA - IO_L4N_T0U_N7_DBC_AD7N_A25_65
set_property IOSTANDARD  LVCMOS18 [get_ports "SM_FAN_TACH"] ;# Bank  65 VCCO - VCC1V8_FPGA - IO_L4N_T0U_N7_DBC_AD7N_A25_65
#set_property PACKAGE_PIN BE19     [get_ports "8N7178"] ;# Bank  65 VCCO - VCC1V8_FPGA - IO_L3P_T0L_N4_AD15P_A26_65
#set_property IOSTANDARD  LVCMOSxx [get_ports "8N7178"] ;# Bank  65 VCCO - VCC1V8_FPGA - IO_L3P_T0L_N4_AD15P_A26_65
#set_property PACKAGE_PIN BF19     [get_ports "8N7181"] ;# Bank  65 VCCO - VCC1V8_FPGA - IO_L3N_T0L_N5_AD15N_A27_65
#set_property IOSTANDARD  LVCMOSxx [get_ports "8N7181"] ;# Bank  65 VCCO - VCC1V8_FPGA - IO_L3N_T0L_N5_AD15N_A27_65
set_property PACKAGE_PIN BF17     [get_ports "BPI_FLASH_OE_B"] ;# Bank  65 VCCO - VCC1V8_FPGA - IO_L2P_T0L_N2_FOE_B_65
set_property IOSTANDARD  LVCMOS18 [get_ports "BPI_FLASH_OE_B"] ;# Bank  65 VCCO - VCC1V8_FPGA - IO_L2P_T0L_N2_FOE_B_65
set_property PACKAGE_PIN BF16     [get_ports "BPI_FLASH_FWE_B"] ;# Bank  65 VCCO - VCC1V8_FPGA - IO_L2N_T0L_N3_FWE_FCS2_B_65
set_property IOSTANDARD  LVCMOS18 [get_ports "BPI_FLASH_FWE_B"] ;# Bank  65 VCCO - VCC1V8_FPGA - IO_L2N_T0L_N3_FWE_FCS2_B_65
set_property PACKAGE_PIN BF21     [get_ports "SM_FAN_PWM"] ;# Bank  65 VCCO - VCC1V8_FPGA - IO_T0U_N12_VRP_A28_65
set_property IOSTANDARD  LVCMOS18 [get_ports "SM_FAN_PWM"] ;# Bank  65 VCCO - VCC1V8_FPGA - IO_T0U_N12_VRP_A28_65
set_property PACKAGE_PIN BE20     [get_ports "BPI_FLASH_A24"] ;# Bank  65 VCCO - VCC1V8_FPGA - IO_L1P_T0L_N0_DBC_RS0_65
set_property IOSTANDARD  LVCMOS18 [get_ports "BPI_FLASH_A24"] ;# Bank  65 VCCO - VCC1V8_FPGA - IO_L1P_T0L_N0_DBC_RS0_65
set_property PACKAGE_PIN BF20     [get_ports "BPI_FLASH_A25"] ;# Bank  65 VCCO - VCC1V8_FPGA - IO_L1N_T0L_N1_DBC_RS1_65
set_property IOSTANDARD  LVCMOS18 [get_ports "BPI_FLASH_A25"] ;# Bank  65 VCCO - VCC1V8_FPGA - IO_L1N_T0L_N1_DBC_RS1_65
set_property PACKAGE_PIN BB13     [get_ports "FMC_HPC0_LA14_P"] ;# Bank  66 VCCO - VADJ_1V8_FPGA - IO_L24P_T3U_N10_66
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC0_LA14_P"] ;# Bank  66 VCCO - VADJ_1V8_FPGA - IO_L24P_T3U_N10_66
set_property PACKAGE_PIN BB12     [get_ports "FMC_HPC0_LA14_N"] ;# Bank  66 VCCO - VADJ_1V8_FPGA - IO_L24N_T3U_N11_66
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC0_LA14_N"] ;# Bank  66 VCCO - VADJ_1V8_FPGA - IO_L24N_T3U_N11_66
#set_property PACKAGE_PIN BB11     [get_ports "9N4392"] ;# Bank  66 VCCO - VADJ_1V8_FPGA - IO_T3U_N12_66
#set_property IOSTANDARD  LVCMOSxx [get_ports "9N4392"] ;# Bank  66 VCCO - VADJ_1V8_FPGA - IO_T3U_N12_66
set_property PACKAGE_PIN BA14     [get_ports "FMC_HPC0_LA13_P"] ;# Bank  66 VCCO - VADJ_1V8_FPGA - IO_L23P_T3U_N8_66
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC0_LA13_P"] ;# Bank  66 VCCO - VADJ_1V8_FPGA - IO_L23P_T3U_N8_66
set_property PACKAGE_PIN BB14     [get_ports "FMC_HPC0_LA13_N"] ;# Bank  66 VCCO - VADJ_1V8_FPGA - IO_L23N_T3U_N9_66
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC0_LA13_N"] ;# Bank  66 VCCO - VADJ_1V8_FPGA - IO_L23N_T3U_N9_66
set_property PACKAGE_PIN BA16     [get_ports "SYSMON_AD0_R_P"] ;# Bank  66 VCCO - VADJ_1V8_FPGA - IO_L22P_T3U_N6_DBC_AD0P_66
set_property IOSTANDARD  LVCMOS18 [get_ports "SYSMON_AD0_R_P"] ;# Bank  66 VCCO - VADJ_1V8_FPGA - IO_L22P_T3U_N6_DBC_AD0P_66
set_property PACKAGE_PIN BA15     [get_ports "SYSMON_AD0_R_N"] ;# Bank  66 VCCO - VADJ_1V8_FPGA - IO_L22N_T3U_N7_DBC_AD0N_66
set_property IOSTANDARD  LVCMOS18 [get_ports "SYSMON_AD0_R_N"] ;# Bank  66 VCCO - VADJ_1V8_FPGA - IO_L22N_T3U_N7_DBC_AD0N_66
set_property PACKAGE_PIN BC15     [get_ports "SYSMON_AD8_R_P"] ;# Bank  66 VCCO - VADJ_1V8_FPGA - IO_L21P_T3L_N4_AD8P_66
set_property IOSTANDARD  LVCMOS18 [get_ports "SYSMON_AD8_R_P"] ;# Bank  66 VCCO - VADJ_1V8_FPGA - IO_L21P_T3L_N4_AD8P_66
set_property PACKAGE_PIN BD15     [get_ports "SYSMON_AD8_R_N"] ;# Bank  66 VCCO - VADJ_1V8_FPGA - IO_L21N_T3L_N5_AD8N_66
set_property IOSTANDARD  LVCMOS18 [get_ports "SYSMON_AD8_R_N"] ;# Bank  66 VCCO - VADJ_1V8_FPGA - IO_L21N_T3L_N5_AD8N_66
set_property PACKAGE_PIN BB16     [get_ports "PMOD0_3_LS"] ;# Bank  66 VCCO - VADJ_1V8_FPGA - IO_L20P_T3L_N2_AD1P_66
set_property IOSTANDARD  LVCMOS18 [get_ports "PMOD0_3_LS"] ;# Bank  66 VCCO - VADJ_1V8_FPGA - IO_L20P_T3L_N2_AD1P_66
set_property PACKAGE_PIN BC16     [get_ports "PMOD0_7_LS"] ;# Bank  66 VCCO - VADJ_1V8_FPGA - IO_L20N_T3L_N3_AD1N_66
set_property IOSTANDARD  LVCMOS18 [get_ports "PMOD0_7_LS"] ;# Bank  66 VCCO - VADJ_1V8_FPGA - IO_L20N_T3L_N3_AD1N_66
set_property PACKAGE_PIN BC14     [get_ports "PMOD0_0_LS"] ;# Bank  66 VCCO - VADJ_1V8_FPGA - IO_L19P_T3L_N0_DBC_AD9P_66
set_property IOSTANDARD  LVCMOS18 [get_ports "PMOD0_0_LS"] ;# Bank  66 VCCO - VADJ_1V8_FPGA - IO_L19P_T3L_N0_DBC_AD9P_66
set_property PACKAGE_PIN BC13     [get_ports "PMOD0_4_LS"] ;# Bank  66 VCCO - VADJ_1V8_FPGA - IO_L19N_T3L_N1_DBC_AD9N_66
set_property IOSTANDARD  LVCMOS18 [get_ports "PMOD0_4_LS"] ;# Bank  66 VCCO - VADJ_1V8_FPGA - IO_L19N_T3L_N1_DBC_AD9N_66
set_property PACKAGE_PIN AW8      [get_ports "SYSMON_AD2_R_P"] ;# Bank  66 VCCO - VADJ_1V8_FPGA - IO_L18P_T2U_N10_AD2P_66
set_property IOSTANDARD  LVCMOS18 [get_ports "SYSMON_AD2_R_P"] ;# Bank  66 VCCO - VADJ_1V8_FPGA - IO_L18P_T2U_N10_AD2P_66
set_property PACKAGE_PIN AW7      [get_ports "SYSMON_AD2_R_N"] ;# Bank  66 VCCO - VADJ_1V8_FPGA - IO_L18N_T2U_N11_AD2N_66
set_property IOSTANDARD  LVCMOS18 [get_ports "SYSMON_AD2_R_N"] ;# Bank  66 VCCO - VADJ_1V8_FPGA - IO_L18N_T2U_N11_AD2N_66
set_property PACKAGE_PIN AY8      [get_ports "FMC_HPC0_LA16_P"] ;# Bank  66 VCCO - VADJ_1V8_FPGA - IO_L17P_T2U_N8_AD10P_66
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC0_LA16_P"] ;# Bank  66 VCCO - VADJ_1V8_FPGA - IO_L17P_T2U_N8_AD10P_66
set_property PACKAGE_PIN AY7      [get_ports "FMC_HPC0_LA16_N"] ;# Bank  66 VCCO - VADJ_1V8_FPGA - IO_L17N_T2U_N9_AD10N_66
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC0_LA16_N"] ;# Bank  66 VCCO - VADJ_1V8_FPGA - IO_L17N_T2U_N9_AD10N_66
set_property PACKAGE_PIN AV9      [get_ports "FMC_HPC0_LA15_P"] ;# Bank  66 VCCO - VADJ_1V8_FPGA - IO_L16P_T2U_N6_QBC_AD3P_66
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC0_LA15_P"] ;# Bank  66 VCCO - VADJ_1V8_FPGA - IO_L16P_T2U_N6_QBC_AD3P_66
set_property PACKAGE_PIN AV8      [get_ports "FMC_HPC0_LA15_N"] ;# Bank  66 VCCO - VADJ_1V8_FPGA - IO_L16N_T2U_N7_QBC_AD3N_66
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC0_LA15_N"] ;# Bank  66 VCCO - VADJ_1V8_FPGA - IO_L16N_T2U_N7_QBC_AD3N_66
set_property PACKAGE_PIN BA7      [get_ports "FMC_HPC0_LA02_P"] ;# Bank  66 VCCO - VADJ_1V8_FPGA - IO_L15P_T2L_N4_AD11P_66
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC0_LA02_P"] ;# Bank  66 VCCO - VADJ_1V8_FPGA - IO_L15P_T2L_N4_AD11P_66
set_property PACKAGE_PIN BB7      [get_ports "FMC_HPC0_LA02_N"] ;# Bank  66 VCCO - VADJ_1V8_FPGA - IO_L15N_T2L_N5_AD11N_66
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC0_LA02_N"] ;# Bank  66 VCCO - VADJ_1V8_FPGA - IO_L15N_T2L_N5_AD11N_66
set_property PACKAGE_PIN BB9      [get_ports "FMC_HPC0_CLK0_M2C_P"] ;# Bank  66 VCCO - VADJ_1V8_FPGA - IO_L14P_T2L_N2_GC_66
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC0_CLK0_M2C_P"] ;# Bank  66 VCCO - VADJ_1V8_FPGA - IO_L14P_T2L_N2_GC_66
set_property PACKAGE_PIN BB8      [get_ports "FMC_HPC0_CLK0_M2C_N"] ;# Bank  66 VCCO - VADJ_1V8_FPGA - IO_L14N_T2L_N3_GC_66
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC0_CLK0_M2C_N"] ;# Bank  66 VCCO - VADJ_1V8_FPGA - IO_L14N_T2L_N3_GC_66
set_property PACKAGE_PIN BA10     [get_ports "PMOD0_1_LS"] ;# Bank  66 VCCO - VADJ_1V8_FPGA - IO_T2U_N12_66
set_property IOSTANDARD  LVCMOS18 [get_ports "PMOD0_1_LS"] ;# Bank  66 VCCO - VADJ_1V8_FPGA - IO_T2U_N12_66
set_property PACKAGE_PIN AY9      [get_ports "FMC_HPC0_LA00_CC_P"] ;# Bank  66 VCCO - VADJ_1V8_FPGA - IO_L13P_T2L_N0_GC_QBC_66
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC0_LA00_CC_P"] ;# Bank  66 VCCO - VADJ_1V8_FPGA - IO_L13P_T2L_N0_GC_QBC_66
set_property PACKAGE_PIN BA9      [get_ports "FMC_HPC0_LA00_CC_N"] ;# Bank  66 VCCO - VADJ_1V8_FPGA - IO_L13N_T2L_N1_GC_QBC_66
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC0_LA00_CC_N"] ;# Bank  66 VCCO - VADJ_1V8_FPGA - IO_L13N_T2L_N1_GC_QBC_66
set_property PACKAGE_PIN BC9      [get_ports "CLK_125MHZ_P"] ;# Bank  66 VCCO - VADJ_1V8_FPGA - IO_L12P_T1U_N10_GC_66
set_property IOSTANDARD  LVDS [get_ports "CLK_125MHZ_P"] ;# Bank  66 VCCO - VADJ_1V8_FPGA - IO_L12P_T1U_N10_GC_66
set_property PACKAGE_PIN BC8      [get_ports "CLK_125MHZ_N"] ;# Bank  66 VCCO - VADJ_1V8_FPGA - IO_L12N_T1U_N11_GC_66
set_property IOSTANDARD  LVDS [get_ports "CLK_125MHZ_N"] ;# Bank  66 VCCO - VADJ_1V8_FPGA - IO_L12N_T1U_N11_GC_66
set_property PACKAGE_PIN BF7      [get_ports "PMOD0_5_LS"] ;# Bank  66 VCCO - VADJ_1V8_FPGA - IO_T1U_N12_66
set_property IOSTANDARD  LVCMOS18 [get_ports "PMOD0_5_LS"] ;# Bank  66 VCCO - VADJ_1V8_FPGA - IO_T1U_N12_66
set_property PACKAGE_PIN BC10     [get_ports "FMC_HPC0_LA01_CC_P"] ;# Bank  66 VCCO - VADJ_1V8_FPGA - IO_L11P_T1U_N8_GC_66
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC0_LA01_CC_P"] ;# Bank  66 VCCO - VADJ_1V8_FPGA - IO_L11P_T1U_N8_GC_66
set_property PACKAGE_PIN BD10     [get_ports "FMC_HPC0_LA01_CC_N"] ;# Bank  66 VCCO - VADJ_1V8_FPGA - IO_L11N_T1U_N9_GC_66
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC0_LA01_CC_N"] ;# Bank  66 VCCO - VADJ_1V8_FPGA - IO_L11N_T1U_N9_GC_66
set_property PACKAGE_PIN BF10     [get_ports "FMC_HPC0_LA08_P"] ;# Bank  66 VCCO - VADJ_1V8_FPGA - IO_L10P_T1U_N6_QBC_AD4P_66
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC0_LA08_P"] ;# Bank  66 VCCO - VADJ_1V8_FPGA - IO_L10P_T1U_N6_QBC_AD4P_66
set_property PACKAGE_PIN BF9      [get_ports "FMC_HPC0_LA08_N"] ;# Bank  66 VCCO - VADJ_1V8_FPGA - IO_L10N_T1U_N7_QBC_AD4N_66
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC0_LA08_N"] ;# Bank  66 VCCO - VADJ_1V8_FPGA - IO_L10N_T1U_N7_QBC_AD4N_66
set_property PACKAGE_PIN BE10     [get_ports "FMC_HPC0_LA06_P"] ;# Bank  66 VCCO - VADJ_1V8_FPGA - IO_L9P_T1L_N4_AD12P_66
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC0_LA06_P"] ;# Bank  66 VCCO - VADJ_1V8_FPGA - IO_L9P_T1L_N4_AD12P_66
set_property PACKAGE_PIN BE9      [get_ports "FMC_HPC0_LA06_N"] ;# Bank  66 VCCO - VADJ_1V8_FPGA - IO_L9N_T1L_N5_AD12N_66
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC0_LA06_N"] ;# Bank  66 VCCO - VADJ_1V8_FPGA - IO_L9N_T1L_N5_AD12N_66
set_property PACKAGE_PIN BE8      [get_ports "FMC_HPC0_LA04_P"] ;# Bank  66 VCCO - VADJ_1V8_FPGA - IO_L8P_T1L_N2_AD5P_66
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC0_LA04_P"] ;# Bank  66 VCCO - VADJ_1V8_FPGA - IO_L8P_T1L_N2_AD5P_66
set_property PACKAGE_PIN BE7      [get_ports "FMC_HPC0_LA04_N"] ;# Bank  66 VCCO - VADJ_1V8_FPGA - IO_L8N_T1L_N3_AD5N_66
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC0_LA04_N"] ;# Bank  66 VCCO - VADJ_1V8_FPGA - IO_L8N_T1L_N3_AD5N_66
set_property PACKAGE_PIN BD8      [get_ports "FMC_HPC0_LA03_P"] ;# Bank  66 VCCO - VADJ_1V8_FPGA - IO_L7P_T1L_N0_QBC_AD13P_66
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC0_LA03_P"] ;# Bank  66 VCCO - VADJ_1V8_FPGA - IO_L7P_T1L_N0_QBC_AD13P_66
set_property PACKAGE_PIN BD7      [get_ports "FMC_HPC0_LA03_N"] ;# Bank  66 VCCO - VADJ_1V8_FPGA - IO_L7N_T1L_N1_QBC_AD13N_66
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC0_LA03_N"] ;# Bank  66 VCCO - VADJ_1V8_FPGA - IO_L7N_T1L_N1_QBC_AD13N_66
set_property PACKAGE_PIN BE15     [get_ports "FMC_HPC0_LA12_P"] ;# Bank  66 VCCO - VADJ_1V8_FPGA - IO_L6P_T0U_N10_AD6P_66
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC0_LA12_P"] ;# Bank  66 VCCO - VADJ_1V8_FPGA - IO_L6P_T0U_N10_AD6P_66
set_property PACKAGE_PIN BF15     [get_ports "FMC_HPC0_LA12_N"] ;# Bank  66 VCCO - VADJ_1V8_FPGA - IO_L6N_T0U_N11_AD6N_66
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC0_LA12_N"] ;# Bank  66 VCCO - VADJ_1V8_FPGA - IO_L6N_T0U_N11_AD6N_66
set_property PACKAGE_PIN BE14     [get_ports "FMC_HPC0_LA10_P"] ;# Bank  66 VCCO - VADJ_1V8_FPGA - IO_L5P_T0U_N8_AD14P_66
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC0_LA10_P"] ;# Bank  66 VCCO - VADJ_1V8_FPGA - IO_L5P_T0U_N8_AD14P_66
set_property PACKAGE_PIN BF14     [get_ports "FMC_HPC0_LA10_N"] ;# Bank  66 VCCO - VADJ_1V8_FPGA - IO_L5N_T0U_N9_AD14N_66
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC0_LA10_N"] ;# Bank  66 VCCO - VADJ_1V8_FPGA - IO_L5N_T0U_N9_AD14N_66
set_property PACKAGE_PIN BD13     [get_ports "FMC_HPC0_LA09_P"] ;# Bank  66 VCCO - VADJ_1V8_FPGA - IO_L4P_T0U_N6_DBC_AD7P_66
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC0_LA09_P"] ;# Bank  66 VCCO - VADJ_1V8_FPGA - IO_L4P_T0U_N6_DBC_AD7P_66
set_property PACKAGE_PIN BE13     [get_ports "FMC_HPC0_LA09_N"] ;# Bank  66 VCCO - VADJ_1V8_FPGA - IO_L4N_T0U_N7_DBC_AD7N_66
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC0_LA09_N"] ;# Bank  66 VCCO - VADJ_1V8_FPGA - IO_L4N_T0U_N7_DBC_AD7N_66
set_property PACKAGE_PIN BC11     [get_ports "FMC_HPC0_LA11_P"] ;# Bank  66 VCCO - VADJ_1V8_FPGA - IO_L3P_T0L_N4_AD15P_66
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC0_LA11_P"] ;# Bank  66 VCCO - VADJ_1V8_FPGA - IO_L3P_T0L_N4_AD15P_66
set_property PACKAGE_PIN BD11     [get_ports "FMC_HPC0_LA11_N"] ;# Bank  66 VCCO - VADJ_1V8_FPGA - IO_L3N_T0L_N5_AD15N_66
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC0_LA11_N"] ;# Bank  66 VCCO - VADJ_1V8_FPGA - IO_L3N_T0L_N5_AD15N_66
set_property PACKAGE_PIN BF12     [get_ports "FMC_HPC0_LA05_P"] ;# Bank  66 VCCO - VADJ_1V8_FPGA - IO_L2P_T0L_N2_66
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC0_LA05_P"] ;# Bank  66 VCCO - VADJ_1V8_FPGA - IO_L2P_T0L_N2_66
set_property PACKAGE_PIN BF11     [get_ports "FMC_HPC0_LA05_N"] ;# Bank  66 VCCO - VADJ_1V8_FPGA - IO_L2N_T0L_N3_66
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC0_LA05_N"] ;# Bank  66 VCCO - VADJ_1V8_FPGA - IO_L2N_T0L_N3_66
#set_property PACKAGE_PIN BD16     [get_ports "VRP_66"] ;# Bank  66 VCCO - VADJ_1V8_FPGA - IO_T0U_N12_VRP_66
#set_property IOSTANDARD  LVCMOSxx [get_ports "VRP_66"] ;# Bank  66 VCCO - VADJ_1V8_FPGA - IO_T0U_N12_VRP_66
set_property PACKAGE_PIN BD12     [get_ports "FMC_HPC0_LA07_P"] ;# Bank  66 VCCO - VADJ_1V8_FPGA - IO_L1P_T0L_N0_DBC_66
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC0_LA07_P"] ;# Bank  66 VCCO - VADJ_1V8_FPGA - IO_L1P_T0L_N0_DBC_66
set_property PACKAGE_PIN BE12     [get_ports "FMC_HPC0_LA07_N"] ;# Bank  66 VCCO - VADJ_1V8_FPGA - IO_L1N_T0L_N1_DBC_66
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC0_LA07_N"] ;# Bank  66 VCCO - VADJ_1V8_FPGA - IO_L1N_T0L_N1_DBC_66
set_property PACKAGE_PIN AK14     [get_ports "FMC_HPC0_LA29_P"] ;# Bank  67 VCCO - VADJ_1V8_FPGA - IO_L24P_T3U_N10_67
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC0_LA29_P"] ;# Bank  67 VCCO - VADJ_1V8_FPGA - IO_L24P_T3U_N10_67
set_property PACKAGE_PIN AK13     [get_ports "FMC_HPC0_LA29_N"] ;# Bank  67 VCCO - VADJ_1V8_FPGA - IO_L24N_T3U_N11_67
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC0_LA29_N"] ;# Bank  67 VCCO - VADJ_1V8_FPGA - IO_L24N_T3U_N11_67
#set_property PACKAGE_PIN AM16     [get_ports "9N4052"] ;# Bank  67 VCCO - VADJ_1V8_FPGA - IO_T3U_N12_67
#set_property IOSTANDARD  LVCMOSxx [get_ports "9N4052"] ;# Bank  67 VCCO - VADJ_1V8_FPGA - IO_T3U_N12_67
set_property PACKAGE_PIN AM13     [get_ports "FMC_HPC0_LA25_P"] ;# Bank  67 VCCO - VADJ_1V8_FPGA - IO_L23P_T3U_N8_67
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC0_LA25_P"] ;# Bank  67 VCCO - VADJ_1V8_FPGA - IO_L23P_T3U_N8_67
set_property PACKAGE_PIN AM12     [get_ports "FMC_HPC0_LA25_N"] ;# Bank  67 VCCO - VADJ_1V8_FPGA - IO_L23N_T3U_N9_67
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC0_LA25_N"] ;# Bank  67 VCCO - VADJ_1V8_FPGA - IO_L23N_T3U_N9_67
set_property PACKAGE_PIN AJ13     [get_ports "FMC_HPC0_LA28_P"] ;# Bank  67 VCCO - VADJ_1V8_FPGA - IO_L22P_T3U_N6_DBC_AD0P_67
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC0_LA28_P"] ;# Bank  67 VCCO - VADJ_1V8_FPGA - IO_L22P_T3U_N6_DBC_AD0P_67
set_property PACKAGE_PIN AJ12     [get_ports "FMC_HPC0_LA28_N"] ;# Bank  67 VCCO - VADJ_1V8_FPGA - IO_L22N_T3U_N7_DBC_AD0N_67
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC0_LA28_N"] ;# Bank  67 VCCO - VADJ_1V8_FPGA - IO_L22N_T3U_N7_DBC_AD0N_67
set_property PACKAGE_PIN AK12     [get_ports "FMC_HPC0_LA30_P"] ;# Bank  67 VCCO - VADJ_1V8_FPGA - IO_L21P_T3L_N4_AD8P_67
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC0_LA30_P"] ;# Bank  67 VCCO - VADJ_1V8_FPGA - IO_L21P_T3L_N4_AD8P_67
set_property PACKAGE_PIN AL12     [get_ports "FMC_HPC0_LA30_N"] ;# Bank  67 VCCO - VADJ_1V8_FPGA - IO_L21N_T3L_N5_AD8N_67
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC0_LA30_N"] ;# Bank  67 VCCO - VADJ_1V8_FPGA - IO_L21N_T3L_N5_AD8N_67
set_property PACKAGE_PIN AK15     [get_ports "FMC_HPC0_LA24_P"] ;# Bank  67 VCCO - VADJ_1V8_FPGA - IO_L20P_T3L_N2_AD1P_67
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC0_LA24_P"] ;# Bank  67 VCCO - VADJ_1V8_FPGA - IO_L20P_T3L_N2_AD1P_67
set_property PACKAGE_PIN AL15     [get_ports "FMC_HPC0_LA24_N"] ;# Bank  67 VCCO - VADJ_1V8_FPGA - IO_L20N_T3L_N3_AD1N_67
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC0_LA24_N"] ;# Bank  67 VCCO - VADJ_1V8_FPGA - IO_L20N_T3L_N3_AD1N_67
set_property PACKAGE_PIN AL14     [get_ports "FMC_HPC0_LA26_P"] ;# Bank  67 VCCO - VADJ_1V8_FPGA - IO_L19P_T3L_N0_DBC_AD9P_67
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC0_LA26_P"] ;# Bank  67 VCCO - VADJ_1V8_FPGA - IO_L19P_T3L_N0_DBC_AD9P_67
set_property PACKAGE_PIN AM14     [get_ports "FMC_HPC0_LA26_N"] ;# Bank  67 VCCO - VADJ_1V8_FPGA - IO_L19N_T3L_N1_DBC_AD9N_67
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC0_LA26_N"] ;# Bank  67 VCCO - VADJ_1V8_FPGA - IO_L19N_T3L_N1_DBC_AD9N_67
set_property PACKAGE_PIN AN15     [get_ports "FMC_HPC0_LA22_P"] ;# Bank  67 VCCO - VADJ_1V8_FPGA - IO_L18P_T2U_N10_AD2P_67
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC0_LA22_P"] ;# Bank  67 VCCO - VADJ_1V8_FPGA - IO_L18P_T2U_N10_AD2P_67
set_property PACKAGE_PIN AP15     [get_ports "FMC_HPC0_LA22_N"] ;# Bank  67 VCCO - VADJ_1V8_FPGA - IO_L18N_T2U_N11_AD2N_67
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC0_LA22_N"] ;# Bank  67 VCCO - VADJ_1V8_FPGA - IO_L18N_T2U_N11_AD2N_67
set_property PACKAGE_PIN AN16     [get_ports "FMC_HPC0_LA21_P"] ;# Bank  67 VCCO - VADJ_1V8_FPGA - IO_L17P_T2U_N8_AD10P_67
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC0_LA21_P"] ;# Bank  67 VCCO - VADJ_1V8_FPGA - IO_L17P_T2U_N8_AD10P_67
set_property PACKAGE_PIN AP16     [get_ports "FMC_HPC0_LA21_N"] ;# Bank  67 VCCO - VADJ_1V8_FPGA - IO_L17N_T2U_N9_AD10N_67
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC0_LA21_N"] ;# Bank  67 VCCO - VADJ_1V8_FPGA - IO_L17N_T2U_N9_AD10N_67
set_property PACKAGE_PIN AP12     [get_ports "FMC_HPC0_LA31_P"] ;# Bank  67 VCCO - VADJ_1V8_FPGA - IO_L16P_T2U_N6_QBC_AD3P_67
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC0_LA31_P"] ;# Bank  67 VCCO - VADJ_1V8_FPGA - IO_L16P_T2U_N6_QBC_AD3P_67
set_property PACKAGE_PIN AR12     [get_ports "FMC_HPC0_LA31_N"] ;# Bank  67 VCCO - VADJ_1V8_FPGA - IO_L16N_T2U_N7_QBC_AD3N_67
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC0_LA31_N"] ;# Bank  67 VCCO - VADJ_1V8_FPGA - IO_L16N_T2U_N7_QBC_AD3N_67
set_property PACKAGE_PIN AN14     [get_ports "FMC_HPC0_LA27_P"] ;# Bank  67 VCCO - VADJ_1V8_FPGA - IO_L15P_T2L_N4_AD11P_67
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC0_LA27_P"] ;# Bank  67 VCCO - VADJ_1V8_FPGA - IO_L15P_T2L_N4_AD11P_67
set_property PACKAGE_PIN AN13     [get_ports "FMC_HPC0_LA27_N"] ;# Bank  67 VCCO - VADJ_1V8_FPGA - IO_L15N_T2L_N5_AD11N_67
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC0_LA27_N"] ;# Bank  67 VCCO - VADJ_1V8_FPGA - IO_L15N_T2L_N5_AD11N_67
set_property PACKAGE_PIN AP13     [get_ports "FMC_HPC0_LA18_CC_P"] ;# Bank  67 VCCO - VADJ_1V8_FPGA - IO_L14P_T2L_N2_GC_67
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC0_LA18_CC_P"] ;# Bank  67 VCCO - VADJ_1V8_FPGA - IO_L14P_T2L_N2_GC_67
set_property PACKAGE_PIN AR13     [get_ports "FMC_HPC0_LA18_CC_N"] ;# Bank  67 VCCO - VADJ_1V8_FPGA - IO_L14N_T2L_N3_GC_67
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC0_LA18_CC_N"] ;# Bank  67 VCCO - VADJ_1V8_FPGA - IO_L14N_T2L_N3_GC_67
#set_property PACKAGE_PIN AR15     [get_ports "9N7171"] ;# Bank  67 VCCO - VADJ_1V8_FPGA - IO_T2U_N12_67
#set_property IOSTANDARD  LVCMOSxx [get_ports "9N7171"] ;# Bank  67 VCCO - VADJ_1V8_FPGA - IO_T2U_N12_67
set_property PACKAGE_PIN AR14     [get_ports "USER_SMA_CLOCK_P"] ;# Bank  67 VCCO - VADJ_1V8_FPGA - IO_L13P_T2L_N0_GC_QBC_67
set_property IOSTANDARD  LVDS [get_ports "USER_SMA_CLOCK_P"] ;# Bank  67 VCCO - VADJ_1V8_FPGA - IO_L13P_T2L_N0_GC_QBC_67
set_property PACKAGE_PIN AT14     [get_ports "USER_SMA_CLOCK_N"] ;# Bank  67 VCCO - VADJ_1V8_FPGA - IO_L13N_T2L_N1_GC_QBC_67
set_property IOSTANDARD  LVDS [get_ports "USER_SMA_CLOCK_N"] ;# Bank  67 VCCO - VADJ_1V8_FPGA - IO_L13N_T2L_N1_GC_QBC_67
set_property PACKAGE_PIN AV14     [get_ports "FMC_HPC0_LA17_CC_P"] ;# Bank  67 VCCO - VADJ_1V8_FPGA - IO_L12P_T1U_N10_GC_67
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC0_LA17_CC_P"] ;# Bank  67 VCCO - VADJ_1V8_FPGA - IO_L12P_T1U_N10_GC_67
set_property PACKAGE_PIN AV13     [get_ports "FMC_HPC0_LA17_CC_N"] ;# Bank  67 VCCO - VADJ_1V8_FPGA - IO_L12N_T1U_N11_GC_67
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC0_LA17_CC_N"] ;# Bank  67 VCCO - VADJ_1V8_FPGA - IO_L12N_T1U_N11_GC_67
set_property PACKAGE_PIN AW16     [get_ports "PMOD0_2_LS"] ;# Bank  67 VCCO - VADJ_1V8_FPGA - IO_T1U_N12_67
set_property IOSTANDARD  LVCMOS18 [get_ports "PMOD0_2_LS"] ;# Bank  67 VCCO - VADJ_1V8_FPGA - IO_T1U_N12_67
set_property PACKAGE_PIN AU14     [get_ports "FMC_HPC0_CLK1_M2C_P"] ;# Bank  67 VCCO - VADJ_1V8_FPGA - IO_L11P_T1U_N8_GC_67
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC0_CLK1_M2C_P"] ;# Bank  67 VCCO - VADJ_1V8_FPGA - IO_L11P_T1U_N8_GC_67
set_property PACKAGE_PIN AU13     [get_ports "FMC_HPC0_CLK1_M2C_N"] ;# Bank  67 VCCO - VADJ_1V8_FPGA - IO_L11N_T1U_N9_GC_67
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC0_CLK1_M2C_N"] ;# Bank  67 VCCO - VADJ_1V8_FPGA - IO_L11N_T1U_N9_GC_67
set_property PACKAGE_PIN AY15     [get_ports "FMC_HPC0_LA20_P"] ;# Bank  67 VCCO - VADJ_1V8_FPGA - IO_L10P_T1U_N6_QBC_AD4P_67
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC0_LA20_P"] ;# Bank  67 VCCO - VADJ_1V8_FPGA - IO_L10P_T1U_N6_QBC_AD4P_67
set_property PACKAGE_PIN AY14     [get_ports "FMC_HPC0_LA20_N"] ;# Bank  67 VCCO - VADJ_1V8_FPGA - IO_L10N_T1U_N7_QBC_AD4N_67
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC0_LA20_N"] ;# Bank  67 VCCO - VADJ_1V8_FPGA - IO_L10N_T1U_N7_QBC_AD4N_67
set_property PACKAGE_PIN AV15     [get_ports "FMC_HPC0_LA19_P"] ;# Bank  67 VCCO - VADJ_1V8_FPGA - IO_L9P_T1L_N4_AD12P_67
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC0_LA19_P"] ;# Bank  67 VCCO - VADJ_1V8_FPGA - IO_L9P_T1L_N4_AD12P_67
set_property PACKAGE_PIN AW15     [get_ports "FMC_HPC0_LA19_N"] ;# Bank  67 VCCO - VADJ_1V8_FPGA - IO_L9N_T1L_N5_AD12N_67
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC0_LA19_N"] ;# Bank  67 VCCO - VADJ_1V8_FPGA - IO_L9N_T1L_N5_AD12N_67
set_property PACKAGE_PIN AU16     [get_ports "FMC_HPC0_LA33_P"] ;# Bank  67 VCCO - VADJ_1V8_FPGA - IO_L8P_T1L_N2_AD5P_67
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC0_LA33_P"] ;# Bank  67 VCCO - VADJ_1V8_FPGA - IO_L8P_T1L_N2_AD5P_67
set_property PACKAGE_PIN AV16     [get_ports "FMC_HPC0_LA33_N"] ;# Bank  67 VCCO - VADJ_1V8_FPGA - IO_L8N_T1L_N3_AD5N_67
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC0_LA33_N"] ;# Bank  67 VCCO - VADJ_1V8_FPGA - IO_L8N_T1L_N3_AD5N_67
set_property PACKAGE_PIN AT16     [get_ports "FMC_HPC0_LA23_P"] ;# Bank  67 VCCO - VADJ_1V8_FPGA - IO_L7P_T1L_N0_QBC_AD13P_67
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC0_LA23_P"] ;# Bank  67 VCCO - VADJ_1V8_FPGA - IO_L7P_T1L_N0_QBC_AD13P_67
set_property PACKAGE_PIN AT15     [get_ports "FMC_HPC0_LA23_N"] ;# Bank  67 VCCO - VADJ_1V8_FPGA - IO_L7N_T1L_N1_QBC_AD13N_67
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC0_LA23_N"] ;# Bank  67 VCCO - VADJ_1V8_FPGA - IO_L7N_T1L_N1_QBC_AD13N_67
set_property PACKAGE_PIN AU11     [get_ports "FMC_HPC0_LA32_P"] ;# Bank  67 VCCO - VADJ_1V8_FPGA - IO_L6P_T0U_N10_AD6P_67
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC0_LA32_P"] ;# Bank  67 VCCO - VADJ_1V8_FPGA - IO_L6P_T0U_N10_AD6P_67
set_property PACKAGE_PIN AV11     [get_ports "FMC_HPC0_LA32_N"] ;# Bank  67 VCCO - VADJ_1V8_FPGA - IO_L6N_T0U_N11_AD6N_67
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC0_LA32_N"] ;# Bank  67 VCCO - VADJ_1V8_FPGA - IO_L6N_T0U_N11_AD6N_67
#set_property PACKAGE_PIN AW13     [get_ports "9N7174"] ;# Bank  67 VCCO - VADJ_1V8_FPGA - IO_L5P_T0U_N8_AD14P_67
#set_property IOSTANDARD  LVCMOSxx [get_ports "9N7174"] ;# Bank  67 VCCO - VADJ_1V8_FPGA - IO_L5P_T0U_N8_AD14P_67
#set_property PACKAGE_PIN AY13     [get_ports "9N7175"] ;# Bank  67 VCCO - VADJ_1V8_FPGA - IO_L5N_T0U_N9_AD14N_67
#set_property IOSTANDARD  LVCMOSxx [get_ports "9N7175"] ;# Bank  67 VCCO - VADJ_1V8_FPGA - IO_L5N_T0U_N9_AD14N_67
#set_property PACKAGE_PIN AV10     [get_ports "9N7163"] ;# Bank  67 VCCO - VADJ_1V8_FPGA - IO_L4P_T0U_N6_DBC_AD7P_67
#set_property IOSTANDARD  LVCMOSxx [get_ports "9N7163"] ;# Bank  67 VCCO - VADJ_1V8_FPGA - IO_L4P_T0U_N6_DBC_AD7P_67
#set_property PACKAGE_PIN AW10     [get_ports "9N7165"] ;# Bank  67 VCCO - VADJ_1V8_FPGA - IO_L4N_T0U_N7_DBC_AD7N_67
#set_property IOSTANDARD  LVCMOSxx [get_ports "9N7165"] ;# Bank  67 VCCO - VADJ_1V8_FPGA - IO_L4N_T0U_N7_DBC_AD7N_67
#set_property PACKAGE_PIN AW11     [get_ports "9N7167"] ;# Bank  67 VCCO - VADJ_1V8_FPGA - IO_L3P_T0L_N4_AD15P_67
#set_property IOSTANDARD  LVCMOSxx [get_ports "9N7167"] ;# Bank  67 VCCO - VADJ_1V8_FPGA - IO_L3P_T0L_N4_AD15P_67
#set_property PACKAGE_PIN AY10     [get_ports "9N7169"] ;# Bank  67 VCCO - VADJ_1V8_FPGA - IO_L3N_T0L_N5_AD15N_67
#set_property IOSTANDARD  LVCMOSxx [get_ports "9N7169"] ;# Bank  67 VCCO - VADJ_1V8_FPGA - IO_L3N_T0L_N5_AD15N_67
set_property PACKAGE_PIN AW12     [get_ports "PMOD0_6_LS"] ;# Bank  67 VCCO - VADJ_1V8_FPGA - IO_L2P_T0L_N2_67
set_property IOSTANDARD  LVCMOS18 [get_ports "PMOD0_6_LS"] ;# Bank  67 VCCO - VADJ_1V8_FPGA - IO_L2P_T0L_N2_67
#set_property PACKAGE_PIN AY12     [get_ports "9N7724"] ;# Bank  67 VCCO - VADJ_1V8_FPGA - IO_L2N_T0L_N3_67
#set_property IOSTANDARD  LVCMOSxx [get_ports "9N7724"] ;# Bank  67 VCCO - VADJ_1V8_FPGA - IO_L2N_T0L_N3_67
#set_property PACKAGE_PIN BA12     [get_ports "VRP_67"] ;# Bank  67 VCCO - VADJ_1V8_FPGA - IO_T0U_N12_VRP_67
#set_property IOSTANDARD  LVCMOSxx [get_ports "VRP_67"] ;# Bank  67 VCCO - VADJ_1V8_FPGA - IO_T0U_N12_VRP_67
#set_property PACKAGE_PIN AT12     [get_ports "9N7727"] ;# Bank  67 VCCO - VADJ_1V8_FPGA - IO_L1P_T0L_N0_DBC_67
#set_property IOSTANDARD  LVCMOSxx [get_ports "9N7727"] ;# Bank  67 VCCO - VADJ_1V8_FPGA - IO_L1P_T0L_N0_DBC_67
#set_property PACKAGE_PIN AU12     [get_ports "9N7730"] ;# Bank  67 VCCO - VADJ_1V8_FPGA - IO_L1N_T0L_N1_DBC_67
#set_property IOSTANDARD  LVCMOSxx [get_ports "9N7730"] ;# Bank  67 VCCO - VADJ_1V8_FPGA - IO_L1N_T0L_N1_DBC_67
set_property PACKAGE_PIN K12      [get_ports "FMC_HPC0_HA10_P"] ;# Bank  68 VCCO - VADJ_1V8_FPGA - IO_L24P_T3U_N10_68
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC0_HA10_P"] ;# Bank  68 VCCO - VADJ_1V8_FPGA - IO_L24P_T3U_N10_68
set_property PACKAGE_PIN J12      [get_ports "FMC_HPC0_HA10_N"] ;# Bank  68 VCCO - VADJ_1V8_FPGA - IO_L24N_T3U_N11_68
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC0_HA10_N"] ;# Bank  68 VCCO - VADJ_1V8_FPGA - IO_L24N_T3U_N11_68
#set_property PACKAGE_PIN J14      [get_ports "10N2871"] ;# Bank  68 VCCO - VADJ_1V8_FPGA - IO_T3U_N12_68
#set_property IOSTANDARD  LVCMOSxx [get_ports "10N2871"] ;# Bank  68 VCCO - VADJ_1V8_FPGA - IO_T3U_N12_68
set_property PACKAGE_PIN K14      [get_ports "FMC_HPC0_HA14_P"] ;# Bank  68 VCCO - VADJ_1V8_FPGA - IO_L23P_T3U_N8_68
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC0_HA14_P"] ;# Bank  68 VCCO - VADJ_1V8_FPGA - IO_L23P_T3U_N8_68
set_property PACKAGE_PIN K13      [get_ports "FMC_HPC0_HA14_N"] ;# Bank  68 VCCO - VADJ_1V8_FPGA - IO_L23N_T3U_N9_68
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC0_HA14_N"] ;# Bank  68 VCCO - VADJ_1V8_FPGA - IO_L23N_T3U_N9_68
set_property PACKAGE_PIN M11      [get_ports "FMC_HPC0_HA11_P"] ;# Bank  68 VCCO - VADJ_1V8_FPGA - IO_L22P_T3U_N6_DBC_AD0P_68
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC0_HA11_P"] ;# Bank  68 VCCO - VADJ_1V8_FPGA - IO_L22P_T3U_N6_DBC_AD0P_68
set_property PACKAGE_PIN L11      [get_ports "FMC_HPC0_HA11_N"] ;# Bank  68 VCCO - VADJ_1V8_FPGA - IO_L22N_T3U_N7_DBC_AD0N_68
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC0_HA11_N"] ;# Bank  68 VCCO - VADJ_1V8_FPGA - IO_L22N_T3U_N7_DBC_AD0N_68
set_property PACKAGE_PIN K11      [get_ports "FMC_HPC0_HA03_P"] ;# Bank  68 VCCO - VADJ_1V8_FPGA - IO_L21P_T3L_N4_AD8P_68
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC0_HA03_P"] ;# Bank  68 VCCO - VADJ_1V8_FPGA - IO_L21P_T3L_N4_AD8P_68
set_property PACKAGE_PIN J11      [get_ports "FMC_HPC0_HA03_N"] ;# Bank  68 VCCO - VADJ_1V8_FPGA - IO_L21N_T3L_N5_AD8N_68
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC0_HA03_N"] ;# Bank  68 VCCO - VADJ_1V8_FPGA - IO_L21N_T3L_N5_AD8N_68
set_property PACKAGE_PIN L14      [get_ports "FMC_HPC0_HA18_P"] ;# Bank  68 VCCO - VADJ_1V8_FPGA - IO_L20P_T3L_N2_AD1P_68
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC0_HA18_P"] ;# Bank  68 VCCO - VADJ_1V8_FPGA - IO_L20P_T3L_N2_AD1P_68
set_property PACKAGE_PIN L13      [get_ports "FMC_HPC0_HA18_N"] ;# Bank  68 VCCO - VADJ_1V8_FPGA - IO_L20N_T3L_N3_AD1N_68
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC0_HA18_N"] ;# Bank  68 VCCO - VADJ_1V8_FPGA - IO_L20N_T3L_N3_AD1N_68
set_property PACKAGE_PIN M13      [get_ports "FMC_HPC0_HA21_P"] ;# Bank  68 VCCO - VADJ_1V8_FPGA - IO_L19P_T3L_N0_DBC_AD9P_68
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC0_HA21_P"] ;# Bank  68 VCCO - VADJ_1V8_FPGA - IO_L19P_T3L_N0_DBC_AD9P_68
set_property PACKAGE_PIN M12      [get_ports "FMC_HPC0_HA21_N"] ;# Bank  68 VCCO - VADJ_1V8_FPGA - IO_L19N_T3L_N1_DBC_AD9N_68
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC0_HA21_N"] ;# Bank  68 VCCO - VADJ_1V8_FPGA - IO_L19N_T3L_N1_DBC_AD9N_68
set_property PACKAGE_PIN R12      [get_ports "FMC_HPC0_HA07_P"] ;# Bank  68 VCCO - VADJ_1V8_FPGA - IO_L18P_T2U_N10_AD2P_68
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC0_HA07_P"] ;# Bank  68 VCCO - VADJ_1V8_FPGA - IO_L18P_T2U_N10_AD2P_68
set_property PACKAGE_PIN P12      [get_ports "FMC_HPC0_HA07_N"] ;# Bank  68 VCCO - VADJ_1V8_FPGA - IO_L18N_T2U_N11_AD2N_68
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC0_HA07_N"] ;# Bank  68 VCCO - VADJ_1V8_FPGA - IO_L18N_T2U_N11_AD2N_68
set_property PACKAGE_PIN M15      [get_ports "FMC_HPC0_HA22_P"] ;# Bank  68 VCCO - VADJ_1V8_FPGA - IO_L17P_T2U_N8_AD10P_68
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC0_HA22_P"] ;# Bank  68 VCCO - VADJ_1V8_FPGA - IO_L17P_T2U_N8_AD10P_68
set_property PACKAGE_PIN L15      [get_ports "FMC_HPC0_HA22_N"] ;# Bank  68 VCCO - VADJ_1V8_FPGA - IO_L17N_T2U_N9_AD10N_68
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC0_HA22_N"] ;# Bank  68 VCCO - VADJ_1V8_FPGA - IO_L17N_T2U_N9_AD10N_68
set_property PACKAGE_PIN R11      [get_ports "FMC_HPC0_HA20_P"] ;# Bank  68 VCCO - VADJ_1V8_FPGA - IO_L16P_T2U_N6_QBC_AD3P_68
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC0_HA20_P"] ;# Bank  68 VCCO - VADJ_1V8_FPGA - IO_L16P_T2U_N6_QBC_AD3P_68
set_property PACKAGE_PIN P11      [get_ports "FMC_HPC0_HA20_N"] ;# Bank  68 VCCO - VADJ_1V8_FPGA - IO_L16N_T2U_N7_QBC_AD3N_68
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC0_HA20_N"] ;# Bank  68 VCCO - VADJ_1V8_FPGA - IO_L16N_T2U_N7_QBC_AD3N_68
set_property PACKAGE_PIN P15      [get_ports "FMC_HPC0_HA06_P"] ;# Bank  68 VCCO - VADJ_1V8_FPGA - IO_L15P_T2L_N4_AD11P_68
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC0_HA06_P"] ;# Bank  68 VCCO - VADJ_1V8_FPGA - IO_L15P_T2L_N4_AD11P_68
set_property PACKAGE_PIN N15      [get_ports "FMC_HPC0_HA06_N"] ;# Bank  68 VCCO - VADJ_1V8_FPGA - IO_L15N_T2L_N5_AD11N_68
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC0_HA06_N"] ;# Bank  68 VCCO - VADJ_1V8_FPGA - IO_L15N_T2L_N5_AD11N_68
set_property PACKAGE_PIN R14      [get_ports "FMC_HPC0_HA19_P"] ;# Bank  68 VCCO - VADJ_1V8_FPGA - IO_L14P_T2L_N2_GC_68
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC0_HA19_P"] ;# Bank  68 VCCO - VADJ_1V8_FPGA - IO_L14P_T2L_N2_GC_68
set_property PACKAGE_PIN P14      [get_ports "FMC_HPC0_HA19_N"] ;# Bank  68 VCCO - VADJ_1V8_FPGA - IO_L14N_T2L_N3_GC_68
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC0_HA19_N"] ;# Bank  68 VCCO - VADJ_1V8_FPGA - IO_L14N_T2L_N3_GC_68
#set_property PACKAGE_PIN N12      [get_ports "10N5281"] ;# Bank  68 VCCO - VADJ_1V8_FPGA - IO_T2U_N12_68
#set_property IOSTANDARD  LVCMOSxx [get_ports "10N5281"] ;# Bank  68 VCCO - VADJ_1V8_FPGA - IO_T2U_N12_68
set_property PACKAGE_PIN N14      [get_ports "FMC_HPC0_HA00_CC_P"] ;# Bank  68 VCCO - VADJ_1V8_FPGA - IO_L13P_T2L_N0_GC_QBC_68
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC0_HA00_CC_P"] ;# Bank  68 VCCO - VADJ_1V8_FPGA - IO_L13P_T2L_N0_GC_QBC_68
set_property PACKAGE_PIN N13      [get_ports "FMC_HPC0_HA00_CC_N"] ;# Bank  68 VCCO - VADJ_1V8_FPGA - IO_L13N_T2L_N1_GC_QBC_68
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC0_HA00_CC_N"] ;# Bank  68 VCCO - VADJ_1V8_FPGA - IO_L13N_T2L_N1_GC_QBC_68
set_property PACKAGE_PIN U13      [get_ports "FMC_HPC0_HA17_CC_P"] ;# Bank  68 VCCO - VADJ_1V8_FPGA - IO_L12P_T1U_N10_GC_68
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC0_HA17_CC_P"] ;# Bank  68 VCCO - VADJ_1V8_FPGA - IO_L12P_T1U_N10_GC_68
set_property PACKAGE_PIN T13      [get_ports "FMC_HPC0_HA17_CC_N"] ;# Bank  68 VCCO - VADJ_1V8_FPGA - IO_L12N_T1U_N11_GC_68
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC0_HA17_CC_N"] ;# Bank  68 VCCO - VADJ_1V8_FPGA - IO_L12N_T1U_N11_GC_68
#set_property PACKAGE_PIN R16      [get_ports "10N5284"] ;# Bank  68 VCCO - VADJ_1V8_FPGA - IO_T1U_N12_68
#set_property IOSTANDARD  LVCMOSxx [get_ports "10N5284"] ;# Bank  68 VCCO - VADJ_1V8_FPGA - IO_T1U_N12_68
set_property PACKAGE_PIN T14      [get_ports "FMC_HPC0_HA01_CC_P"] ;# Bank  68 VCCO - VADJ_1V8_FPGA - IO_L11P_T1U_N8_GC_68
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC0_HA01_CC_P"] ;# Bank  68 VCCO - VADJ_1V8_FPGA - IO_L11P_T1U_N8_GC_68
set_property PACKAGE_PIN R13      [get_ports "FMC_HPC0_HA01_CC_N"] ;# Bank  68 VCCO - VADJ_1V8_FPGA - IO_L11N_T1U_N9_GC_68
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC0_HA01_CC_N"] ;# Bank  68 VCCO - VADJ_1V8_FPGA - IO_L11N_T1U_N9_GC_68
set_property PACKAGE_PIN U11      [get_ports "FMC_HPC0_HA23_P"] ;# Bank  68 VCCO - VADJ_1V8_FPGA - IO_L10P_T1U_N6_QBC_AD4P_68
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC0_HA23_P"] ;# Bank  68 VCCO - VADJ_1V8_FPGA - IO_L10P_T1U_N6_QBC_AD4P_68
set_property PACKAGE_PIN T11      [get_ports "FMC_HPC0_HA23_N"] ;# Bank  68 VCCO - VADJ_1V8_FPGA - IO_L10N_T1U_N7_QBC_AD4N_68
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC0_HA23_N"] ;# Bank  68 VCCO - VADJ_1V8_FPGA - IO_L10N_T1U_N7_QBC_AD4N_68
set_property PACKAGE_PIN T16      [get_ports "FMC_HPC0_HA02_P"] ;# Bank  68 VCCO - VADJ_1V8_FPGA - IO_L9P_T1L_N4_AD12P_68
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC0_HA02_P"] ;# Bank  68 VCCO - VADJ_1V8_FPGA - IO_L9P_T1L_N4_AD12P_68
set_property PACKAGE_PIN T15      [get_ports "FMC_HPC0_HA02_N"] ;# Bank  68 VCCO - VADJ_1V8_FPGA - IO_L9N_T1L_N5_AD12N_68
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC0_HA02_N"] ;# Bank  68 VCCO - VADJ_1V8_FPGA - IO_L9N_T1L_N5_AD12N_68
set_property PACKAGE_PIN V16      [get_ports "FMC_HPC0_HA16_P"] ;# Bank  68 VCCO - VADJ_1V8_FPGA - IO_L8P_T1L_N2_AD5P_68
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC0_HA16_P"] ;# Bank  68 VCCO - VADJ_1V8_FPGA - IO_L8P_T1L_N2_AD5P_68
set_property PACKAGE_PIN U16      [get_ports "FMC_HPC0_HA16_N"] ;# Bank  68 VCCO - VADJ_1V8_FPGA - IO_L8N_T1L_N3_AD5N_68
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC0_HA16_N"] ;# Bank  68 VCCO - VADJ_1V8_FPGA - IO_L8N_T1L_N3_AD5N_68
set_property PACKAGE_PIN V15      [get_ports "FMC_HPC0_HA12_P"] ;# Bank  68 VCCO - VADJ_1V8_FPGA - IO_L7P_T1L_N0_QBC_AD13P_68
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC0_HA12_P"] ;# Bank  68 VCCO - VADJ_1V8_FPGA - IO_L7P_T1L_N0_QBC_AD13P_68
set_property PACKAGE_PIN U15      [get_ports "FMC_HPC0_HA12_N"] ;# Bank  68 VCCO - VADJ_1V8_FPGA - IO_L7N_T1L_N1_QBC_AD13N_68
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC0_HA12_N"] ;# Bank  68 VCCO - VADJ_1V8_FPGA - IO_L7N_T1L_N1_QBC_AD13N_68
set_property PACKAGE_PIN W14      [get_ports "FMC_HPC0_HA13_P"] ;# Bank  68 VCCO - VADJ_1V8_FPGA - IO_L6P_T0U_N10_AD6P_68
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC0_HA13_P"] ;# Bank  68 VCCO - VADJ_1V8_FPGA - IO_L6P_T0U_N10_AD6P_68
set_property PACKAGE_PIN V14      [get_ports "FMC_HPC0_HA13_N"] ;# Bank  68 VCCO - VADJ_1V8_FPGA - IO_L6N_T0U_N11_AD6N_68
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC0_HA13_N"] ;# Bank  68 VCCO - VADJ_1V8_FPGA - IO_L6N_T0U_N11_AD6N_68
set_property PACKAGE_PIN AA12     [get_ports "FMC_HPC0_HA05_P"] ;# Bank  68 VCCO - VADJ_1V8_FPGA - IO_L5P_T0U_N8_AD14P_68
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC0_HA05_P"] ;# Bank  68 VCCO - VADJ_1V8_FPGA - IO_L5P_T0U_N8_AD14P_68
set_property PACKAGE_PIN Y12      [get_ports "FMC_HPC0_HA05_N"] ;# Bank  68 VCCO - VADJ_1V8_FPGA - IO_L5N_T0U_N9_AD14N_68
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC0_HA05_N"] ;# Bank  68 VCCO - VADJ_1V8_FPGA - IO_L5N_T0U_N9_AD14N_68
set_property PACKAGE_PIN V13      [get_ports "FMC_HPC0_HA15_P"] ;# Bank  68 VCCO - VADJ_1V8_FPGA - IO_L4P_T0U_N6_DBC_AD7P_68
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC0_HA15_P"] ;# Bank  68 VCCO - VADJ_1V8_FPGA - IO_L4P_T0U_N6_DBC_AD7P_68
set_property PACKAGE_PIN U12      [get_ports "FMC_HPC0_HA15_N"] ;# Bank  68 VCCO - VADJ_1V8_FPGA - IO_L4N_T0U_N7_DBC_AD7N_68
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC0_HA15_N"] ;# Bank  68 VCCO - VADJ_1V8_FPGA - IO_L4N_T0U_N7_DBC_AD7N_68
set_property PACKAGE_PIN W12      [get_ports "FMC_HPC0_HA08_P"] ;# Bank  68 VCCO - VADJ_1V8_FPGA - IO_L3P_T0L_N4_AD15P_68
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC0_HA08_P"] ;# Bank  68 VCCO - VADJ_1V8_FPGA - IO_L3P_T0L_N4_AD15P_68
set_property PACKAGE_PIN V12      [get_ports "FMC_HPC0_HA08_N"] ;# Bank  68 VCCO - VADJ_1V8_FPGA - IO_L3N_T0L_N5_AD15N_68
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC0_HA08_N"] ;# Bank  68 VCCO - VADJ_1V8_FPGA - IO_L3N_T0L_N5_AD15N_68
set_property PACKAGE_PIN AA14     [get_ports "FMC_HPC0_HA09_P"] ;# Bank  68 VCCO - VADJ_1V8_FPGA - IO_L2P_T0L_N2_68
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC0_HA09_P"] ;# Bank  68 VCCO - VADJ_1V8_FPGA - IO_L2P_T0L_N2_68
set_property PACKAGE_PIN Y14      [get_ports "FMC_HPC0_HA09_N"] ;# Bank  68 VCCO - VADJ_1V8_FPGA - IO_L2N_T0L_N3_68
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC0_HA09_N"] ;# Bank  68 VCCO - VADJ_1V8_FPGA - IO_L2N_T0L_N3_68
#set_property PACKAGE_PIN W15      [get_ports "VRP_68"] ;# Bank  68 VCCO - VADJ_1V8_FPGA - IO_T0U_N12_VRP_68
#set_property IOSTANDARD  LVCMOSxx [get_ports "VRP_68"] ;# Bank  68 VCCO - VADJ_1V8_FPGA - IO_T0U_N12_VRP_68
set_property PACKAGE_PIN AA13     [get_ports "FMC_HPC0_HA04_P"] ;# Bank  68 VCCO - VADJ_1V8_FPGA - IO_L1P_T0L_N0_DBC_68
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC0_HA04_P"] ;# Bank  68 VCCO - VADJ_1V8_FPGA - IO_L1P_T0L_N0_DBC_68
set_property PACKAGE_PIN Y13      [get_ports "FMC_HPC0_HA04_N"] ;# Bank  68 VCCO - VADJ_1V8_FPGA - IO_L1N_T0L_N1_DBC_68
set_property IOSTANDARD  LVDS [get_ports "FMC_HPC0_HA04_N"] ;# Bank  68 VCCO - VADJ_1V8_FPGA - IO_L1N_T0L_N1_DBC_68
set_property PACKAGE_PIN B16      [get_ports "RLD3_C1_72B_DQ8"] ;# Bank  69 VCCO - VCC1V2_FPGA - IO_L24P_T3U_N10_69
set_property IOSTANDARD  SSTL12 [get_ports "RLD3_C1_72B_DQ8"] ;# Bank  69 VCCO - VCC1V2_FPGA - IO_L24P_T3U_N10_69
set_property PACKAGE_PIN B15      [get_ports "RLD3_C1_72B_DQ1"] ;# Bank  69 VCCO - VCC1V2_FPGA - IO_L24N_T3U_N11_69
set_property IOSTANDARD  SSTL12 [get_ports "RLD3_C1_72B_DQ1"] ;# Bank  69 VCCO - VCC1V2_FPGA - IO_L24N_T3U_N11_69
#set_property PACKAGE_PIN D14      [get_ports "10N4475"] ;# Bank  69 VCCO - VCC1V2_FPGA - IO_T3U_N12_69
#set_property IOSTANDARD  LVCMOSxx [get_ports "10N4475"] ;# Bank  69 VCCO - VCC1V2_FPGA - IO_T3U_N12_69
set_property PACKAGE_PIN C15      [get_ports "RLD3_C1_72B_DQ3"] ;# Bank  69 VCCO - VCC1V2_FPGA - IO_L23P_T3U_N8_69
set_property IOSTANDARD  SSTL12 [get_ports "RLD3_C1_72B_DQ3"] ;# Bank  69 VCCO - VCC1V2_FPGA - IO_L23P_T3U_N8_69
set_property PACKAGE_PIN C14      [get_ports "RLD3_C1_72B_DQ6"] ;# Bank  69 VCCO - VCC1V2_FPGA - IO_L23N_T3U_N9_69
set_property IOSTANDARD  SSTL12 [get_ports "RLD3_C1_72B_DQ6"] ;# Bank  69 VCCO - VCC1V2_FPGA - IO_L23N_T3U_N9_69
set_property PACKAGE_PIN A14      [get_ports "RLD3_C1_72B_DQ2"] ;# Bank  69 VCCO - VCC1V2_FPGA - IO_L22P_T3U_N6_DBC_AD0P_69
set_property IOSTANDARD  SSTL12 [get_ports "RLD3_C1_72B_DQ2"] ;# Bank  69 VCCO - VCC1V2_FPGA - IO_L22P_T3U_N6_DBC_AD0P_69
set_property PACKAGE_PIN A13      [get_ports "RLD3_C1_72B_DQ7"] ;# Bank  69 VCCO - VCC1V2_FPGA - IO_L22N_T3U_N7_DBC_AD0N_69
set_property IOSTANDARD  SSTL12 [get_ports "RLD3_C1_72B_DQ7"] ;# Bank  69 VCCO - VCC1V2_FPGA - IO_L22N_T3U_N7_DBC_AD0N_69
set_property PACKAGE_PIN A16      [get_ports "RLD3_C1_72B_DQ4"] ;# Bank  69 VCCO - VCC1V2_FPGA - IO_L21P_T3L_N4_AD8P_69
set_property IOSTANDARD  SSTL12 [get_ports "RLD3_C1_72B_DQ4"] ;# Bank  69 VCCO - VCC1V2_FPGA - IO_L21P_T3L_N4_AD8P_69
set_property PACKAGE_PIN A15      [get_ports "RLD3_C1_72B_DQ0"] ;# Bank  69 VCCO - VCC1V2_FPGA - IO_L21N_T3L_N5_AD8N_69
set_property IOSTANDARD  SSTL12 [get_ports "RLD3_C1_72B_DQ0"] ;# Bank  69 VCCO - VCC1V2_FPGA - IO_L21N_T3L_N5_AD8N_69
set_property PACKAGE_PIN C12      [get_ports "RLD3_C1_72B_QVLD0"] ;# Bank  69 VCCO - VCC1V2_FPGA - IO_L20P_T3L_N2_AD1P_69
set_property IOSTANDARD  SSTL12 [get_ports "RLD3_C1_72B_QVLD0"] ;# Bank  69 VCCO - VCC1V2_FPGA - IO_L20P_T3L_N2_AD1P_69
set_property PACKAGE_PIN B12      [get_ports "RLD3_C1_72B_DQ5"] ;# Bank  69 VCCO - VCC1V2_FPGA - IO_L20N_T3L_N3_AD1N_69
set_property IOSTANDARD  SSTL12 [get_ports "RLD3_C1_72B_DQ5"] ;# Bank  69 VCCO - VCC1V2_FPGA - IO_L20N_T3L_N3_AD1N_69
set_property PACKAGE_PIN C13      [get_ports "RLD3_C1_72B_QK0_P"] ;# Bank  69 VCCO - VCC1V2_FPGA - IO_L19P_T3L_N0_DBC_AD9P_69
set_property IOSTANDARD  DIFF_SSTL12 [get_ports "RLD3_C1_72B_QK0_P"] ;# Bank  69 VCCO - VCC1V2_FPGA - IO_L19P_T3L_N0_DBC_AD9P_69
set_property PACKAGE_PIN B13      [get_ports "RLD3_C1_72B_QK0_N"] ;# Bank  69 VCCO - VCC1V2_FPGA - IO_L19N_T3L_N1_DBC_AD9N_69
set_property IOSTANDARD  DIFF_SSTL12 [get_ports "RLD3_C1_72B_QK0_N"] ;# Bank  69 VCCO - VCC1V2_FPGA - IO_L19N_T3L_N1_DBC_AD9N_69
set_property PACKAGE_PIN H15      [get_ports "RLD3_C1_72B_DQ25"] ;# Bank  69 VCCO - VCC1V2_FPGA - IO_L18P_T2U_N10_AD2P_69
set_property IOSTANDARD  SSTL12 [get_ports "RLD3_C1_72B_DQ25"] ;# Bank  69 VCCO - VCC1V2_FPGA - IO_L18P_T2U_N10_AD2P_69
set_property PACKAGE_PIN H14      [get_ports "RLD3_C1_72B_DM0"] ;# Bank  69 VCCO - VCC1V2_FPGA - IO_L18N_T2U_N11_AD2N_69
set_property IOSTANDARD  SSTL12 [get_ports "RLD3_C1_72B_DM0"] ;# Bank  69 VCCO - VCC1V2_FPGA - IO_L18N_T2U_N11_AD2N_69
set_property PACKAGE_PIN G15      [get_ports "RLD3_C1_72B_DQ23"] ;# Bank  69 VCCO - VCC1V2_FPGA - IO_L17P_T2U_N8_AD10P_69
set_property IOSTANDARD  SSTL12 [get_ports "RLD3_C1_72B_DQ23"] ;# Bank  69 VCCO - VCC1V2_FPGA - IO_L17P_T2U_N8_AD10P_69
set_property PACKAGE_PIN F15      [get_ports "RLD3_C1_72B_DQ26"] ;# Bank  69 VCCO - VCC1V2_FPGA - IO_L17N_T2U_N9_AD10N_69
set_property IOSTANDARD  SSTL12 [get_ports "RLD3_C1_72B_DQ26"] ;# Bank  69 VCCO - VCC1V2_FPGA - IO_L17N_T2U_N9_AD10N_69
set_property PACKAGE_PIN F14      [get_ports "RLD3_C1_72B_DQ18"] ;# Bank  69 VCCO - VCC1V2_FPGA - IO_L16P_T2U_N6_QBC_AD3P_69
set_property IOSTANDARD  SSTL12 [get_ports "RLD3_C1_72B_DQ18"] ;# Bank  69 VCCO - VCC1V2_FPGA - IO_L16P_T2U_N6_QBC_AD3P_69
set_property PACKAGE_PIN E14      [get_ports "RLD3_C1_72B_DQ22"] ;# Bank  69 VCCO - VCC1V2_FPGA - IO_L16N_T2U_N7_QBC_AD3N_69
set_property IOSTANDARD  SSTL12 [get_ports "RLD3_C1_72B_DQ22"] ;# Bank  69 VCCO - VCC1V2_FPGA - IO_L16N_T2U_N7_QBC_AD3N_69
set_property PACKAGE_PIN H13      [get_ports "RLD3_C1_72B_DQ19"] ;# Bank  69 VCCO - VCC1V2_FPGA - IO_L15P_T2L_N4_AD11P_69
set_property IOSTANDARD  SSTL12 [get_ports "RLD3_C1_72B_DQ19"] ;# Bank  69 VCCO - VCC1V2_FPGA - IO_L15P_T2L_N4_AD11P_69
set_property PACKAGE_PIN G13      [get_ports "RLD3_C1_72B_DQ24"] ;# Bank  69 VCCO - VCC1V2_FPGA - IO_L15N_T2L_N5_AD11N_69
set_property IOSTANDARD  SSTL12 [get_ports "RLD3_C1_72B_DQ24"] ;# Bank  69 VCCO - VCC1V2_FPGA - IO_L15N_T2L_N5_AD11N_69
set_property PACKAGE_PIN F13      [get_ports "RLD3_C1_72B_DQ21"] ;# Bank  69 VCCO - VCC1V2_FPGA - IO_L14P_T2L_N2_GC_69
set_property IOSTANDARD  SSTL12 [get_ports "RLD3_C1_72B_DQ21"] ;# Bank  69 VCCO - VCC1V2_FPGA - IO_L14P_T2L_N2_GC_69
set_property PACKAGE_PIN E13      [get_ports "RLD3_C1_72B_DQ20"] ;# Bank  69 VCCO - VCC1V2_FPGA - IO_L14N_T2L_N3_GC_69
set_property IOSTANDARD  SSTL12 [get_ports "RLD3_C1_72B_DQ20"] ;# Bank  69 VCCO - VCC1V2_FPGA - IO_L14N_T2L_N3_GC_69
set_property PACKAGE_PIN D15      [get_ports "RLD3_C1_72B_QVLD1"] ;# Bank  69 VCCO - VCC1V2_FPGA - IO_T2U_N12_69
set_property IOSTANDARD  SSTL12 [get_ports "RLD3_C1_72B_QVLD1"] ;# Bank  69 VCCO - VCC1V2_FPGA - IO_T2U_N12_69
set_property PACKAGE_PIN E12      [get_ports "RLD3_C1_72B_QK2_P"] ;# Bank  69 VCCO - VCC1V2_FPGA - IO_L13P_T2L_N0_GC_QBC_69
set_property IOSTANDARD  DIFF_SSTL12 [get_ports "RLD3_C1_72B_QK2_P"] ;# Bank  69 VCCO - VCC1V2_FPGA - IO_L13P_T2L_N0_GC_QBC_69
set_property PACKAGE_PIN D12      [get_ports "RLD3_C1_72B_QK2_N"] ;# Bank  69 VCCO - VCC1V2_FPGA - IO_L13N_T2L_N1_GC_QBC_69
set_property IOSTANDARD  DIFF_SSTL12 [get_ports "RLD3_C1_72B_QK2_N"] ;# Bank  69 VCCO - VCC1V2_FPGA - IO_L13N_T2L_N1_GC_QBC_69
set_property PACKAGE_PIN B11      [get_ports "RLD3_C1_72B_DQ13"] ;# Bank  69 VCCO - VCC1V2_FPGA - IO_L12P_T1U_N10_GC_69
set_property IOSTANDARD  SSTL12 [get_ports "RLD3_C1_72B_DQ13"] ;# Bank  69 VCCO - VCC1V2_FPGA - IO_L12P_T1U_N10_GC_69
set_property PACKAGE_PIN A11      [get_ports "RLD3_C1_72B_DQ12"] ;# Bank  69 VCCO - VCC1V2_FPGA - IO_L12N_T1U_N11_GC_69
set_property IOSTANDARD  SSTL12 [get_ports "RLD3_C1_72B_DQ12"] ;# Bank  69 VCCO - VCC1V2_FPGA - IO_L12N_T1U_N11_GC_69
set_property PACKAGE_PIN A10      [get_ports "GPIO_SW_E"] ;# Bank  69 VCCO - VCC1V2_FPGA - IO_T1U_N12_69
set_property IOSTANDARD  LVCMOS12 [get_ports "GPIO_SW_E"] ;# Bank  69 VCCO - VCC1V2_FPGA - IO_T1U_N12_69
set_property PACKAGE_PIN C10      [get_ports "RLD3_C1_72B_DQ9"] ;# Bank  69 VCCO - VCC1V2_FPGA - IO_L11P_T1U_N8_GC_69
set_property IOSTANDARD  SSTL12 [get_ports "RLD3_C1_72B_DQ9"] ;# Bank  69 VCCO - VCC1V2_FPGA - IO_L11P_T1U_N8_GC_69
set_property PACKAGE_PIN B10      [get_ports "RLD3_C1_72B_DQ11"] ;# Bank  69 VCCO - VCC1V2_FPGA - IO_L11N_T1U_N9_GC_69
set_property IOSTANDARD  SSTL12 [get_ports "RLD3_C1_72B_DQ11"] ;# Bank  69 VCCO - VCC1V2_FPGA - IO_L11N_T1U_N9_GC_69
set_property PACKAGE_PIN A9       [get_ports "RLD3_C1_72B_DQ14"] ;# Bank  69 VCCO - VCC1V2_FPGA - IO_L10P_T1U_N6_QBC_AD4P_69
set_property IOSTANDARD  SSTL12 [get_ports "RLD3_C1_72B_DQ14"] ;# Bank  69 VCCO - VCC1V2_FPGA - IO_L10P_T1U_N6_QBC_AD4P_69
set_property PACKAGE_PIN A8       [get_ports "RLD3_C1_72B_DQ10"] ;# Bank  69 VCCO - VCC1V2_FPGA - IO_L10N_T1U_N7_QBC_AD4N_69
set_property IOSTANDARD  SSTL12 [get_ports "RLD3_C1_72B_DQ10"] ;# Bank  69 VCCO - VCC1V2_FPGA - IO_L10N_T1U_N7_QBC_AD4N_69
set_property PACKAGE_PIN B8       [get_ports "RLD3_C1_72B_DQ17"] ;# Bank  69 VCCO - VCC1V2_FPGA - IO_L9P_T1L_N4_AD12P_69
set_property IOSTANDARD  SSTL12 [get_ports "RLD3_C1_72B_DQ17"] ;# Bank  69 VCCO - VCC1V2_FPGA - IO_L9P_T1L_N4_AD12P_69
set_property PACKAGE_PIN B7       [get_ports "RLD3_C1_72B_DQ16"] ;# Bank  69 VCCO - VCC1V2_FPGA - IO_L9N_T1L_N5_AD12N_69
set_property IOSTANDARD  SSTL12 [get_ports "RLD3_C1_72B_DQ16"] ;# Bank  69 VCCO - VCC1V2_FPGA - IO_L9N_T1L_N5_AD12N_69
set_property PACKAGE_PIN D7       [get_ports "RLD3_C1_72B_DM1"] ;# Bank  69 VCCO - VCC1V2_FPGA - IO_L8P_T1L_N2_AD5P_69
set_property IOSTANDARD  SSTL12 [get_ports "RLD3_C1_72B_DM1"] ;# Bank  69 VCCO - VCC1V2_FPGA - IO_L8P_T1L_N2_AD5P_69
set_property PACKAGE_PIN C7       [get_ports "RLD3_C1_72B_DQ15"] ;# Bank  69 VCCO - VCC1V2_FPGA - IO_L8N_T1L_N3_AD5N_69
set_property IOSTANDARD  SSTL12 [get_ports "RLD3_C1_72B_DQ15"] ;# Bank  69 VCCO - VCC1V2_FPGA - IO_L8N_T1L_N3_AD5N_69
set_property PACKAGE_PIN C9       [get_ports "RLD3_C1_72B_QK1_P"] ;# Bank  69 VCCO - VCC1V2_FPGA - IO_L7P_T1L_N0_QBC_AD13P_69
set_property IOSTANDARD  DIFF_SSTL12 [get_ports "RLD3_C1_72B_QK1_P"] ;# Bank  69 VCCO - VCC1V2_FPGA - IO_L7P_T1L_N0_QBC_AD13P_69
set_property PACKAGE_PIN C8       [get_ports "RLD3_C1_72B_QK1_N"] ;# Bank  69 VCCO - VCC1V2_FPGA - IO_L7N_T1L_N1_QBC_AD13N_69
set_property IOSTANDARD  DIFF_SSTL12 [get_ports "RLD3_C1_72B_QK1_N"] ;# Bank  69 VCCO - VCC1V2_FPGA - IO_L7N_T1L_N1_QBC_AD13N_69
set_property PACKAGE_PIN E9       [get_ports "RLD3_C1_72B_DQ32"] ;# Bank  69 VCCO - VCC1V2_FPGA - IO_L6P_T0U_N10_AD6P_69
set_property IOSTANDARD  SSTL12 [get_ports "RLD3_C1_72B_DQ32"] ;# Bank  69 VCCO - VCC1V2_FPGA - IO_L6P_T0U_N10_AD6P_69
set_property PACKAGE_PIN D9       [get_ports "GPIO_SW_S"] ;# Bank  69 VCCO - VCC1V2_FPGA - IO_L6N_T0U_N11_AD6N_69
set_property IOSTANDARD  LVCMOS12 [get_ports "GPIO_SW_S"] ;# Bank  69 VCCO - VCC1V2_FPGA - IO_L6N_T0U_N11_AD6N_69
set_property PACKAGE_PIN H12      [get_ports "RLD3_C1_72B_DQ29"] ;# Bank  69 VCCO - VCC1V2_FPGA - IO_L5P_T0U_N8_AD14P_69
set_property IOSTANDARD  SSTL12 [get_ports "RLD3_C1_72B_DQ29"] ;# Bank  69 VCCO - VCC1V2_FPGA - IO_L5P_T0U_N8_AD14P_69
set_property PACKAGE_PIN G12      [get_ports "RLD3_C1_72B_DQ27"] ;# Bank  69 VCCO - VCC1V2_FPGA - IO_L5N_T0U_N9_AD14N_69
set_property IOSTANDARD  SSTL12 [get_ports "RLD3_C1_72B_DQ27"] ;# Bank  69 VCCO - VCC1V2_FPGA - IO_L5N_T0U_N9_AD14N_69
set_property PACKAGE_PIN D11      [get_ports "RLD3_C1_72B_DQ34"] ;# Bank  69 VCCO - VCC1V2_FPGA - IO_L4P_T0U_N6_DBC_AD7P_69
set_property IOSTANDARD  SSTL12 [get_ports "RLD3_C1_72B_DQ34"] ;# Bank  69 VCCO - VCC1V2_FPGA - IO_L4P_T0U_N6_DBC_AD7P_69
set_property PACKAGE_PIN D10      [get_ports "RLD3_C1_72B_DQ28"] ;# Bank  69 VCCO - VCC1V2_FPGA - IO_L4N_T0U_N7_DBC_AD7N_69
set_property IOSTANDARD  SSTL12 [get_ports "RLD3_C1_72B_DQ28"] ;# Bank  69 VCCO - VCC1V2_FPGA - IO_L4N_T0U_N7_DBC_AD7N_69
set_property PACKAGE_PIN F10      [get_ports "RLD3_C1_72B_DQ35"] ;# Bank  69 VCCO - VCC1V2_FPGA - IO_L3P_T0L_N4_AD15P_69
set_property IOSTANDARD  SSTL12 [get_ports "RLD3_C1_72B_DQ35"] ;# Bank  69 VCCO - VCC1V2_FPGA - IO_L3P_T0L_N4_AD15P_69
set_property PACKAGE_PIN F9       [get_ports "RLD3_C1_72B_DQ30"] ;# Bank  69 VCCO - VCC1V2_FPGA - IO_L3N_T0L_N5_AD15N_69
set_property IOSTANDARD  SSTL12 [get_ports "RLD3_C1_72B_DQ30"] ;# Bank  69 VCCO - VCC1V2_FPGA - IO_L3N_T0L_N5_AD15N_69
set_property PACKAGE_PIN F11      [get_ports "RLD3_C1_72B_DQ33"] ;# Bank  69 VCCO - VCC1V2_FPGA - IO_L2P_T0L_N2_69
set_property IOSTANDARD  SSTL12 [get_ports "RLD3_C1_72B_DQ33"] ;# Bank  69 VCCO - VCC1V2_FPGA - IO_L2P_T0L_N2_69
set_property PACKAGE_PIN E11      [get_ports "RLD3_C1_72B_DQ31"] ;# Bank  69 VCCO - VCC1V2_FPGA - IO_L2N_T0L_N3_69
set_property IOSTANDARD  SSTL12 [get_ports "RLD3_C1_72B_DQ31"] ;# Bank  69 VCCO - VCC1V2_FPGA - IO_L2N_T0L_N3_69
set_property PACKAGE_PIN D8       [get_ports "VRP_69"] ;# Bank  69 VCCO - VCC1V2_FPGA - IO_T0U_N12_VRP_69
set_property IOSTANDARD  SSTL12 [get_ports "VRP_69"] ;# Bank  69 VCCO - VCC1V2_FPGA - IO_T0U_N12_VRP_69
set_property PACKAGE_PIN G11      [get_ports "RLD3_C1_72B_QK3_P"] ;# Bank  69 VCCO - VCC1V2_FPGA - IO_L1P_T0L_N0_DBC_69
set_property IOSTANDARD  DIFF_SSTL12 [get_ports "RLD3_C1_72B_QK3_P"] ;# Bank  69 VCCO - VCC1V2_FPGA - IO_L1P_T0L_N0_DBC_69
set_property PACKAGE_PIN G10      [get_ports "RLD3_C1_72B_QK3_N"] ;# Bank  69 VCCO - VCC1V2_FPGA - IO_L1N_T0L_N1_DBC_69
set_property IOSTANDARD  DIFF_SSTL12 [get_ports "RLD3_C1_72B_QK3_N"] ;# Bank  69 VCCO - VCC1V2_FPGA - IO_L1N_T0L_N1_DBC_69
set_property PACKAGE_PIN B21      [get_ports "RLD3_C1_72B_A12"] ;# Bank  70 VCCO - VCC1V2_FPGA - IO_L24P_T3U_N10_70
set_property IOSTANDARD  SSTL12 [get_ports "RLD3_C1_72B_A12"] ;# Bank  70 VCCO - VCC1V2_FPGA - IO_L24P_T3U_N10_70
set_property PACKAGE_PIN A21      [get_ports "RLD3_C1_72B_RESET_B"] ;# Bank  70 VCCO - VCC1V2_FPGA - IO_L24N_T3U_N11_70
set_property IOSTANDARD  SSTL12 [get_ports "RLD3_C1_72B_RESET_B"] ;# Bank  70 VCCO - VCC1V2_FPGA - IO_L24N_T3U_N11_70
set_property PACKAGE_PIN D21      [get_ports "5330N1160"] ;# Bank  70 VCCO - VCC1V2_FPGA - IO_T3U_N12_70
set_property IOSTANDARD  SSTL12 [get_ports "5330N1160"] ;# Bank  70 VCCO - VCC1V2_FPGA - IO_T3U_N12_70
set_property PACKAGE_PIN B23      [get_ports "RLD3_C1_72B_A14"] ;# Bank  70 VCCO - VCC1V2_FPGA - IO_L23P_T3U_N8_70
set_property IOSTANDARD  SSTL12 [get_ports "RLD3_C1_72B_A14"] ;# Bank  70 VCCO - VCC1V2_FPGA - IO_L23P_T3U_N8_70
set_property PACKAGE_PIN B22      [get_ports "RLD3_C1_72B_A19"] ;# Bank  70 VCCO - VCC1V2_FPGA - IO_L23N_T3U_N9_70
set_property IOSTANDARD  SSTL12 [get_ports "RLD3_C1_72B_A19"] ;# Bank  70 VCCO - VCC1V2_FPGA - IO_L23N_T3U_N9_70
set_property PACKAGE_PIN D22      [get_ports "RLD3_C1_72B_A16"] ;# Bank  70 VCCO - VCC1V2_FPGA - IO_L22P_T3U_N6_DBC_AD0P_70
set_property IOSTANDARD  SSTL12 [get_ports "RLD3_C1_72B_A16"] ;# Bank  70 VCCO - VCC1V2_FPGA - IO_L22P_T3U_N6_DBC_AD0P_70
set_property PACKAGE_PIN C22      [get_ports "RLD3_C1_72B_BA3"] ;# Bank  70 VCCO - VCC1V2_FPGA - IO_L22N_T3U_N7_DBC_AD0N_70
set_property IOSTANDARD  SSTL12 [get_ports "RLD3_C1_72B_BA3"] ;# Bank  70 VCCO - VCC1V2_FPGA - IO_L22N_T3U_N7_DBC_AD0N_70
set_property PACKAGE_PIN C24      [get_ports "RLD3_C1_72B_DK1_P"] ;# Bank  70 VCCO - VCC1V2_FPGA - IO_L21P_T3L_N4_AD8P_70
set_property IOSTANDARD  DIFF_SSTL12 [get_ports "RLD3_C1_72B_DK1_P"] ;# Bank  70 VCCO - VCC1V2_FPGA - IO_L21P_T3L_N4_AD8P_70
set_property PACKAGE_PIN C23      [get_ports "RLD3_C1_72B_DK1_N"] ;# Bank  70 VCCO - VCC1V2_FPGA - IO_L21N_T3L_N5_AD8N_70
set_property IOSTANDARD  DIFF_SSTL12 [get_ports "RLD3_C1_72B_DK1_N"] ;# Bank  70 VCCO - VCC1V2_FPGA - IO_L21N_T3L_N5_AD8N_70
set_property PACKAGE_PIN A24      [get_ports "RLD3_C1_72B_DK0_P"] ;# Bank  70 VCCO - VCC1V2_FPGA - IO_L20P_T3L_N2_AD1P_70
set_property IOSTANDARD  DIFF_SSTL12 [get_ports "RLD3_C1_72B_DK0_P"] ;# Bank  70 VCCO - VCC1V2_FPGA - IO_L20P_T3L_N2_AD1P_70
set_property PACKAGE_PIN A23      [get_ports "RLD3_C1_72B_DK0_N"] ;# Bank  70 VCCO - VCC1V2_FPGA - IO_L20N_T3L_N3_AD1N_70
set_property IOSTANDARD  DIFF_SSTL12 [get_ports "RLD3_C1_72B_DK0_N"] ;# Bank  70 VCCO - VCC1V2_FPGA - IO_L20N_T3L_N3_AD1N_70
set_property PACKAGE_PIN E24      [get_ports "RLD3_C1_72B_CK_P"] ;# Bank  70 VCCO - VCC1V2_FPGA - IO_L19P_T3L_N0_DBC_AD9P_70
set_property IOSTANDARD  DIFF_SSTL12 [get_ports "RLD3_C1_72B_CK_P"] ;# Bank  70 VCCO - VCC1V2_FPGA - IO_L19P_T3L_N0_DBC_AD9P_70
set_property PACKAGE_PIN D24      [get_ports "RLD3_C1_72B_CK_N"] ;# Bank  70 VCCO - VCC1V2_FPGA - IO_L19N_T3L_N1_DBC_AD9N_70
set_property IOSTANDARD  DIFF_SSTL12 [get_ports "RLD3_C1_72B_CK_N"] ;# Bank  70 VCCO - VCC1V2_FPGA - IO_L19N_T3L_N1_DBC_AD9N_70
set_property PACKAGE_PIN F24      [get_ports "RLD3_C1_72B_BA1"] ;# Bank  70 VCCO - VCC1V2_FPGA - IO_L18P_T2U_N10_AD2P_70
set_property IOSTANDARD  SSTL12 [get_ports "RLD3_C1_72B_BA1"] ;# Bank  70 VCCO - VCC1V2_FPGA - IO_L18P_T2U_N10_AD2P_70
set_property PACKAGE_PIN F23      [get_ports "RLD3_C1_72B_WE_B"] ;# Bank  70 VCCO - VCC1V2_FPGA - IO_L18N_T2U_N11_AD2N_70
set_property IOSTANDARD  SSTL12 [get_ports "RLD3_C1_72B_WE_B"] ;# Bank  70 VCCO - VCC1V2_FPGA - IO_L18N_T2U_N11_AD2N_70
set_property PACKAGE_PIN F21      [get_ports "RLD3_C1_72B_A10"] ;# Bank  70 VCCO - VCC1V2_FPGA - IO_L17P_T2U_N8_AD10P_70
set_property IOSTANDARD  SSTL12 [get_ports "RLD3_C1_72B_A10"] ;# Bank  70 VCCO - VCC1V2_FPGA - IO_L17P_T2U_N8_AD10P_70
set_property PACKAGE_PIN E21      [get_ports "RLD3_C1_72B_A18"] ;# Bank  70 VCCO - VCC1V2_FPGA - IO_L17N_T2U_N9_AD10N_70
set_property IOSTANDARD  SSTL12 [get_ports "RLD3_C1_72B_A18"] ;# Bank  70 VCCO - VCC1V2_FPGA - IO_L17N_T2U_N9_AD10N_70
set_property PACKAGE_PIN H24      [get_ports "RLD3_C1_72B_A11"] ;# Bank  70 VCCO - VCC1V2_FPGA - IO_L16P_T2U_N6_QBC_AD3P_70
set_property IOSTANDARD  SSTL12 [get_ports "RLD3_C1_72B_A11"] ;# Bank  70 VCCO - VCC1V2_FPGA - IO_L16P_T2U_N6_QBC_AD3P_70
set_property PACKAGE_PIN G23      [get_ports "RLD3_C1_72B_A7"] ;# Bank  70 VCCO - VCC1V2_FPGA - IO_L16N_T2U_N7_QBC_AD3N_70
set_property IOSTANDARD  SSTL12 [get_ports "RLD3_C1_72B_A7"] ;# Bank  70 VCCO - VCC1V2_FPGA - IO_L16N_T2U_N7_QBC_AD3N_70
set_property PACKAGE_PIN E23      [get_ports "RLD3_C1_72B_A4"] ;# Bank  70 VCCO - VCC1V2_FPGA - IO_L15P_T2L_N4_AD11P_70
set_property IOSTANDARD  SSTL12 [get_ports "RLD3_C1_72B_A4"] ;# Bank  70 VCCO - VCC1V2_FPGA - IO_L15P_T2L_N4_AD11P_70
set_property PACKAGE_PIN E22      [get_ports "RLD3_C1_72B_A6"] ;# Bank  70 VCCO - VCC1V2_FPGA - IO_L15N_T2L_N5_AD11N_70
set_property IOSTANDARD  SSTL12 [get_ports "RLD3_C1_72B_A6"] ;# Bank  70 VCCO - VCC1V2_FPGA - IO_L15N_T2L_N5_AD11N_70
set_property PACKAGE_PIN H23      [get_ports "RLD3_C1_72B_A15"] ;# Bank  70 VCCO - VCC1V2_FPGA - IO_L14P_T2L_N2_GC_70
set_property IOSTANDARD  SSTL12 [get_ports "RLD3_C1_72B_A15"] ;# Bank  70 VCCO - VCC1V2_FPGA - IO_L14P_T2L_N2_GC_70
set_property PACKAGE_PIN H22      [get_ports "RLD3_C1_72B_A1"] ;# Bank  70 VCCO - VCC1V2_FPGA - IO_L14N_T2L_N3_GC_70
set_property IOSTANDARD  SSTL12 [get_ports "RLD3_C1_72B_A1"] ;# Bank  70 VCCO - VCC1V2_FPGA - IO_L14N_T2L_N3_GC_70
set_property PACKAGE_PIN H20      [get_ports "RLD3_C1_72B_BA2"] ;# Bank  70 VCCO - VCC1V2_FPGA - IO_T2U_N12_70
set_property IOSTANDARD  SSTL12 [get_ports "RLD3_C1_72B_BA2"] ;# Bank  70 VCCO - VCC1V2_FPGA - IO_T2U_N12_70
set_property PACKAGE_PIN G22      [get_ports "SYSCLK2_300_P"] ;# Bank  70 VCCO - VCC1V2_FPGA - IO_L13P_T2L_N0_GC_QBC_70
set_property IOSTANDARD  DIFF_SSTL12 [get_ports "SYSCLK2_300_P"] ;# Bank  70 VCCO - VCC1V2_FPGA - IO_L13P_T2L_N0_GC_QBC_70
set_property PACKAGE_PIN G21      [get_ports "SYSCLK2_300_N"] ;# Bank  70 VCCO - VCC1V2_FPGA - IO_L13N_T2L_N1_GC_QBC_70
set_property IOSTANDARD  DIFF_SSTL12 [get_ports "SYSCLK2_300_N"] ;# Bank  70 VCCO - VCC1V2_FPGA - IO_L13N_T2L_N1_GC_QBC_70
set_property PACKAGE_PIN K22      [get_ports "RLD3_C1_72B_A13"] ;# Bank  70 VCCO - VCC1V2_FPGA - IO_L12P_T1U_N10_GC_70
set_property IOSTANDARD  SSTL12 [get_ports "RLD3_C1_72B_A13"] ;# Bank  70 VCCO - VCC1V2_FPGA - IO_L12P_T1U_N10_GC_70
set_property PACKAGE_PIN J22      [get_ports "RLD3_C1_72B_A0"] ;# Bank  70 VCCO - VCC1V2_FPGA - IO_L12N_T1U_N11_GC_70
set_property IOSTANDARD  SSTL12 [get_ports "RLD3_C1_72B_A0"] ;# Bank  70 VCCO - VCC1V2_FPGA - IO_L12N_T1U_N11_GC_70
set_property PACKAGE_PIN J20      [get_ports "PMOD1_2_LS"] ;# Bank  70 VCCO - VCC1V2_FPGA - IO_T1U_N12_70
set_property IOSTANDARD  LVCMOS12 [get_ports "PMOD1_2_LS"] ;# Bank  70 VCCO - VCC1V2_FPGA - IO_T1U_N12_70
set_property PACKAGE_PIN K21      [get_ports "RLD3_C1_72B_A9"] ;# Bank  70 VCCO - VCC1V2_FPGA - IO_L11P_T1U_N8_GC_70
set_property IOSTANDARD  SSTL12 [get_ports "RLD3_C1_72B_A9"] ;# Bank  70 VCCO - VCC1V2_FPGA - IO_L11P_T1U_N8_GC_70
set_property PACKAGE_PIN J21      [get_ports "RLD3_C1_72B_A5"] ;# Bank  70 VCCO - VCC1V2_FPGA - IO_L11N_T1U_N9_GC_70
set_property IOSTANDARD  SSTL12 [get_ports "RLD3_C1_72B_A5"] ;# Bank  70 VCCO - VCC1V2_FPGA - IO_L11N_T1U_N9_GC_70
set_property PACKAGE_PIN M20      [get_ports "RLD3_C1_72B_DK3_P"] ;# Bank  70 VCCO - VCC1V2_FPGA - IO_L10P_T1U_N6_QBC_AD4P_70
set_property IOSTANDARD  DIFF_SSTL12 [get_ports "RLD3_C1_72B_DK3_P"] ;# Bank  70 VCCO - VCC1V2_FPGA - IO_L10P_T1U_N6_QBC_AD4P_70
set_property PACKAGE_PIN L20      [get_ports "RLD3_C1_72B_DK3_N"] ;# Bank  70 VCCO - VCC1V2_FPGA - IO_L10N_T1U_N7_QBC_AD4N_70
set_property IOSTANDARD  DIFF_SSTL12 [get_ports "RLD3_C1_72B_DK3_N"] ;# Bank  70 VCCO - VCC1V2_FPGA - IO_L10N_T1U_N7_QBC_AD4N_70
set_property PACKAGE_PIN M21      [get_ports "RLD3_C1_72B_DK2_P"] ;# Bank  70 VCCO - VCC1V2_FPGA - IO_L9P_T1L_N4_AD12P_70
set_property IOSTANDARD  DIFF_SSTL12 [get_ports "RLD3_C1_72B_DK2_P"] ;# Bank  70 VCCO - VCC1V2_FPGA - IO_L9P_T1L_N4_AD12P_70
set_property PACKAGE_PIN L21      [get_ports "RLD3_C1_72B_DK2_N"] ;# Bank  70 VCCO - VCC1V2_FPGA - IO_L9N_T1L_N5_AD12N_70
set_property IOSTANDARD  DIFF_SSTL12 [get_ports "RLD3_C1_72B_DK2_N"] ;# Bank  70 VCCO - VCC1V2_FPGA - IO_L9N_T1L_N5_AD12N_70
set_property PACKAGE_PIN K24      [get_ports "PMOD1_3_LS"] ;# Bank  70 VCCO - VCC1V2_FPGA - IO_L8P_T1L_N2_AD5P_70
set_property IOSTANDARD  LVCMOS12 [get_ports "PMOD1_3_LS"] ;# Bank  70 VCCO - VCC1V2_FPGA - IO_L8P_T1L_N2_AD5P_70
set_property PACKAGE_PIN J24      [get_ports "PMOD1_4_LS"] ;# Bank  70 VCCO - VCC1V2_FPGA - IO_L8N_T1L_N3_AD5N_70
set_property IOSTANDARD  LVCMOS12 [get_ports "PMOD1_4_LS"] ;# Bank  70 VCCO - VCC1V2_FPGA - IO_L8N_T1L_N3_AD5N_70
set_property PACKAGE_PIN L23      [get_ports "RLD3_C1_72B_A8"] ;# Bank  70 VCCO - VCC1V2_FPGA - IO_L7P_T1L_N0_QBC_AD13P_70
set_property IOSTANDARD  SSTL12 [get_ports "RLD3_C1_72B_A8"] ;# Bank  70 VCCO - VCC1V2_FPGA - IO_L7P_T1L_N0_QBC_AD13P_70
set_property PACKAGE_PIN K23      [get_ports "RLD3_C1_72B_CS_B"] ;# Bank  70 VCCO - VCC1V2_FPGA - IO_L7N_T1L_N1_QBC_AD13N_70
set_property IOSTANDARD  SSTL12 [get_ports "RLD3_C1_72B_CS_B"] ;# Bank  70 VCCO - VCC1V2_FPGA - IO_L7N_T1L_N1_QBC_AD13N_70
set_property PACKAGE_PIN T23      [get_ports "PMOD1_5_LS"] ;# Bank  70 VCCO - VCC1V2_FPGA - IO_L6P_T0U_N10_AD6P_70
set_property IOSTANDARD  LVCMOS12 [get_ports "PMOD1_5_LS"] ;# Bank  70 VCCO - VCC1V2_FPGA - IO_L6P_T0U_N10_AD6P_70
set_property PACKAGE_PIN R23      [get_ports "PMOD1_6_LS"] ;# Bank  70 VCCO - VCC1V2_FPGA - IO_L6N_T0U_N11_AD6N_70
set_property IOSTANDARD  LVCMOS12 [get_ports "PMOD1_6_LS"] ;# Bank  70 VCCO - VCC1V2_FPGA - IO_L6N_T0U_N11_AD6N_70
set_property PACKAGE_PIN R22      [get_ports "PMOD1_7_LS"] ;# Bank  70 VCCO - VCC1V2_FPGA - IO_L5P_T0U_N8_AD14P_70
set_property IOSTANDARD  LVCMOS12 [get_ports "PMOD1_7_LS"] ;# Bank  70 VCCO - VCC1V2_FPGA - IO_L5P_T0U_N8_AD14P_70
set_property PACKAGE_PIN P22      [get_ports "PMOD1_0_LS"] ;# Bank  70 VCCO - VCC1V2_FPGA - IO_L5N_T0U_N9_AD14N_70
set_property IOSTANDARD  LVCMOS12 [get_ports "PMOD1_0_LS"] ;# Bank  70 VCCO - VCC1V2_FPGA - IO_L5N_T0U_N9_AD14N_70
set_property PACKAGE_PIN N22      [get_ports "PMOD1_1_LS"] ;# Bank  70 VCCO - VCC1V2_FPGA - IO_L4P_T0U_N6_DBC_AD7P_70
set_property IOSTANDARD  LVCMOS12 [get_ports "PMOD1_1_LS"] ;# Bank  70 VCCO - VCC1V2_FPGA - IO_L4P_T0U_N6_DBC_AD7P_70
set_property PACKAGE_PIN M22      [get_ports "GPIO_SW_W"] ;# Bank  70 VCCO - VCC1V2_FPGA - IO_L4N_T0U_N7_DBC_AD7N_70
set_property IOSTANDARD  LVCMOS12 [get_ports "GPIO_SW_W"] ;# Bank  70 VCCO - VCC1V2_FPGA - IO_L4N_T0U_N7_DBC_AD7N_70
set_property PACKAGE_PIN R21      [get_ports "RLD3_C1_72B_A3"] ;# Bank  70 VCCO - VCC1V2_FPGA - IO_L3P_T0L_N4_AD15P_70
set_property IOSTANDARD  SSTL12 [get_ports "RLD3_C1_72B_A3"] ;# Bank  70 VCCO - VCC1V2_FPGA - IO_L3P_T0L_N4_AD15P_70
set_property PACKAGE_PIN P21      [get_ports "MAXIM_CABLE_B_FPGA"] ;# Bank  70 VCCO - VCC1V2_FPGA - IO_L3N_T0L_N5_AD15N_70
set_property IOSTANDARD  LVCMOS12 [get_ports "MAXIM_CABLE_B_FPGA"] ;# Bank  70 VCCO - VCC1V2_FPGA - IO_L3N_T0L_N5_AD15N_70
set_property PACKAGE_PIN N23      [get_ports "RLD3_C1_72B_BA0"] ;# Bank  70 VCCO - VCC1V2_FPGA - IO_L2P_T0L_N2_70
set_property IOSTANDARD  SSTL12 [get_ports "RLD3_C1_72B_BA0"] ;# Bank  70 VCCO - VCC1V2_FPGA - IO_L2P_T0L_N2_70
set_property PACKAGE_PIN M23      [get_ports "RLD3_C1_72B_A17"] ;# Bank  70 VCCO - VCC1V2_FPGA - IO_L2N_T0L_N3_70
set_property IOSTANDARD  SSTL12 [get_ports "RLD3_C1_72B_A17"] ;# Bank  70 VCCO - VCC1V2_FPGA - IO_L2N_T0L_N3_70
set_property PACKAGE_PIN T21      [get_ports "VRP_70"] ;# Bank  70 VCCO - VCC1V2_FPGA - IO_T0U_N12_VRP_70
set_property IOSTANDARD  SSTL12 [get_ports "VRP_70"] ;# Bank  70 VCCO - VCC1V2_FPGA - IO_T0U_N12_VRP_70
set_property PACKAGE_PIN P20      [get_ports "RLD3_C1_72B_REF_B"] ;# Bank  70 VCCO - VCC1V2_FPGA - IO_L1P_T0L_N0_DBC_70
set_property IOSTANDARD  SSTL12 [get_ports "RLD3_C1_72B_REF_B"] ;# Bank  70 VCCO - VCC1V2_FPGA - IO_L1P_T0L_N0_DBC_70
set_property PACKAGE_PIN N20      [get_ports "RLD3_C1_72B_A2"] ;# Bank  70 VCCO - VCC1V2_FPGA - IO_L1N_T0L_N1_DBC_70
set_property IOSTANDARD  SSTL12 [get_ports "RLD3_C1_72B_A2"] ;# Bank  70 VCCO - VCC1V2_FPGA - IO_L1N_T0L_N1_DBC_70
#Other net   PACKAGE_PIN T20      - VREF_70                   Bank  70 - VREF_70
set_property PACKAGE_PIN C20      [get_ports "RLD3_C1_72B_DQ38"] ;# Bank  71 VCCO - VCC1V2_FPGA - IO_L24P_T3U_N10_71
set_property IOSTANDARD  SSTL12 [get_ports "RLD3_C1_72B_DQ38"] ;# Bank  71 VCCO - VCC1V2_FPGA - IO_L24P_T3U_N10_71
set_property PACKAGE_PIN B20      [get_ports "RLD3_C1_72B_QVLD2"] ;# Bank  71 VCCO - VCC1V2_FPGA - IO_L24N_T3U_N11_71
set_property IOSTANDARD  SSTL12 [get_ports "RLD3_C1_72B_QVLD2"] ;# Bank  71 VCCO - VCC1V2_FPGA - IO_L24N_T3U_N11_71
set_property PACKAGE_PIN A20      [get_ports "5330N1189"] ;# Bank  71 VCCO - VCC1V2_FPGA - IO_T3U_N12_71
set_property IOSTANDARD  SSTL12 [get_ports "5330N1189"] ;# Bank  71 VCCO - VCC1V2_FPGA - IO_T3U_N12_71
set_property PACKAGE_PIN D20      [get_ports "RLD3_C1_72B_DQ41"] ;# Bank  71 VCCO - VCC1V2_FPGA - IO_L23P_T3U_N8_71
set_property IOSTANDARD  SSTL12 [get_ports "RLD3_C1_72B_DQ41"] ;# Bank  71 VCCO - VCC1V2_FPGA - IO_L23P_T3U_N8_71
set_property PACKAGE_PIN D19      [get_ports "RLD3_C1_72B_DQ42"] ;# Bank  71 VCCO - VCC1V2_FPGA - IO_L23N_T3U_N9_71
set_property IOSTANDARD  SSTL12 [get_ports "RLD3_C1_72B_DQ42"] ;# Bank  71 VCCO - VCC1V2_FPGA - IO_L23N_T3U_N9_71
set_property PACKAGE_PIN A19      [get_ports "RLD3_C1_72B_DQ43"] ;# Bank  71 VCCO - VCC1V2_FPGA - IO_L22P_T3U_N6_DBC_AD0P_71
set_property IOSTANDARD  SSTL12 [get_ports "RLD3_C1_72B_DQ43"] ;# Bank  71 VCCO - VCC1V2_FPGA - IO_L22P_T3U_N6_DBC_AD0P_71
set_property PACKAGE_PIN A18      [get_ports "RLD3_C1_72B_DQ39"] ;# Bank  71 VCCO - VCC1V2_FPGA - IO_L22N_T3U_N7_DBC_AD0N_71
set_property IOSTANDARD  SSTL12 [get_ports "RLD3_C1_72B_DQ39"] ;# Bank  71 VCCO - VCC1V2_FPGA - IO_L22N_T3U_N7_DBC_AD0N_71
set_property PACKAGE_PIN C19      [get_ports "RLD3_C1_72B_DQ40"] ;# Bank  71 VCCO - VCC1V2_FPGA - IO_L21P_T3L_N4_AD8P_71
set_property IOSTANDARD  SSTL12 [get_ports "RLD3_C1_72B_DQ40"] ;# Bank  71 VCCO - VCC1V2_FPGA - IO_L21P_T3L_N4_AD8P_71
set_property PACKAGE_PIN C18      [get_ports "RLD3_C1_72B_DQ36"] ;# Bank  71 VCCO - VCC1V2_FPGA - IO_L21N_T3L_N5_AD8N_71
set_property IOSTANDARD  SSTL12 [get_ports "RLD3_C1_72B_DQ36"] ;# Bank  71 VCCO - VCC1V2_FPGA - IO_L21N_T3L_N5_AD8N_71
set_property PACKAGE_PIN D17      [get_ports "RLD3_C1_72B_DQ44"] ;# Bank  71 VCCO - VCC1V2_FPGA - IO_L20P_T3L_N2_AD1P_71
set_property IOSTANDARD  SSTL12 [get_ports "RLD3_C1_72B_DQ44"] ;# Bank  71 VCCO - VCC1V2_FPGA - IO_L20P_T3L_N2_AD1P_71
set_property PACKAGE_PIN C17      [get_ports "RLD3_C1_72B_DQ37"] ;# Bank  71 VCCO - VCC1V2_FPGA - IO_L20N_T3L_N3_AD1N_71
set_property IOSTANDARD  SSTL12 [get_ports "RLD3_C1_72B_DQ37"] ;# Bank  71 VCCO - VCC1V2_FPGA - IO_L20N_T3L_N3_AD1N_71
set_property PACKAGE_PIN B18      [get_ports "RLD3_C1_72B_QK4_P"] ;# Bank  71 VCCO - VCC1V2_FPGA - IO_L19P_T3L_N0_DBC_AD9P_71
set_property IOSTANDARD  DIFF_SSTL12 [get_ports "RLD3_C1_72B_QK4_P"] ;# Bank  71 VCCO - VCC1V2_FPGA - IO_L19P_T3L_N0_DBC_AD9P_71
set_property PACKAGE_PIN B17      [get_ports "RLD3_C1_72B_QK4_N"] ;# Bank  71 VCCO - VCC1V2_FPGA - IO_L19N_T3L_N1_DBC_AD9N_71
set_property IOSTANDARD  DIFF_SSTL12 [get_ports "RLD3_C1_72B_QK4_N"] ;# Bank  71 VCCO - VCC1V2_FPGA - IO_L19N_T3L_N1_DBC_AD9N_71
set_property PACKAGE_PIN E17      [get_ports "RLD3_C1_72B_DQ57"] ;# Bank  71 VCCO - VCC1V2_FPGA - IO_L18P_T2U_N10_AD2P_71
set_property IOSTANDARD  SSTL12 [get_ports "RLD3_C1_72B_DQ57"] ;# Bank  71 VCCO - VCC1V2_FPGA - IO_L18P_T2U_N10_AD2P_71
set_property PACKAGE_PIN D16      [get_ports "RLD3_C1_72B_DM2"] ;# Bank  71 VCCO - VCC1V2_FPGA - IO_L18N_T2U_N11_AD2N_71
set_property IOSTANDARD  SSTL12 [get_ports "RLD3_C1_72B_DM2"] ;# Bank  71 VCCO - VCC1V2_FPGA - IO_L18N_T2U_N11_AD2N_71
set_property PACKAGE_PIN G20      [get_ports "RLD3_C1_72B_DQ54"] ;# Bank  71 VCCO - VCC1V2_FPGA - IO_L17P_T2U_N8_AD10P_71
set_property IOSTANDARD  SSTL12 [get_ports "RLD3_C1_72B_DQ54"] ;# Bank  71 VCCO - VCC1V2_FPGA - IO_L17P_T2U_N8_AD10P_71
set_property PACKAGE_PIN F20      [get_ports "RLD3_C1_72B_DQ58"] ;# Bank  71 VCCO - VCC1V2_FPGA - IO_L17N_T2U_N9_AD10N_71
set_property IOSTANDARD  SSTL12 [get_ports "RLD3_C1_72B_DQ58"] ;# Bank  71 VCCO - VCC1V2_FPGA - IO_L17N_T2U_N9_AD10N_71
set_property PACKAGE_PIN F16      [get_ports "RLD3_C1_72B_DQ60"] ;# Bank  71 VCCO - VCC1V2_FPGA - IO_L16P_T2U_N6_QBC_AD3P_71
set_property IOSTANDARD  SSTL12 [get_ports "RLD3_C1_72B_DQ60"] ;# Bank  71 VCCO - VCC1V2_FPGA - IO_L16P_T2U_N6_QBC_AD3P_71
set_property PACKAGE_PIN E16      [get_ports "RLD3_C1_72B_DQ62"] ;# Bank  71 VCCO - VCC1V2_FPGA - IO_L16N_T2U_N7_QBC_AD3N_71
set_property IOSTANDARD  SSTL12 [get_ports "RLD3_C1_72B_DQ62"] ;# Bank  71 VCCO - VCC1V2_FPGA - IO_L16N_T2U_N7_QBC_AD3N_71
set_property PACKAGE_PIN E19      [get_ports "RLD3_C1_72B_DQ55"] ;# Bank  71 VCCO - VCC1V2_FPGA - IO_L15P_T2L_N4_AD11P_71
set_property IOSTANDARD  SSTL12 [get_ports "RLD3_C1_72B_DQ55"] ;# Bank  71 VCCO - VCC1V2_FPGA - IO_L15P_T2L_N4_AD11P_71
set_property PACKAGE_PIN E18      [get_ports "RLD3_C1_72B_DQ59"] ;# Bank  71 VCCO - VCC1V2_FPGA - IO_L15N_T2L_N5_AD11N_71
set_property IOSTANDARD  SSTL12 [get_ports "RLD3_C1_72B_DQ59"] ;# Bank  71 VCCO - VCC1V2_FPGA - IO_L15N_T2L_N5_AD11N_71
set_property PACKAGE_PIN F19      [get_ports "RLD3_C1_72B_DQ61"] ;# Bank  71 VCCO - VCC1V2_FPGA - IO_L14P_T2L_N2_GC_71
set_property IOSTANDARD  SSTL12 [get_ports "RLD3_C1_72B_DQ61"] ;# Bank  71 VCCO - VCC1V2_FPGA - IO_L14P_T2L_N2_GC_71
set_property PACKAGE_PIN F18      [get_ports "RLD3_C1_72B_DQ56"] ;# Bank  71 VCCO - VCC1V2_FPGA - IO_L14N_T2L_N3_GC_71
set_property IOSTANDARD  SSTL12 [get_ports "RLD3_C1_72B_DQ56"] ;# Bank  71 VCCO - VCC1V2_FPGA - IO_L14N_T2L_N3_GC_71
set_property PACKAGE_PIN G16      [get_ports "RLD3_C1_72B_QVLD3"] ;# Bank  71 VCCO - VCC1V2_FPGA - IO_T2U_N12_71
set_property IOSTANDARD  SSTL12 [get_ports "RLD3_C1_72B_QVLD3"] ;# Bank  71 VCCO - VCC1V2_FPGA - IO_T2U_N12_71
set_property PACKAGE_PIN G18      [get_ports "RLD3_C1_72B_QK6_P"] ;# Bank  71 VCCO - VCC1V2_FPGA - IO_L13P_T2L_N0_GC_QBC_71
set_property IOSTANDARD  DIFF_SSTL12 [get_ports "RLD3_C1_72B_QK6_P"] ;# Bank  71 VCCO - VCC1V2_FPGA - IO_L13P_T2L_N0_GC_QBC_71
set_property PACKAGE_PIN G17      [get_ports "RLD3_C1_72B_QK6_N"] ;# Bank  71 VCCO - VCC1V2_FPGA - IO_L13N_T2L_N1_GC_QBC_71
set_property IOSTANDARD  DIFF_SSTL12 [get_ports "RLD3_C1_72B_QK6_N"] ;# Bank  71 VCCO - VCC1V2_FPGA - IO_L13N_T2L_N1_GC_QBC_71
set_property PACKAGE_PIN H19      [get_ports "RLD3_C1_72B_DQ51"] ;# Bank  71 VCCO - VCC1V2_FPGA - IO_L12P_T1U_N10_GC_71
set_property IOSTANDARD  SSTL12 [get_ports "RLD3_C1_72B_DQ51"] ;# Bank  71 VCCO - VCC1V2_FPGA - IO_L12P_T1U_N10_GC_71
set_property PACKAGE_PIN H18      [get_ports "RLD3_C1_72B_DM3"] ;# Bank  71 VCCO - VCC1V2_FPGA - IO_L12N_T1U_N11_GC_71
set_property IOSTANDARD  SSTL12 [get_ports "RLD3_C1_72B_DM3"] ;# Bank  71 VCCO - VCC1V2_FPGA - IO_L12N_T1U_N11_GC_71
set_property PACKAGE_PIN L19      [get_ports "GPIO_DIP_SW1"] ;# Bank  71 VCCO - VCC1V2_FPGA - IO_T1U_N12_71
set_property IOSTANDARD  LVCMOS12 [get_ports "GPIO_DIP_SW1"] ;# Bank  71 VCCO - VCC1V2_FPGA - IO_T1U_N12_71
set_property PACKAGE_PIN J17      [get_ports "RLD3_C1_72B_DQ48"] ;# Bank  71 VCCO - VCC1V2_FPGA - IO_L11P_T1U_N8_GC_71
set_property IOSTANDARD  SSTL12 [get_ports "RLD3_C1_72B_DQ48"] ;# Bank  71 VCCO - VCC1V2_FPGA - IO_L11P_T1U_N8_GC_71
set_property PACKAGE_PIN H17      [get_ports "RLD3_C1_72B_DQ53"] ;# Bank  71 VCCO - VCC1V2_FPGA - IO_L11N_T1U_N9_GC_71
set_property IOSTANDARD  SSTL12 [get_ports "RLD3_C1_72B_DQ53"] ;# Bank  71 VCCO - VCC1V2_FPGA - IO_L11N_T1U_N9_GC_71
set_property PACKAGE_PIN K19      [get_ports "RLD3_C1_72B_DQ46"] ;# Bank  71 VCCO - VCC1V2_FPGA - IO_L10P_T1U_N6_QBC_AD4P_71
set_property IOSTANDARD  SSTL12 [get_ports "RLD3_C1_72B_DQ46"] ;# Bank  71 VCCO - VCC1V2_FPGA - IO_L10P_T1U_N6_QBC_AD4P_71
set_property PACKAGE_PIN J19      [get_ports "RLD3_C1_72B_DQ45"] ;# Bank  71 VCCO - VCC1V2_FPGA - IO_L10N_T1U_N7_QBC_AD4N_71
set_property IOSTANDARD  SSTL12 [get_ports "RLD3_C1_72B_DQ45"] ;# Bank  71 VCCO - VCC1V2_FPGA - IO_L10N_T1U_N7_QBC_AD4N_71
set_property PACKAGE_PIN L18      [get_ports "RLD3_C1_72B_DQ52"] ;# Bank  71 VCCO - VCC1V2_FPGA - IO_L9P_T1L_N4_AD12P_71
set_property IOSTANDARD  SSTL12 [get_ports "RLD3_C1_72B_DQ52"] ;# Bank  71 VCCO - VCC1V2_FPGA - IO_L9P_T1L_N4_AD12P_71
set_property PACKAGE_PIN K18      [get_ports "RLD3_C1_72B_DQ50"] ;# Bank  71 VCCO - VCC1V2_FPGA - IO_L9N_T1L_N5_AD12N_71
set_property IOSTANDARD  SSTL12 [get_ports "RLD3_C1_72B_DQ50"] ;# Bank  71 VCCO - VCC1V2_FPGA - IO_L9N_T1L_N5_AD12N_71
set_property PACKAGE_PIN L16      [get_ports "RLD3_C1_72B_DQ49"] ;# Bank  71 VCCO - VCC1V2_FPGA - IO_L8P_T1L_N2_AD5P_71
set_property IOSTANDARD  SSTL12 [get_ports "RLD3_C1_72B_DQ49"] ;# Bank  71 VCCO - VCC1V2_FPGA - IO_L8P_T1L_N2_AD5P_71
set_property PACKAGE_PIN K16      [get_ports "RLD3_C1_72B_DQ47"] ;# Bank  71 VCCO - VCC1V2_FPGA - IO_L8N_T1L_N3_AD5N_71
set_property IOSTANDARD  SSTL12 [get_ports "RLD3_C1_72B_DQ47"] ;# Bank  71 VCCO - VCC1V2_FPGA - IO_L8N_T1L_N3_AD5N_71
set_property PACKAGE_PIN K17      [get_ports "RLD3_C1_72B_QK5_P"] ;# Bank  71 VCCO - VCC1V2_FPGA - IO_L7P_T1L_N0_QBC_AD13P_71
set_property IOSTANDARD  DIFF_SSTL12 [get_ports "RLD3_C1_72B_QK5_P"] ;# Bank  71 VCCO - VCC1V2_FPGA - IO_L7P_T1L_N0_QBC_AD13P_71
set_property PACKAGE_PIN J16      [get_ports "RLD3_C1_72B_QK5_N"] ;# Bank  71 VCCO - VCC1V2_FPGA - IO_L7N_T1L_N1_QBC_AD13N_71
set_property IOSTANDARD  DIFF_SSTL12 [get_ports "RLD3_C1_72B_QK5_N"] ;# Bank  71 VCCO - VCC1V2_FPGA - IO_L7N_T1L_N1_QBC_AD13N_71
set_property PACKAGE_PIN N17      [get_ports "RLD3_C1_72B_DQ65"] ;# Bank  71 VCCO - VCC1V2_FPGA - IO_L6P_T0U_N10_AD6P_71
set_property IOSTANDARD  SSTL12 [get_ports "RLD3_C1_72B_DQ65"] ;# Bank  71 VCCO - VCC1V2_FPGA - IO_L6P_T0U_N10_AD6P_71
#set_property PACKAGE_PIN M16      [get_ports "5330N1245"] ;# Bank  71 VCCO - VCC1V2_FPGA - IO_L6N_T0U_N11_AD6N_71
#set_property IOSTANDARD  LVCMOSxx [get_ports "5330N1245"] ;# Bank  71 VCCO - VCC1V2_FPGA - IO_L6N_T0U_N11_AD6N_71
set_property PACKAGE_PIN N19      [get_ports "RLD3_C1_72B_DQ70"] ;# Bank  71 VCCO - VCC1V2_FPGA - IO_L5P_T0U_N8_AD14P_71
set_property IOSTANDARD  SSTL12 [get_ports "RLD3_C1_72B_DQ70"] ;# Bank  71 VCCO - VCC1V2_FPGA - IO_L5P_T0U_N8_AD14P_71
set_property PACKAGE_PIN N18      [get_ports "RLD3_C1_72B_DQ68"] ;# Bank  71 VCCO - VCC1V2_FPGA - IO_L5N_T0U_N9_AD14N_71
set_property IOSTANDARD  SSTL12 [get_ports "RLD3_C1_72B_DQ68"] ;# Bank  71 VCCO - VCC1V2_FPGA - IO_L5N_T0U_N9_AD14N_71
set_property PACKAGE_PIN P17      [get_ports "RLD3_C1_72B_DQ66"] ;# Bank  71 VCCO - VCC1V2_FPGA - IO_L4P_T0U_N6_DBC_AD7P_71
set_property IOSTANDARD  SSTL12 [get_ports "RLD3_C1_72B_DQ66"] ;# Bank  71 VCCO - VCC1V2_FPGA - IO_L4P_T0U_N6_DBC_AD7P_71
set_property PACKAGE_PIN P16      [get_ports "RLD3_C1_72B_DQ63"] ;# Bank  71 VCCO - VCC1V2_FPGA - IO_L4N_T0U_N7_DBC_AD7N_71
set_property IOSTANDARD  SSTL12 [get_ports "RLD3_C1_72B_DQ63"] ;# Bank  71 VCCO - VCC1V2_FPGA - IO_L4N_T0U_N7_DBC_AD7N_71
set_property PACKAGE_PIN M18      [get_ports "RLD3_C1_72B_DQ64"] ;# Bank  71 VCCO - VCC1V2_FPGA - IO_L3P_T0L_N4_AD15P_71
set_property IOSTANDARD  SSTL12 [get_ports "RLD3_C1_72B_DQ64"] ;# Bank  71 VCCO - VCC1V2_FPGA - IO_L3P_T0L_N4_AD15P_71
set_property PACKAGE_PIN M17      [get_ports "RLD3_C1_72B_DQ69"] ;# Bank  71 VCCO - VCC1V2_FPGA - IO_L3N_T0L_N5_AD15N_71
set_property IOSTANDARD  SSTL12 [get_ports "RLD3_C1_72B_DQ69"] ;# Bank  71 VCCO - VCC1V2_FPGA - IO_L3N_T0L_N5_AD15N_71
set_property PACKAGE_PIN R19      [get_ports "RLD3_C1_72B_DQ67"] ;# Bank  71 VCCO - VCC1V2_FPGA - IO_L2P_T0L_N2_71
set_property IOSTANDARD  SSTL12 [get_ports "RLD3_C1_72B_DQ67"] ;# Bank  71 VCCO - VCC1V2_FPGA - IO_L2P_T0L_N2_71
set_property PACKAGE_PIN P19      [get_ports "RLD3_C1_72B_DQ71"] ;# Bank  71 VCCO - VCC1V2_FPGA - IO_L2N_T0L_N3_71
set_property IOSTANDARD  SSTL12 [get_ports "RLD3_C1_72B_DQ71"] ;# Bank  71 VCCO - VCC1V2_FPGA - IO_L2N_T0L_N3_71
#set_property PACKAGE_PIN T18      [get_ports "VRP_71"] ;# Bank  71 VCCO - VCC1V2_FPGA - IO_T0U_N12_VRP_71
#set_property IOSTANDARD  LVCMOSxx [get_ports "VRP_71"] ;# Bank  71 VCCO - VCC1V2_FPGA - IO_T0U_N12_VRP_71
set_property PACKAGE_PIN R18      [get_ports "RLD3_C1_72B_QK7_P"] ;# Bank  71 VCCO - VCC1V2_FPGA - IO_L1P_T0L_N0_DBC_71
set_property IOSTANDARD  DIFF_SSTL12 [get_ports "RLD3_C1_72B_QK7_P"] ;# Bank  71 VCCO - VCC1V2_FPGA - IO_L1P_T0L_N0_DBC_71
set_property PACKAGE_PIN R17      [get_ports "RLD3_C1_72B_QK7_N"] ;# Bank  71 VCCO - VCC1V2_FPGA - IO_L1N_T0L_N1_DBC_71
set_property IOSTANDARD  DIFF_SSTL12 [get_ports "RLD3_C1_72B_QK7_N"] ;# Bank  71 VCCO - VCC1V2_FPGA - IO_L1N_T0L_N1_DBC_71
set_property PACKAGE_PIN AL24     [get_ports "QSFP_MODSELL_LS"] ;# Bank  84 VCCO - VCC1V8_FPGA - IO_L24P_T3U_N10_84
set_property IOSTANDARD  LVCMOS18 [get_ports "QSFP_MODSELL_LS"] ;# Bank  84 VCCO - VCC1V8_FPGA - IO_L24P_T3U_N10_84
set_property PACKAGE_PIN AM24     [get_ports "QSFP_RESETL_LS"] ;# Bank  84 VCCO - VCC1V8_FPGA - IO_L24N_T3U_N11_84
set_property IOSTANDARD  LVCMOS18 [get_ports "QSFP_RESETL_LS"] ;# Bank  84 VCCO - VCC1V8_FPGA - IO_L24N_T3U_N11_84
set_property PACKAGE_PIN AL25     [get_ports "QSFP_MODPRSL_LS"] ;# Bank  84 VCCO - VCC1V8_FPGA - IO_T3U_N12_84
set_property IOSTANDARD  LVCMOS18 [get_ports "QSFP_MODPRSL_LS"] ;# Bank  84 VCCO - VCC1V8_FPGA - IO_T3U_N12_84
set_property PACKAGE_PIN AL21     [get_ports "QSFP_INTL_LS"] ;# Bank  84 VCCO - VCC1V8_FPGA - IO_L23P_T3U_N8_84
set_property IOSTANDARD  LVCMOS18 [get_ports "QSFP_INTL_LS"] ;# Bank  84 VCCO - VCC1V8_FPGA - IO_L23P_T3U_N8_84
set_property PACKAGE_PIN AM21     [get_ports "QSFP_LPMODE_LS"] ;# Bank  84 VCCO - VCC1V8_FPGA - IO_L23N_T3U_N9_84
set_property IOSTANDARD  LVCMOS18 [get_ports "QSFP_LPMODE_LS"] ;# Bank  84 VCCO - VCC1V8_FPGA - IO_L23N_T3U_N9_84
set_property PACKAGE_PIN AM23     [get_ports "IIC_MUX_RESET_B_LS"] ;# Bank  84 VCCO - VCC1V8_FPGA - IO_L22P_T3U_N6_DBC_AD0P_84
set_property IOSTANDARD  LVCMOS18 [get_ports "IIC_MUX_RESET_B_LS"] ;# Bank  84 VCCO - VCC1V8_FPGA - IO_L22P_T3U_N6_DBC_AD0P_84
set_property PACKAGE_PIN AM22     [get_ports "SYSCTLR_GPIO_6"] ;# Bank  84 VCCO - VCC1V8_FPGA - IO_L22N_T3U_N7_DBC_AD0N_84
set_property IOSTANDARD  LVCMOS18 [get_ports "SYSCTLR_GPIO_6"] ;# Bank  84 VCCO - VCC1V8_FPGA - IO_L22N_T3U_N7_DBC_AD0N_84
set_property PACKAGE_PIN AN21     [get_ports "IIC_MAIN_SCL_LS"] ;# Bank  84 VCCO - VCC1V8_FPGA - IO_L21P_T3L_N4_AD8P_84
set_property IOSTANDARD  LVCMOS18 [get_ports "IIC_MAIN_SCL_LS"] ;# Bank  84 VCCO - VCC1V8_FPGA - IO_L21P_T3L_N4_AD8P_84
set_property PACKAGE_PIN AP21     [get_ports "IIC_MAIN_SDA_LS"] ;# Bank  84 VCCO - VCC1V8_FPGA - IO_L21N_T3L_N5_AD8N_84
set_property IOSTANDARD  LVCMOS18 [get_ports "IIC_MAIN_SDA_LS"] ;# Bank  84 VCCO - VCC1V8_FPGA - IO_L21N_T3L_N5_AD8N_84
set_property PACKAGE_PIN AN24     [get_ports "SI5328_RST_LS"] ;# Bank  84 VCCO - VCC1V8_FPGA - IO_L20P_T3L_N2_AD1P_84
set_property IOSTANDARD  LVCMOS18 [get_ports "SI5328_RST_LS"] ;# Bank  84 VCCO - VCC1V8_FPGA - IO_L20P_T3L_N2_AD1P_84
set_property PACKAGE_PIN AN23     [get_ports "FMC_VADJ_ON_LS"] ;# Bank  84 VCCO - VCC1V8_FPGA - IO_L20N_T3L_N3_AD1N_84
set_property IOSTANDARD  LVCMOS18 [get_ports "FMC_VADJ_ON_LS"] ;# Bank  84 VCCO - VCC1V8_FPGA - IO_L20N_T3L_N3_AD1N_84
set_property PACKAGE_PIN AP23     [get_ports "VADJ_1V8_PGOOD_LS"] ;# Bank  84 VCCO - VCC1V8_FPGA - IO_L19P_T3L_N0_DBC_AD9P_84
set_property IOSTANDARD  LVCMOS18 [get_ports "VADJ_1V8_PGOOD_LS"] ;# Bank  84 VCCO - VCC1V8_FPGA - IO_L19P_T3L_N0_DBC_AD9P_84
set_property PACKAGE_PIN AP22     [get_ports "FMC_HPC0_PG_M2C_LS"] ;# Bank  84 VCCO - VCC1V8_FPGA - IO_L19N_T3L_N1_DBC_AD9N_84
set_property IOSTANDARD  LVCMOS18 [get_ports "FMC_HPC0_PG_M2C_LS"] ;# Bank  84 VCCO - VCC1V8_FPGA - IO_L19N_T3L_N1_DBC_AD9N_84
set_property PACKAGE_PIN AR24     [get_ports "SGMII_RX_P"] ;# Bank  84 VCCO - VCC1V8_FPGA - IO_L18P_T2U_N10_AD2P_84
set_property IOSTANDARD  DIFF_HSTL_I_18 [get_ports "SGMII_RX_P"] ;# Bank  84 VCCO - VCC1V8_FPGA - IO_L18P_T2U_N10_AD2P_84
set_property PACKAGE_PIN AT24     [get_ports "SGMII_RX_N"] ;# Bank  84 VCCO - VCC1V8_FPGA - IO_L18N_T2U_N11_AD2N_84
set_property IOSTANDARD  DIFF_HSTL_I_18 [get_ports "SGMII_RX_N"] ;# Bank  84 VCCO - VCC1V8_FPGA - IO_L18N_T2U_N11_AD2N_84
set_property PACKAGE_PIN AR23     [get_ports "SGMII_TX_P"] ;# Bank  84 VCCO - VCC1V8_FPGA - IO_L17P_T2U_N8_AD10P_84
set_property IOSTANDARD  DIFF_HSTL_I_18 [get_ports "SGMII_TX_P"] ;# Bank  84 VCCO - VCC1V8_FPGA - IO_L17P_T2U_N8_AD10P_84
set_property PACKAGE_PIN AR22     [get_ports "SGMII_TX_N"] ;# Bank  84 VCCO - VCC1V8_FPGA - IO_L17N_T2U_N9_AD10N_84
set_property IOSTANDARD  DIFF_HSTL_I_18 [get_ports "SGMII_TX_N"] ;# Bank  84 VCCO - VCC1V8_FPGA - IO_L17N_T2U_N9_AD10N_84
set_property PACKAGE_PIN AU24     [get_ports "FMC_HPC1_PG_M2C_LS"] ;# Bank  84 VCCO - VCC1V8_FPGA - IO_L16P_T2U_N6_QBC_AD3P_84
set_property IOSTANDARD  LVCMOS18 [get_ports "FMC_HPC1_PG_M2C_LS"] ;# Bank  84 VCCO - VCC1V8_FPGA - IO_L16P_T2U_N6_QBC_AD3P_84
set_property PACKAGE_PIN AV24     [get_ports "PHY_MDIO_LS"] ;# Bank  84 VCCO - VCC1V8_FPGA - IO_L16N_T2U_N7_QBC_AD3N_84
set_property IOSTANDARD  LVCMOS18 [get_ports "PHY_MDIO_LS"] ;# Bank  84 VCCO - VCC1V8_FPGA - IO_L16N_T2U_N7_QBC_AD3N_84
set_property PACKAGE_PIN AU21     [get_ports "PHY_RESET_LS"] ;# Bank  84 VCCO - VCC1V8_FPGA - IO_L15P_T2L_N4_AD11P_84
set_property IOSTANDARD  LVCMOS18 [get_ports "PHY_RESET_LS"] ;# Bank  84 VCCO - VCC1V8_FPGA - IO_L15P_T2L_N4_AD11P_84
set_property PACKAGE_PIN AV21     [get_ports "PHY_MDC_LS"] ;# Bank  84 VCCO - VCC1V8_FPGA - IO_L15N_T2L_N5_AD11N_84
set_property IOSTANDARD  LVCMOS18 [get_ports "PHY_MDC_LS"] ;# Bank  84 VCCO - VCC1V8_FPGA - IO_L15N_T2L_N5_AD11N_84
set_property PACKAGE_PIN AU23     [get_ports "USER_SI570_CLOCK_P"] ;# Bank  84 VCCO - VCC1V8_FPGA - IO_L14P_T2L_N2_GC_84
set_property IOSTANDARD  LVDS_25 [get_ports "USER_SI570_CLOCK_P"] ;# Bank  84 VCCO - VCC1V8_FPGA - IO_L14P_T2L_N2_GC_84
set_property PACKAGE_PIN AV23     [get_ports "USER_SI570_CLOCK_N"] ;# Bank  84 VCCO - VCC1V8_FPGA - IO_L14N_T2L_N3_GC_84
set_property IOSTANDARD  LVDS_25 [get_ports "USER_SI570_CLOCK_N"] ;# Bank  84 VCCO - VCC1V8_FPGA - IO_L14N_T2L_N3_GC_84
set_property PACKAGE_PIN AT21     [get_ports "PHY_INT_LS"] ;# Bank  84 VCCO - VCC1V8_FPGA - IO_T2U_N12_84
set_property IOSTANDARD  LVCMOS18 [get_ports "PHY_INT_LS"] ;# Bank  84 VCCO - VCC1V8_FPGA - IO_T2U_N12_84
set_property PACKAGE_PIN AT22     [get_ports "SGMIICLK_P"] ;# Bank  84 VCCO - VCC1V8_FPGA - IO_L13P_T2L_N0_GC_QBC_84
set_property IOSTANDARD  LVDS_25 [get_ports "SGMIICLK_P"] ;# Bank  84 VCCO - VCC1V8_FPGA - IO_L13P_T2L_N0_GC_QBC_84
set_property PACKAGE_PIN AU22     [get_ports "SGMIICLK_N"] ;# Bank  84 VCCO - VCC1V8_FPGA - IO_L13N_T2L_N1_GC_QBC_84
set_property IOSTANDARD  LVDS_25 [get_ports "SGMIICLK_N"] ;# Bank  84 VCCO - VCC1V8_FPGA - IO_L13N_T2L_N1_GC_QBC_84
set_property PACKAGE_PIN AW23     [get_ports "SYSCTLR_GPIO_5"] ;# Bank  94 VCCO - VCC1V8_FPGA - IO_L12P_T1U_N10_GC_94
set_property IOSTANDARD  LVCMOS18 [get_ports "SYSCTLR_GPIO_5"] ;# Bank  94 VCCO - VCC1V8_FPGA - IO_L12P_T1U_N10_GC_94
set_property PACKAGE_PIN AW22     [get_ports "SYSCTLR_GPIO_7"] ;# Bank  94 VCCO - VCC1V8_FPGA - IO_L12N_T1U_N11_GC_94
set_property IOSTANDARD  LVCMOS18 [get_ports "SYSCTLR_GPIO_7"] ;# Bank  94 VCCO - VCC1V8_FPGA - IO_L12N_T1U_N11_GC_94
set_property PACKAGE_PIN BA21     [get_ports "PRG_CNTL1_CFP2_LS"] ;# Bank  94 VCCO - VCC1V8_FPGA - IO_T1U_N12_94
set_property IOSTANDARD  LVCMOS18 [get_ports "PRG_CNTL1_CFP2_LS"] ;# Bank  94 VCCO - VCC1V8_FPGA - IO_T1U_N12_94
set_property PACKAGE_PIN AY24     [get_ports "PRG_CNTL2_CFP2_LS"] ;# Bank  94 VCCO - VCC1V8_FPGA - IO_L11P_T1U_N8_GC_94
set_property IOSTANDARD  LVCMOS18 [get_ports "PRG_CNTL2_CFP2_LS"] ;# Bank  94 VCCO - VCC1V8_FPGA - IO_L11P_T1U_N8_GC_94
set_property PACKAGE_PIN AY23     [get_ports "PRG_CNTL3_CFP2_LS"] ;# Bank  94 VCCO - VCC1V8_FPGA - IO_L11N_T1U_N9_GC_94
set_property IOSTANDARD  LVCMOS18 [get_ports "PRG_CNTL3_CFP2_LS"] ;# Bank  94 VCCO - VCC1V8_FPGA - IO_L11N_T1U_N9_GC_94
set_property PACKAGE_PIN AY22     [get_ports "TX_DIS_CFP2_LS"] ;# Bank  94 VCCO - VCC1V8_FPGA - IO_L10P_T1U_N6_QBC_AD4P_94
set_property IOSTANDARD  LVCMOS18 [get_ports "TX_DIS_CFP2_LS"] ;# Bank  94 VCCO - VCC1V8_FPGA - IO_L10P_T1U_N6_QBC_AD4P_94
set_property PACKAGE_PIN BA22     [get_ports "PRTADR0_CFP2_LS"] ;# Bank  94 VCCO - VCC1V8_FPGA - IO_L10N_T1U_N7_QBC_AD4N_94
set_property IOSTANDARD  LVCMOS18 [get_ports "PRTADR0_CFP2_LS"] ;# Bank  94 VCCO - VCC1V8_FPGA - IO_L10N_T1U_N7_QBC_AD4N_94
set_property PACKAGE_PIN AW25     [get_ports "PRTADR1_CFP2_LS"] ;# Bank  94 VCCO - VCC1V8_FPGA - IO_L9P_T1L_N4_AD12P_94
set_property IOSTANDARD  LVCMOS18 [get_ports "PRTADR1_CFP2_LS"] ;# Bank  94 VCCO - VCC1V8_FPGA - IO_L9P_T1L_N4_AD12P_94
set_property PACKAGE_PIN AY25     [get_ports "PRTADR2_CFP2_LS"] ;# Bank  94 VCCO - VCC1V8_FPGA - IO_L9N_T1L_N5_AD12N_94
set_property IOSTANDARD  LVCMOS18 [get_ports "PRTADR2_CFP2_LS"] ;# Bank  94 VCCO - VCC1V8_FPGA - IO_L9N_T1L_N5_AD12N_94
set_property PACKAGE_PIN BB22     [get_ports "PRG_ALRM3_CFP2_LS"] ;# Bank  94 VCCO - VCC1V8_FPGA - IO_L8P_T1L_N2_AD5P_94
set_property IOSTANDARD  LVCMOS18 [get_ports "PRG_ALRM3_CFP2_LS"] ;# Bank  94 VCCO - VCC1V8_FPGA - IO_L8P_T1L_N2_AD5P_94
set_property PACKAGE_PIN BB21     [get_ports "RX_LOS_CFP2_LS"] ;# Bank  94 VCCO - VCC1V8_FPGA - IO_L8N_T1L_N3_AD5N_94
set_property IOSTANDARD  LVCMOS18 [get_ports "RX_LOS_CFP2_LS"] ;# Bank  94 VCCO - VCC1V8_FPGA - IO_L8N_T1L_N3_AD5N_94
set_property PACKAGE_PIN BA25     [get_ports "MOD_ABS_CFP2_LS"] ;# Bank  94 VCCO - VCC1V8_FPGA - IO_L7P_T1L_N0_QBC_AD13P_94
set_property IOSTANDARD  LVCMOS18 [get_ports "MOD_ABS_CFP2_LS"] ;# Bank  94 VCCO - VCC1V8_FPGA - IO_L7P_T1L_N0_QBC_AD13P_94
set_property PACKAGE_PIN BA24     [get_ports "GLB_ALRMN_CFP2_LS"] ;# Bank  94 VCCO - VCC1V8_FPGA - IO_L7N_T1L_N1_QBC_AD13N_94
set_property IOSTANDARD  LVCMOS18 [get_ports "GLB_ALRMN_CFP2_LS"] ;# Bank  94 VCCO - VCC1V8_FPGA - IO_L7N_T1L_N1_QBC_AD13N_94
set_property PACKAGE_PIN BC21     [get_ports "MOD_LOPWR_CFP2_LS"] ;# Bank  94 VCCO - VCC1V8_FPGA - IO_L6P_T0U_N10_AD6P_94
set_property IOSTANDARD  LVCMOS18 [get_ports "MOD_LOPWR_CFP2_LS"] ;# Bank  94 VCCO - VCC1V8_FPGA - IO_L6P_T0U_N10_AD6P_94
set_property PACKAGE_PIN BD21     [get_ports "MOD_RSTN_CFP2_LS"] ;# Bank  94 VCCO - VCC1V8_FPGA - IO_L6N_T0U_N11_AD6N_94
set_property IOSTANDARD  LVCMOS18 [get_ports "MOD_RSTN_CFP2_LS"] ;# Bank  94 VCCO - VCC1V8_FPGA - IO_L6N_T0U_N11_AD6N_94
set_property PACKAGE_PIN BB24     [get_ports "PRG_ALRM1_CFP2_LS"] ;# Bank  94 VCCO - VCC1V8_FPGA - IO_L5P_T0U_N8_AD14P_94
set_property IOSTANDARD  LVCMOS18 [get_ports "PRG_ALRM1_CFP2_LS"] ;# Bank  94 VCCO - VCC1V8_FPGA - IO_L5P_T0U_N8_AD14P_94
set_property PACKAGE_PIN BB23     [get_ports "PRG_ALRM2_CFP2_LS"] ;# Bank  94 VCCO - VCC1V8_FPGA - IO_L5N_T0U_N9_AD14N_94
set_property IOSTANDARD  LVCMOS18 [get_ports "PRG_ALRM2_CFP2_LS"] ;# Bank  94 VCCO - VCC1V8_FPGA - IO_L5N_T0U_N9_AD14N_94
set_property PACKAGE_PIN BE22     [get_ports "MDC_CFP2_LS"] ;# Bank  94 VCCO - VCC1V8_FPGA - IO_L4P_T0U_N6_DBC_AD7P_94
set_property IOSTANDARD  LVCMOS18 [get_ports "MDC_CFP2_LS"] ;# Bank  94 VCCO - VCC1V8_FPGA - IO_L4P_T0U_N6_DBC_AD7P_94
set_property PACKAGE_PIN BF22     [get_ports "MDIO_CFP2_LS"] ;# Bank  94 VCCO - VCC1V8_FPGA - IO_L4N_T0U_N7_DBC_AD7N_94
set_property IOSTANDARD  LVCMOS18 [get_ports "MDIO_CFP2_LS"] ;# Bank  94 VCCO - VCC1V8_FPGA - IO_L4N_T0U_N7_DBC_AD7N_94
set_property PACKAGE_PIN BD23     [get_ports "FMC_HPC1_PRSNT_M2C_B_LS"] ;# Bank  94 VCCO - VCC1V8_FPGA - IO_L3P_T0L_N4_AD15P_94
set_property IOSTANDARD  LVCMOS18 [get_ports "FMC_HPC1_PRSNT_M2C_B_LS"] ;# Bank  94 VCCO - VCC1V8_FPGA - IO_L3P_T0L_N4_AD15P_94
set_property PACKAGE_PIN BE23     [get_ports "PMBUS_ALERT_FPGA"] ;# Bank  94 VCCO - VCC1V8_FPGA - IO_L3N_T0L_N5_AD15N_94
set_property IOSTANDARD  LVCMOS18 [get_ports "PMBUS_ALERT_FPGA"] ;# Bank  94 VCCO - VCC1V8_FPGA - IO_L3N_T0L_N5_AD15N_94
set_property PACKAGE_PIN BC23     [get_ports "BPI_WAIT"] ;# Bank  94 VCCO - VCC1V8_FPGA - IO_L2P_T0L_N2_94
set_property IOSTANDARD  LVCMOS18 [get_ports "BPI_WAIT"] ;# Bank  94 VCCO - VCC1V8_FPGA - IO_L2P_T0L_N2_94
set_property PACKAGE_PIN BD22     [get_ports "USB_UART_RTS"] ;# Bank  94 VCCO - VCC1V8_FPGA - IO_L2N_T0L_N3_94
set_property IOSTANDARD  LVCMOS18 [get_ports "USB_UART_RTS"] ;# Bank  94 VCCO - VCC1V8_FPGA - IO_L2N_T0L_N3_94
set_property PACKAGE_PIN BC24     [get_ports "USB_UART_TX"] ;# Bank  94 VCCO - VCC1V8_FPGA - IO_T0U_N12_94
set_property IOSTANDARD  LVCMOS18 [get_ports "USB_UART_TX"] ;# Bank  94 VCCO - VCC1V8_FPGA - IO_T0U_N12_94
set_property PACKAGE_PIN BE24     [get_ports "USB_UART_RX"] ;# Bank  94 VCCO - VCC1V8_FPGA - IO_L1P_T0L_N0_DBC_94
set_property IOSTANDARD  LVCMOS18 [get_ports "USB_UART_RX"] ;# Bank  94 VCCO - VCC1V8_FPGA - IO_L1P_T0L_N0_DBC_94
set_property PACKAGE_PIN BF24     [get_ports "USB_UART_CTS"] ;# Bank  94 VCCO - VCC1V8_FPGA - IO_L1N_T0L_N1_DBC_94
set_property IOSTANDARD  LVCMOS18 [get_ports "USB_UART_CTS"] ;# Bank  94 VCCO - VCC1V8_FPGA - IO_L1N_T0L_N1_DBC_94
#Other net   PACKAGE_PIN AW21     - 5331N677                  Bank  94 - VREF_94
#Other net   PACKAGE_PIN AV43     - 5333N914                  Bank 125 - MGTYTXN3_125
#Other net   PACKAGE_PIN AV42     - 5333N912                  Bank 125 - MGTYTXP3_125
#Other net   PACKAGE_PIN AU45     - GND                       Bank 125 - MGTYRXP3_125
#Other net   PACKAGE_PIN AU46     - GND                       Bank 125 - MGTYRXN3_125
#set_property PACKAGE_PIN AM39     [get_ports "5333N1673"] ;# Bank 125 - MGTREFCLK1N_125
#set_property PACKAGE_PIN AM38     [get_ports "5333N1672"] ;# Bank 125 - MGTREFCLK1P_125
#Other net   PACKAGE_PIN AY43     - 5333N910                  Bank 125 - MGTYTXN2_125
#Other net   PACKAGE_PIN AY42     - 5333N908                  Bank 125 - MGTYTXP2_125
#Other net   PACKAGE_PIN AW45     - GND                       Bank 125 - MGTYRXP2_125
#Other net   PACKAGE_PIN AW46     - GND                       Bank 125 - MGTYRXN2_125
#Other net   PACKAGE_PIN BB43     - 5333N906                  Bank 125 - MGTYTXN1_125
#Other net   PACKAGE_PIN BB42     - 5333N904                  Bank 125 - MGTYTXP1_125
#Other net   PACKAGE_PIN BA45     - GND                       Bank 125 - MGTYRXP1_125
#Other net   PACKAGE_PIN BA46     - GND                       Bank 125 - MGTYRXN1_125
#set_property PACKAGE_PIN AN41     [get_ports "5333N1667"] ;# Bank 125 - MGTREFCLK0N_125
#set_property PACKAGE_PIN AN40     [get_ports "5333N1666"] ;# Bank 125 - MGTREFCLK0P_125
#Other net   PACKAGE_PIN BD43     - 5333N902                  Bank 125 - MGTYTXN0_125
#Other net   PACKAGE_PIN BD42     - 5333N900                  Bank 125 - MGTYTXP0_125
#Other net   PACKAGE_PIN BC45     - GND                       Bank 125 - MGTYRXP0_125
#Other net   PACKAGE_PIN BC46     - GND                       Bank 125 - MGTYRXN0_125
#Other net   PACKAGE_PIN AL41     - BULLSEYE_GTY_TX3_N        Bank 126 - MGTYTXN3_126
#Other net   PACKAGE_PIN AL40     - BULLSEYE_GTY_TX3_P        Bank 126 - MGTYTXP3_126
#Other net   PACKAGE_PIN AJ45     - BULLSEYE_GTY_RX3_P        Bank 126 - MGTYRXP3_126
#Other net   PACKAGE_PIN AJ46     - BULLSEYE_GTY_RX3_N        Bank 126 - MGTYRXN3_126
set_property PACKAGE_PIN AH39     [get_ports "MGT_SI570_CLOCK3_C_N"] ;# Bank 126 - MGTREFCLK1N_126
set_property PACKAGE_PIN AH38     [get_ports "MGT_SI570_CLOCK3_C_P"] ;# Bank 126 - MGTREFCLK1P_126
#Other net   PACKAGE_PIN AM43     - BULLSEYE_GTY_TX2_N        Bank 126 - MGTYTXN2_126
#Other net   PACKAGE_PIN AM42     - BULLSEYE_GTY_TX2_P        Bank 126 - MGTYTXP2_126
#Other net   PACKAGE_PIN AL45     - BULLSEYE_GTY_RX2_P        Bank 126 - MGTYRXP2_126
#Other net   PACKAGE_PIN AL46     - BULLSEYE_GTY_RX2_N        Bank 126 - MGTYRXN2_126
#Other net   PACKAGE_PIN AP43     - BULLSEYE_GTY_TX1_N        Bank 126 - MGTYTXN1_126
#Other net   PACKAGE_PIN AP42     - BULLSEYE_GTY_TX1_P        Bank 126 - MGTYTXP1_126
#Other net   PACKAGE_PIN AN45     - BULLSEYE_GTY_RX1_P        Bank 126 - MGTYRXP1_126
#Other net   PACKAGE_PIN AN46     - BULLSEYE_GTY_RX1_N        Bank 126 - MGTYRXN1_126
set_property PACKAGE_PIN AK39     [get_ports "BULLSEYE_GTY_REFCLK_C_N"] ;# Bank 126 - MGTREFCLK0N_126
set_property PACKAGE_PIN AK38     [get_ports "BULLSEYE_GTY_REFCLK_C_P"] ;# Bank 126 - MGTREFCLK0P_126
#Other net   PACKAGE_PIN AT43     - BULLSEYE_GTY_TX0_N        Bank 126 - MGTYTXN0_126
#Other net   PACKAGE_PIN AT42     - BULLSEYE_GTY_TX0_P        Bank 126 - MGTYTXP0_126
#Other net   PACKAGE_PIN AR45     - BULLSEYE_GTY_RX0_P        Bank 126 - MGTYRXP0_126
#Other net   PACKAGE_PIN AR46     - BULLSEYE_GTY_RX0_N        Bank 126 - MGTYRXN0_126
#Other net   PACKAGE_PIN AE41     - QSFP_TX4_N                Bank 127 - MGTYTXN3_127
#Other net   PACKAGE_PIN AE40     - QSFP_TX4_P                Bank 127 - MGTYTXP3_127
#Other net   PACKAGE_PIN AD43     - QSFP_RX4_P                Bank 127 - MGTYRXP3_127
#Other net   PACKAGE_PIN AD44     - QSFP_RX4_N                Bank 127 - MGTYRXN3_127
set_property PACKAGE_PIN AD39     [get_ports "SI5328_CLOCK2_C_N"] ;# Bank 127 - MGTREFCLK1N_127
set_property PACKAGE_PIN AD38     [get_ports "SI5328_CLOCK2_C_P"] ;# Bank 127 - MGTREFCLK1P_127
#Other net   PACKAGE_PIN AG41     - QSFP_TX3_N                Bank 127 - MGTYTXN2_127
#Other net   PACKAGE_PIN AG40     - QSFP_TX3_P                Bank 127 - MGTYTXP2_127
#Other net   PACKAGE_PIN AE45     - QSFP_RX3_P                Bank 127 - MGTYRXP2_127
#Other net   PACKAGE_PIN AE46     - QSFP_RX3_N                Bank 127 - MGTYRXN2_127
#Other net   PACKAGE_PIN AJ41     - QSFP_TX2_N                Bank 127 - MGTYTXN1_127
#Other net   PACKAGE_PIN AJ40     - QSFP_TX2_P                Bank 127 - MGTYTXP1_127
#Other net   PACKAGE_PIN AF43     - QSFP_RX2_P                Bank 127 - MGTYRXP1_127
#Other net   PACKAGE_PIN AF44     - QSFP_RX2_N                Bank 127 - MGTYRXN1_127
set_property PACKAGE_PIN AF39     [get_ports "MGT_SI570_CLOCK2_C_N"] ;# Bank 127 - MGTREFCLK0N_127
set_property PACKAGE_PIN AF38     [get_ports "MGT_SI570_CLOCK2_C_P"] ;# Bank 127 - MGTREFCLK0P_127
#Other net   PACKAGE_PIN AK43     - QSFP_TX1_N                Bank 127 - MGTYTXN0_127
#Other net   PACKAGE_PIN AK42     - QSFP_TX1_P                Bank 127 - MGTYTXP0_127
#Other net   PACKAGE_PIN AG45     - QSFP_RX1_P                Bank 127 - MGTYRXP0_127
#Other net   PACKAGE_PIN AG46     - QSFP_RX1_N                Bank 127 - MGTYRXN0_127
#Other net   PACKAGE_PIN U41      - CFP2_TX4_X_N              Bank 128 - MGTYTXN3_128
#Other net   PACKAGE_PIN U40      - CFP2_TX4_X_P              Bank 128 - MGTYTXP3_128
#Other net   PACKAGE_PIN Y43      - CFP2_RX4_X_P              Bank 128 - MGTYRXP3_128
#Other net   PACKAGE_PIN Y44      - CFP2_RX4_X_N              Bank 128 - MGTYRXN3_128
#set_property PACKAGE_PIN Y39      [get_ports "5334N1407"] ;# Bank 128 - MGTREFCLK1N_128
#set_property PACKAGE_PIN Y38      [get_ports "5334N1406"] ;# Bank 128 - MGTREFCLK1P_128
#Other net   PACKAGE_PIN W41      - CFP2_TX7_X_N              Bank 128 - MGTYTXN2_128
#Other net   PACKAGE_PIN W40      - CFP2_TX7_X_P              Bank 128 - MGTYTXP2_128
#Other net   PACKAGE_PIN AA45     - CFP2_RX7_X_P              Bank 128 - MGTYRXP2_128
#Other net   PACKAGE_PIN AA46     - CFP2_RX7_X_N              Bank 128 - MGTYRXN2_128
#Other net   PACKAGE_PIN AA41     - CFP2_TX8_X_N              Bank 128 - MGTYTXN1_128
#Other net   PACKAGE_PIN AA40     - CFP2_TX8_X_P              Bank 128 - MGTYTXP1_128
#Other net   PACKAGE_PIN AB43     - CFP2_RX8_X_P              Bank 128 - MGTYRXP1_128
#Other net   PACKAGE_PIN AB44     - CFP2_RX8_X_N              Bank 128 - MGTYRXN1_128
#set_property PACKAGE_PIN AB39     [get_ports "5334N1405"] ;# Bank 128 - MGTREFCLK0N_128
#set_property PACKAGE_PIN AB38     [get_ports "5334N1404"] ;# Bank 128 - MGTREFCLK0P_128
#Other net   PACKAGE_PIN AC41     - CFP2_TX9_X_N              Bank 128 - MGTYTXN0_128
#Other net   PACKAGE_PIN AC40     - CFP2_TX9_X_P              Bank 128 - MGTYTXP0_128
#Other net   PACKAGE_PIN AC45     - CFP2_RX9_X_P              Bank 128 - MGTYRXP0_128
#Other net   PACKAGE_PIN AC46     - CFP2_RX9_X_N              Bank 128 - MGTYRXN0_128
#Other net   PACKAGE_PIN K43      - CFP2_TX1_0_N              Bank 129 - MGTYTXN3_129
#Other net   PACKAGE_PIN K42      - CFP2_TX1_0_P              Bank 129 - MGTYTXP3_129
#Other net   PACKAGE_PIN N45      - CFP2_RX1_0_P              Bank 129 - MGTYRXP3_129
#Other net   PACKAGE_PIN N46      - CFP2_RX1_0_N              Bank 129 - MGTYRXN3_129
set_property PACKAGE_PIN T39      [get_ports "SI5328_CLOCK1_C_N"] ;# Bank 129 - MGTREFCLK1N_129
set_property PACKAGE_PIN T38      [get_ports "SI5328_CLOCK1_C_P"] ;# Bank 129 - MGTREFCLK1P_129
#Other net   PACKAGE_PIN M43      - CFP2_TX2_1_N              Bank 129 - MGTYTXN2_129
#Other net   PACKAGE_PIN M42      - CFP2_TX2_1_P              Bank 129 - MGTYTXP2_129
#Other net   PACKAGE_PIN R45      - CFP2_RX2_1_P              Bank 129 - MGTYRXP2_129
#Other net   PACKAGE_PIN R46      - CFP2_RX2_1_N              Bank 129 - MGTYRXN2_129
#Other net   PACKAGE_PIN L40      - MGTAVTT_FPGA              Bank 129 - MGTAVTTRCAL_LN
#set_property PACKAGE_PIN L41      [get_ports "5334N475"] ;# Bank 129 - MGTRREF_LN
#Other net   PACKAGE_PIN P43      - CFP2_TX5_2_N              Bank 129 - MGTYTXN1_129
#Other net   PACKAGE_PIN P42      - CFP2_TX5_2_P              Bank 129 - MGTYTXP1_129
#Other net   PACKAGE_PIN U45      - CFP2_RX5_2_P              Bank 129 - MGTYRXP1_129
#Other net   PACKAGE_PIN U46      - CFP2_RX5_2_N              Bank 129 - MGTYRXN1_129
set_property PACKAGE_PIN V39      [get_ports "MGT_SI570_CLOCK1_C_N"] ;# Bank 129 - MGTREFCLK0N_129
set_property PACKAGE_PIN V38      [get_ports "MGT_SI570_CLOCK1_C_P"] ;# Bank 129 - MGTREFCLK0P_129
#Other net   PACKAGE_PIN T43      - CFP2_TX6_3_N              Bank 129 - MGTYTXN0_129
#Other net   PACKAGE_PIN T42      - CFP2_TX6_3_P              Bank 129 - MGTYTXP0_129
#Other net   PACKAGE_PIN W45      - CFP2_RX6_3_P              Bank 129 - MGTYRXP0_129
#Other net   PACKAGE_PIN W46      - CFP2_RX6_3_N              Bank 129 - MGTYRXN0_129
#Other net   PACKAGE_PIN B43      - 5334N1337                 Bank 130 - MGTYTXN3_130
#Other net   PACKAGE_PIN B42      - 5334N1336                 Bank 130 - MGTYTXP3_130
#Other net   PACKAGE_PIN E45      - 5334N1340                 Bank 130 - MGTYRXP3_130
#Other net   PACKAGE_PIN E46      - 5334N1341                 Bank 130 - MGTYRXN3_130
#set_property PACKAGE_PIN N41      [get_ports "5334N1383"] ;# Bank 130 - MGTREFCLK1N_130
#set_property PACKAGE_PIN N40      [get_ports "5334N1382"] ;# Bank 130 - MGTREFCLK1P_130
#Other net   PACKAGE_PIN D43      - 5334N1335                 Bank 130 - MGTYTXN2_130
#Other net   PACKAGE_PIN D42      - 5334N1334                 Bank 130 - MGTYTXP2_130
#Other net   PACKAGE_PIN G45      - 5334N1338                 Bank 130 - MGTYRXP2_130
#Other net   PACKAGE_PIN G46      - 5334N1339                 Bank 130 - MGTYRXN2_130
#Other net   PACKAGE_PIN F43      - CFP2_TX0_X_N              Bank 130 - MGTYTXN1_130
#Other net   PACKAGE_PIN F42      - CFP2_TX0_X_P              Bank 130 - MGTYTXP1_130
#Other net   PACKAGE_PIN J45      - CFP2_RX0_X_P              Bank 130 - MGTYRXP1_130
#Other net   PACKAGE_PIN J46      - CFP2_RX0_X_N              Bank 130 - MGTYRXN1_130
#set_property PACKAGE_PIN R41      [get_ports "5334N1381"] ;# Bank 130 - MGTREFCLK0N_130
#set_property PACKAGE_PIN R40      [get_ports "5334N1380"] ;# Bank 130 - MGTREFCLK0P_130
#Other net   PACKAGE_PIN H43      - CFP2_TX3_X_N              Bank 130 - MGTYTXN0_130
#Other net   PACKAGE_PIN H42      - CFP2_TX3_X_P              Bank 130 - MGTYTXP0_130
#Other net   PACKAGE_PIN L45      - CFP2_RX3_X_P              Bank 130 - MGTYRXP0_130
#Other net   PACKAGE_PIN L46      - CFP2_RX3_X_N              Bank 130 - MGTYRXN0_130
#Other net   PACKAGE_PIN AW5      - PCIE_TX4_P                Bank 224 - MGTHTXP3_224
#Other net   PACKAGE_PIN AT2      - PCIE_RX4_P                Bank 224 - MGTHRXP3_224
#Other net   PACKAGE_PIN AT1      - PCIE_RX4_N                Bank 224 - MGTHRXN3_224
#Other net   PACKAGE_PIN AW4      - PCIE_TX4_N                Bank 224 - MGTHTXN3_224
#set_property PACKAGE_PIN AN9      [get_ports "11N5882"] ;# Bank 224 - MGTREFCLK1P_224
#set_property PACKAGE_PIN AN8      [get_ports "11N5883"] ;# Bank 224 - MGTREFCLK1N_224
#Other net   PACKAGE_PIN BA5      - PCIE_TX5_P                Bank 224 - MGTHTXP2_224
#Other net   PACKAGE_PIN AV2      - PCIE_RX5_P                Bank 224 - MGTHRXP2_224
#Other net   PACKAGE_PIN AV1      - PCIE_RX5_N                Bank 224 - MGTHRXN2_224
#Other net   PACKAGE_PIN BA4      - PCIE_TX5_N                Bank 224 - MGTHTXN2_224
#Other net   PACKAGE_PIN BC5      - PCIE_TX6_P                Bank 224 - MGTHTXP1_224
#Other net   PACKAGE_PIN AY2      - PCIE_RX6_P                Bank 224 - MGTHRXP1_224
#Other net   PACKAGE_PIN AY1      - PCIE_RX6_N                Bank 224 - MGTHRXN1_224
#Other net   PACKAGE_PIN BC4      - PCIE_TX6_N                Bank 224 - MGTHTXN1_224
#set_property PACKAGE_PIN AR9      [get_ports "11N5901"] ;# Bank 224 - MGTREFCLK0P_224
#set_property PACKAGE_PIN AR8      [get_ports "11N5900"] ;# Bank 224 - MGTREFCLK0N_224
#Other net   PACKAGE_PIN BE5      - PCIE_TX7_P                Bank 224 - MGTHTXP0_224
#Other net   PACKAGE_PIN BB2      - PCIE_RX7_P                Bank 224 - MGTHRXP0_224
#Other net   PACKAGE_PIN BB1      - PCIE_RX7_N                Bank 224 - MGTHRXN0_224
#Other net   PACKAGE_PIN BE4      - PCIE_TX7_N                Bank 224 - MGTHTXN0_224
#Other net   PACKAGE_PIN AP7      - PCIE_TX0_P                Bank 225 - MGTHTXP3_225
#Other net   PACKAGE_PIN AJ4      - PCIE_RX0_P                Bank 225 - MGTHRXP3_225
#Other net   PACKAGE_PIN AJ3      - PCIE_RX0_N                Bank 225 - MGTHRXN3_225
#Other net   PACKAGE_PIN AP6      - PCIE_TX0_N                Bank 225 - MGTHTXN3_225
#set_property PACKAGE_PIN AJ9      [get_ports "11N5839"] ;# Bank 225 - MGTREFCLK1P_225
#set_property PACKAGE_PIN AJ8      [get_ports "11N5838"] ;# Bank 225 - MGTREFCLK1N_225
#Other net   PACKAGE_PIN AR5      - PCIE_TX1_P                Bank 225 - MGTHTXP2_225
#Other net   PACKAGE_PIN AK2      - PCIE_RX1_P                Bank 225 - MGTHRXP2_225
#Other net   PACKAGE_PIN AK1      - PCIE_RX1_N                Bank 225 - MGTHRXN2_225
#Other net   PACKAGE_PIN AR4      - PCIE_TX1_N                Bank 225 - MGTHTXN2_225
#set_property PACKAGE_PIN BD2      [get_ports "11N5614"] ;# Bank 225 - MGTRREF_RS
#Other net   PACKAGE_PIN BD3      - MGTAVTT_FPGA              Bank 225 - MGTAVTTRCAL_RS
#Other net   PACKAGE_PIN AT7      - PCIE_TX2_P                Bank 225 - MGTHTXP1_225
#Other net   PACKAGE_PIN AM2      - PCIE_RX2_P                Bank 225 - MGTHRXP1_225
#Other net   PACKAGE_PIN AM1      - PCIE_RX2_N                Bank 225 - MGTHRXN1_225
#Other net   PACKAGE_PIN AT6      - PCIE_TX2_N                Bank 225 - MGTHTXN1_225
set_property PACKAGE_PIN AL9      [get_ports "PCIE_CLK_QO_P"] ;# Bank 225 - MGTREFCLK0P_225
set_property PACKAGE_PIN AL8      [get_ports "PCIE_CLK_QO_N"] ;# Bank 225 - MGTREFCLK0N_225
#Other net   PACKAGE_PIN AU5      - PCIE_TX3_P                Bank 225 - MGTHTXP0_225
#Other net   PACKAGE_PIN AP2      - PCIE_RX3_P                Bank 225 - MGTHRXP0_225
#Other net   PACKAGE_PIN AP1      - PCIE_RX3_N                Bank 225 - MGTHRXN0_225
#Other net   PACKAGE_PIN AU4      - PCIE_TX3_N                Bank 225 - MGTHTXN0_225
#Other net   PACKAGE_PIN AH7      - FMC_HPC1_DP3_C2M_P        Bank 226 - MGTHTXP3_226
#Other net   PACKAGE_PIN AE4      - FMC_HPC1_DP3_M2C_P        Bank 226 - MGTHRXP3_226
#Other net   PACKAGE_PIN AE3      - FMC_HPC1_DP3_M2C_N        Bank 226 - MGTHRXN3_226
#Other net   PACKAGE_PIN AH6      - FMC_HPC1_DP3_C2M_N        Bank 226 - MGTHTXN3_226
#set_property PACKAGE_PIN AE9      [get_ports "11N6523"] ;# Bank 226 - MGTREFCLK1P_226
#set_property PACKAGE_PIN AE8      [get_ports "11N6524"] ;# Bank 226 - MGTREFCLK1N_226
#Other net   PACKAGE_PIN AK7      - FMC_HPC1_DP2_C2M_P        Bank 226 - MGTHTXP2_226
#Other net   PACKAGE_PIN AF2      - FMC_HPC1_DP2_M2C_P        Bank 226 - MGTHRXP2_226
#Other net   PACKAGE_PIN AF1      - FMC_HPC1_DP2_M2C_N        Bank 226 - MGTHRXN2_226
#Other net   PACKAGE_PIN AK6      - FMC_HPC1_DP2_C2M_N        Bank 226 - MGTHTXN2_226
#Other net   PACKAGE_PIN AM7      - FMC_HPC1_DP1_C2M_P        Bank 226 - MGTHTXP1_226
#Other net   PACKAGE_PIN AG4      - FMC_HPC1_DP1_M2C_P        Bank 226 - MGTHRXP1_226
#Other net   PACKAGE_PIN AG3      - FMC_HPC1_DP1_M2C_N        Bank 226 - MGTHRXN1_226
#Other net   PACKAGE_PIN AM6      - FMC_HPC1_DP1_C2M_N        Bank 226 - MGTHTXN1_226
#set_property PACKAGE_PIN AG9      [get_ports "11N6521"] ;# Bank 226 - MGTREFCLK0P_226
#set_property PACKAGE_PIN AG8      [get_ports "11N6522"] ;# Bank 226 - MGTREFCLK0N_226
#Other net   PACKAGE_PIN AN5      - FMC_HPC1_DP0_C2M_P        Bank 226 - MGTHTXP0_226
#Other net   PACKAGE_PIN AH2      - FMC_HPC1_DP0_M2C_P        Bank 226 - MGTHRXP0_226
#Other net   PACKAGE_PIN AH1      - FMC_HPC1_DP0_M2C_N        Bank 226 - MGTHRXN0_226
#Other net   PACKAGE_PIN AN4      - FMC_HPC1_DP0_C2M_N        Bank 226 - MGTHTXN0_226
#Other net   PACKAGE_PIN Y7       - FMC_HPC1_DP7_C2M_P        Bank 227 - MGTHTXP3_227
#Other net   PACKAGE_PIN AA4      - FMC_HPC1_DP7_M2C_P        Bank 227 - MGTHRXP3_227
#Other net   PACKAGE_PIN AA3      - FMC_HPC1_DP7_M2C_N        Bank 227 - MGTHRXN3_227
#Other net   PACKAGE_PIN Y6       - FMC_HPC1_DP7_C2M_N        Bank 227 - MGTHTXN3_227
set_property PACKAGE_PIN AA9      [get_ports "FMC_HPC1_GBTCLK1_M2C_C_P"] ;# Bank 227 - MGTREFCLK1P_227
set_property PACKAGE_PIN AA8      [get_ports "FMC_HPC1_GBTCLK1_M2C_C_N"] ;# Bank 227 - MGTREFCLK1N_227
#Other net   PACKAGE_PIN AB7      - FMC_HPC1_DP6_C2M_P        Bank 227 - MGTHTXP2_227
#Other net   PACKAGE_PIN AB2      - FMC_HPC1_DP6_M2C_P        Bank 227 - MGTHRXP2_227
#Other net   PACKAGE_PIN AB1      - FMC_HPC1_DP6_M2C_N        Bank 227 - MGTHRXN2_227
#Other net   PACKAGE_PIN AB6      - FMC_HPC1_DP6_C2M_N        Bank 227 - MGTHTXN2_227
#Other net   PACKAGE_PIN AD7      - FMC_HPC1_DP5_C2M_P        Bank 227 - MGTHTXP1_227
#Other net   PACKAGE_PIN AC4      - FMC_HPC1_DP5_M2C_P        Bank 227 - MGTHRXP1_227
#Other net   PACKAGE_PIN AC3      - FMC_HPC1_DP5_M2C_N        Bank 227 - MGTHRXN1_227
#Other net   PACKAGE_PIN AD6      - FMC_HPC1_DP5_C2M_N        Bank 227 - MGTHTXN1_227
set_property PACKAGE_PIN AC9      [get_ports "FMC_HPC1_GBTCLK0_M2C_C_P"] ;# Bank 227 - MGTREFCLK0P_227
set_property PACKAGE_PIN AC8      [get_ports "FMC_HPC1_GBTCLK0_M2C_C_N"] ;# Bank 227 - MGTREFCLK0N_227
#Other net   PACKAGE_PIN AF7      - FMC_HPC1_DP4_C2M_P        Bank 227 - MGTHTXP0_227
#Other net   PACKAGE_PIN AD2      - FMC_HPC1_DP4_M2C_P        Bank 227 - MGTHRXP0_227
#Other net   PACKAGE_PIN AD1      - FMC_HPC1_DP4_M2C_N        Bank 227 - MGTHRXN0_227
#Other net   PACKAGE_PIN AF6      - FMC_HPC1_DP4_C2M_N        Bank 227 - MGTHTXN0_227
#Other net   PACKAGE_PIN M7       - FMC_HPC1_DP9_C2M_P        Bank 228 - MGTHTXP3_228
#Other net   PACKAGE_PIN U4       - FMC_HPC1_DP9_M2C_P        Bank 228 - MGTHRXP3_228
#Other net   PACKAGE_PIN U3       - FMC_HPC1_DP9_M2C_N        Bank 228 - MGTHRXN3_228
#Other net   PACKAGE_PIN M6       - FMC_HPC1_DP9_C2M_N        Bank 228 - MGTHTXN3_228
#set_property PACKAGE_PIN U9       [get_ports "11N5942"] ;# Bank 228 - MGTREFCLK1P_228
#set_property PACKAGE_PIN U8       [get_ports "11N5943"] ;# Bank 228 - MGTREFCLK1N_228
#Other net   PACKAGE_PIN P7       - FMC_HPC1_DP8_C2M_P        Bank 228 - MGTHTXP2_228
#Other net   PACKAGE_PIN V2       - FMC_HPC1_DP8_M2C_P        Bank 228 - MGTHRXP2_228
#Other net   PACKAGE_PIN V1       - FMC_HPC1_DP8_M2C_N        Bank 228 - MGTHRXN2_228
#Other net   PACKAGE_PIN P6       - FMC_HPC1_DP8_C2M_N        Bank 228 - MGTHTXN2_228
#Other net   PACKAGE_PIN T7       - FMC_HPC0_DP9_C2M_P        Bank 228 - MGTHTXP1_228
#Other net   PACKAGE_PIN W4       - FMC_HPC0_DP9_M2C_P        Bank 228 - MGTHRXP1_228
#Other net   PACKAGE_PIN W3       - FMC_HPC0_DP9_M2C_N        Bank 228 - MGTHRXN1_228
#Other net   PACKAGE_PIN T6       - FMC_HPC0_DP9_C2M_N        Bank 228 - MGTHTXN1_228
set_property PACKAGE_PIN W9       [get_ports "BULLSEYE_GTH_REFCLK_C_P"] ;# Bank 228 - MGTREFCLK0P_228
set_property PACKAGE_PIN W8       [get_ports "BULLSEYE_GTH_REFCLK_C_N"] ;# Bank 228 - MGTREFCLK0N_228
#Other net   PACKAGE_PIN V7       - FMC_HPC0_DP8_C2M_P        Bank 228 - MGTHTXP0_228
#Other net   PACKAGE_PIN Y2       - FMC_HPC0_DP8_M2C_P        Bank 228 - MGTHRXP0_228
#Other net   PACKAGE_PIN Y1       - FMC_HPC0_DP8_M2C_N        Bank 228 - MGTHRXN0_228
#Other net   PACKAGE_PIN V6       - FMC_HPC0_DP8_C2M_N        Bank 228 - MGTHTXN0_228
#Other net   PACKAGE_PIN H7       - FMC_HPC0_DP7_C2M_P        Bank 229 - MGTHTXP3_229
#Other net   PACKAGE_PIN M2       - FMC_HPC0_DP7_M2C_P        Bank 229 - MGTHRXP3_229
#Other net   PACKAGE_PIN M1       - FMC_HPC0_DP7_M2C_N        Bank 229 - MGTHRXN3_229
#Other net   PACKAGE_PIN H6       - FMC_HPC0_DP7_C2M_N        Bank 229 - MGTHTXN3_229
set_property PACKAGE_PIN N9       [get_ports "FMC_HPC0_GBTCLK1_M2C_C_P"] ;# Bank 229 - MGTREFCLK1P_229
set_property PACKAGE_PIN N8       [get_ports "FMC_HPC0_GBTCLK1_M2C_C_N"] ;# Bank 229 - MGTREFCLK1N_229
#Other net   PACKAGE_PIN J5       - FMC_HPC0_DP6_C2M_P        Bank 229 - MGTHTXP2_229
#Other net   PACKAGE_PIN P2       - FMC_HPC0_DP6_M2C_P        Bank 229 - MGTHRXP2_229
#Other net   PACKAGE_PIN P1       - FMC_HPC0_DP6_M2C_N        Bank 229 - MGTHRXN2_229
#Other net   PACKAGE_PIN J4       - FMC_HPC0_DP6_C2M_N        Bank 229 - MGTHTXN2_229
#Other net   PACKAGE_PIN K7       - FMC_HPC0_DP5_C2M_P        Bank 229 - MGTHTXP1_229
#Other net   PACKAGE_PIN R4       - FMC_HPC0_DP5_M2C_P        Bank 229 - MGTHRXP1_229
#Other net   PACKAGE_PIN R3       - FMC_HPC0_DP5_M2C_N        Bank 229 - MGTHRXN1_229
#Other net   PACKAGE_PIN K6       - FMC_HPC0_DP5_C2M_N        Bank 229 - MGTHTXN1_229
set_property PACKAGE_PIN R9       [get_ports "FMC_HPC0_GBTCLK0_M2C_C_P"] ;# Bank 229 - MGTREFCLK0P_229
set_property PACKAGE_PIN R8       [get_ports "FMC_HPC0_GBTCLK0_M2C_C_N"] ;# Bank 229 - MGTREFCLK0N_229
#Other net   PACKAGE_PIN L5       - FMC_HPC0_DP4_C2M_P        Bank 229 - MGTHTXP0_229
#Other net   PACKAGE_PIN T2       - FMC_HPC0_DP4_M2C_P        Bank 229 - MGTHRXP0_229
#Other net   PACKAGE_PIN T1       - FMC_HPC0_DP4_M2C_N        Bank 229 - MGTHRXN0_229
#Other net   PACKAGE_PIN L4       - FMC_HPC0_DP4_C2M_N        Bank 229 - MGTHTXN0_229
#Other net   PACKAGE_PIN C5       - FMC_HPC0_DP3_C2M_P        Bank 230 - MGTHTXP3_230
#Other net   PACKAGE_PIN D2       - FMC_HPC0_DP3_M2C_P        Bank 230 - MGTHRXP3_230
#Other net   PACKAGE_PIN D1       - FMC_HPC0_DP3_M2C_N        Bank 230 - MGTHRXN3_230
#Other net   PACKAGE_PIN C4       - FMC_HPC0_DP3_C2M_N        Bank 230 - MGTHTXN3_230
#set_property PACKAGE_PIN J9       [get_ports "5332N619"] ;# Bank 230 - MGTREFCLK1P_230
#set_property PACKAGE_PIN J8       [get_ports "5332N620"] ;# Bank 230 - MGTREFCLK1N_230
#Other net   PACKAGE_PIN E5       - FMC_HPC0_DP2_C2M_P        Bank 230 - MGTHTXP2_230
#Other net   PACKAGE_PIN F2       - FMC_HPC0_DP2_M2C_P        Bank 230 - MGTHRXP2_230
#Other net   PACKAGE_PIN F1       - FMC_HPC0_DP2_M2C_N        Bank 230 - MGTHRXN2_230
#Other net   PACKAGE_PIN E4       - FMC_HPC0_DP2_C2M_N        Bank 230 - MGTHTXN2_230
#Other net   PACKAGE_PIN F7       - FMC_HPC0_DP1_C2M_P        Bank 230 - MGTHTXP1_230
#Other net   PACKAGE_PIN H2       - FMC_HPC0_DP1_M2C_P        Bank 230 - MGTHRXP1_230
#Other net   PACKAGE_PIN H1       - FMC_HPC0_DP1_M2C_N        Bank 230 - MGTHRXN1_230
#Other net   PACKAGE_PIN F6       - FMC_HPC0_DP1_C2M_N        Bank 230 - MGTHTXN1_230
#set_property PACKAGE_PIN L9       [get_ports "5332N615"] ;# Bank 230 - MGTREFCLK0P_230
#set_property PACKAGE_PIN L8       [get_ports "5332N616"] ;# Bank 230 - MGTREFCLK0N_230
#Other net   PACKAGE_PIN G5       - FMC_HPC0_DP0_C2M_P        Bank 230 - MGTHTXP0_230
#Other net   PACKAGE_PIN K2       - FMC_HPC0_DP0_M2C_P        Bank 230 - MGTHRXP0_230
#Other net   PACKAGE_PIN K1       - FMC_HPC0_DP0_M2C_N        Bank 230 - MGTHRXN0_230
#Other net   PACKAGE_PIN G4       - FMC_HPC0_DP0_C2M_N        Bank 230 - MGTHTXN0_230
