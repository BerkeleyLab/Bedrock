`timescale 1ns / 1ns
`define AUTOMATIC_self
`define AUTOMATIC_decode
`define AUTOMATIC_piezo_couple
`define AUTOMATIC_compr
`define AUTOMATIC_amp_lp
`define AUTOMATIC_cav_elec
`define AUTOMATIC_prng
`define AUTOMATIC_a_cav
`define AUTOMATIC_a_for
`define AUTOMATIC_a_rfl
`include "station_auto.vh"

// Single cavity emulator
// Now that cav_elec is working, this idea extends easily to multiple
// cavities sharing mechanical dynamics, but the port count balloons.
// Functionality overlaps some with cav_elec_tb.v
// Address map imported via cav_elec:
//    1-2     LO DDS
//    8-11    prompt forward and reflected setup
//   16-23    mode 0 cav_mode registers
//   24-31    mode 1 cav_mode registers
//   32-39    mode 2 cav_mode registers
// 2048-4095  mode 0 mechanical coupling in and out
// 4096-6143  mode 1 mechanical coupling in and out
// 6144-8191  mode 3 mechanical coupling in and out
// to which we add here:
//    3-4     beam timing
//    65      amplifier bandwidth
//  129-131   ADC offsets
//    159     PRNG enable
//  160-191   PRNG A initialization
//  192-223   PRNG B initialization
// 1024-2047  resonator
// 8192-9215  piezo coupling to mechanical system
// 9216-10239 noise coupling to mechanical system

// XXX want some way to view mechanical state
// Do I want to read out a piezo current, that depends on mechanics?
// Do we want to add coarse cable drift, or are phase shifts enough?
// 11999 LUTs and 34 DSP48E1 in XC7Axx
module station(
  input clk,
  input iq,
  input signed [17:0] drive,  // not counting beam
  input start,
  input signed [17:0] mech_x,
  input signed [17:0]  piezo,
  input start_outer,
  // Output ADCs at 20 MHz IF
  output signed [15:0] a_field,
  output signed [15:0] a_forward,
  output signed [15:0] a_reflect,
  output signed [17:0] cav_eig_drive,
  output signed [17:0] piezo_eig_drive,
  input [11:0] beam_timing,
  // Local Bus for simulator configuration
  `AUTOMATIC_self
);

`AUTOMATIC_decode

// Virtual Piezo
// Couple the piezo to mechanical drive
(* lb_automatic *)
outer_prod piezo_couple  // auto
	(.clk(clk), .start(start_outer), .x(piezo), .result(piezo_eig_drive),
	 `AUTOMATIC_piezo_couple
);

// Amplifier compression step
wire signed [17:0] compress_out;
(* lb_automatic *)
a_compress compr // auto
	(.clk(clk), .iq(iq), .d_in(drive), .d_out(compress_out),
	`AUTOMATIC_compr);
reg signed [17:0] compress_out_d=0;
always @(posedge clk) compress_out_d <= compress_out;
wire signed [17:0] ampf_in = compress_out_d; // was drive

// Amplifier low-pass filter, maximum bandwidth 3.75 MHz
wire signed [17:0] amp_out1;
(* lb_automatic *)
lp_pair #(.shift(2)) amp_lp  // auto
	(.clk(clk), .drive(ampf_in), .drive2(24'b0), .res(amp_out1), `AUTOMATIC_amp_lp);

// Configure number of modes processed
// I don't make it host-settable (at least not yet),
// because of its interaction with interp_span.
parameter n_mech_modes = 7;
parameter n_cycles = n_mech_modes * 2;
parameter interp_span = 4;  // ceil(log2(n_cycles))
parameter mode_count = 3;

// Allow tweaks to the cavity electrical eigenmode time scale
parameter mode_shift=18;

// Control how much frequency shifting is possible with mechanical displacement
parameter df_scale=0;     // see cav_freq.v

// Instantiate one cavity
wire signed [17:0] field, forward, reflect;
(* lb_automatic *)
cav_elec #(.mode_shift(mode_shift), .interp_span(interp_span), .df_scale(df_scale), .mode_count(mode_count)) cav_elec // auto
	(.clk(clk),
	.iq(iq), .drive(amp_out1), .beam_timing(beam_timing),
	.field(field), .forward(forward), .reflect(reflect),
	.start(start), .mech_x(mech_x), .eig_drive(cav_eig_drive),
	`AUTOMATIC_cav_elec
);

// Pseudorandom number subsystem
wire [31:0] rnda, rndb;
(* lb_automatic *)
prng prng  // auto
	(.clk(clk), .rnda(rnda), .rndb(rndb),
	`AUTOMATIC_prng);

// ADCs themselves
// Offsets could be allowed to drift
(* lb_automatic *)
adc_em #(.del(1)) a_cav // auto
	(.clk(clk), .strobe(iq), .in(field),   .rnd(rnda[12: 0]), .adc(a_field), `AUTOMATIC_a_cav);
(* lb_automatic *)
adc_em #(.del(1)) a_for // auto
	(.clk(clk), .strobe(iq), .in(forward), .rnd(rnda[25:13]), .adc(a_forward), `AUTOMATIC_a_for);
(* lb_automatic *)
adc_em #(.del(1)) a_rfl // auto
	(.clk(clk), .strobe(iq), .in(reflect), .rnd(rndb[12: 0]), .adc(a_reflect), `AUTOMATIC_a_rfl);

endmodule
