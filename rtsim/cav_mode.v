`timescale 1ns / 1ns

// Represents a single cavity mode
// Larry Doolittle, LBNL, May 2014
// Uses up six multipliers
// Fabric use is dominated by two 18-bit fully unrolled CORDIC processors
// Intended to be clocked at twice the ADC clock rate, should work
// at full speed in any of V5, V6, A7, K7.  Should come close on S6.

// This covers the electrical side, and includes an interface to the
// mechanical side (mech_freq, v_squared).

// The expectation is that several of these modules will be instantiated,
// one per passband mode (or at least the top two).  Their field and
// reflected outputs will be summed (and note the individual control on
// the phase of these contributions).  The final reflected wave will
// also include a direct reflection component from the forward wave.
// Also, coarse (many cycle) delays need to be constructed.  The drive
// to this module should include the beam-loading component (which does
// not get reflected).

// At some point, we want to add the ability to simulate a quench.

// Per-mode memory map:
//   0   not used
//   1   m_coarse_freq (see cav_elec.v)
//   2   drive_coupling
//   3   bw
//   4-7 out_couple

// Synthesis places this in the 4.8 ns range (on a '7A100T-2),
// pretty far from what I think should be the 3.8 ns limit from the
// CORDIC elements.  The IIR element in lp_pair tests by itself at
// 3.0 ns, so that's not it.

`include "cav_mode_auto.vh"

module cav_mode(
	input clk,
	// Input signal on waveguide given in IQ form
	input iq,  // high for I, low for Q
	input signed [17:0] drive,  // High power amplifier only
	input [11:0] beam_timing,  // common to all modes
	input [18:0] lo_phase,  // should change every other cycle, see below
	// Field probe and reflected wave signals at 20 MHz IF, interleaved
	output signed [18:0] probe_refl,
	input [18:0] beam_phs,
	// Coupling to mechanical system
	// mech_freq step size is 94.3 MHz / 2^32 = 0.022 Hz,
	// range is +/- 2^27 steps = +/- 2.9 MHz from nominal 1300 MHz
	// (adequate to represent 8pi/9 and 7pi/9 modes).
	input signed [27:0] mech_freq,
	output signed [17:0] v_squared,
	input signed [17:0] drive_coupling,  // external
	input signed [17:0] beam_coupling,  // external
	input signed [17:0] bw,  // external
	`AUTOMATIC_self
);

`AUTOMATIC_decode

parameter shift=18; // passed transparently to lp_pair.v

// Compute beam drive magnitude
// Wastes at least half a multiplier
reg signed [29:0] beam_mag_wide=0;
always @(posedge clk) beam_mag_wide <= beam_coupling * $signed({1'b0,beam_timing});
wire signed [17:0] beam_mag = beam_mag_wide[21:4];  // XXX cheat scaling?

// Phase accumulator from mechanical system
reg signed [31:0] mech_phase_fine=0;
always @(posedge clk) if (~iq) mech_phase_fine <= mech_phase_fine + mech_freq;
wire [18:0] mech_phase = mech_phase_fine[31:13];

// Half the CORDIC cycles will be used to compute the drive coupling,
// and the other half will compute the beam loading vector.
reg signed [17:0] cordic_x = 0;
always @(posedge clk) cordic_x <= iq ? beam_mag : drive_coupling;
reg [18:0] cordic_phs = 0;
always @(posedge clk) cordic_phs <= mech_phase + (iq ? beam_phs : 0);

wire signed [17:0] xout, yout;
cordicg_b22 #(.nstg(20), .width(18)) icordic(.clk(clk), .opin(2'b0),
	.xin(cordic_x), .yin(18'b0), .phasein(cordic_phs),
	.xout(xout), .yout(yout));

// Buffer layer, generates Re/Im sequential pair from CORDIC output.
// Note that a consistent pair should come from a single value of lo_phase.
reg signed [17:0] yout_d=0, mul_coef=0, beam_drv=0;
always @(posedge clk) begin
	yout_d <= yout;
	mul_coef <= ~iq ? xout : yout_d;
	beam_drv <=  iq ? xout : yout_d;
end

// Vector multiply drive by the time-varying vector to convert it
// from reference coordinates to cavity-centered coordinates.
wire signed [17:0] mul_result;
complex_mul in_couple(.clk(clk), .gate_in(1'b1), .iq(iq),
	.x(drive), .y(mul_coef), .z(mul_result));

// Depend on the fact that when the beam loading input magnitude is zero,
// the CORDIC output is precisely zero, and therefore doesn't contribute
// to roundoff error.
// One cycle delay aligns real and imaginary parts with amplifier drive.
reg signed [23:0] drive2=0;
always @(posedge clk) drive2 <= {beam_drv,6'b0};

// Now that we're in the natural coordinates of the cavity resonance,
// the cavity itself is just a vector IIR low-pass filter.
wire signed [17:0] res;
lp_pair #(.shift(shift)) lp_pair(.clk(clk), .drive(mul_result),
	.drive2(drive2), .bw(bw), .res(res));

// Two channels of output coupling, field probe and reflected wave.
// Also upconverts to IF, as provided by lo_phase input.
reg [18:0] out_phase=0;
always @(posedge clk) out_phase <= lo_phase - mech_phase;
pair_couple out_couple // auto
	(.clk(clk), .iq(iq),
	.drive(res), .lo_phase(out_phase),
	.pair(probe_refl),
	`AUTOMATIC_out_couple
);

// square and (1+z^{-1}) filter res, goes to v_squared
wire signed [18:0] mag2;
mag_square square(.clk(clk), .iq(iq), .d_in(res), .mag2_out(mag2));
// mag2 is guaranteed positive!
assign v_squared = mag2[18:1];

endmodule
