`timescale 1ns / 1ns

// Additional logic in the main CONTROLLER clock domain that wraps around
// the LLRF controller proper:
//   timing generator
//   function generator
//   slow (byte-serial) readout chain, including ADC min/max values
// Larry Doolittle, LBNL, August 2014
// In Artix under XST 14.7, synthesizes to 6504 LUTs, 20 DSP48E1,
// and clocks at well over 125 MHz.

// always need this
//`define LB_DECODE_llrf_shell
`define AUTOMATIC_self
`define AUTOMATIC_decode
`define AUTOMATIC_controller

`include "llrf_shell_auto.vh"

module llrf_shell(
	input clk,
	// RF ADC inputs, at IF
	input signed [15:0] a_field,
	input signed [15:0] a_forward,
	input signed [15:0] a_reflect,
	// RF DAC drive, but don't upconvert ourselves
	output iq,
	output [17:0] drive,
	// RF ADC inputs from fiber link
	input [16:0] iq_recv,
	input qsync_rx,
	input [7:0] tag_rx,  // XXX add this to slow chain!
	// SSB RF DAC drive (if you don't use it, six multipliers will disappear)
	output [15:0] dac1_out0,
	output [15:0] dac1_out1,
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
	// External waveform recording
	output signed [19:0] mon_result,
	output mon_strobe,
	output mon_boundary,
	// Stream of slow data: timestamp and adc min/max for now
	// Keep data path narrow for routing reasons, not logic element count
	input slow_op,
	input slow_snap,
	output [7:0] slow_out,

	`AUTOMATIC_self
);

`AUTOMATIC_decode

// Compute raw ADC min/max
wire mm_snap=slow_snap;
wire signed [15:0] adc1_min, adc1_max;
wire signed [15:0] adc2_min, adc2_max;
wire signed [15:0] adc3_min, adc3_max;
minmax #(16) mm1(.clk(clk), .xin(a_field),   .reset(mm_snap), .xmin(adc1_min), .xmax(adc1_max));
minmax #(16) mm2(.clk(clk), .xin(a_forward), .reset(mm_snap), .xmin(adc2_min), .xmax(adc2_max));
minmax #(16) mm3(.clk(clk), .xin(a_reflect), .reset(mm_snap), .xmin(adc3_min), .xmax(adc3_max));

// Nest to get the real work
wire [7:0] tag_now;
wire [11:0] cmp_event;
(* lb_automatic *)
rf_controller controller // auto
	(.clk(clk),
	.a_field(a_field), .a_forward(a_forward), .a_reflect(a_reflect), .a_phref(16'b0),
	.iq_recv(iq_recv), .qsync_rx(qsync_rx),
	.iq(iq), .drive(drive),
	.dac1_out0(dac1_out0), .dac1_out1(dac1_out1),
	.piezo_ctl(piezo_ctl), .piezo_stb(piezo_stb),
	.sat_count(sat_count), .trace_boundary(trace_boundary),
	.trace_out(trace_out), .trace_out_gate(trace_out_gate),
	.ext_trig(ext_trig), .master_cic_tick(master_cic_tick),
	.mon_result(mon_result), .mon_strobe(mon_strobe), .mon_boundary(mon_boundary),
	.tag_now(tag_now), .cmp_event(cmp_event),
	`AUTOMATIC_controller
);

// Logic for controller_status involves latching signals from cmp_event
// Similar synchronous-to-waveform concept as ADC min/max, above
reg [15:0] controller_status=0;
always @(posedge clk) controller_status <= (slow_snap ? 12'b0 : controller_status) | {4'b0, cmp_event};

// Cycle counter
wire [7:0] timestamp_out;
timestamp ts(.clk(clk), .aux_trig(1'b0), .slow_op(slow_op), .slow_snap(slow_snap),
	.shift_in(8'b0), .shift_out(timestamp_out)
);

// Our share of slow readout
// tag_now and tag_old are set up for causality and consistency detection when
// changing other controls. tag_now shows the value of tag at the end-time of
// the buffer, tag_old shows it at the begin-time of the buffer.  Not perfect
// because of non-boxcar filtering and sloppy pipelining.
`define SLOW_SR_LEN 7*16
`define SLOW_SR_DATA { adc1_min, adc1_max, adc2_min, adc2_max, adc3_min, adc3_max, tag_now, tag_old }
parameter sr_length = `SLOW_SR_LEN;
reg [sr_length-1:0] slow_read=0;
reg [7:0] tag_old=0;
always @(posedge clk) if (slow_op) begin
	slow_read <= slow_snap ? `SLOW_SR_DATA : {slow_read[sr_length-9:0],timestamp_out};
	if (slow_snap) tag_old <= tag_now;
end
assign slow_out = slow_read[sr_length-1:sr_length-8];

endmodule
