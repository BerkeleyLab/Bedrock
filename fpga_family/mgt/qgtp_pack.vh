// ------------------------------------
// QGTP_PACK.VH
// Helper macros for GTP transceivers
// ------------------------------------

`define GTi_WIRES(GTi) wire gt``GTi``_txresetdone, gt``GTi``_rxresetdone,\
                            gt``GTi``_txoutclk_out_l, gt``GTi``_rxoutclk_out_l;

`define GTi_COMMON_WIRES(GTi) `ifdef GT``GTi``_PLL0\
                              wire gt``GTi``_pll0reset;\
                              wire gt``GTi``_pll1reset=1'b0;\
                              `else\
                              wire gt``GTi``_pll0reset=1'b0;\
                              wire gt``GTi``_pll1reset;\
                              `endif

`define GTi_PORT_MAP(GTi) .sysclk_in                   (drpclk_in),\
                          .soft_reset_tx_in            (soft_reset),\
                          .soft_reset_rx_in            (soft_reset),\
                          .dont_reset_on_data_error_in (1'b0),\
                          .gt0_tx_fsm_reset_done_out   (gt``GTi``_txfsm_resetdone_out),\
                          .gt0_rx_fsm_reset_done_out   (gt``GTi``_rxfsm_resetdone_out),\
                          `ifdef GT``GTi``_8B10B_EN\
                          .gt0_rxcharisk_out           (gt``GTi``_rxcharisk_out),\
                          .gt0_rxchariscomma_out       (gt``GTi``_rxchariscomma_out),\
                          .gt0_txcharisk_in            (gt``GTi``_txcharisk_in),\
                          .gt0_rxdisperr_out           (),\
                          .gt0_rxnotintable_out        (),\
                          .gt0_rxbyteisaligned_out     (gt``GTi``_rxbyteisaligned),\
                          `endif\
                          .gt0_data_valid_in           (1'b1),\
                          .gt0_drpclk_in               (drpclk_in),\
                          `ifdef GT``GTi``_DRP_EN\
                          .gt0_drpaddr_in              (gt``GTi``_drpaddr_in),\
                          .gt0_drpdi_in                (gt``GTi``_drpdi_in),\
                          .gt0_drpdo_out               (gt``GTi``_drpdo_out),\
                          .gt0_drpen_in                (gt``GTi``_drpen_in),\
                          .gt0_drprdy_out              (gt``GTi``_drprdy_out),\
                          .gt0_drpwe_in                (gt``GTi``_drpwe_in),\
                          `else\
                          .gt0_drpaddr_in              (9'b0),\
                          .gt0_drpdi_in                (16'b0),\
                          .gt0_drpdo_out               (),\
                          .gt0_drpen_in                (1'b0),\
                          .gt0_drprdy_out              (),\
                          .gt0_drpwe_in                (1'b0),\
                          `endif\
                          .gt0_dmonitorout_out         (),\
                          .gt0_rxlpmlfhold_in          (1'b0),\
                          .gt0_rxlpmhfhold_in          (1'b0),\
                          .gt0_drp_busy_out            (),\
                          .gt0_eyescanreset_in         (1'b0),\
                          .gt0_rxuserrdy_in            (gt``GTi``_rxusrrdy_in),\
                          .gt0_eyescandataerror_out    (),\
                          .gt0_eyescantrigger_in       (1'b0),\
                          .gt0_rxusrclk_in             (gt``GTi``_rxusrclk_in),\
                          .gt0_rxusrclk2_in            (gt``GTi``_rxusrclk_in),\
                          .gt0_rxdata_out              (gt``GTi``_rxdata_out),\
                          .gt0_gtprxp_in               (gt``GTi``_rxp_in),\
                          .gt0_gtprxn_in               (gt``GTi``_rxn_in),\
                          .gt0_rxbufstatus_out         (gt``GTi``_rxbufstatus),\
                          .gt0_rxoutclk_out            (gt``GTi``_rxoutclk_out_l),\
                          .gt0_rxoutclkfabric_out      (),\
                          .gt0_gtrxreset_in            (soft_reset),\
                          .gt0_rxlpmreset_in           (soft_reset),\
                          .gt0_rxpmareset_in           (soft_reset),\
                          .gt0_rxresetdone_out         (gt``GTi``_rxresetdone),\
                          .gt0_gttxreset_in            (soft_reset),\
                          .gt0_txuserrdy_in            (gt``GTi``_txusrrdy_in),\
                          .gt0_txusrclk_in             (gt``GTi``_txusrclk_in),\
                          .gt0_txusrclk2_in            (gt``GTi``_txusrclk_in),\
                          .gt0_txbufstatus_out         (gt``GTi``_txbufstatus),\
                          .gt0_txdata_in               (gt``GTi``_txdata_in),\
                          .gt0_gtptxn_out              (gt``GTi``_txn_out),\
                          .gt0_gtptxp_out              (gt``GTi``_txp_out),\
                          .gt0_txoutclk_out            (gt``GTi``_txoutclk_out_l),\
                          .gt0_txoutclkfabric_out      (),\
                          .gt0_txoutclkpcs_out         (),\
                          .gt0_txresetdone_out         (gt``GTi``_txresetdone),\
                          `ifdef GT``GTi``_PLL0\
                          .gt0_pll0reset_out           (gt``GTi``_pll0reset),\
                          .gt0_pll0lock_in             (pll0_lock),\
                          .gt0_pll0refclklost_in       (pll0_refclklost),\
                          `else\
                          .gt0_pll1reset_out           (gt``GTi``_pll1reset),\
                          .gt0_pll1lock_in             (pll1_lock),\
                          .gt0_pll1refclklost_in       (pll1_refclklost),\
                          `endif\
                          .gt0_pll0outclk_in           (pll0_outclk),\
                          .gt0_pll0outrefclk_in        (pll0_outrefclk),\
                          .gt0_pll1outclk_in           (pll1_outclk),\
                          .gt0_pll1outrefclk_in        (pll1_outrefclk)

`define GT_OUTCLK_BUFG(GTi) BUFG i_gt``GTi``_txoutclk_buf (.I (gt``GTi``_txoutclk_out_l), .O (gt``GTi``_txoutclk_out));\
                            BUFG i_gt``GTi``_rxoutclk_buf (.I (gt``GTi``_rxoutclk_out_l), .O (gt``GTi``_rxoutclk_out));

`define GT_OUTCLK_BUFH(GTi) BUFH i_gt``GTi``_txoutclk_buf (.I (gt``GTi``_txoutclk_out_l), .O (gt``GTi``_txoutclk_out));\
                            BUFH i_gt``GTi``_rxoutclk_buf (.I (gt``GTi``_rxoutclk_out_l), .O (gt``GTi``_rxoutclk_out));

`define GTP_COMMON_WRAP_PORTS input  soft_reset_tx_in,\
                              input  soft_reset_rx_in,\
                              output pll0_outclk,\
                              output pll0_outrefclk,\
                              output pll0_refclklost,\
                              input  pll0_reset,\
                              output pll1_outclk,\
                              output pll1_outrefclk,\
                              output pll1_refclklost,\
                              input  pll1_reset
