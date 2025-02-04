`timescale 1ns / 1ns

/** IQ_DEINTERLEAVER_MULTICHANNEL **
    Convenience wrapper that instantiates a generic number of iq_deinterleaver
    Inputs are flattened vectors of the individual channels.

*/

module iq_deinterleaver_multichannel #(
   parameter NCHAN     = 2,
   parameter SCALE_WI  = 18,
   parameter DWI       = 16,
   parameter DAVR      = 4
) (
   input                         clk,
   input  signed [SCALE_WI-1:0]  scale_in,
   input  signed [NCHAN*DWI-1:0] iq_data_in,
   input                         iq_sel,
   output                        valid_out,
   output [NCHAN*(DWI+DAVR)-1:0] i_data_out,
   output [NCHAN*(DWI+DAVR)-1:0] q_data_out
);
   wire [NCHAN-1:0] valids_out;

   genvar ch_id;
   generate for (ch_id=0; ch_id < NCHAN; ch_id=ch_id+1) begin : g_iq_deinterleaver

      iq_deinterleaver #(
         .scale_wi  (SCALE_WI),
         .dwi       (DWI),
         .davr      (DAVR)
      ) i_iq_deinterleaver (
         .clk        (clk),
         .scale_in   (scale_in),
         .iq_data_in (iq_data_in[(ch_id+1)*DWI-1:ch_id*DWI]),
         .iq_sel     (iq_sel),
         .valid_out  (valids_out[ch_id]),
         .i_data_out (i_data_out[(ch_id+1)*(DWI+DAVR)-1:ch_id*(DWI+DAVR)]),
         .q_data_out (q_data_out[(ch_id+1)*(DWI+DAVR)-1:ch_id*(DWI+DAVR)])
      );

   end endgenerate

   assign valid_out = valids_out[0];
endmodule
