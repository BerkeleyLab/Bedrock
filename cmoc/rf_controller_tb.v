`timescale 1ns / 1ns

`define ADDR_HIT_dut_phase_step 0
`define ADDR_HIT_dut_modulo 0
`define ADDR_HIT_dut_wave_samp_per 0
`define ADDR_HIT_dut_chan_keep 0
`define ADDR_HIT_dut_wave_shift 0
`define ADDR_HIT_dut_piezo_piezo_dc 0
`define ADDR_HIT_dut_fdbk_core_coarse_scale 0
`define ADDR_HIT_dut_fdbk_core_mp_proc_sel_en 0
`define ADDR_HIT_dut_fdbk_core_mp_proc_ph_offset 0
`define ADDR_HIT_dut_fdbk_core_mp_proc_sel_thresh 0
`define ADDR_HIT_dut_fdbk_core_mp_proc_setmp 0
`define ADDR_HIT_dut_fdbk_core_mp_proc_coeff 0
`define ADDR_HIT_dut_fdbk_core_mp_proc_lim 0
`define ADDR_HIT_dut_lp_notch_lp1a_kx 0
`define ADDR_HIT_dut_lp_notch_lp1a_ky 0
`define ADDR_HIT_dut_lp_notch_lp1b_kx 0
`define ADDR_HIT_dut_lp_notch_lp1b_ky 0

`define LB_DECODE_rf_controller_tb
`include "rf_controller_tb_auto.vh"

module rf_controller_tb;

reg clk;
reg lb_clk;
integer cc;
reg trace;
real phase;
reg [16:0] fiber_i, fiber_q;
initial begin
	if ($test$plusargs("vcd")) begin
		$dumpfile("rf_controller.vcd");
		$dumpvars(5,rf_controller_tb);
	end
	trace = $test$plusargs("trace");
	if (!$value$plusargs("phase=%f", phase)) phase = 0.0;
	fiber_i = 3000.0 * $cos(phase);
	fiber_q = 3000.0 * $sin(phase);
	for (cc=0; cc < 990; cc=cc+1) begin
		clk=0; #5;
		clk=1; #5;
	end
end

// Local bus (not used in this test bench)
reg signed [31:0] lb_data;
reg [15:0] lb_addr;
reg lb_write=0;

`AUTOMATIC_decode

reg signed [15:0] a_field=0, a_forward=0, a_reflect=0, a_phref=0;
// put a sine wave on a_field
reg signed [15:0] cos_r=0;
always @(posedge clk) begin
	cos_r = $floor(12000.0*$cos((2.0*3.14159265359*cc*7.0/33.0) + phase)+0.5);
	a_field <= cos_r;
end

reg [16:0] iq_recv=0;
reg [3:0] fiber_state=0;
always @(posedge clk) begin
	fiber_state <= fiber_state+1;
	iq_recv <= fiber_state[0] ? fiber_i : fiber_q;
end
wire qsync_rx = fiber_state==0;

reg ext_trig=0;
reg master_cic_tick=0;
wire [19:0] mon_result;
wire mon_strobe, mon_boundary;

rf_controller dut // auto
	(.clk(clk),
	.a_field(a_field), .a_forward(a_forward), .a_reflect(a_reflect), .a_phref(a_phref),
	.iq_recv(iq_recv), .qsync_rx(qsync_rx),
	.ext_trig(ext_trig), .master_cic_tick(master_cic_tick),
	.mon_result(mon_result), .mon_strobe(mon_strobe), .mon_boundary(mon_boundary),
	`AUTOMATIC_dut);

initial begin
	#1; // lose race with t=0
	// Set up 7/33 LO
	dut_phase_step = 222425*4096+868;
	dut_modulo = 4;
	dut_wave_samp_per = 1;
	dut_wave_shift = 0;
	dut_chan_keep = 4080;
	dut_use_fiber_iq = 1;
	// $display("foo");
	dut.wave_cnt = 1;
	#6000;
	dut_use_fiber_iq = 0;
end

reg signed [19:0] line_buf[0:7];
integer l=0;
reg arm=0;
reg signed [17:0] display_phase;
always @(posedge clk) begin
	if (mon_strobe) begin
		line_buf[l] = mon_result;
		l = l+1;
	end
	if (mon_boundary) begin
		if (trace && l==8) $display("%6d %6d %6d %6d %6d %6d %6d %6d %7d mon",
			line_buf[0], line_buf[1], line_buf[2], line_buf[3],
			line_buf[4], line_buf[5], line_buf[6], line_buf[7],
			display_phase);
		l = 0;
	end
	arm <= dut.fdbk_core.sync3;
	if (arm) display_phase <= dut.fdbk_core.out_mp;
end

// always @(negedge clk) $display(a_field);

endmodule
