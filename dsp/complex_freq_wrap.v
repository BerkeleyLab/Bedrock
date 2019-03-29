/** COMPLEX_FREQ_WRAP **
    Wraps around complex_freq.v and adds COMB (CCFILT) portion
    of upstream CIC filter and conveyor belt channel selection.

    Assumes following conveyor belt ordering:
    {I,Q} * {Field, Forward, Reverse, Fiber, Drive, spare}
*/

module complex_freq_wrap #(
   parameter n_chan     = 12,
   parameter sr_wi      = 40, // Conveyor belt data width
   parameter shift_base = 4,
   parameter refcnt_w   = 17
) (
   input              clk,         // single clock domain
   input  [1:0]       channel_sel, // 0 - Field, 1 - Forward, 2 - Reverse
   input              sample_wave,
   input  [3:0]       wave_shift,
   input              sr_valid,
   input  [sr_wi-1:0] sr_data,
   output signed [refcnt_w-1:0] reg_freq,
   output             reg_freq_valid,
   output [16:0]      reg_amp_max,
   output [16:0]      reg_amp_min,
   output             reg_updated,
   output             reg_timing_err
);
   localparam CCFILT_OUTW = 20;
   localparam CFREQ_INW   = 18;

   wire signed [CCFILT_OUTW-1:0] cc_result;
   wire cc_strobe;
   wire signed [CFREQ_INW-1:0] cfreq_data;
   wire signed [CFREQ_INW-1:0] cfreq_din;
   wire cfreq_valid;

   localparam FWD_CHID = 1, REV_CHID = 2, FIELD_CHID = 0;
   reg  [n_chan-1: 0] fchan_mask, fchan_mask_r;
   wire fchan_time_err, cfreq_time_err;

   // TODO: Review this comment taken from piezo_control.v
   // Use same shift_base as llrf_dsp's ccfilt
   // Should use the same shift parameter (13) as llrf_dsp constructs
   // from wave_shift=6, in turn based on wave_samp_per=32.
   // Use 9 for now because ... simulations.
   ccfilt #(
      .use_hb     (0),
      .use_delay  (0),
      .dsr_len    (n_chan),
      .dw         (sr_wi),
      .outw       (CCFILT_OUTW),
      .shift_base (shift_base))
   ccfilt(
      .clk        (clk),
      .reset      (1'b0),
      .sr_in      (sr_data),
      .sr_valid   (sr_valid & sample_wave),
      .shift      (wave_shift),
      .result     (cc_result),
      .strobe     (cc_strobe));

   // TODO: Check that we want to truncate LSBs - Assumes that CCFILT_OUTW >= CFREQ_INW
   assign cfreq_data = cc_result[CCFILT_OUTW-1:CCFILT_OUTW-CFREQ_INW];

   // Channel selection
   always @(channel_sel) begin
      fchan_mask = 0;
      case (channel_sel)
         FWD_CHID   : fchan_mask[3:2] = 2'b11;
         REV_CHID   : fchan_mask[5:4] = 2'b11;
         FIELD_CHID : fchan_mask[1:0] = 2'b11;
      endcase
   end

   // Latch onto new mask between strobes
   always @(posedge clk) if (cc_strobe == 0) fchan_mask_r <= fchan_mask;

   fchan_subset #(
      .KEEP_OLD (1),
      .a_dw     (CFREQ_INW),
      .o_dw     (CFREQ_INW),
      .len      (n_chan))
   i_fchan_subset (
      .clk      (clk),
      .keep     (fchan_mask_r),
      .a_data   (cfreq_data),
      .a_gate   (cc_strobe),
      .a_trig   (~cc_strobe),
      .o_data   (cfreq_din),
      .o_gate   (cfreq_valid),
      .o_trig   (),
      .time_err (fchan_time_err)
   );

   complex_freq #(
      .refcnt_w(refcnt_w))
   i_complex_freq (
      .clk        (clk),
      .sdata      (cfreq_din),
      .sgate      (cfreq_valid),
      .freq       (reg_freq),
      .freq_valid (reg_freq_valid),
      .amp_max    (reg_amp_max),
      .amp_min    (reg_amp_min),
      .updated    (reg_updated),
      .timing_err (cfreq_time_err)
   );

   assign reg_timing_err = cfreq_time_err | fchan_time_err;


endmodule
