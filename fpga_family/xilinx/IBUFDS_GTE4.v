`timescale 1ns / 1ns

(* ivl_synthesis_cell *)
module IBUFDS_GTE4 #(
    parameter DIFF_TERM = "FALSE",
    parameter [0:0] REFCLK_EN_TX_PATH = 1'b0,
    parameter [1:0] REFCLK_HROW_CK_SEL = 2'b00,
    parameter [1:0] REFCLK_ICNTL_RX = 2'b00
)(
    input I,
    input IB,
    input CEB,
    output O,
    output ODIV2
);
    buf B1(O, I);

    reg x=0;
    always @(posedge I) x<=~x;
    buf B2(ODIV2, x);

endmodule
