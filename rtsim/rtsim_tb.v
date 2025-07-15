`timescale 1ns / 1ns

module rtsim_tb;

reg clk, trace;
integer cc, errors;

`ifdef SIMULATE
initial begin
	if ($test$plusargs("vcd")) begin
		$dumpfile("rtsim.vcd");
		$dumpvars(6,rtsim_tb);
	end
	trace = $test$plusargs("trace");
	errors=0;
	for (cc=0; cc<16000; cc=cc+1) begin
		clk=0; #3;
		clk=1; #3;
	end
	//$display("%s",errors==0?"PASS":"FAIL");
	$finish(0);
end
`endif

integer file1, file2;
reg [255:0] file1_name;
reg [255:0] file2_name;

`ifdef SIMULATE
initial begin
	if (!$value$plusargs("dfile=%s", file1_name)) file1_name="rtsim_in.dat";
	file1 = $fopen(file1_name,"r");
	file2 = 0;
	if ($value$plusargs("pfile=%s", file2_name)) file2 = $fopen(file2_name,"w");
end // initial begin

`endif

integer rc=2;
wire control_clk=clk;
reg [31:0] control_data, cd;
reg [14:0] control_addr, control_addr_d, ca;
reg control_write=0, control_read=0, control_read_d=0;
integer control_cnt=0;
integer wait_horizon=5;
integer ix;

always @(posedge control_clk) begin
	control_cnt <= control_cnt+1;
	if (control_cnt > wait_horizon && control_cnt%3==1 && rc==2) begin
		`ifdef SIMULATE
		rc=$fscanf(file1,"%d %d\n",ca,cd);
		`endif
		if (rc==2) begin
			if (ca == 555) begin
				`ifdef SIMULATE
				$display("stall %d cycles",cd);
				`endif
				wait_horizon = control_cnt + cd;
				// for (ix=0; ix<cd; ix=ix+1) @(posedge control_clk);
			end else begin
				`ifdef SIMULATE
				$display("local bus[%d] = 0x%x (%d)", ca, cd, cd);
				`endif
				control_data <= cd;
				control_addr <= ca;
				control_write <= 1;
			end
		end
	end else begin
		control_data <= 32'hx;
		control_addr <= 7'hx;
		control_write <= 0;
		control_read <= 0;
	end
	control_addr_d <= control_addr;
	control_read_d <= control_read;
end

reg iq=0;
reg signed [17:0] drive=0, piezo=0;
always @(posedge clk) begin
	iq <= ~iq;
	if (cc>400) drive <= iq ? 50000 : 0;
	if (cc>600) piezo <= 90000;
	if (cc>800) piezo <= 0;
end

wire signed [15:0] a_field, a_forward, a_reflect;
// Parameter settings here should be mirrored in param.py
rtsim #(.mode_shift(9), .n_mech_modes(7), .df_scale(9)) v(.clk(clk),
	.iq(iq), .drive(drive), .piezo(piezo),
	.lb_data(control_data), .lb_addr(control_addr), .lb_write(control_write),
	.a_field(a_field), .a_forward(a_forward), .a_reflect(a_reflect)
);

// Post-process the three ADCs to get (and print) I and Q
// Start with LO generation, remembering that ADCs update every other clock cycle
reg [5:0] lo_phase=0;
reg cic_sample=0;
reg signed [17:0] cosd=0, sind=0;
`ifdef SIMULATE
real cosr, sinr;
always @(posedge clk) if (iq) begin
	lo_phase <= (lo_phase+7) % 33;
	cic_sample <= lo_phase == 1;
	cosr = $floor(0.5 + 131069.0 * $cos(lo_phase * 2 * 3.1415926535 / 33.0));  cosd <= cosr;
	sinr = $floor(0.5 + 131069.0 * $sin(lo_phase * 2 * 3.1415926535 / 33.0));  sind <= sinr;
end // if (iq)
`endif
wire cic_sample1 = cic_sample&iq;
reg cic_sampled=0;
always @(posedge clk) cic_sampled <= cic_sample1;

wire signed [17:0] cav_i, cav_q, fwd_i, fwd_q, rfl_i, rfl_q;
simple_cic cic_cav(.clk(clk), .sample(cic_sample1), .cosd(cosd), .sind(sind), .in(a_field),   .out_i(cav_i), .out_q(cav_q));
simple_cic cic_fwd(.clk(clk), .sample(cic_sample1), .cosd(cosd), .sind(sind), .in(a_forward), .out_i(fwd_i), .out_q(fwd_q));
simple_cic cic_rfl(.clk(clk), .sample(cic_sample1), .cosd(cosd), .sind(sind), .in(a_reflect), .out_i(rfl_i), .out_q(rfl_q));

`ifdef SIMULATE
always @(posedge clk) if (cic_sampled) $fdisplay(file2,"%d %d  %d %d  %d %d  %d %d %d", cav_i,cav_q, fwd_i,fwd_q, rfl_i,rfl_q,
	v.station.cav_elec.cav_mode[0].m_fine_freq,
	v.station.cav_elec.cav_mode[1].m_fine_freq,
	v.station.cav_elec.cav_mode[2].m_fine_freq);

always @(posedge clk) if (0) $display("%d %d %d %d %d %d %d",
	v.station.cav_elec.cav_mode[0].mode.out_couple.out_phase,
	v.station.cav_elec.cav_mode[0].mode.out_couple.xout,
	v.station.cav_elec.cav_mode[0].mode.out_couple.yout,
	v.station.cav_elec.cav_mode[0].mode.out_couple.d_real,
	v.station.cav_elec.cav_mode[0].mode.out_couple.d_imag,
	v.station.cav_elec.cav_mode[0].mode.out_couple.out_sum,
	v.station.cav_elec.cav_mode[0].mode.probe_refl
);

reg signed [35:0] save_real;
always @(posedge clk) if (0) begin
	if (v.cav_mech.resonator.pc_d ==0) save_real=v.resonator.sat_result;
	if (v.cav_mech.resonator.pc_d ==1) $display("state %d %d",
		save_real, v.cav_mech.resonator.sat_result);
end
`endif //  `ifdef SIMULATE

endmodule

module simple_cic(
	input clk,
	input sample,
	input signed [17:0] cosd,
	input signed [17:0] sind,
	input signed [15:0] in,
	output signed [17:0] out_i,
	output signed [17:0] out_q
);
reg signed [23:0] acc_i=0, acc_q=0;
reg signed [23:0] hld_i=0, hld_q=0;
reg signed [23:0] cic_i=0, cic_q=0;
wire signed [33:0] cos_prod = in*cosd;
wire signed [33:0] sin_prod = in*sind;
always @(posedge clk) begin
	acc_i <= acc_i + (cos_prod>>>15);
	acc_q <= acc_q + (sin_prod>>>15);
	if (sample) begin
		hld_i <= acc_i;  cic_i <= acc_i - hld_i;
		hld_q <= acc_q;  cic_q <= acc_q - hld_q;
	end
end
assign out_i = $signed(cic_i[23:2])/33;
assign out_q = $signed(cic_q[23:2])/33;
endmodule
