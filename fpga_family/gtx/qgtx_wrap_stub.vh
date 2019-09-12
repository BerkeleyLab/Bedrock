// ------------------------------------
// QGTX_WRAP_STUB.vh
// Generic module body of q{0,1,2,3}_gtx_wrap component.
// This stub is meant to be `included into qgtx_wrap.v, where globally set defines will
// configure it with the right settings and correct number of GTX instances.
//
// Helper macros are defined in qgtx_wrap_pack.vh
//
// ------------------------------------

`ifdef GT0_ENABLE `GTi_WIRES(0)`endif
`ifdef GT1_ENABLE `GTi_WIRES(1)`endif
`ifdef GT2_ENABLE `GTi_WIRES(2)`endif
`ifdef GT3_ENABLE `GTi_WIRES(3)`endif

`ifndef SIMULATE
   // Instantiate wizard-generated Quad GTX
   // Configured by gtx_gen.tcl

   `ifdef Q3 `define Q_GTX_MODULE(I) q3_gtx``I``
   `elsif Q2 `define Q_GTX_MODULE(I) q2_gtx``I``
   `elsif Q1 `define Q_GTX_MODULE(I) q1_gtx``I``
   `else     `define Q_GTX_MODULE(I) q0_gtx``I``
   `endif

   wire [3:0] pll_locked, txresetdone, rxresetdone;

   `ifdef GT0_ENABLE
      `Q_GTX_MODULE(0) i_gtx0 (
         `GTi_PORT_MAP (0)
      );

      assign {pll_locked[0], txresetdone[0], rxresetdone[0]} = {gt0_pll_locked, gt0_txresetdone, gt0_rxresetdone};

      `GT_OUTCLK_BUF(0)
   `else
      assign {pll_locked[0], txresetdone[0], rxresetdone[0]} = 'b111;
   `endif

   `ifdef GT1_ENABLE
      `Q_GTX_MODULE(1) i_gtx1 (
         `GTi_PORT_MAP (1)
      );

      assign {pll_locked[1], txresetdone[1], rxresetdone[1]} = {gt0_pll_locked, gt0_txresetdone, gt0_rxresetdone};

      `GT_OUTCLK_BUF(1)
   `else
      assign {pll_locked[1], txresetdone[1], rxresetdone[1]} = 'b111;
   `endif

   `ifdef GT2_ENABLE
      `Q_GTX_MODULE(2) i_gtx2 (
         `GTi_PORT_MAP (2)
      );

      assign {pll_locked[2], txresetdone[2], rxresetdone[2]} = {gt0_pll_locked, gt0_txresetdone, gt0_rxresetdone};

      `GT_OUTCLK_BUF(2)
   `else
      assign {pll_locked[2], txresetdone[2], rxresetdone[2]} = 'b111;
   `endif

   `ifdef GT3_ENABLE
      `Q_GTX_MODULE(3) i_gtx3 (
         `GTi_PORT_MAP (3)
      );

      assign {pll_locked[3], txresetdone[3], rxresetdone[3]} = {gt0_pll_locked, gt0_txresetdone, gt0_rxresetdone};

      `GT_OUTCLK_BUF(3)
   `else
      assign {pll_locked[3], txresetdone[3], rxresetdone[3]} = 'b111;
   `endif

   assign gt_cpll_locked = &pll_locked;
   assign gt_txrx_resetdone = &{txresetdone, rxresetdone};

`endif // `ifndef SIMULATE

