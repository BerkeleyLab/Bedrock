`timescale 1ns / 1ns

// One more try to package up the LBNL conveyor belt in a usable and
// comprehensible form.

// New things going on here:
//  1. adc count is parameterized, and therefore a single input port
//     is nadc*dw bits wide; each block of dw bits is a signed number.
//  2. Independent I and Q shift registers
//  3. 32-bit wide memory read port can either hold the 20-bit full-resolution
//     measurement, or two packed 16-bit I and Q data

// LCLS-II dissection of possible use cases
// 1320/14 MHz raw ADC clock
// /33 for base CIC, 2.857 MS/s
// /8 to get 357 kS/s, suitable for loop characterization
// or /16 to get 179 kS/s, and a channel-subset is streamable for close-in
//   noise characterization
//   179 kS/s * 2 ADCs * 2 components * 20 bits = 14.3 Mbit/s
//   or without re-writing any infrastructure now,
//   179 kS/s * 2 ADCs * 2 components * 64 bits = 45.7 Mbit/s
// or /64 to get 44.64 kS/s, easily streamable and good for acoustic
//   characterization, including most SRF trip analysis
//   44.64 kS/s * 8 cavities * 2 components * 16 bits = 11.4 Mbit/s
//   Useful to grab 8 packets at a time with 1024 octets each,
//   requires each half of a ping-pong buffer to be 4K x 16.

// To support more than 33*16-point averaging, without losing resolution, you
// need wider data paths in ccfilt, with its recently-added outw parameter.
// 16 + log2(33*16/2)/2 = 20
// where the /2 inside the log represents mean(sin(theta)^2), and the answer
// comes out slightly more than 20 because we've ignored the intended
// adjustment to lo_amp.

// See nco_setup.py for help setting phase_step_h, phase_step_l, and modulo.

module iq_trace #(
   parameter dw         = 16, // ADC input width
   parameter oscw       = 18, // Oscillator input width
   parameter davr       = 3,  // Guard bits at output of mixer
   parameter ow         = 28, // second-order CIC data path width
   parameter rw         = 20, // result width out of ccfilt
   parameter pcw        = 13, // cic_period counter width
   parameter shift_base = 7,  // see ccfilt.v
   parameter nadc       = 8,
   parameter aw         = 13  // for circle_buf, see below
) (
  input                      clk,
  input                      reset,
  input                      trig,
  input        [1:0]         trig_mode,  // 0: free-run, 1: single-shot, 2: sync start, XXX not yet used
  input        [nadc*dw-1:0] adcs,   // each dw-wide adc data is signed
  input signed [oscw-1:0]    cosa,
  input signed [oscw-1:0]    sina,
  // Presumably host-settable parameters in the clk domain
  input        [pcw-1:0]     cic_period,  // expected values 33 to 33*128
  input        [3:0]         cic_shift,   // expected values 7 to 15
  input        [nadc-1:0]    keep,   // bit n :: channel n
  // 18+10+4 = 32 so all of the last three parameters could be a single
  // configuration word that fully defines output scaling
  //
  // host readout port, based on circle_buf.  ro_data is:
  //  ro_addr[aw+1] == 1'b1       packed 16-bit {I, Q} results
  //  ro_addr[aw+1:aw] == 2'b10   long (rw bits) I result
  //  ro_addr[aw+1:aw] == 2'b11   long (rw bits) Q result
  input                      ro_clk,
  output                     ro_enable,
  input                      ro_ack,
  input  [aw+1:0]            ro_addr,
  output [31:0]              ro_data,
  output [31:0]              ro_status
);

   // Set up some global signals in the right clock domain
   reg [1:0] trig_mode_r = 0;
   reg       trig_pending = 0;
   wire      boundary;

   wire trig_actual = trig_pending & boundary;
   always @(posedge clk) begin
      if (boundary) trig_pending <= 0;
      if (trig)     trig_pending <= 1;

      trig_mode_r <= trig_mode;
   end

   // ---------------------
   // Instantiate Sampler
   // ---------------------
   wire cic_sample;

   multi_sampler #(
      .sample_period_wi (pcw))
   i_multi_sampler (
      .clk             (clk),
      .reset           (reset),
      .ext_trig        (1'b1),
      .sample_period   (cic_period),
      .dsample0_period (8'h1),
      .dsample1_period (8'h1),
      .dsample2_period (8'h1),
      .sample_out      (cic_sample),
      .dsample0_stb    (),
      .dsample1_stb    ()
   );

   // ---------------------
   // Instantiate mixers to create I and Q streams
   // ---------------------
   wire signed [nadc*(dw+davr)-1:0] mixout_i, mixout_q;

   iq_mixer_multichannel #(
      .NCHAN (nadc),
      .DWI   (dw),
      .DAVR  (davr),
      .DWLO  (oscw)
   ) i_iq_mixer_multichannel (
      .clk      (clk),
      .adc      (adcs),
      .cos      (cosa),
      .sin      (sina),
      .mixout_i (mixout_i),
      .mixout_q (mixout_q)
   );

   // ---------------------
   // Instantiate two CIC_MULTICHANNEL, one for each stream
   // ---------------------
   wire strobe_cc;
   wire signed [rw-1:0] result_i, result_q;

   cic_multichannel #(
      .n_chan        (nadc),
      // DI parameters
      .di_dwi        (dw+davr),
      .di_rwi        (ow),
      .di_noise_bits (1), // NOTE: Setting to 1 to compensate for removed /2 from double_inte
      .cc_outw       (rw),
      .cc_halfband   (0),
      .cc_use_delay  (0),
      .cc_shift_base (shift_base))
   i_cic_multichannel_i
   (
      .clk           (clk),
      .reset         (reset),
      .stb_in        (1'b1),
      .d_in          (mixout_i),
      .cic_sample    (cic_sample),
      .cc_sample     (1'b1),
      .cc_shift      (cic_shift),
      .di_stb_out    (), // Unused double-integrator tap
      .di_sr_out     (),
      .cc_stb_out    (strobe_cc),
      .cc_sr_out     (result_i)
   );

   cic_multichannel #(
      .n_chan        (nadc),
      // DI parameters
      .di_dwi        (dw+davr),
      .di_rwi        (ow),
      .di_noise_bits (1), // NOTE: Setting to 1 to compensate for removed /2 from double_inte
      .cc_outw       (rw),
      .cc_halfband   (0),
      .cc_use_delay  (0),
      .cc_shift_base (shift_base))
   i_cic_multichannel_q
   (
      .clk           (clk),
      .reset         (reset),
      .stb_in        (1'b1),
      .d_in          (mixout_q),
      .cic_sample    (cic_sample),
      .cc_sample     (1'b1),
      .cc_shift      (cic_shift),
      .di_stb_out    (),
      .di_sr_out     (),
      .cc_stb_out    (), // Time-aligned with strobe_cc
      .cc_sr_out     (result_q)
   );


   // ---------------------
   // Instantiate circle_buf_serial to store I and Q streams and handle channel masking
   // ---------------------

   assign boundary = ~strobe_cc;

   // Run/stop mode based on trigger and trigger mode
   wire buf_sync;
   reg run=0;
   always @(posedge clk) begin
      if (trig_mode_r == 0)                run <= 1;
      if (trig_mode_r == 1 && buf_sync)    run <= 0;
      if (trig_mode_r != 0 && trig_actual) run <= 1;
   end
   wire circle_stb = strobe_cc & run;

   // Circular buffer
   // 2 * 20 bits from 2 * ccfilt, 8K depth * 2 I&Q channels means aw=13
   // 2 * 8K * 2 * 20 = 640 kbits = 20 BRAM36 in Xilinx 7-series
   wire [2*rw-1:0] circle_out;

   circle_buf_serial #(
      .n_chan        (nadc),
      .lsb_mask      (1), // Right to left. LSB=CH0
      .buf_aw        (aw),
      .buf_dw        (2*rw),
      .buf_auto_flip (0))
   i_circle_buf_serial (
      .iclk            (clk),
      .reset           (reset),
      .sr_in           ({result_q,result_i}),
      .sr_stb          (circle_stb),
      .chan_mask       (keep),
      .oclk            (ro_clk),
      .buf_sync        (buf_sync),
      .buf_transferred (),
      .buf_stop        (1'b0),
      .buf_count       (ro_status[31:16]),
      .buf_stat2       (),
      .buf_stat        (ro_status[15:0]),
      .debug_stat      (),
      .stb_out         (ro_ack),
      .enable          (ro_enable),
      .read_addr       (ro_addr[aw-1:0]),
      .d_out           (circle_out)
   );

   // Form 32-bit output bus
   reg [31:0] obus;
   wire [1:0] obus_mode = ro_addr[aw+1:aw];
   always @(*) casez (obus_mode)
           2'b0?: obus = {circle_out[rw-1:rw-16], circle_out[2*rw-1:2*rw-16]};
           2'b10: obus = {circle_out[  rw-1:0],  {(32-rw){1'b0}}};
           2'b11: obus = {circle_out[2*rw-1:rw], {(32-rw){1'b0}}};
   endcase
   assign ro_data = obus;

endmodule
