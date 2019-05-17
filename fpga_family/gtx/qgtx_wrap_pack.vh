// ------------------------------------
// QGTX_WRAP_PACK.VH
// Helper macros for qgtx_wrap.v
// ------------------------------------

`define GTi_PORTS(GTi, DWI) output               gt``GTi``_rxoutclk_out,\
                            input                gt``GTi``_rxusrclk_in,\
                            input                gt``GTi``_rxusrclk2_in,\
                            output               gt``GTi``_txoutclk_out,\
                            input                gt``GTi``_txusrclk_in,\
                            input                gt``GTi``_txusrclk2_in,\
                            input                gt``GTi``_rxusrrdy_in,\
                            output [DWI-1:0]     gt``GTi``_rxdata_out,\
                            input                gt``GTi``_txusrrdy_in,\
                            input  [DWI-1:0]     gt``GTi``_txdata_in,\
                            input                gt``GTi``_rxn_in,\
                            input                gt``GTi``_rxp_in,\
                            output               gt``GTi``_txn_out,\
                            output               gt``GTi``_txp_out,\
                            output               gt``GTi``_rxfsm_resetdone_out,\
                            output               gt``GTi``_txfsm_resetdone_out,\
                            `ifdef GT``GTi``_8B10B_EN\
                            output [(DWI/8)-1:0] gt``GTi``_rxcharisk_out,\
                            input  [(DWI/8)-1:0] gt``GTi``_txcharisk_in,\
                            output               gt``GTi``_rxbyteisaligned,\
                            `endif\
                            output [2:0]         gt``GTi``_rxbufstatus,\
                            output [1:0]         gt``GTi``_txbufstatus,

`define GTi_WIRES(GTi) wire gt``GTi``_cpll_locked, gt``GTi``_txresetdone, gt``GTi``_rxresetdone,\
                            gt``GTi``_txoutclk_out_l, gt``GTi``_rxoutclk_out_l;

`define GTi_PORT_MAP(GTi) .sysclk_in                   (drpclk_in),\
                          .soft_reset_tx_in            (soft_reset),\
                          .soft_reset_rx_in            (soft_reset),\
                          .dont_reset_on_data_error_in (1'b0),\
                          .gt0_gtrefclk0_in            (gtrefclk0),\
                          .gt0_gtrefclk1_in            (gtrefclk1),\
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
                          .gt0_cpllfbclklost_out       (),\
                          .gt0_cplllock_out            (gt``GTi``_cpll_locked),\
                          .gt0_cplllockdetclk_in       (drpclk_in),\
                          .gt0_cpllreset_in            (gt_cpll_reset),\
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
                          .gt0_gtxrxp_in               (gt``GTi``_rxp_in),\
                          .gt0_gtxrxn_in               (gt``GTi``_rxn_in),\
                          .gt0_rxbufstatus_out         (gt``GTi``_rxbufstatus),\
                          .gt0_rxdfelpmreset_in        (1'b0),\
                          .gt0_rxmonitorout_out        (),\
                          .gt0_rxmonitorsel_in         (1'b0),\
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
                          .gt0_gtxtxn_out              (gt``GTi``_txn_out),\
                          .gt0_gtxtxp_out              (gt``GTi``_txp_out),\
                          .gt0_txoutclk_out            (gt``GTi``_txoutclk_out_l),\
                          .gt0_txoutclkfabric_out      (),\
                          .gt0_txoutclkpcs_out         (),\
                          .gt0_txresetdone_out         (gt``GTi``_txresetdone),\
                          .gt0_qplloutclk_in           (1'b0),\
                          .gt0_qplloutrefclk_in        (1'b0)

`define GTX_OUTCLK_BUF(GTi) BUFG i_gt``GTi``_txoutclk_buf (.I (gt``GTi``_txoutclk_out_l), .O (gt``GTi``_txoutclk_out));\
                            BUFG i_gt``GTi``_rxoutclk_buf (.I (gt``GTi``_rxoutclk_out_l), .O (gt``GTi``_rxoutclk_out));

`define Q_REDEFINE(Qi) `undef GT0_ENABLE\
                       `undef GT1_ENABLE\
                       `undef GT2_ENABLE\
                       `undef GT3_ENABLE\
                       `ifdef Q``Qi``_GTREFCLK1_EN `define GTREFCLK1_EN `endif\
                       `ifdef Q``Qi``_GT0_ENABLE `define GT0_ENABLE\
                       `endif\
                       `ifdef Q``Qi``_GT1_ENABLE `define GT1_ENABLE\
                       `endif\
                       `ifdef Q``Qi``_GT2_ENABLE `define GT2_ENABLE\
                       `endif\
                       `ifdef Q``Qi``_GT3_ENABLE `define GT3_ENABLE\
                       `endif\
                       `ifdef Q``Qi``_GT0_8B10B_EN `define GT0_8B10B_EN\
                       `endif\
                       `ifdef Q``Qi``_GT1_8B10B_EN `define GT1_8B10B_EN\
                       `endif\
                       `ifdef Q``Qi``_GT2_8B10B_EN `define GT2_8B10B_EN\
                       `endif\
                       `ifdef Q``Qi``_GT3_8B10B_EN `define GT3_8B10B_EN\
                       `endif
