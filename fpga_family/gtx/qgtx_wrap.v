`timescale 1ns / 1ps

// ------------------------------------
// QGTX_WRAP.v
// Module declaration of 4 quad wrappers, q{0,1,2,3}_gtx_wrap
// The body for each module is `included from qgtx_wrap_stub.vh, which
// uses globaly set defines (redefined for each quad by `Q_REDEFINE)
// to generate the correct per-quad configuration
// ------------------------------------
`include "qgtx_wrap_pack.vh"

`ifndef SIMULATE

`define Q0
`Q_REDEFINE(0)

module q0_gtx_wrap # (
   parameter GT0_WI = 20,
   parameter GT1_WI = 20,
   parameter GT2_WI = 20,
   parameter GT3_WI = 20
)(
   input         drpclk_in,
   input         soft_reset,
   input         gtrefclk0,
   input         gtrefclk1,
   `ifdef GT0_ENABLE
   `GTi_PORTS(0, GT0_WI)
   `endif
   `ifdef GT1_ENABLE
   `GTi_PORTS(1, GT1_WI)
   `endif
   `ifdef GT2_ENABLE
   `GTi_PORTS(2, GT2_WI)
   `endif
   `ifdef GT3_ENABLE
   `GTi_PORTS(3, GT3_WI)
   `endif
   output        gt_cpll_locked,
   output        gt_txrx_resetdone
);
`include "qgtx_wrap_stub.vh"

endmodule

`undef Q0
`define Q1
`Q_REDEFINE(1)

module q1_gtx_wrap # (
   parameter GT0_WI = 20,
   parameter GT1_WI = 20,
   parameter GT2_WI = 20,
   parameter GT3_WI = 20
)(
   input         drpclk_in,
   input         soft_reset,
   input         gtrefclk0,
   input         gtrefclk1,
   `ifdef GT0_ENABLE
   `GTi_PORTS(0, GT0_WI)
   `endif
   `ifdef GT1_ENABLE
   `GTi_PORTS(1, GT1_WI)
   `endif
   `ifdef GT2_ENABLE
   `GTi_PORTS(2, GT2_WI)
   `endif
   `ifdef GT3_ENABLE
   `GTi_PORTS(3, GT3_WI)
   `endif
   output        gt_cpll_locked,
   output        gt_txrx_resetdone
);
`include "qgtx_wrap_stub.vh"

endmodule

`undef Q1
`define Q2
`Q_REDEFINE(2)

module q2_gtx_wrap # (
   parameter GT0_WI = 20,
   parameter GT1_WI = 20,
   parameter GT2_WI = 20,
   parameter GT3_WI = 20
)(
   input         drpclk_in,
   input         soft_reset,
   input         gtrefclk0,
   input         gtrefclk1,
   `ifdef GT0_ENABLE
   `GTi_PORTS(0, GT0_WI)
   `endif
   `ifdef GT1_ENABLE
   `GTi_PORTS(1, GT1_WI)
   `endif
   `ifdef GT2_ENABLE
   `GTi_PORTS(2, GT2_WI)
   `endif
   `ifdef GT3_ENABLE
   `GTi_PORTS(3, GT3_WI)
   `endif
   output        gt_cpll_locked,
   output        gt_txrx_resetdone
);
`include "qgtx_wrap_stub.vh"

endmodule

`undef Q2
`define Q3
`Q_REDEFINE(3)

module q3_gtx_wrap # (
   parameter GT0_WI = 20,
   parameter GT1_WI = 20,
   parameter GT2_WI = 20,
   parameter GT3_WI = 20
)(
   input         drpclk_in,
   input         soft_reset,
   input         gtrefclk0,
   input         gtrefclk1,
   `ifdef GT0_ENABLE
   `GTi_PORTS(0, GT0_WI)
   `endif
   `ifdef GT1_ENABLE
   `GTi_PORTS(1, GT1_WI)
   `endif
   `ifdef GT2_ENABLE
   `GTi_PORTS(2, GT2_WI)
   `endif
   `ifdef GT3_ENABLE
   `GTi_PORTS(3, GT3_WI)
   `endif
   output        gt_cpll_locked,
   output        gt_txrx_resetdone
);
`include "qgtx_wrap_stub.vh"

endmodule

`undef Q3

`else // SIMULATE

module qgtx_wrap # (
   parameter GT0_WI = 20,
   parameter GT1_WI = 20,
   parameter GT2_WI = 20,
   parameter GT3_WI = 20
)(
   input         drpclk_in,
   input         soft_reset,
   input         gtrefclk0,
   input         gtrefclk1,
   output        gt_cpll_locked,
   output        gt_txrx_resetdone
);
`include "qgtx_wrap_stub.vh"

endmodule

`endif // SIMULATE

