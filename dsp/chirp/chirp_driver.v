// ------------------------------------
// chirp_driver.v
//
// Self-contained chirp generator (quadratic phase generator + amplitude
// shaper) with CORDIC sine/cosine generator and all auxiliary components.
// The variant of the CORDIC used here is 18-bit, 20 stages.

// ------------------------------------

module chirp_driver #(
   parameter DD_SHIFT = 8,
   parameter AMP_WI = 20,
   parameter PH_WI = 32,
   parameter LEN_WI = 32,
   parameter CHIRP_RATE = 8
) (
   input                         clk,
   input                         chirp_start, // Edge-triggered

   // Chirp parameters
   input                         chirp_en,
   input [LEN_WI-1:0]            chirp_len,       // Full chirp length (inc. rise and fall)
   input signed [PH_WI-1:0]      chirp_dphase,
   input signed [PH_WI-1:0]      chirp_ddphase,
   input [AMP_WI-1:0]            chirp_amp_slope, // Slope of rise and fall amplitude ramps
   input [AMP_WI-1:0]            chirp_amp_max,   // Maximum amplitude of chirp envelope

   output signed [CORDIC_WI-1:0] cordic_cos,
   output signed [CORDIC_WI-1:0] cordic_sin,
   output                        cordic_trig, // Cordic update strobe; Monitoring only, can be ignored

   output                        chirp_status,
   output [2:0]                  chirp_error
);

   localparam CORDIC_WI = 18;
   localparam CORDIC_STAGE = 20;

   wire chirp_gate;
   wire [15:0] chirp_rate_16b = CHIRP_RATE;

   multi_sampler #(
      .sample_period_wi(16))
   i_multi_sampler (
      .clk             (clk),
      .reset           (1'b0),
      .ext_trig        (chirp_en), // Always enabled
      .sample_period   (chirp_rate_16b),
      .dsample0_period (8'h0),
      .dsample1_period (8'h0),
      .dsample2_period (8'h0),
      .sample_out      (chirp_gate)
   );

   // ---------------------
   // Chirp generator
   // ---------------------
   wire signed [CORDIC_WI-1:0]   cordic_amp;
   wire signed [CORDIC_WI+1-1:0] cordic_phase;

   chirp_wrap # (
      .DD_SHIFT  (DD_SHIFT),
      .AMP_WI    (AMP_WI),
      .PH_WI     (PH_WI),
      .LEN_WI    (LEN_WI),
      .CORDIC_WI (CORDIC_WI))
   i_chirp_wrap (
      .clk             (clk),
      .ext_trig        (chirp_gate),
      .chirp_start     (chirp_start),

      // Chirp parameters
      .chirp_len       (chirp_len),
      .chirp_dphase    (chirp_dphase),
      .chirp_ddphase   (chirp_ddphase),
      .chirp_amp_slope (chirp_amp_slope),
      .chirp_amp_max   (chirp_amp_max),

      .cordic_trig     (cordic_trig),
      .cordic_amp      (cordic_amp),
      .cordic_phase    (cordic_phase),

      .chirp_status    (chirp_status),
      .chirp_error     (chirp_error)
   );

   // ---------------------
   // CORDIC
   // ---------------------
   wire signed [CORDIC_WI-1:0] cosa, sina;

   cordicg_b22 #(
      .width  (CORDIC_WI),
      .nstg   (CORDIC_STAGE))
   i_cordicg_b22 (
      .clk      (clk),
      .opin     (2'b00),
      .xin      (18'b0),
      .yin      (cordic_amp),
      .phasein  ({cordic_phase}),
      .xout     (cordic_cos),
      .yout     (cordic_sin),
      .phaseout ()
   );

endmodule
