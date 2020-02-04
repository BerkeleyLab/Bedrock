// ------------------------------------
// QGTP_COMMON_WRAP_STUB.vh
// Generic module body of q{0,1,2,3}_gtp_common_wrap component.
// This stub is meant to be `included into qgtp_common_wrap.v, where globally set defines will
// configure it with the right settings and correct number of GTP instances.
//
// Helper macros are defined in qgtp_pack.vh
//
// ------------------------------------

   wire pll0_pd, pll1_pd;
   wire pll_soft_reset;
   wire pll0_reset_l, pll0_init_reset, pll1_reset_l, pll1_init_reset;

`ifndef SIMULATE
   // Instantiate wizard-generated primitives
   // Configured by gtx_gen.tcl

   `ifdef Q3
      `define Q_GTP_COMM q3_gtcommon_common
      `define Q_GTP_COMM_RAIL q3_gtcommon_cpll_railing
      `define Q_GTP_COMM_RST q3_gtcommon_common_reset
   `elsif Q2
      `define Q_GTP_COMM q2_gtcommon_common
      `define Q_GTP_COMM_RAIL q2_gtcommon_cpll_railing
      `define Q_GTP_COMM_RST q2_gtcommon_common_reset
   `elsif Q1
      `define Q_GTP_COMM q1_gtcommon_common
      `define Q_GTP_COMM_RAIL q1_gtcommon_cpll_railing
      `define Q_GTP_COMM_RST q1_gtcommon_common_reset
   `else
      `define Q_GTP_COMM q0_gtcommon_common
      `define Q_GTP_COMM_RAIL q0_gtcommon_cpll_railing
      `define Q_GTP_COMM_RST q0_gtcommon_common_reset
   `endif

    `Q_GTP_COMM_RST i_gtp_common_rst (
       .STABLE_CLOCK (sysclk_in),
       .SOFT_RESET   (soft_reset_tx_in | soft_reset_rx_in),
       .COMMON_RESET (pll_soft_reset));

    `Q_GTP_COMM_RAIL i_gtp_common_rail0 (
       .cpll_reset_out (pll0_init_reset),
       .cpll_pd_out    (pll0_pd),
       .refclk_out     (),
       .refclk_in      (gtrefclk0));

    `Q_GTP_COMM_RAIL i_gtp_common_rail1 (
       .cpll_reset_out (pll1_init_reset),
       .cpll_pd_out    (pll1_pd),
       .refclk_out     (),
       .refclk_in      (gtrefclk0)); // Ideally configurable but in practice it's just generating a reset

    assign pll0_reset_l = pll_soft_reset | pll0_init_reset | pll0_reset;
    assign pll1_reset_l = pll_soft_reset | pll1_init_reset | pll1_reset;


    `Q_GTP_COMM i_gtp_common (
      .PLL0OUTCLK_OUT     (pll0_outclk),
      .PLL0OUTREFCLK_OUT  (pll0_outrefclk),
      .PLL0LOCK_OUT       (pll0_lock),
      .PLL0LOCKDETCLK_IN  (sysclk_in),
      .PLL0REFCLKLOST_OUT (pll0_refclklost),
      .PLL0RESET_IN       (pll0_reset_l),
      .PLL0PD_IN          (pll0_pd),
`ifdef PLL0_REFCLK0
      .PLL0REFCLKSEL_IN   (3'b001),
`else
      .PLL0REFCLKSEL_IN   (3'b010),
`endif
      .PLL1OUTCLK_OUT     (pll1_outclk),
      .PLL1OUTREFCLK_OUT  (pll1_outrefclk),
      .PLL1LOCK_OUT       (pll1_lock),
      .PLL1LOCKDETCLK_IN  (sysclk_in),
      .PLL1REFCLKLOST_OUT (pll1_refclklost),
      .PLL1RESET_IN       (pll1_reset_l),
      .PLL1PD_IN          (pll1_pd),
`ifdef PLL1_REFCLK0
      .PLL1REFCLKSEL_IN   (3'b001),
`else
      .PLL1REFCLKSEL_IN   (3'b010),
`endif
      .GTREFCLK0_IN       (gtrefclk0),
      .GTREFCLK1_IN       (gtrefclk1));


`endif // `ifndef SIMULATE
