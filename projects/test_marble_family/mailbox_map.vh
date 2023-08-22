`ifndef __MAILBOX_MAP_VH
`define __MAILBOX_MAP_VH

localparam MAILBOX_HASH = 32'hc1144c22;

//  Page 2
localparam FMC_MGT_CTL_ADDR = 'h20;
localparam FMC_MGT_CTL_SIZE = 1;
//  Page 3
localparam COUNT_ADDR = 'h30;
localparam COUNT_SIZE = 2;
localparam LM75_0_ADDR = 'h34;
localparam LM75_0_SIZE = 2;
localparam LM75_1_ADDR = 'h36;
localparam LM75_1_SIZE = 2;
localparam FMC_ST_ADDR = 'h38;
localparam FMC_ST_SIZE = 1;
localparam PWR_ST_ADDR = 'h39;
localparam PWR_ST_SIZE = 1;
localparam MGTMUX_ST_ADDR = 'h3a;
localparam MGTMUX_ST_SIZE = 1;
localparam GIT32_ADDR = 'h3c;
localparam GIT32_SIZE = 4;
//  Page 4
localparam MAX_T1_HI_ADDR = 'h40;
localparam MAX_T1_HI_SIZE = 1;
localparam MAX_T1_LO_ADDR = 'h41;
localparam MAX_T1_LO_SIZE = 1;
localparam MAX_T2_HI_ADDR = 'h42;
localparam MAX_T2_HI_SIZE = 1;
localparam MAX_T2_LO_ADDR = 'h43;
localparam MAX_T2_LO_SIZE = 1;
localparam MAX_F1_TACH_ADDR = 'h44;
localparam MAX_F1_TACH_SIZE = 1;
localparam MAX_F2_TACH_ADDR = 'h45;
localparam MAX_F2_TACH_SIZE = 1;
localparam MAX_F1_DUTY_ADDR = 'h46;
localparam MAX_F1_DUTY_SIZE = 1;
localparam MAX_F2_DUTY_ADDR = 'h47;
localparam MAX_F2_DUTY_SIZE = 1;
localparam PCB_REV_ADDR = 'h48;
localparam PCB_REV_SIZE = 1;
//localparam COUNT_ADDR = 'h4a;
//localparam COUNT_SIZE = 2;
localparam HASH_ADDR = 'h4c;
localparam HASH_SIZE = 4;
//  Page 5
localparam I2C_BUS_STATUS_ADDR = 'h50;
localparam I2C_BUS_STATUS_SIZE = 1;
//  Page 6
localparam FSYNTH_I2C_ADDR_ADDR = 'h60;
localparam FSYNTH_I2C_ADDR_SIZE = 1;
localparam FSYNTH_CONFIG_ADDR = 'h61;
localparam FSYNTH_CONFIG_SIZE = 1;
localparam FSYNTH_FREQ_ADDR = 'h62;
localparam FSYNTH_FREQ_SIZE = 4;
`endif // __MAILBOX_MAP_VH
