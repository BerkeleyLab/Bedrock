// ------------------------------------
// QGT_WRAP_STUB.vh
// Generic module body of q{0,1,2,3}_gt_wrap component.
// This stub is meant to be `included into qgt_wrap.v, where globally set defines will
// configure it with the right settings and correct number of GT instances.
//
// Helper macros are defined in qgt_wrap_pack.vh
//
// ------------------------------------

`ifdef GT_TYPE__GTP
`include "qgtp_pack.vh"
`elsif GT_TYPE__GTX
`include "qgtx_pack.vh"
`endif

`ifdef GTCOMMON_EN

`ifdef GT0_ENABLE `GTi_COMMON_WIRES(0)`endif
`ifdef GT1_ENABLE `GTi_COMMON_WIRES(1)`endif
`ifdef GT2_ENABLE `GTi_COMMON_WIRES(2)`endif
`ifdef GT3_ENABLE `GTi_COMMON_WIRES(3)`endif

`ifdef GT_TYPE__GTP

   `ifdef Q3 `define Q_GTP_COMMON_MODULE q3_gtp_common_wrap
   `elsif Q2 `define Q_GTP_COMMON_MODULE q2_gtp_common_wrap
   `elsif Q1 `define Q_GTP_COMMON_MODULE q1_gtp_common_wrap
   `else     `define Q_GTP_COMMON_MODULE q0_gtp_common_wrap
   `endif

   wire pll0_lock, pll1_lock;
   wire pll0_outclk, pll1_outclk;
   wire pll0_outrefclk, pll1_outrefclk;
   wire pll0_refclklost, pll1_refclklost;

   wire pll0_reset_l = |{1'b0,
       `ifdef GT0_ENABLE gt0_pll0reset, `endif
       `ifdef GT1_ENABLE gt1_pll0reset, `endif
       `ifdef GT2_ENABLE gt2_pll0reset, `endif
       `ifdef GT3_ENABLE gt3_pll0reset, `endif
                         1'b0};

   wire pll1_reset_l = |{1'b0,
       `ifdef GT0_ENABLE gt0_pll1reset, `endif
       `ifdef GT1_ENABLE gt1_pll1reset, `endif
       `ifdef GT2_ENABLE gt2_pll1reset, `endif
       `ifdef GT3_ENABLE gt3_pll1reset, `endif
                         1'b0};

   `Q_GTP_COMMON_MODULE i_gtp_common_wrap (
      .sysclk_in        (drpclk_in),
      .gtrefclk0        (gtrefclk0),
      .gtrefclk1        (gtrefclk1),
      .pll0_lock        (pll0_lock),
      .pll1_lock        (pll1_lock),
      .soft_reset_tx_in (soft_reset),
      .soft_reset_rx_in (soft_reset),
      .pll0_outclk      (pll0_outclk),
      .pll0_outrefclk   (pll0_outrefclk),
      .pll0_refclklost  (pll0_refclklost),
      .pll0_reset       (pll0_reset_l),
      .pll1_outclk      (pll1_outclk),
      .pll1_outrefclk   (pll1_outrefclk),
      .pll1_refclklost  (pll1_refclklost),
      .pll1_reset       (pll1_reset_l));

   `ifdef GT0_ENABLE wire gt0_pll_locked=&{pll0_lock, pll1_lock}; `endif
   `ifdef GT1_ENABLE wire gt1_pll_locked=&{pll0_lock, pll1_lock}; `endif
   `ifdef GT2_ENABLE wire gt2_pll_locked=&{pll0_lock, pll1_lock}; `endif
   `ifdef GT3_ENABLE wire gt3_pll_locked=&{pll0_lock, pll1_lock}; `endif

`endif // GTCOMMON_EN

`else
   // TODO: Add support for QGTX_COMMON/QPLL
`endif // GT_TYPE__GTP

`ifdef GT0_ENABLE `GTi_WIRES(0)`endif
`ifdef GT1_ENABLE `GTi_WIRES(1)`endif
`ifdef GT2_ENABLE `GTi_WIRES(2)`endif
`ifdef GT3_ENABLE `GTi_WIRES(3)`endif

`ifndef SIMULATE

   // Instantiate wizard-generated Quad GT
   // Configured by gt_gen.tcl
   `ifdef Q3 `define Q_GT_MODULE(I) q3_gt``I``
   `elsif Q2 `define Q_GT_MODULE(I) q2_gt``I``
   `elsif Q1 `define Q_GT_MODULE(I) q1_gt``I``
   `else     `define Q_GT_MODULE(I) q0_gt``I``
   `endif

   `ifdef GT0_ENABLE
      `Q_GT_MODULE(0) i_gt0 (
         `GTi_PORT_MAP (0)
      );

      `GT_OUTCLK_BUF(0)
   `endif

   `ifdef GT1_ENABLE
      `Q_GT_MODULE(1) i_gt1 (
         `GTi_PORT_MAP (1)
      );

      `GT_OUTCLK_BUF(1)
   `endif

   `ifdef GT2_ENABLE
      `Q_GT_MODULE(2) i_gt2 (
         `GTi_PORT_MAP (2)
      );

      `GT_OUTCLK_BUF(2)
   `endif

   `ifdef GT3_ENABLE
      `Q_GT_MODULE(3) i_gt3 (
         `GTi_PORT_MAP (3)
      );

      `GT_OUTCLK_BUF(3)
   `endif

   assign gt_cpll_locked = &{1'b1,
           `ifdef GT0_ENABLE gt0_pll_locked, `endif
           `ifdef GT1_ENABLE gt1_pll_locked, `endif
           `ifdef GT2_ENABLE gt2_pll_locked, `endif
           `ifdef GT3_ENABLE gt3_pll_locked, `endif
                             1'b1};

   assign gt_txrx_resetdone = &{1'b1,
              `ifdef GT0_ENABLE gt0_txresetdone, gt0_rxresetdone, `endif
              `ifdef GT1_ENABLE gt1_txresetdone, gt1_rxresetdone, `endif
              `ifdef GT2_ENABLE gt2_txresetdone, gt2_rxresetdone, `endif
              `ifdef GT3_ENABLE gt3_txresetdone, gt3_rxresetdone, `endif
                                1'b1};

`else // SIMULATE

   // Instantiate dummy components to help dependency generation and basic syntax checking
   qgtp_common_wrap i_q_gtp_common_wrap(
      .sysclk_in (drpclk_in),
      .gtrefclk0 (gtrefclk0),
      .gtrefclk1 (gtrefclk1),
      .pll0_lock (),
      .pll1_lock ());

`endif // SIMULATE

