`timescale 1ns / 1ns

// Core of an SEL feedback system
// Larry Doolittle, LBNL, 2014
// See boxes.eps

// Spartan-6: 2326 LUTs, 4 DSP48A1s
// less than 10% of an XC6SLX45(T)

// Small dpram memory map used in mp_proc
//   name   \ addr   0          1          2           3
//   setmp         set_X      set_Y       set_p       gain_p
//   coeff         coeff_X_I  coeff_Y_I   coeff_X_P   coeff_Y_P
//   lim           lim_X_hi   lim_Y_hi    lim_X_lo    lim_Y_lo

// Thus to generate a chirp, the AM part goes to lim_X_hi and lim_X_lo,
// propagating to drv_x.  The phase part goes to ph_offset, with sel_en=0,
// which then propagates to drv_p.

`define AUTOMATIC_self
`define AUTOMATIC_decode
`define AUTOMATIC_mp_proc
`define LB_DECODE 1
`include "fdbk_core_auto.vh"

module fdbk_core #(
	parameter thresh_shift = 9, // Threshold shift; typically 9 for SRF use
	parameter ff_dshift = 0, // Deferred ff_ddrive downshift
	// Knobs to use/bypass CORDIC multiplexer, Magnitude/Phase processor (slow),
	// and Low-Latency Processor (bypassing conversion to polar coordinates)
	parameter use_cordic_mux = 1,
	parameter use_mp_proc = 1,
	parameter use_ll_prop = 1
)(
	input clk,  // timespec 8.0 ns
	input sync,  // one in eight
	input iq, // high on first
	input signed [17:0] in_xy,
	output signed [17:0] out_xy,
	output [11:0] cmp_event,  // see mp_proc.v
	(* external *)
	input [1:0] coarse_scale,  // external
	input chirp_en,
	input signed [17:0] chirp_amp,
	input signed [18:0] chirp_ph,
	input               ffd_en,
	input signed [17:0] ff_setm, // FeedForward mag setpoint
	input signed [17:0] ff_setp, // FeedForward ph setpoint - unused
	input signed [17:0] ff_ddrive, // FF drive (derivative) to be accumulated in I term
	input signed [17:0] ff_dphase, // FF phase (derivative); currently unused
	input               ffp_en,
	input signed [17:0] ff_drive,  // FF drive added to P term
	input signed [17:0] ff_phase,  // FF phase
	`AUTOMATIC_self
);
`undef AUTOMATIC_self

`AUTOMATIC_decode

// Sync strobe: Used to establish pipeline balancing based on the different configurations
// Results in sync1, sync2 and sync3 for the different processing stages
reg [7:0] stb=0;
always @(posedge clk) stb <= {stb[6:0],sync};

wire sync1=sync;
wire signed [21:0] ser_data;

// Decimate by 4 to allow for processing time in Cartesian coordinates
// Put Xs on unused inputs in simulation to show data path clearly on waveform viewer
`ifdef SIMULATE
wire signed [17:0] ifill = 18'bx;
`else
wire signed [17:0] ifill = 0;
`endif
iq_chain4 decim(.clk(clk), .sync(sync1), .in1(in_xy), .in2(ifill), .in3(ifill), .in4(ifill), .out(ser_data));
// output is three cycles delayed

wire signed [17:0] out_iq, out_mp;
wire signed [18:0] cordic_in_ph;
wire signed [17:0] cordic_in_xy;

// Shares one CORDIC to convert from Cartesian to polar and vice-versa
// Note the shift by 4 on ser_data to compensate for the decimation factor (2^4)
cordic_mux cordic(.clk(clk), .phase(~iq), .in_iq(ser_data[21:4]), .out_iq(out_iq),
	.in_xy(cordic_in_xy), .in_ph(cordic_in_ph), .out_mp(out_mp));

wire signed [17:0] proc_out_xy, chirp_in_xy;
wire signed [18:0] proc_out_ph, chirp_in_ph;

assign chirp_in_xy = ~iq ? chirp_amp : 18'b0;
assign chirp_in_ph = chirp_ph;

// Multiplexer to enable/bypass controls on magnitude and phase (slow path)
assign cordic_in_ph = chirp_en ? chirp_in_ph : use_mp_proc ? proc_out_ph : {out_mp,1'b0};
assign cordic_in_xy = chirp_en ? chirp_in_xy : use_mp_proc ? proc_out_xy : iq ? out_mp : 0;

// Establish strobe for magnitude and phase processor input
wire sync3 = stb[1];

// Instantiate magnitude and phase processor
// XXX: Review thresh_shift for SRF use
(* lb_automatic *)
mp_proc #(.thresh_shift(thresh_shift), .ff_dshift(ff_dshift)) mp_proc // auto
	(.clk(clk), .sync(sync3),
	.in_mp(out_mp), // .state(state),
	// Feedforward - not well tested
	.ffd_en(ffd_en),
	.ff_setm(ff_setm),
	.ff_setp(ff_setp),
	.ff_ddrive(ff_ddrive),
	.ff_dphase(ff_dphase),
	.ffp_en(ffp_en),
	.ff_drive(ff_drive), .ff_phase(ff_phase),
	//
	.out_xy(proc_out_xy), .out_ph(proc_out_ph),
	.cmp_event(cmp_event),
	`AUTOMATIC_mp_proc
);

// Multiplexer to enable/bypass CORDIC
wire signed [21:0] demux_me = use_cordic_mux ? {out_iq,4'b0} : ser_data;

localparam out_fire = 2 - use_cordic_mux*2 + use_mp_proc*0;
wire sync2 = stb[out_fire];
wire signed [17:0] out1, out2,  out3, out4;
// add 4 to ser_data to remove quantization bias?
// Interpolate output of slow data-path
iq_intrp4 interp(.clk(clk), .sync(sync2), .in(demux_me),
	.out1(out1), .out2(out2), .out3(out3), .out4(out4));

// Low-Latency proportional processor (integral path has plenty of time without affecting performance)
wire signed [17:0] prop_out_iq;
ll_prop prop(.clk(clk), .iq(iq), .in_iq(in_xy), .out_iq(prop_out_iq),
	.coarse_scale(coarse_scale),
	.set_iq(out2), .gain_iq(out3), .drive_iq(out1));

// Select either Low-Latency or SEL outputs
assign out_xy = chirp_en ? out_iq : use_ll_prop ? prop_out_iq : out1;

endmodule
