`timescale 1ns / 1ns
`define AUTOMATIC_decode
`define AUTOMATIC_resonator
`define LB_DECODE_cav_elec_tb
`include "cav_elec_tb_auto.vh"

module cav_elec_tb;

// Nominal clock is 188.6 MHz, corresponding to 94.3 MHz ADC clock.
// 166.7 MHz is just a convenient stand-in.
reg clk;
reg lb_clk;
reg trace;
integer cc;
`ifdef SIMULATE
initial begin
	trace = $test$plusargs("trace");
	if ($test$plusargs("vcd")) begin
		$dumpfile("cav_elec.vcd");
		$dumpvars(5,cav_elec_tb);
	end
	for (cc=0; cc<4600; cc=cc+1) begin
		clk=0; #3;
		clk=1; #3;
	end
	$finish(0);
end
`endif //  `ifdef SIMULATE

// Local bus
reg [31:0] lb_data=0;
reg [14:0] lb_addr=0;
reg lb_write=0;

`AUTOMATIC_decode

// Configure number of modes processed
parameter n_mech_modes = 7;   // number of mechanical modes
parameter n_cycles = n_mech_modes*2;
reg start=0;
always @(posedge clk) start <= cc%n_cycles==0;
parameter interp_span=4;  // ceil(log2(n_cycles))

reg iq=0;
reg signed [17:0] drive=0;
always @(posedge clk) begin
	iq <= ~iq;
	drive <= iq ? 0 : 30000;
	if (cc<300) drive <= 0;
end

reg [19:0] phase_step_h=222425;
reg [11:0] phase_step_l=7;
reg [11:0] modulo=4063;
wire [31:0] phase_step={phase_step_h,phase_step_l};

reg [11:0] beam_timing=0;
wire signed [17:0] field, forward, reflect;
wire signed [17:0] eig_drive, mech_x;
// Speed up the time constant by a factor of 512, by using
// shift=9 instead of shift=18.
cav_elec #(.mode_shift(9), .interp_span(interp_span)) cav_elec(.clk(clk),
	.iq(iq), .drive(drive), .beam_timing(beam_timing),
	.field(field), .forward(forward), .reflect(reflect),
	.start(start), .mech_x(mech_x), .eig_drive(eig_drive),
	.phase_step(phase_step), .modulo(modulo),
	.lb_clk(clk), .lb_data(lb_data), .lb_addr(lb_addr), .lb_write(lb_write)
);

wire start_eig;
reg_delay #(.dw(1), .len(0))
	start_eig_g(.clk(clk), .gate(1'b1), .reset(1'b0), .din(start), .dout(start_eig));

wire clip;
wire res_write = lb_write & (lb_addr[12:10]==1);
(* lb_automatic *)
resonator resonator // auto
	(.clk(clk), .start(start_eig),
	.drive(eig_drive),
	.position(mech_x), .clip(clip),
	`AUTOMATIC_resonator
);

`ifdef SIMULATE
always @(negedge clk) if (trace && iq && (cc>30)) $display("%d %d %d %d",
	forward,reflect,field,cav_elec.cav_mode[0].m_freq);

integer ix;
integer scale=7;
initial begin
	#1;  // lose time zero races
	cav_elec.freq_0_coarse_freq=0;
	cav_elec.mode_0_drive_coupling=60000;
	cav_elec.mode_0_bw=-100000;
	// Prompt coupling
	cav_elec.dp_drive_couple_out_coupling.mem[0]=47000;   // forward
	cav_elec.dp_drive_couple_out_coupling.mem[1]=-34000;  // reflected
	cav_elec.dp_drive_couple_out_phase_offset.mem[0]=0;
	cav_elec.dp_drive_couple_out_phase_offset.mem[1]=0;
	// Mode 0 (pi)
	cav_elec.dp_mode_0_out_couple_out_coupling.mem[0]=68000;  // reflected coupling
	cav_elec.dp_mode_0_out_couple_out_coupling.mem[1]=57000;  // field coupling
	cav_elec.dp_mode_0_out_couple_out_phase_offset.mem[0]=0;  // reflected phase offset
	cav_elec.dp_mode_0_out_couple_out_phase_offset.mem[1]=0;  // field phase offset
	// Mode 1 (8pi/9)
	cav_elec.dp_mode_1_out_couple_out_coupling.mem[0]=0;      // reflected coupling
	cav_elec.dp_mode_1_out_couple_out_coupling.mem[1]=0;      // field coupling
	cav_elec.dp_mode_1_out_couple_out_phase_offset.mem[0]=0;  // reflected phase offset
	cav_elec.dp_mode_1_out_couple_out_phase_offset.mem[1]=0;  // field phase offset
	// Mode 2 (7pi/9)
	cav_elec.dp_mode_2_out_couple_out_coupling.mem[0]=0;      // reflected coupling
	cav_elec.dp_mode_2_out_couple_out_coupling.mem[1]=0;      // field coupling
	cav_elec.dp_mode_2_out_couple_out_phase_offset.mem[0]=0;  // reflected phase offset
	cav_elec.dp_mode_2_out_couple_out_phase_offset.mem[1]=0;  // field phase offset
	for (ix=0; ix<n_cycles; ix=ix+1) begin
		cav_elec.dp_dot_0_k_out.mem[ix]=0;
		cav_elec.dp_dot_1_k_out.mem[ix]=0;
		cav_elec.dp_dot_2_k_out.mem[ix]=0;
		cav_elec.dp_outer_prod_0_k_out.mem[ix]=0;
		cav_elec.dp_outer_prod_1_k_out.mem[ix]=0;
		cav_elec.dp_outer_prod_2_k_out.mem[ix]=0;
	end
	//
	for (ix=0; ix<n_cycles; ix=ix+1) resonator.ab.mem[ix]=0;
	for (ix=0; ix<n_cycles; ix=ix+1) dp_resonator_prop_const.mem[ix]=0;
	resonator.ab.mem[4]=100000000;  // out of 2^35
	resonator.ab.mem[5]=0;
	dp_resonator_prop_const.mem[4]=-80000 | {scale,18'b0};  // out of 2^17
	dp_resonator_prop_const.mem[5]=120000 | {scale,18'b0};
	cav_elec.dp_dot_0_k_out.mem[5]=90000;
	cav_elec.dp_outer_prod_0_k_out.mem[4]=88000;
end
`endif

endmodule
