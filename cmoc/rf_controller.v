`timescale 1ns / 1ns

// XXX Still under construction
// Larry Doolittle, LBNL, August 2014
// see llrf_shell.v
`define AUTOMATIC_self
`define AUTOMATIC_decode
`define AUTOMATIC_lp_notch
`define AUTOMATIC_fdbk_core
`define AUTOMATIC_piezo
`include "rf_controller_auto.vh"

// lb_addr supports at least 4K words; see piezo_control.v for explanation why.
module rf_controller (
	// Everything here is in one clock domain, matches ADC
	input clk,

	// RF ADC inputs, at IF
	input signed [15:0] a_field,
	input signed [15:0] a_forward,
	input signed [15:0] a_reflect,
	input signed [15:0] a_phref,
	// RF ADC inputs from fiber link
	input [16:0] iq_recv,
	input qsync_rx,
	// RF drive without local upconversion
	output iq,
	output signed [17:0] drive,
	// SSB RF DAC drive (if you don't use it, six multipliers will disappear)
	output signed [15:0] dac1_out0,
	output signed [15:0] dac1_out1,
	output signed [15:0] dac2_out0,
	output signed [15:0] dac2_out1,
	// Piezo interface
	output signed [17:0] piezo_ctl,
	output piezo_stb,
	// Digaree monitoring capability
	output [6:0] sat_count,
	output trace_boundary,
	output signed [23:0] trace_out,
	output trace_out_gate,
	// External trigger capability (not sure how useful this will be)
	input ext_trig,
	input master_cic_tick,
	// See comments in llrf_shell.v
	output [7:0] tag_now,
	// See comments in mp_proc.v
	output [11:0] cmp_event,
	// External waveform recording
	output signed [19:0] mon_result,
	output mon_strobe,
	output mon_boundary,
	// host-writable control registers
	(* external *)
	input [31:0] phase_step,  // external
	(* external *)
	input [11:0] modulo,  // external
	(* external, signal_type="single-cycle" *)
	input ctlr_ph_reset,  // external single-cycle
	(* external *)
	input [7:0] wave_samp_per,  // external
	(* external *)
	input [11:0] chan_keep,  // external
	(* external *)
	input [2:0] wave_shift,  // external
	(* external *)
	input [1:0] use_fiber_iq,  // external
	(* external *)
	input [7:0] tag, // external
	`AUTOMATIC_self
);
`undef AUTOMATIC_self

`AUTOMATIC_decode

parameter cic_base_period = 33;  // nominal LCLS-II IF = clk * 7/33

// Brain-dead functionality here, just routing from host-writable register
// to llrf_shell-readable port.
assign tag_now = tag;

// DDS
wire [19:0] phase_step_h = phase_step[31:12];
wire [11:0] phase_step_l = phase_step[11:0];
wire signed [17:0] cosa, sina;
// floor(2^17*(32/33)^2/1.646760258-3) = 74840
// parameter [17:0] lo_amp = 74840;
// Now divide by abs(1+i/16) to keep second_if_out happy
// Other users of cosa,sina will need to account for that 0.2% cal change
parameter [17:0] lo_amp = 74694;
reg dds_reset=0;
rot_dds #(.lo_amp(lo_amp)) dds(.clk(clk), .reset(dds_reset),
	.cosa(cosa), .sina(sina),
	.phase_step_h(phase_step_h), .phase_step_l(phase_step_l),
	.modulo(modulo)
);

// Tricky stuff to allow DDS to go back to a known phase after messing with its frequency
// dds_reset gets a single-cycle hit based on master_cic_tick when requested from software
reg dds_reset_req=0;
always @(posedge clk) begin
	dds_reset <= master_cic_tick & dds_reset_req;
	if (master_cic_tick) dds_reset_req <= 0;
	if (ctlr_ph_reset) dds_reset_req <= 1;
end

// Boost amplitude of LO for use in upconverter and (postponed) fdownconvert,
// since those use cases don't have an internal gain of (33/32)^2.
// Resulting LO has amplitude 74762*1.646760258/2^17*(17/16) = 0.99800
reg signed [17:0] cosal=0, sinal=0;
always @(posedge clk) begin
	cosal <= cosa + (cosa >>> 4);
	sinal <= sina + (sina >>> 4);
end

// State divider
reg [2:0] state=0;
wire state_reset = qsync_rx & use_fiber_iq[0];
// Interchanging I and Q changes handedness of coordinate system;
// sync_state of 2 tested good on hardware in BEG lab, but leave a hook
// in case something changes.
wire [2:0] sync_state = use_fiber_iq[1] ? 1 : 2;
always @(posedge clk) state <= state_reset ? sync_state : state+1;
assign iq=state[0];
reg sync=0;
always @(posedge clk) sync <= state==6;

// CIC timing, LCLS-II configuration supporting 7/33
reg [5:0] cic_state=0;
reg cic_sample=0;
reg [7:0] wave_cnt=0;
always @(posedge clk) begin
	cic_state <= cic_state==(cic_base_period-1) ? 0 : cic_state+1;
	cic_sample <= cic_state==0;
	if (cic_sample) wave_cnt <= wave_cnt==1 ? wave_samp_per : wave_cnt-1;
end
wire sample_wave = wave_cnt==1;

// Multi-channel radio
// Note that we no longer look at phref
wire [43:0] sr_out;
wire sr_valid;
cim_12x #(.dw(44)) cim(.clk(clk), .reset(1'b0), .sample(cic_sample),
	.adca(a_field), .adcb(a_forward), .adcc(a_reflect),
	.inm(iq_recv[16:1]), .outm(drive[17:2]), .iqs(~iq),
	.adcx(16'b0),  // not much point to use this unless we set up a second DDS
	.cosa(cosa), .sina(sina),
	.cosb(18'b0), .sinb(18'b0),
	.sr_out(sr_out), .sr_valid(sr_valid)
);
wire [39:0] sr_out_trunc = sr_out[43:4];  // Truncate truncated and you get trunc

// Process radios for waveform monitoring
wire signed [19:0] mon_12_result;
wire mon_12_strobe;
ccfilt #(.dw(40), .dsr_len(12), .shift_base(4)) ccfilt(.clk(clk),
	.sr_in(sr_out_trunc), .sr_valid(sr_valid & sample_wave),
	.shift({wave_shift,1'b1}), .reset(1'b0),
	.result(mon_12_result), .strobe(mon_12_strobe)
);

fchan_subset #(.a_dw(20), .o_dw(20), .len(12)) fchan_subset(
	.clk(clk), .keep(chan_keep), .reset(1'b0),
	.a_data(mon_12_result), .a_gate(mon_12_strobe), .a_trig(~mon_12_strobe),
	.o_data(mon_result), .o_gate(mon_strobe), .o_trig(mon_boundary)
);

// Process radios for (simple) piezo loop
(* lb_automatic *)
piezo_control piezo // auto
	(.clk(clk),
	.sr_in(sr_out_trunc[35:0]), .sr_valid(sr_valid),
	.piezo_ctl(piezo_ctl), // .piezo_stb(piezo_stb),
	.sat_count(sat_count), .piezo_stb(trace_boundary),
	.trace_out(trace_out), .trace_out_gate(trace_out_gate),
	`AUTOMATIC_piezo
);
assign piezo_stb = cic_sample; // one in 33?

// Washout filter
wire signed [15:0] b_field;
fwashout washout(.clk(clk), .rst(1'b0), .track(1'b1),
	.a_data(a_field), .a_gate(1'b1), .a_trig(1'b0),
	.o_data(b_field)
);

// Digital downconverter
wire signed [15:0] field_xy;
fdownconvert down(.clk(clk), .mod2(iq),
	.cosd(cosa), .sind(sina),  // LO signals
	.a_data(b_field), .o_data(field_xy),
	.a_gate(1'b1), .a_trig(1'b0)  // not really used
);

// Feedback loop core
// Select input source: local ADC or remote over fiber
wire signed [17:0] fdbk_in = use_fiber_iq[0] ? {iq_recv,1'b0} : {field_xy,2'b0};
// iq flag is synchronized via state_reset above
wire signed [17:0] fdbk_out_xy;
(* lb_automatic *)
fdbk_core fdbk_core  // auto
	(.clk(clk),
	.sync(sync),
	.iq(iq), .in_xy(fdbk_in), .out_xy(fdbk_out_xy), .cmp_event(cmp_event),
	// unused features
	.chirp_en(1'b0), .chirp_amp(18'b0), .chirp_ph(19'b0),
	.ffd_en(1'b0), .ff_setm(18'b0), .ff_setp(18'b0), .ff_ddrive(18'b0), .ff_dphase(18'b0),
	.ffp_en(1'b0), .ff_drive(18'b0), .ff_phase(18'b0),
	//
	`AUTOMATIC_fdbk_core
);

// Output low-pass and notch filter combo
wire signed [19:0] drive_w;
(* lb_automatic *)
lp_notch lp_notch  // auto
	(.clk(clk), .iq(iq),
	.x(fdbk_out_xy), .y(drive_w),
	`AUTOMATIC_lp_notch
);
assign drive = drive_w[19:2];

// second_if_out and ssb_out are pin-compatible
second_if_out upconvert(.clk(clk),
	.div_state(state[1:0]), .drive(drive),
	.enable(1'b1), .lo_sel(1'b0),
	.cosa(cosal), .sina(sinal),
	.dac1_out0(dac1_out0), .dac1_out1(dac1_out1),
	.dac2_out0(dac2_out0), .dac2_out1(dac2_out1)
);

endmodule
