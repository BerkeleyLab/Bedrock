`timescale 1ns / 1ns

// ------------------------------------
// QGTP_COMMON_WRAP.v
// Module declaration of 4 GTP Common primitive wrappers, q{0,1,2,3}_gtp_common_wrap
// The body for each module is `included from qgtp_common_wrap_stub.vh, which
// uses globally set defines to generate the correct per-quad configuration
// ------------------------------------
`include "qgtp_pack.vh"

`ifndef SIMULATE

`define Q0

module q0_gtp_common_wrap (
   input sysclk_in,
   input gtrefclk0,
   input gtrefclk1,
   output pll0_lock,
   output pll1_lock,
   `GTP_COMMON_WRAP_PORTS
);
`include "qgtp_common_wrap_stub.vh"

endmodule

`undef Q0
`define Q1

module q1_gtp_common_wrap (
   input sysclk_in,
   input gtrefclk0,
   input gtrefclk1,
   output pll0_lock,
   output pll1_lock,
   `GTP_COMMON_WRAP_PORTS
);
`include "qgtp_common_wrap_stub.vh"

endmodule

`undef Q1
`define Q2

module q2_gtp_common_wrap (
   input sysclk_in,
   input  gtrefclk0,
   input  gtrefclk1,
   output pll0_lock,
   output pll1_lock,
   `GTP_COMMON_WRAP_PORTS
);
`include "qgtp_common_wrap_stub.vh"

endmodule

`undef Q2
`define Q3

module q3_gtp_common_wrap (
   input sysclk_in,
   input gtrefclk0,
   input gtrefclk1,
   output pll0_lock,
   output pll1_lock,
   `GTP_COMMON_WRAP_PORTS
);
`include "qgtp_common_wrap_stub.vh"

endmodule

`undef Q3

`else // SIMULATE

module qgtp_common_wrap (
   input sysclk_in,
   input gtrefclk0,
   input gtrefclk1,
   output pll0_lock,
   output pll1_lock
);
`include "qgtp_common_wrap_stub.vh"

endmodule

`endif // SIMULATE

