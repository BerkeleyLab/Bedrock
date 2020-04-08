`timescale 1ns / 1ns

// ------------------------------------
// lo_lut.v
//
// Read-only dual LUT that relies on lo_lut_gen.py to generate the content
// of the sine and cosine tables.
//
// ------------------------------------

module lo_lut #(
   parameter ADDR_WI=6,
   parameter DATA_WI=18
) (
   input clk,
   input [ADDR_WI-1:0] sin_addr,
   input [ADDR_WI-1:0] cos_addr,
   output signed [DATA_WI-1:0] sin_data,
   output signed [DATA_WI-1:0] cos_data
);

   reg signed [DATA_WI-1:0] data, s_data_r=0, c_data_r=0;
   always @(posedge clk) begin
      case (sin_addr)
         `include "sin_lut.vh"
      endcase
      s_data_r <= data;

      case (cos_addr)
         `include "cos_lut.vh"
      endcase
      c_data_r <= data;
   end

   assign sin_data = s_data_r;
   assign cos_data = c_data_r;
endmodule
