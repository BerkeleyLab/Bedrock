// ------------------------------------
// QGTX_WRAP_STUB.vh
// Generic module body of q{0,1,2,3}_gtx_wrap component.
// This stub is meant to be `included into qgtx_wrap.v, where globally set defines will
// configure it with the right settings and correct number of GTX instances.
//
// Helper macros are defined in qgtx_wrap_pack.vh
//
// ------------------------------------

`ifdef GT0_ENABLE `GTi_WIRES(0) `endif
`ifdef GT1_ENABLE `GTi_WIRES(1) `endif
`ifdef GT2_ENABLE `GTi_WIRES(2) `endif
`ifdef GT3_ENABLE `GTi_WIRES(3) `endif

   wire gt_cpll_reset, gt_txrx_reset;

   qgtx_reset_fsm # (
      .CPLL_RESET_WAIT (60))
   i_qgtx_reset_fsm (
      .drpclk_in (drpclk_in),

      .gt0_cpll_locked `ifdef GT0_ENABLE (gt0_cpll_locked) `else (1'b1) `endif,
      .gt1_cpll_locked `ifdef GT1_ENABLE (gt1_cpll_locked) `else (1'b1) `endif,
      .gt2_cpll_locked `ifdef GT2_ENABLE (gt2_cpll_locked) `else (1'b1) `endif,
      .gt3_cpll_locked `ifdef GT3_ENABLE (gt3_cpll_locked) `else (1'b1) `endif,

      .gt0_txresetdone `ifdef GT0_ENABLE (gt0_txresetdone) `else (1'b1) `endif,
      .gt1_txresetdone `ifdef GT1_ENABLE (gt1_txresetdone) `else (1'b1) `endif,
      .gt2_txresetdone `ifdef GT2_ENABLE (gt2_txresetdone) `else (1'b1) `endif,
      .gt3_txresetdone `ifdef GT3_ENABLE (gt3_txresetdone) `else (1'b1) `endif,

      .gt0_rxresetdone `ifdef GT0_ENABLE (gt0_txresetdone) `else (1'b1) `endif,
      .gt1_rxresetdone `ifdef GT1_ENABLE (gt1_txresetdone) `else (1'b1) `endif,
      .gt2_rxresetdone `ifdef GT2_ENABLE (gt2_txresetdone) `else (1'b1) `endif,
      .gt3_rxresetdone `ifdef GT3_ENABLE (gt3_txresetdone) `else (1'b1) `endif,

      .gt_cpll_reset     (gt_cpll_reset),
      .gt_txrx_reset     (gt_txrx_reset),
      .gt_cpll_locked    (gt_cpll_locked),
      .gt_txrx_resetdone (gt_txrx_resetdone)
   );

`ifndef SIMULATE
   // Instantiate wizard-generated Quad GTX
   // Configured by gtx_gen.tcl

   `ifdef Q3 `define Q_GTX_MODULE(I) q3_gtx``I``
   `elsif Q2 `define Q_GTX_MODULE(I) q2_gtx``I``
   `elsif Q1 `define Q_GTX_MODULE(I) q1_gtx``I``
   `else     `define Q_GTX_MODULE(I) q0_gtx``I``
   `endif

   `ifdef GT0_ENABLE
      `Q_GTX_MODULE(0) i_gtx0 (
         `GTi_PORT_MAP (0)
      );

      `GTX_OUTCLK_BUF(0)
   `endif

   `ifdef GT1_ENABLE
      `Q_GTX_MODULE(1) i_gtx1 (
         `GTi_PORT_MAP (1)
      );

      `GTX_OUTCLK_BUF(1)
   `endif

   `ifdef GT2_ENABLE
      `Q_GTX_MODULE(2) i_gtx2 (
         `GTi_PORT_MAP (2)
      );

      `GTX_OUTCLK_BUF(2)
   `endif

   `ifdef GT3_ENABLE
      `Q_GTX_MODULE(3) i_gtx3 (
         `GTi_PORT_MAP (3)
      );

      `GTX_OUTCLK_BUF(3)
   `endif

`endif // `ifndef SIMULATE

