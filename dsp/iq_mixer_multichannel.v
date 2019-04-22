`timescale 1ns / 1ns

/** IQ_MIXER_MULTICHANNEL **
    Convenience wrapper that instantiates a generic number of mixer pairs
    for IQ or near-IQ mixing.
    Inputs are flattened vectors of the individual channels.

*/

module iq_mixer_multichannel #(
   parameter NORMALIZE = 0,
   parameter NCHAN     = 2,  // Number of input channels
   parameter DWI       = 16, // Width of ADC input
   parameter DAVR      = 4,  // Guard bits to keep in the output
   parameter DWLO      = 18) // Width of sin/cos input
(
   input                                clk,
   input  signed [NCHAN*DWI-1:0]        adc,
   input  signed [DWLO-1:0]             cos,
   input  signed [DWLO-1:0]             sin,
   output signed [NCHAN*(DWI+DAVR)-1:0] mixout_i,
   output signed [NCHAN*(DWI+DAVR)-1:0] mixout_q
);

   genvar ch_id;
   generate for (ch_id=0; ch_id < NCHAN; ch_id=ch_id+1) begin : g_mixer_sin_cos

      mixer #(
         .NORMALIZE (NORMALIZE),
         .dwi       (DWI),
         .davr      (DAVR),
         .dwlo      (DWLO)
      )
      i_mixer_cos
      (
         .clk    (clk),
         .adcf   (adc[(ch_id+1)*DWI-1: ch_id*DWI]),
         .mult   (cos),
         .mixout (mixout_i[(ch_id+1)*(DWI+DAVR)-1: ch_id*(DWI+DAVR)])
      );

      mixer #(
         .NORMALIZE (NORMALIZE),
         .dwi       (DWI),
         .davr      (DAVR),
         .dwlo      (DWLO)
      )
      i_mixer_sin
      (
         .clk    (clk),
         .adcf   (adc[(ch_id+1)*DWI-1: ch_id*DWI]),
         .mult   (sin),
         .mixout (mixout_q[(ch_id+1)*(DWI+DAVR)-1: ch_id*(DWI+DAVR)])
      );

   end endgenerate
endmodule
