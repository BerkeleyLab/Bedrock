`timescale 1ns / 1ps

module gth_wrap(
	input soft_reset,
    input gtrefclk_p,
    input gtrefclk_n,
    input drpclk_in,            // 62.5 MHz
    input [19:0] gt_txdata_in,
    output [19:0] gt_rxdata_out,

    input gt_reset_tx,
    input gt_reset_rx,
    input gt_reset_tx_datapath_in,
    input gt_reset_rx_datapath_in,
    input gt_rxn_in,
    input gt_rxp_in,
    output gt_txn_out,
    output gt_txp_out,

    output gt_rxresetdone,
    output gt_txresetdone,
    output gt_txusrclk_out,     // 62.5MHz
    output gt_rxusrclk_out,     // 62.5MHz
    output gt_reset_rx_cdr_stable_out,
    output gtpowergood_out,
    output gt_userclk_rx_active_out,
    output gt_userclk_tx_active_out
);

wire rxpmaresetdone_out;
wire txpmaresetdone_out;

`ifndef SIMULATE

// Differential reference clock buffer for MGTREFCLK1_X0Y2
wire gtrefclk;

IBUFDS_GTE3 #(
    .REFCLK_EN_TX_PATH  (1'b0),
    .REFCLK_HROW_CK_SEL (2'b00),
    .REFCLK_ICNTL_RX    (2'b00)
) IBUFDS_GTE3_MGTREFCLK1_X0Y2_INST (
    .I     (gtrefclk_p),
    .IB    (gtrefclk_n),
    .CEB   (1'b0),
    .O     (gtrefclk),
    .ODIV2 ()
);

// create_ip -name gtwizard_ultrascale -vendor xilinx.com -library ip -version 1.7 -module_name gtwizard_ultrascale_0
// set_property -dict {
//     CONFIG.TX_LINE_RATE {1.25}
//     CONFIG.TX_PLL_TYPE {CPLL}
//     CONFIG.TX_REFCLK_FREQUENCY {125}
//     CONFIG.TX_USER_DATA_WIDTH {20}
//     CONFIG.TX_INT_DATA_WIDTH {20}
//     CONFIG.RX_LINE_RATE {1.25}
//     CONFIG.RX_PLL_TYPE {CPLL}
//     CONFIG.RX_REFCLK_FREQUENCY {125}
//     CONFIG.RX_USER_DATA_WIDTH {20}
//     CONFIG.RX_INT_DATA_WIDTH {20}
//     CONFIG.RX_JTOL_FC {0.74985}
//     CONFIG.RX_CB_VAL_0_0 {0000000000}
//     CONFIG.RX_CB_VAL_0_1 {0000000000}
//     CONFIG.RX_CB_VAL_0_2 {0000000000}
//     CONFIG.RX_CB_VAL_0_3 {0000000000}
//     CONFIG.RX_CB_VAL_1_0 {0000000000}
//     CONFIG.RX_CB_VAL_1_1 {0000000000}
//     CONFIG.RX_CB_VAL_1_2 {0000000000}
//     CONFIG.RX_CB_VAL_1_3 {0000000000}
//     CONFIG.RX_CC_VAL_0_0 {0000000000}
//     CONFIG.RX_CC_VAL_0_1 {0000000000}
//     CONFIG.RX_CC_VAL_0_2 {0000000000}
//     CONFIG.RX_CC_VAL_0_3 {0000000000}
//     CONFIG.RX_CC_VAL_1_0 {0000000000}
//     CONFIG.RX_CC_VAL_1_1 {0000000000}
//     CONFIG.RX_CC_VAL_1_2 {0000000000}
//     CONFIG.RX_CC_VAL_1_3 {0000000000}
//     CONFIG.RX_REFCLK_SOURCE {X0Y0 clk1+2}
//     CONFIG.TX_REFCLK_SOURCE {X0Y0 clk1+2}
//     CONFIG.TXPROGDIV_FREQ_SOURCE {CPLL}
//     CONFIG.TXPROGDIV_FREQ_VAL {62.5}
//     CONFIG.FREERUN_FREQUENCY {62.5}
//     CONFIG.LOCATE_TX_USER_CLOCKING {CORE}
//     CONFIG.LOCATE_RX_USER_CLOCKING {CORE}
// } [get_ips gtwizard_ultrascale_0]
// generate_target {instantiation_template} [get_files gtwizard_ultrascale_0.xci]
// generate_target all [get_files  gtwizard_ultrascale_0.xci]
// export_ip_user_files -of_objects [get_files gtwizard_ultrascale_0.xci] -no_script -force -quiet
// create_ip_run [get_files -of_objects [get_fileset sources_1] gtwizard_ultrascale_0.xci]
// IP VLNV: xilinx.com:ip:gtwizard_ultrascale:1.7
// IP Revision: 6

gtwizard_ultrascale_0 gtwizard_i (
  .gtwiz_userclk_tx_reset_in            (~txpmaresetdone_out),                  // input wire [0 : 0] gtwiz_userclk_tx_reset_in
  .gtwiz_userclk_tx_srcclk_out          (),                                     // output wire [0 : 0] gtwiz_userclk_tx_srcclk_out
  .gtwiz_userclk_tx_usrclk_out          (),                                     // output wire [0 : 0] gtwiz_userclk_tx_usrclk_out
  .gtwiz_userclk_tx_usrclk2_out         (gt_txusrclk_out),                      // output wire [0 : 0] gtwiz_userclk_tx_usrclk2_out
  .gtwiz_userclk_tx_active_out          (gt_userclk_tx_active_out),             // output wire [0 : 0] gtwiz_userclk_tx_active_out
  .gtwiz_userclk_rx_reset_in            (~rxpmaresetdone_out),                  // input wire [0 : 0] gtwiz_userclk_rx_reset_in
  .gtwiz_userclk_rx_srcclk_out          (),                                     // output wire [0 : 0] gtwiz_userclk_rx_srcclk_out
  .gtwiz_userclk_rx_usrclk_out          (),                                     // output wire [0 : 0] gtwiz_userclk_rx_usrclk_out
  .gtwiz_userclk_rx_usrclk2_out         (gt_rxusrclk_out),                      // output wire [0 : 0] gtwiz_userclk_rx_usrclk2_out
  .gtwiz_userclk_rx_active_out          (gt_userclk_rx_active_out),             // output wire [0 : 0] gtwiz_userclk_rx_active_out
  .gtwiz_reset_clk_freerun_in           (drpclk_in),                            // input wire [0 : 0] gtwiz_reset_clk_freerun_in
  .gtwiz_reset_all_in                   (soft_reset),                           // input wire [0 : 0] gtwiz_reset_all_in
  .gtwiz_reset_tx_pll_and_datapath_in   (gt_reset_tx),                          // input wire [0 : 0] gtwiz_reset_tx_pll_and_datapath_in
  .gtwiz_reset_tx_datapath_in           (gt_reset_tx_datapath_in),              // input wire [0 : 0] gtwiz_reset_tx_datapath_in
  .gtwiz_reset_rx_pll_and_datapath_in   (gt_reset_rx),                          // input wire [0 : 0] gtwiz_reset_rx_pll_and_datapath_in
  .gtwiz_reset_rx_datapath_in           (gt_reset_rx_datapath_in),              // input wire [0 : 0] gtwiz_reset_rx_datapath_in
  .gtwiz_reset_rx_cdr_stable_out        (gt_reset_rx_cdr_stable_out),           // output wire [0 : 0] gtwiz_reset_rx_cdr_stable_out
  .gtwiz_reset_tx_done_out              (gt_txresetdone),                       // output wire [0 : 0] gtwiz_reset_tx_done_out
  .gtwiz_reset_rx_done_out              (gt_rxresetdone),                       // output wire [0 : 0] gtwiz_reset_rx_done_out
  .gtwiz_userdata_tx_in                 (gt_txdata_in),                         // input wire [19 : 0] gtwiz_userdata_tx_in
  .gtwiz_userdata_rx_out                (gt_rxdata_out),                        // output wire [19 : 0] gtwiz_userdata_rx_out
  .drpclk_in                            (drpclk_in),                            // input wire [0 : 0] drpclk_in
  .gthrxn_in                            (gt_rxn_in),                            // input wire [0 : 0] gthrxn_in
  .gthrxp_in                            (gt_rxp_in),                            // input wire [0 : 0] gthrxp_in
  .gtrefclk0_in                         (gtrefclk),                             // input wire [0 : 0] gtrefclk0_in
  .gthtxn_out                           (gt_txn_out),                           // output wire [0 : 0] gthtxn_out
  .gthtxp_out                           (gt_txp_out),                           // output wire [0 : 0] gthtxp_out
  .gtpowergood_out                      (gtpowergood_out),                      // output wire [0 : 0] gtpowergood_out
  .rxpmaresetdone_out                   (rxpmaresetdone_out),                   // output wire [0 : 0] rxpmaresetdone_out
  .txpmaresetdone_out                   (txpmaresetdone_out)                    // output wire [0 : 0] txpmaresetdone_out
);

`endif // `ifndef SIMULATE
endmodule
