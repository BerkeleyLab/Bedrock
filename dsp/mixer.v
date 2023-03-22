`timescale 1ns / 1ns

module mixer #(
   parameter NORMALIZE = 0,
   parameter NUM_DROP_BITS = 1, // Number of bits to drop at the output.
                                // The typical case is where mult is never
                                // -FS, so we can drop at least 1 redundant
                                // sign bit from the output
   parameter dwi       = 16, // Width of ADC input
   parameter davr      = 4,  // Guard bits to keep at output. E.g. if downstream
                             // CIC averaging is 64, the useful data increase is sqrt(64),
                             // so add 3 bits; 4 bits to account for rounding error
   parameter dwlo      = 18  // Width of local-oscillator input
) (
   input                        clk,
   input  signed [dwi-1:0]      adcf,
   input  signed [dwlo-1:0]     mult,
   output signed [dwi+davr-1:0] mixout
);

   reg signed [dwi-1+davr:0] mixout_r = 0;
   reg signed [dwi-1:0]      adcf1 = 0;
   reg signed [dwlo-1:0]     mult1 = 0;
   reg signed [dwi+dwlo-1:0] mix_out_r = 0;
   reg signed [dwi-1+davr:0] mix_out1 = 0, mix_out2 = 0;

   generate
   if (NORMALIZE==1) begin
      reg  signed [dwi+dwlo-1:0] mixmulti=0;
      wire signed [dwi+dwlo-1:0] mix_out_w=mixmulti;//adcf*mult;
      always @(posedge clk) begin
         mixmulti <= adcf * mult;
         mixout_r <= mix_out_w[dwi+dwlo-1:dwlo-davr] + mix_out_w[dwlo-davr-1];
      end
      assign mixout = mixout_r;
   end
   else begin
      always @(posedge clk) begin
         adcf1     <= adcf;
         mult1     <= mult;
         mix_out_r <= adcf1 * mult1;  // internal multiplier pipeline
         mix_out1  <= mix_out_r[dwi+dwlo-NUM_DROP_BITS-1:dwlo-davr-NUM_DROP_BITS];
         mix_out2  <= mix_out1;
      end
      assign mixout = mix_out2;
   end
   endgenerate

endmodule
