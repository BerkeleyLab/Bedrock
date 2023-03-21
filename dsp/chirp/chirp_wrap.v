// ------------------------------------
// chirp_wrap.v
//
// Chirp generator that combines a quadratic phase generator and an amplitude
// shaper to produce a time-limited chirp, triggered by chirp_start.
//
// This module is designed to connect to an external CORDIC. The periodicity
// of ext_trig w.r.t the clock determines the CORDIC update rate, which then
// typically drives a downstream DAC. The size/throughput of the CORDIC must
// be such that it can handle this update rate.
//
// See README.md for additional details and considerations.
//
// ------------------------------------

module chirp_wrap # (
   parameter DD_SHIFT = 16, // See comments in parab.v for dx
   parameter AMP_WI = 20,
   parameter PH_WI = 20,
   parameter LEN_WI = 32,
   parameter CORDIC_WI = 21 // Must be at least AMP_WI+1 due to accommodate sign;
                            // cordic_phase port is always one bit wider
) (
   input clk,
   input ext_trig,
   input chirp_start, // Edge-triggered

   // Chirp parameters
   input [LEN_WI-1:0]        chirp_len,    // Full chirp length (inc. rise and fall)
   input signed [PH_WI-1:0]  chirp_dphase,
   input signed [PH_WI-1:0]  chirp_ddphase,
   input [AMP_WI-1:0]        chirp_amp_slope, // Slope of rise and fall amplitude ramps
   input [AMP_WI-1:0]        chirp_amp_max,   // Maximum amplitude of chirp envelope

   output                          cordic_trig,
   output signed [CORDIC_WI-1:0]   cordic_amp,
   output signed [CORDIC_WI+1-1:0] cordic_phase,

   output       chirp_status, // 1 - When chirp is being generated; Control registers
                              // can be safely updated when chirp_status is low.
   output [2:0] chirp_error   // [0] - Chirp amplitude not zero at start of next chirp
                              // [1] - Excessive incoming data rate
                              // [2] - ddphase accumulation overflow
);

   // Latch onto single-cycle chirp_start until next ext_trig
   reg chirp_start_r = 0;
   always @(posedge clk) begin
      if (chirp_start)
         chirp_start_r <= 1;
      if (ext_trig && gate)
         chirp_start_r <= 0;
   end

   // Run length handling
   reg [LEN_WI-1:0] cycle=0;
   wire cycle_zero = ~(|cycle);

   reg active_r=0;  // stretched beyond run to end of chirp

   always @(posedge clk) begin
      if (chirp_start_r) active_r <= 1;

      if (gate | chirp_start_r) begin
         if (active_r && gate && !cycle_zero) cycle <= cycle - 1;
         if (cycle_zero && chirp_start_r && gate) cycle <= chirp_len;
         if (cycle_zero && !chirp_start_r) active_r <= 0;
      end
   end

   wire gate = ext_trig & active_r;
   wire reset = ~active_r | (cycle_zero & gate);
   assign chirp_status = active_r;  // module output,

   // Instantiate quadratic phase generator
   wire signed [PH_WI-1:0] phase;
   wire parab_error;

   parab #(
      .dw (PH_WI),
      .ow (PH_WI),
      .dx (DD_SHIFT)
   ) i_parab (
      .clk     (clk),
      .gate    (gate),
      .reset   (reset),
      .gate_o  (cordic_trig),
      .dphase  (chirp_dphase),
      .ddphase (chirp_ddphase),
      .phase   (phase),
      .error   (parab_error)
   );

   // Instantiate amplitude modulation generator
   wire [AMP_WI-1:0] amp_out;
   wire ramps_error, a_warning;

   ramps #(
      .dw (AMP_WI),
      .cw (LEN_WI)
   ) i_ramps (
      .clk       (clk),
      .gate      (gate),
      .reset     (reset),
      .duration  (chirp_len),
      .amp_slope (chirp_amp_slope),
      .amp_max   (chirp_amp_max),
      .amp       (amp_out),
      .gate_o    (),
      .a_warning (a_warning),
      .error     (ramps_error)
   );

   // amp_out is always positive; One extra bit for sign
   assign cordic_amp = (CORDIC_WI >= AMP_WI) ? amp_out << (CORDIC_WI-AMP_WI-1) :
                                               {1'b0, amp_out[AMP_WI-1:AMP_WI-CORDIC_WI+1]};

   // 1-bit wider than cordic_amp
   wire [PH_WI:0] cordic_phase_l = (CORDIC_WI+1 >= PH_WI) ? phase << (CORDIC_WI+1-PH_WI) :
                                                            phase >> (PH_WI-CORDIC_WI-1);

   assign cordic_phase = cordic_phase_l << 1; // We don't care about the sign; double the scale

   assign chirp_error = {parab_error, ramps_error, a_warning};

endmodule
