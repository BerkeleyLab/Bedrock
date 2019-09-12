// ------------------------------------
// QGTP_PACK.VH
// Helper macros for GTP transceivers
// ------------------------------------

`define GTi_WIRES(GTi) wire gt``GTi``_pll_locked, gt``GTi``_txresetdone, gt``GTi``_rxresetdone,\
                            gt``GTi``_txoutclk_out_l, gt``GTi``_rxoutclk_out_l;

    // TODO: Check these
    wire gt``GTi``_pll0reset_i, gt``GTi``_pll1reset_i;

    wire pll0refclklost_i, pll1refclklost_i,
         pll0lock_i, pll1lock_i,
         pll0outclk_i, pll1outclk_i,
         pll0outrefclk_i, pll1outrefclk_i;

    wire gt0_pll0pd_t  ;
    wire gt0_pll1pd_t  ;
    wire gt0_pll1reset_t  ;

`define GTi_PORT_MAP(GTi) .sysclk_in                   (drpclk_in),\
                          .soft_reset_tx_in            (soft_reset),\
                          .soft_reset_rx_in            (soft_reset),\
                          .dont_reset_on_data_error_in (1'b0),\
                          .gt0_tx_fsm_reset_done_out   (gt``GTi``_txfsm_resetdone_out),\
                          .gt0_rx_fsm_reset_done_out   (gt``GTi``_rxfsm_resetdone_out),\
                          `ifdef GT``GTi``_8B10B_EN\
                          .gt0_rxcharisk_out           (gt``GTi``_rxcharisk_out),\
                          .gt0_txcharisk_in            (gt``GTi``_txcharisk_in),\
                          .gt0_rxdisperr_out           (),\
                          .gt0_rxnotintable_out        (),\
                          .gt0_rxmcommaalignen_in      (1'b1),\
                          .gt0_rxpcommaalignen_in      (1'b1),\
                          .gt0_rxbyteisaligned_out     (gt``GTi``_rxbyteisaligned),\
                          `endif\
                          .gt0_data_valid_in           (1'b1),\
                          .gt0_drpaddr_in              (9'b0),\
                          .gt0_drpclk_in               (drpclk_in),\
                          .gt0_drpdi_in                (16'b0),\
                          .gt0_drpdo_out               (),\
                          .gt0_drpen_in                (1'b0),\
                          .gt0_drprdy_out              (),\
                          .gt0_drpwe_in                (1'b0),\
                          .gt0_dmonitorout_out         (),\
                          .gt0_eyescanreset_in         (1'b0),\
                          .gt0_rxuserrdy_in            (gt``GTi``_rxusrrdy_in),\
                          .gt0_eyescandataerror_out    (),\
                          .gt0_eyescantrigger_in       (1'b0),\
                          .gt0_rxusrclk_in             (gt``GTi``_rxusrclk_in),\
                          .gt0_rxusrclk2_in            (gt``GTi``_rxusrclk2_in),\
                          .gt0_rxdata_out              (gt``GTi``_rxdata_out),\
                          .gt0_gtprxp_in               (gt``GTi``_rxp_in),\
                          .gt0_gtprxn_in               (gt``GTi``_rxn_in),\
                          .gt0_rxbufstatus_out         (gt``GTi``_rxbufstatus),\
                          .gt0_drxmonitorout_out       (),\
                          .gt0_rxoutclk_out            (gt``GTi``_rxoutclk_out_l),\
                          .gt0_rxoutclkfabric_out      (),\
                          .gt0_gtrxreset_in            (gt_txrx_reset),\
                          .gt0_rxpmareset_in           (gt_txrx_reset),\
                          .gt0_rxresetdone_out         (gt``GTi``_rxresetdone),\
                          .gt0_gttxreset_in            (gt_txrx_reset),\
                          .gt0_txuserrdy_in            (gt``GTi``_txusrrdy_in),\
                          .gt0_txusrclk_in             (gt``GTi``_txusrclk_in),\
                          .gt0_txusrclk2_in            (gt``GTi``_txusrclk2_in),\
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
                          .gt0_pll0lock_in             (pll0lock_i),\
                          .gt0_pll0refclklost_in       (pll0refclklost_i),\
                          `else
                          .gt0_pll1reset_out           (gt``GTi``_pll1reset),\
                          .gt0_pll1lock_in             (pll1lock_i),\
                          .gt0_pll1refclklost_in       (pll1refclklost_i),\
                          `endif
                          .gt0_pll0outclk_in           (pll0outclk_i),\
                          .gt0_pll0outrefclk_in        (pll0outrefclk_i),\
                          .gt0_pll1outclk_in           (pll1outclk_i),\
                          .gt0_pll1outrefclk_in        (pll1outrefclk_i)

`define GT_OUTCLK_BUF(GTi) BUFG i_gt``GTi``_txoutclk_buf (.I (gt``GTi``_txoutclk_out_l), .O (gt``GTi``_txoutclk_out));\
                           BUFG i_gt``GTi``_rxoutclk_buf (.I (gt``GTi``_rxoutclk_out_l), .O (gt``GTi``_rxoutclk_out));

`define GTP_COMMON_PORT_MAP .PLL0OUTCLK_OUT     (pll0outclk_i),\
                            .PLL0OUTREFCLK_OUT  (pll0outrefclk_i),\
                            .PLL0LOCK_OUT       (pll0lock_i),\
                            .PLL0LOCKDETCLK_IN  (drpclk_in),\
                            .PLL0REFCLKLOST_OUT (pll0refclklost_i),\
                            .PLL0RESET_IN       (gt_pll_reset),\
                            .PLL0PD_IN          (gt_pll_powerdown),\
                            .PLL0REFCLKSEL_IN   (3'b001),\
                            .PLL1OUTCLK_OUT     (pll1outclk_i),\
                            .PLL1OUTREFCLK_OUT  (pll1outrefclk_i),\
                            .PLL1LOCK_OUT       (pll1lock_i),\
                            .PLL1LOCKDETCLK_IN  (drpclk_in),\
                            .PLL1REFCLKLOST_OUT (pll1refclklost_i),  \
                            .PLL1RESET_IN       (gt_pll_reset),\
                            .PLL1PD_IN          (gt_pll_powerdown),\
                            .PLL1REFCLKSEL_IN   (3'b001),\
                            .GTREFCLK0_IN       (gtrefclk0),\
                            .GTREFCLK1_IN       (gtrefclk1)

