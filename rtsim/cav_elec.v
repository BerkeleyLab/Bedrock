`timescale 1ns / 1ns

// Represents the electromagnetic component of a cavity
// Larry Doolittle, LBNL, May-June 2014
// 27 multipliers
//   1  beam loading (done with gates?)
//   2  prompt coupling
//  24  8 per mode, three modes
// Synthesis in XC7A100T uses 26 DSP48E1s, 6 RAMB18E1, and 10739 Slice LUTs
// (16% of chip).
// Doesn't count 2 multipliers and 4 BRAM for the mechanical state-space
// engine that this connects to.
//
// Eventually want to emulate arc faults in the waveguide.

// External to this module, someone should add:
//   coarse delays
//   mechanical mode emulation
//   ADC noise
//   HPA characteristics, especially compression and delay
// and for extra credit:
//   finite directivity of forward and reflected coupler

// The size of this module is such that four or eight of them could be
// instantiated (with associated cavity controllers) in a single moderate
// sized FPGA, allowing real-time simulation of a realistic module with
// coupled mechanical modes.

`define AUTOMATIC_self
`define AUTOMATIC_decode
`define AUTOMATIC_map
`define AUTOMATIC_dot
`define AUTOMATIC_mode
`define AUTOMATIC_freq
`define AUTOMATIC_outer_prod
`define AUTOMATIC_drive_couple
`include "cav_elec_auto.vh"

module cav_elec(
	input clk,
	// Input signal on waveguide given in IQ form
	input iq,  // high for I, low for Q
	input signed [17:0] drive,  // not counting beam
	input [11:0] beam_timing,
	// Output signals at 20 MHz IF
	output signed [17:0] field,
	output signed [17:0] forward,
	output signed [17:0] reflect,
	// Coupling from mechanical system in eigenmode form
	// This module is responsible for the matrix multiplication from
	// this coordinate system to get each individual response term.
	// I have only shaken the pi mode before, this is more general.
	input start,
	input signed [17:0] mech_x,
	// Coupling to mechanical system
	output signed [17:0] eig_drive,
	//
	(*external*)
	input [31:0] phase_step,  // external
	(*external*)
	input [11:0] modulo,  // external
	`AUTOMATIC_self
);

`AUTOMATIC_decode
`AUTOMATIC_map

// LO phase step is 7/33 per _pair_ of clock cycles.
wire [18:0] lo_phase;
wire [19:0] phase_step_h = phase_step[31:12];
wire [11:0] phase_step_l = phase_step[11:0];
ph_gacc ph_gacc(.clk(clk), .reset(1'b0), .gate(iq), .phase_acc(lo_phase),
	.phase_step_h(phase_step_h), .phase_step_l(phase_step_l),
	.modulo(modulo));

// One cycle delay, to match lo_phase pipeline stage inside cav_mode
reg [18:0] lo_phase_d=0;
always @(posedge clk) lo_phase_d <= lo_phase;

// Historical
reg signed [17:0] cav_drive=0, prompt_drive=0;
always @(posedge clk) begin
	cav_drive <= drive;
	prompt_drive <= drive;  // match pipelines
end

// Placeholder for now.
reg [18:0] beam_phs = 3000;

// Generate prompt terms for forward and reflected waves
wire signed [18:0] fwd_ref;
(* lb_automatic *)
pair_couple drive_couple // auto
	(.clk(clk), .iq(iq),
	.drive(prompt_drive), .lo_phase(lo_phase_d),
	.pair(fwd_ref),
	`AUTOMATIC_drive_couple
);

// Set phasing of start pulses for the various engines
wire start_outer;
reg_delay #(.dw(1), .len(0))
	start_outer_g(.clk(clk), .gate(1'b1), .reset(1'b0), .din(start), .dout(start_outer));
wire start_dot;  // should happen 9 cycles after start_eig
reg_delay #(.dw(1), .len(10))
	start_dot_g(.clk(clk), .gate(1'b1), .reset(1'b0), .din(start), .dout(start_dot));

parameter mode_shift=18;  // see cav_mode.v
parameter interp_span=5;  // see interp2.v
parameter df_scale=0;     // see cav_freq.v

// Use a generate loop to make a bunch of passband modes.
// Can't go wild with the number of modes, because of the
// single-cycle accumulation of probe_refl and eig_drive signals.
// That accumulator needs to have ceil(log2(mode_count)) more
// bits than probe_refl itself.
parameter mode_count = 3;
parameter mode_ln = 2;  // ceil(log2(mode_count))
wire signed [18+mode_ln:0] probe_refl_acc[0:mode_count];
assign probe_refl_acc[0]=0;

wire signed [17+mode_ln:0] eig_drive_acc[0:mode_count];
assign eig_drive_acc[0]=0;

genvar mode_n;
generate for (mode_n=0; mode_n<mode_count; mode_n=mode_n+1) begin: cav_mode
	wire signed [18:0] m_probe_refl;
	// Dot product of state vector with our row of the sensitivity matrix
	// to get frequency perturbation of this mode
	wire signed [17:0] d_result;
	wire d_strobe;
	(* lb_automatic, gvar="mode_n", gcnt=3 *)
	dot_prod dot  // auto(mode_n,3)
		(.clk(clk), .start(start_dot), .x(mech_x),
		.result(d_result), .strobe(d_strobe),
		`AUTOMATIC_dot
	);
	// Interpolate
	wire signed [17:0] m_fine_freq;
	cic_interp #(.span(interp_span)) interp(.clk(clk), .d_in(d_result), .strobe(d_strobe), .d_out(m_fine_freq));
	// Add coarse frequency (control parameter to cav_freq)
	// Pro tip: limit coarse frequency to +/-134086656, so adding
	// the fine frequency to it can't overflow.
	// m_freq step size is 94.3 MHz / 2^32 = 0.022 Hz,
	// range is +/- 2^27 steps = +/- 2.94 MHz from nominal
	wire signed [27:0] m_freq;
	(* lb_automatic, gvar="mode_n", gcnt=3 *)
	cav_freq #(.df_scale(df_scale)) freq  // auto(mode_n,3)
		(.clk(clk), .fine(m_fine_freq), .out(m_freq), `AUTOMATIC_freq);
	//
	// Actual electrical mode
	wire signed [17:0] v_squared;
	(* lb_automatic, gvar="mode_n", gcnt=3 *)
	cav_mode #(.shift(mode_shift)) mode  // auto(mode_n,3)
		(.clk(clk),
		.iq(iq), .drive(cav_drive), .lo_phase(lo_phase),
		.beam_timing(beam_timing), .beam_phs(beam_phs),
		.probe_refl(m_probe_refl),
		.mech_freq(m_freq), .v_squared(v_squared),
		`AUTOMATIC_mode
	);
	// Accumulate probe and reflected waves, still multiplexed
	assign probe_refl_acc[mode_n+1] = probe_refl_acc[mode_n] + m_probe_refl;
	//
	// Outer product of v^2 to get per-mechanical-eigenmode drive terms
	wire signed [17:0] m_eig_drive;
	(* lb_automatic, gvar="mode_n", gcnt=3 *)
	outer_prod outer_prod  // auto(mode_n,3)
		(.clk(clk), .start(start_outer),
		.x(v_squared), .result(m_eig_drive),
		`AUTOMATIC_outer_prod
	);
	// Accumulate eigenmode drives
	assign eig_drive_acc[mode_n+1] = eig_drive_acc[mode_n] + m_eig_drive;
end endgenerate

// Register the combinatorial adders
reg signed [18+mode_ln:0] probe_refl=0, eig_drive_r=0;
always @(posedge clk) begin
	probe_refl <= probe_refl_acc[mode_count];
	eig_drive_r <= eig_drive_acc[mode_count];
end
assign eig_drive = eig_drive_r;

// XXX If the directional coupler is upstairs, there are 8 to 10 cycles
// of delay between the forward wave and the prompt reflection.
`define SAT(x,old,new) ((~|x[old:new] | &x[old:new]) ? x[new:0] : {x[old],{new{~x[old]}}})
reg signed [17:0] probe_r=0, refl_r=0, fwd_r=0;
wire signed [20:0] refl_sum = probe_refl + fwd_ref;
always @(posedge clk) begin
	if ( iq) probe_r <= `SAT(probe_refl, 20,17);
	if (~iq) refl_r  <= `SAT(refl_sum,   20,17);
	if ( iq) fwd_r   <= `SAT(fwd_ref,    18,17);
end

assign field   = iq ? probe_r : 0;
assign forward = iq ? fwd_r   : 0;
assign reflect = iq ? refl_r  : 0;

endmodule
