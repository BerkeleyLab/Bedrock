// FMC test on SP605 through GMII
`define ETH_IP {8'd131,8'd243,8'd168,8'd80} //lrd1.lbl.gov
`define ETH_MAC 48'h00105ad152b4
`define READ_PIP_LEN 13
`define N_LED 4

`include "ether_fmc_mc.vh"
