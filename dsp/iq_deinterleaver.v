`timescale 1ns / 1ns

/** IQ_DEINTERLEAVER **
     Deinterleave an IQ stream into separate I and Q components.
     scale input allows IQ data to be scaled down by a non-binary factor, which
     can be used to match the scaling of downconverted channels

     I_OUT = (I_IN*scale) >> (scale_wi-davr-1)
*/

module iq_deinterleaver #(
   parameter scale_wi  = 18, // Width of scale input and downscale factor
   parameter dwi       = 16, // Width of iq stream
   parameter davr      = 4)  // Guard bits to keep at output of scale multiplicaiton
(
   input                        clk,
   input  signed [scale_wi-1:0] scale_in,   // Scaling factor; scale is typically positive;
                                            // full-scale negative is not allowed
   input  signed [dwi-1:0]      iq_data_in, // IQ interleaved data
   input                        iq_sel,     // 1 (I), 0 (Q)
   output                       valid_out,
   output        [dwi+davr-1:0] i_data_out,
   output        [dwi+davr-1:0] q_data_out
);
   localparam SEL_I = 1, SEL_Q = 0;

   reg signed  [scale_wi+dwi-1:0] scaled_iq = 0, scaled_iq_r = 0;
   wire signed [dwi+davr-1:0]     scaled_iq_out;
   reg         [dwi+davr-1:0]     i_data_l = 0, i_data = 0, q_data = 0;
   reg                            iq_sel_r = 0, iq_sel_r2 = 0;
   reg                            valid_r = 0, valid_r2 = 0;

   // Use a multiplier so we can get full-scale to match between
   // input and output when using a non-binary CIC interval
   always @(posedge clk) begin
      scaled_iq   <= iq_data_in * scale_in;
      iq_sel_r    <= iq_sel;
      scaled_iq_r <= scaled_iq;
      iq_sel_r2   <= iq_sel_r;
   end

   // Drop sign bit and shift down TODO: Explain this operation, especially -1
   assign scaled_iq_out = scaled_iq_r[scale_wi+dwi-2:scale_wi-davr-1];

   always @(posedge clk) begin
      case (iq_sel_r2)
         SEL_I : i_data_l <= scaled_iq_out;
         SEL_Q : q_data   <= scaled_iq_out;
      endcase

      valid_r <= iq_sel_r2==SEL_I ? 1'b1 : 1'b0;

      i_data   <= i_data_l; // Time-align the common case where I and Q are paired
      valid_r2 <= valid_r;
   end

   assign valid_out  = valid_r2;
   assign i_data_out = i_data;
   assign q_data_out = q_data;

endmodule
