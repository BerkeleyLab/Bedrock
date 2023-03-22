`timescale 1ns / 1ns

/** CIC Multichannel
    Generic multichannel Cascaded-Integrator-Comb filter comprised of:
    - Double Integrator (DI) per channel
    - Multichannel Serializer sampling the output of all DIs into a shift-chain
      at a rate defined by cic_base_per
    - (Optional configurable delay chain)
    - Cascaded Differentiator and post-filter (CC Filter) with barrel shifter
      sampled at a rate defined by cc_samp_per
    - CIC timing generator
    - Shift-chain tap of the DI serialized stream

       +-------------------------------------+
       | +-----+   +---+                     |
 in[0]--->D INT+--->   |         +-------------> di_sr_out
       | +-----+   | S |         |           |
       |           | E |         |  +------+ |
       | +-----+   | R |         |  |      | |
 in[1]--->D INT+---> I +-[][][]--+-->CCFILT+---> cc_sr_out
       | +-----+   | A |  SHIFT     |      | |
       |           | L |            +---^--+ |
       | +-----+   |   |                |    |
 in[N]--->D INT+--->   |                |    |
       | +-----+   +-^-+                |    |
       |             |                  |    |
       +-------------------------------------+
                     |                  |
          cic_sample +                  + cc_sample
*/

module cic_multichannel #(
   parameter n_chan=12,

   // DI parameters
   parameter di_dwi=16,       // data width
   parameter di_rwi=32,       // result width
                              // Difference between above two widths should be N*log2 of the maximum number
                              // of samples per CIC sample, where N=2 is the order of the CIC filter
   parameter di_noise_bits=4, // Number of noise bits to discard at the output of Double Integrator.
                              // This depends on the SNR of the inputs and the CIC sample rate

   parameter shift_delay=0,   // Optional shifter between Integrator and Comb. A value of 0 disables shifter

   parameter cc_outw=20,      // CCFilt output width; Must be 20 if using half-band filter
   parameter cc_halfband=1,
   parameter cc_use_delay=0,  // Match pipeline length of filt_halfband=1
   parameter cc_shift_base=0, // Bits to discard from previous acc step
   parameter cc_shift_wi=4
) (
   // Incoming stream
   input                       clk,
   input                       reset,
   input                       stb_in,     // Strobe signal for input samples
   input [n_chan*di_dwi-1:0]   d_in,       // Flattened array of unprocessed data streams. CH0 in LSBs
   input                       cic_sample, // CIC base sampling signal

   // CC Filter controls
   input                       cc_sample,  // CCFilt sampling signal
   input [cc_shift_wi-1:0]     cc_shift,   // controls scaling of filter result

   // Post-integrator conveyor belt tap
   output                      di_stb_out,
   output [di_rwi-1:0]         di_sr_out,

   // Post-CC filter conveyor belt out
   output                      cc_stb_out,
   output signed [cc_outw-1:0] cc_sr_out
);
   // Synchronize reset
   reg [1:0] reset_r=0;

   always @(posedge clk) begin
      reset_r <= {reset_r[0],reset};
   end

   // ------
   // Double Integrator per channel
   // ------

   wire [n_chan*di_rwi-1:0] di_out;

   genvar ch_id;
   generate for (ch_id=0; ch_id < n_chan; ch_id=ch_id+1) begin : g_d_int

      double_inte_smp #(
         .dwi (di_dwi),
         .dwo (di_rwi))
      i_double_inte (
         .clk    (clk),
         .reset  (reset_r[1]),
         .stb_in (stb_in),
         .in     (d_in[(ch_id+1)*di_dwi-1:ch_id*di_dwi]),
         .out    (di_out[(ch_id+1)*di_rwi-1:ch_id*di_rwi])
        );

   end endgenerate

   // ------
   // Multichannel serializer/conveyor belt generator
   // ------

   wire [di_rwi-1:0] sr_out_l;
   wire stb_out_l;

   serializer_multichannel #(
      .n_chan (n_chan),
      .dw     (di_rwi))
   i_serializer_multich (
      .clk        (clk),
      .sample_in  (cic_sample),
      .data_in    (di_out),
      .gate_out   (stb_out_l),
      .stream_out (sr_out_l)
   );

   // ------
   // Optional shift-based delay
   // ------
   wire [di_rwi-1:0] sr_out_shift;
   wire stb_out_shift, stb_out_shift_l;

   reg_delay #(
      .dw  (di_rwi+1),
      .len (shift_delay*n_chan))
   i_shift_delay (
      .clk   (clk),
      .reset (reset),
      .gate  (stb_out_l), // Shift at line-rate
      .din   ({sr_out_l, stb_out_l}),
      .dout  ({sr_out_shift, stb_out_shift_l})
   );

   assign stb_out_shift = stb_out_shift_l & stb_out_l;

   // Pre-comb conveyor-belt tap
   assign di_stb_out = stb_out_shift;
   assign di_sr_out  = sr_out_shift;

   // ------
   // Cascaded differentiator and post-filter
   // ------
`ifdef SIMULATE
   // Enforces correct parameter settings
   initial begin
      if (cc_halfband && cc_outw != 20) begin
         $display("ERROR: Output width of CC filt must be 20 when using the Half-Band filter");
         $finish;
      end
   end
`endif

   ccfilt #(
      .dw         (di_rwi-di_noise_bits),
      .outw       (cc_outw),
      .shift_wi   (cc_shift_wi),
      .shift_base (cc_shift_base),
      .dsr_len    (n_chan),
      .use_hb     (cc_halfband),
      .use_delay  (cc_use_delay))
   i_ccfilt
   (
      .clk      (clk),
      .reset    (reset),
      .sr_in    (sr_out_shift[di_rwi-1:(di_noise_bits)]), // Discard noisy LSBs
      .sr_valid (stb_out_shift&cc_sample),
      .shift    (cc_shift),
      .result   (cc_sr_out), // signed filtered and scaled result
      .strobe   (cc_stb_out)
   );

endmodule
