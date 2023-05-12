`timescale 1ns / 1ns

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
   input  [1:0]       channel_sel, // 0 - Field, 1 - Forward, 2 - Reverse, 3 - IQ_Fiber (from PRC)
   input              sample_wave,
   input  [3:0]       wave_shift,
   input              sr_valid,
   input  [sr_wi-1:0] sr_data,
   output signed [refcnt_w-1:0] reg_freq,
   output             reg_freq_valid,
   output [16:0]      reg_amp_max,
   output [16:0]      reg_amp_min,
   output             reg_updated,
   // Additional outputs
   output [23:0]      avg_power,
   output             avg_power_strobe,
   output             reg_timing_err
);
   localparam CCFILT_OUTW = 20;
   localparam CFREQ_INW   = 18;
   localparam FIELD_CHID = 0, FWD_CHID = 1, REV_CHID = 2, IQFIB_CHID = 3;

   wire signed [CCFILT_OUTW-1:0] cc_result;
   wire cc_strobe;
   wire signed [CFREQ_INW-1:0] cfreq_data;
   wire signed [CFREQ_INW-1:0] cfreq_din;
   wire cfreq_valid;

   reg  [n_chan-1: 0] fchan_mask, fchan_mask_r;
   wire fchan_time_err, cfreq_time_err;

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

   // Truncate LSBs - Assumes that CCFILT_OUTW >= CFREQ_INW
   assign cfreq_data = cc_result[CCFILT_OUTW-1:CCFILT_OUTW-CFREQ_INW];

   // Channel selection
   always @(channel_sel) begin
      fchan_mask = 0;
      case (channel_sel)
         FIELD_CHID : fchan_mask[1:0] = 2'b11;
         FWD_CHID   : fchan_mask[3:2] = 2'b11;
         REV_CHID   : fchan_mask[5:4] = 2'b11;
         IQFIB_CHID : fchan_mask[7:6] = 2'b11;
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
      .reset    (1'b0),
      .keep     (fchan_mask_r),
      .a_data   (cfreq_data),
      .a_gate   (cc_strobe),
      .a_trig   (~cc_strobe),
      .o_data   (cfreq_din),
      .o_gate   (cfreq_valid),
      .o_trig   (),
      .time_err (fchan_time_err)
   );

   wire [23:0] square_sum_out;
   wire square_sum_valid;
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
      .timing_err (cfreq_time_err),
      .square_sum_out   (square_sum_out),
      .square_sum_valid (square_sum_valid)
   );

   // First-order CIC filter of square_sum
   localparam square_sum_ex=15;  // average and decimate by 2^square_sum_ex
   cic_simple_us #(.dw(24), .ex(square_sum_ex)) cic(.clk(clk),
      .data_in(square_sum_out), .data_in_gate(square_sum_valid),
      .roll(1'b0),
      .data_out(avg_power), .data_out_gate(avg_power_strobe)
   );

   assign reg_timing_err = cfreq_time_err | fchan_time_err;

endmodule
