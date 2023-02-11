`timescale 1ns / 1ns
`include "constants.vams"

/* Bare-bones testbench to facilitate compile checks on DUT and check connectivity.
   Not intended to be comprehensive or do any self-checks. For more thorough testing see:
   - cic_multichannel_tb
   - circle_buf_serial_tb
*/

module cic_wave_recorder_tb;

   // Configurable parameters
   parameter n_chan = 2;

   // Testbench stimulus
   localparam SIM_CYCLES = 50000;
   localparam CIC_DWI = 16;
   localparam BUF_DWI = 16;

   integer num_tx=0;

   reg iclk;
   integer cc, errors;

   initial begin
      if ($test$plusargs("vcd")) begin
         $dumpfile("cic_wave_recorder.vcd");
         $dumpvars(5,cic_wave_recorder_tb);
      end
      errors=0;
      for (cc=0; cc<SIM_CYCLES; cc=cc+1) begin
         iclk=0; #5;
         iclk=1; #5;
      end

      $display("WARNING: Not a self-checking testbench. Will always pass.");
      $display("PASS");
      $finish();
   end

   reg oclk=0;
   always begin
      oclk=0; #3;
      oclk=1; #3;
   end

   // ---------------------
   // Generate stimulus
   // ---------------------

   reg reset = 0, ext_trig = 0;
   always @(posedge iclk) begin
       @(cc==30) begin
           reset <= 1;
           ext_trig <= 0;
       end

       @(cc==50) begin
            reset <= 0;
            ext_trig <= 1;
       end
    end

   localparam den=33, logden=6;
   localparam ampi=10000.0;
   reg [2:0] shift;
   real fden, fnum, ampo_expect, phsi, phs_marg;
   reg overload=0;
   initial begin
      // Test not designed to work with phsi near pi
      // 4 <= den <= 128, no factor of fnum
      ampo_expect=ampi;
      phs_marg=0.00002;
      phs_marg=0.95/ampi;
      if (ampi > 32765.0) begin
         overload=1;
         ampo_expect=32764.0;
         phs_marg=0.2;
      end
      $display("ampi=%.2f  ampo_expect=%.2f  phsi=%.5f  phs_marg=%.5f",
                ampi, ampo_expect, phsi, phs_marg);
      fden=den;
      fnum=3.0;
      shift=logden-2;
      $display("den=%d  logden=%d  shift=%d", den, logden, shift);
   end

   reg signed [15:0] adc=0;

   real th0;
   integer ax;  // can be huge in the face of clipping.  Don't be stupid and
                // set amplitude larger than 2^31 in ADC sine wave below.
                // 100 X overdrive is plenty for this purpose.
   always @(posedge iclk) begin
      th0 = (cc)*`M_TWO_PI*fnum/fden - phsi;
      ax = $floor(ampi*$cos(th0)+0.5);
      if (ax >  32767) ax =  32767;
      if (ax < -32678) ax = -32768;
      adc <= ax;
   end

   // Input stimulus
`ifdef RAND_IN
   reg [n_chan*CIC_DWI-1:0] d_in_flat=0;
   reg [CIC_DWI-1:0] data=12345;

   always @(negedge iclk) begin
      // Shift in random data every cycle
      data <= $urandom;
      d_in_flat <= {d_in_flat[(n_chan-1)*CIC_DWI-1:0], data};
   end
`else
   wire [n_chan*CIC_DWI-1:0] d_in_flat;

   assign d_in_flat = {adc, adc};
`endif

   // Readout emulation
   reg [9:0] read_addr=0;
   reg stb_out=0, odata_val=0;
   reg [1:0] ocnt=0;

   wire enable;
   wire otrig=(ocnt==3) & enable;
   integer frame=0;

   always @(posedge oclk) begin
      ocnt <= ocnt+1;
      if (otrig) read_addr <= read_addr+1;
      if (otrig & (&read_addr)) frame <= frame+1;
      stb_out   <= otrig;
      odata_val <= stb_out;
   end

   // ---------------------
   // Instantiate Sampler
   // ---------------------
   wire cic_sample, cc_sample;

   multi_sampler #(
      .sample_period_wi(8),
      .dsample0_en(1),
      .dsample0_wi(8),
      .dsample1_en(0),
      .dsample1_wi(8),
      .dsample2_en(0),
      .dsample2_wi(8))
   i_multi_sampler (
      .clk(iclk),
      .reset(reset),
      .ext_trig(ext_trig),
      .sample_period(8'h2), // Sample input at half the line rate
      .dsample0_period(8'h1),
      .dsample1_period(8'h1),
      .dsample2_period(8'h0),
      .sample_out(cic_sample),
      .dsample0_stb(cc_sample),
      .dsample1_stb(), // Unused output
      .dsample2_stb()  // Unused output
   );

   // ---------------------
   // Instantiate DUT
   // ---------------------

   wire [BUF_DWI-1:0] d_out;

   cic_wave_recorder #(
      .n_chan        (n_chan),

      // DI parameters
      .di_dwi        (CIC_DWI),  // data width
      .di_rwi        (32),  // result width
                            // Difference between above two widths should be N*log2 of the maximum number
                            // of samples per CIC sample, where N=2 is the order of the CIC filter.

      .di_noise_bits (0),
      .cc_outw       (20),  // CCFilt output width; Must be 20 if using half-band filter
      .cc_halfband   (1),
      .cc_use_delay  (0),   // Match pipeline length of filt_halfband=1
      .cc_shift_base (0),   // Bits to discard from previous acc step
      .buf_dw        (BUF_DWI),
      .buf_aw        (10),
      .lsb_mask      (1),
      .buf_stat_w    (16),
      .buf_auto_flip (1)
      )
   dut
   (
      .iclk         (iclk),
      .reset        (reset),
      .stb_in       (ext_trig),
      .d_in         (d_in_flat),   // Flattened array of unprocessed data streams. CH0 in LSBs
      .cic_sample   (cic_sample),

      // Post-integrator conveyor belt tap
      .di_stb_out   (),
      .di_sr_out    (),

      .cc_sample    (cc_sample),
      .cc_shift     ({1'b0, shift}), // controls scaling of filter result

      // Channel selector controls
      .chan_mask    (2'b11),     // Bitmask of channels to record. chan_mask[0] -> CH0

      // Circular Buffer control and statistics
      .oclk         (oclk),
      .buf_write    (1'b1),

      .buf_sync     (),            // single-cycle when buffer starts/ends
      .buf_transferred(),          // single-cycle when a buffer has been
      .buf_stop     (1'b0),        // single-cycle - interrupts cbuf writing
      .buf_count    (),
      .buf_stat2    (),            // includes fault bit
      .buf_stat     (),            // includes fault bit(), and (if set) the last valid location
      .debug_stat   (),            // {stb_in(), boundary(), btest(), wbank(), rbank(), wr_addr}

      // Circular Buffer data readout
      .buf_stb      (stb_out),
      .buf_enable   (enable),
      .buf_read_addr(read_addr),   // nominally 8192 locations
      .buf_d_out    (d_out)
   );

endmodule
