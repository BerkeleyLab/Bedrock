// -------------------------------------------------------------------------------
// Filename    : adc_cells.v
// Description :
// Author      : Qiang Du
// Maintainer  :
// -------------------------------------------------------------------------------
// Created     : Thu May 31 20:36:30 2012 (-0700)
// Version     :
// Last-Updated:
//           By:
//     Update #: 0
//
// -------------------------------------------------------------------------------

// Commentary  :  DDR wrapping for dual channel adc input running in interleave mode
//
// -------------------------------------------------------------------------------

// Change Log  :
// 1-Jun-2012    Qiang Du
//    change to configurable width.
// 31-May-2012    Qiang Du
//    Initial draft.
//
// -------------------------------------------------------------------------------

// Code:

`timescale 1ns / 1ns

module adc_cells(clk, mux_data_in, adc0, adc1);

   parameter width = 14;
   input         clk;
   input [13:0]  mux_data_in;
   output [13:0] adc0;
   output [13:0] adc1;

   // interleave DDR output from AD9258
   wire        adc_iddr2_rst=1'b0;
   wire        adc_iddr2_set=1'b0;
   wire        adc_iddr2_ce=1'b1;
   // IDDR2 primitive of sp6, refer to http://www.xilinx.com/support/documentation/sw_manuals/xilinx13_4/spartan6_hdl.pdf, page 56 for ddr_alignment
   genvar ix;
   generate
      for (ix=0; ix<width; ix=ix+1) begin: in_cell
`ifndef SIMULATE
         IDDR2 #(.DDR_ALIGNMENT("C0"), .SRTYPE("ASYNC"))
         adc_din0(.D(mux_data_in[ix]), .Q0(adc0[ix]), .Q1(adc1[ix]), .C0(clk), .C1(~clk), .CE(adc_iddr2_ce), .R(adc_iddr2_rst), .S(adc_iddr2_set));
`endif
      end
   endgenerate

endmodule

//
// adc_cells.v ends here
