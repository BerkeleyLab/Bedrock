`timescale 1ns / 1ns

`define LB_DECODE_cav_mode_tb
`include "cav_mode_tb_auto.vh"

module cav_mode_tb;

// Nominal clock is 188.6 MHz, corresponding to 94.3 MHz ADC clock.
// 166.7 MHz is just a convenient stand-in.
reg clk;
reg lb_clk;
reg trace;
integer cc;
initial begin
	trace = $test$plusargs("trace");
	if ($test$plusargs("vcd")) begin
		$dumpfile("cav_mode.vcd");
		$dumpvars(5,cav_mode_tb);
	end
	for (cc=0; cc<2600; cc=cc+1) begin
		clk=0; #3;
		clk=1; #3;
	end
end

// Local bus, not really used in this test bench
reg [31:0] lb_data=0;
reg [14:0] lb_addr=0;
reg lb_write=0;

`AUTOMATIC_decode

reg iq=0;
reg signed [17:0] drive=0;
reg signed [27:0] mech_freq=0;
always @(posedge clk) begin
	iq <= ~iq;
	drive <= iq ? 0 : 30000;
	if (cc>1400) drive <= 0;
	mech_freq <= 2000000; // 44 kHz offset
end

// LO phase step is 7/33 per _pair_ of clock cycles.
// In real life these configuration registers will be host-settable.
wire [19:0] phase_acc;
reg [19:0] phase_step_h=222425;
reg [11:0] phase_step_l=868;
reg [11:0] modulo=4;
wire [18:0] lo_phase;
ph_gacc ph_gacc(.clk(clk), .reset(1'b0), .gate(iq), .phase_acc(lo_phase),
	.phase_step_h(phase_step_h), .phase_step_l(phase_step_l),
	.modulo(modulo));

reg signed [17:0] drive_coupling=60000;
reg signed [17:0] beam_coupling=0;
reg signed [17:0] bw=100000;
reg signed [11:0] beam_timing=0;
reg [18:0] beam_phs=0;

wire signed [18:0] probe_refl;
wire signed [17:0] v_squared;
// Speed up the time constant by a factor of 2048, by using
// shift=7 instead of shift=18.
cav_mode #(.shift(7)) cav_mode(.clk(clk),
	.iq(iq), .drive(drive), .lo_phase(lo_phase),
	.probe_refl(probe_refl),
	.beam_timing(beam_timing), .beam_phs(beam_phs),
	.mech_freq(mech_freq), .v_squared(v_squared),
	.beam_coupling(beam_coupling),
	.drive_coupling(drive_coupling), .bw(bw),
	.lb_data(lb_data), .lb_addr(lb_addr), .lb_write(lb_write), .lb_clk(clk)
);

initial begin
	#1;  // lose time zero races
	cav_mode.dp_out_couple_out_coupling.mem[0]=57000;  // field coupling
	cav_mode.dp_out_couple_out_coupling.mem[1]=0;  // reflected coupling
	cav_mode.dp_out_couple_out_phase_offset.mem[0]=0;  // field phase offset
	cav_mode.dp_out_couple_out_phase_offset.mem[1]=0;  // reflected phase offset
end

reg signed [17:0] mul_result_d=0;
reg signed [17+6:0] state_d=0;
reg signed [17:0] probe_refl_d=0;
always @(posedge clk) if (trace) begin
	mul_result_d <= cav_mode.mul_result;
	state_d      <= cav_mode.lp_pair.state;
	probe_refl_d <= probe_refl;
	if (iq) $display("%d %d  %d %d  %d %d  %d  %d",
		mul_result_d, cav_mode.mul_result,
		state_d, cav_mode.lp_pair.state,
		probe_refl_d, probe_refl,
		v_squared, lo_phase);
end

endmodule
