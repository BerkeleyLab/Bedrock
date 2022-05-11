`timescale 1ns / 1ns

`define ADDR_HIT_dut_coarse_scale 0
`define ADDR_HIT_dut_mp_proc_sel_en 0
`define ADDR_HIT_dut_mp_proc_ph_offset 0
`define ADDR_HIT_dut_mp_proc_setmp 0
`define ADDR_HIT_dut_mp_proc_coeff 0
`define ADDR_HIT_dut_mp_proc_lim 0

`define LB_DECODE_fdbk_core_tb
`include "constants.vams"
`include "fdbk_core_tb_auto.vh"

module fdbk_core_tb;

// Parameter to determine which test to run
// 0: Set-point amplitude scaling
// 1: Set-point phase scaling
// 2: Proportional/Integral feedback gain scaling (Amplitude)
// 3: Proportional/Integral feedback gain scaling (Phase)
integer test_type;

// Parameters used in feedback gain scaling exercise to put a step on the set-point
integer sp_step_time, sp_step_file;
integer lim_step_time, lim_step_file;
reg [255:0] sp_step_file_name;
reg [255:0] lim_step_file_name;

// Parameters used in set-point phase scaling exercise to take I and Q input values to DUT
integer in_i, in_q;

reg clk;
// Local bus and test-bench on the same clock domain
wire lb_clk=clk;
integer cc;

initial begin
	if ($test$plusargs("vcd")) begin
		$dumpfile("fdbk_core.vcd");
		$dumpvars(5,fdbk_core_tb);
	end
	for (cc=0; cc<350; cc=cc+1) begin
		clk=0; #5;
		clk=1; #5;
	end
	$finish();
end

// Input file for initial register sets and output file to dump the results
integer in_file, out_file;
reg [255:0] in_file_name;
reg [255:0] out_file_name;

// The command-line arguments depend on the test type in question
initial begin
	if (!$value$plusargs("in_file=%s", in_file_name)) in_file_name="fdbk_core_in.dat";
	in_file = $fopen(in_file_name,"r");

	if (!$value$plusargs("out_file=%s", out_file_name)) out_file_name="fdbk_core_out.dat";
	out_file = $fopen(out_file_name,"w");

	if (!$value$plusargs("test=%d", test_type)) test_type=0;

	if (test_type==1 || test_type==3 || test_type==5) begin
		if (!$value$plusargs("in_i=%d", in_i)) in_i=0;
		if (!$value$plusargs("in_q=%d", in_q)) in_q=0;
	end

	if (test_type==2 || test_type==3 || test_type == 4 || test_type == 5) begin
		if (!$value$plusargs("sp_step_time=%d", sp_step_time)) sp_step_time=0;

		if (!$value$plusargs("sp_step_file=%s", sp_step_file_name)) sp_step_file_name="setmp_step_file.dat";
		sp_step_file = $fopen(sp_step_file_name,"r");

		if (!$value$plusargs("lim_step_time=%d", lim_step_time)) lim_step_time=0;

		if (!$value$plusargs("lim_step_file=%s", lim_step_file_name)) lim_step_file_name="lim_step_file.dat";
		lim_step_file = $fopen(lim_step_file_name,"r");
	end
end

reg [2:0] state=0;
wire iq=state[0];
reg signed [17:0] in1=0;
// Signals to record previous set-point value to apply step
reg [17:0] setmp_x_prev = 18'b0;
reg [17:0] setmp_y_prev = 18'b0;
reg signed [17:0] mag_test4 = 32000;

// Drive controller input signal (I and Q)
// according to the test_type
// 0: Set-point amplitude scaling
// 1: Set-point phase scaling
// 2: Proportional/Integral feedback gain scaling (Amplitude)
// 3: Proportional/Integral feedback gain scaling (Phase)
// 4: Latency test
// 5: Cavity Set-point test

integer control_cnt2=0;
always @(posedge clk) begin
	state <= state+1;
	control_cnt2 <= control_cnt2+1;
	if (test_type==0)
		in1 <= (~iq) ? 32000: 0;
	else if (test_type==1 || test_type==3)
		in1 <= (~iq) ? in_i: in_q;
	else if (test_type==2)
		in1 <= (~iq) ? 320: 0;
	else if (test_type==5) begin
		in1 <= (~iq) ? in_i: in_q;
		if (control_cnt2>sp_step_time)
			in1 <= (~iq) ? in_i: in_q + 5000; // Step in control input
	end
	else if (test_type==4) begin
		in1 <= (~iq) ? mag_test4: 0;
		if (control_cnt==150) mag_test4 <= mag_test4 + 3000;
	end
	else // Default
		in1 <= 0;
end

integer rc1=2, rc2=2, rc3=2;

// Local bus
reg [31:0] lb_data, cd;
reg [15:0] lb_addr, ca;
reg lb_write=0;
integer control_cnt=0;
// Read register sets from configuration file and drive the local bus
always @(posedge lb_clk) begin
	control_cnt <= control_cnt+1;
	if (control_cnt > 5 && control_cnt%3==1 && rc1==2) begin
		rc1=$fscanf(in_file,"%d %d\n",ca,cd);
		if (rc1==2) begin
			$display("local bus[%d] = 0x%x (%d)", ca, cd, cd);
			lb_data <= cd;
			lb_addr <= ca;
			lb_write <= 1;
		end
	end else
		if (control_cnt>lim_step_time && control_cnt%3==1 && (test_type==2 || test_type==3 || test_type==4 || test_type==5) && rc2==2) begin
			rc2=$fscanf(lim_step_file,"%d %d\n",ca,cd);
			if (rc2==2) begin
				$display("local bus[%d] = 0x%x (%d)", ca, cd, cd);
				lb_data <= cd;
				lb_addr <= ca;
				lb_write <= 1;
			end
		end else
		if (control_cnt>sp_step_time && control_cnt%3==1 && (test_type==2 || test_type==3) && rc3==2) begin
			rc3=$fscanf(sp_step_file,"%d %d\n",ca,cd);
			if (rc3==2) begin
				$display("local bus[%d] = 0x%x (%d)", ca, cd, cd);
				lb_data <= cd;
				lb_addr <= ca;
				lb_write <= 1;
			end
		end
	else
	begin
		lb_data <= 32'hx;
		lb_addr <= 7'hx;
		lb_write <= 0;
	end
end

// Magic Local Bus decoder
`AUTOMATIC_decode

wire sync1=(state==7);
wire signed [17:0] out_xy;
fdbk_core #(.use_mp_proc(1), .use_ll_prop(0)) dut // auto
	(.clk(clk),
	.sync(sync1), .iq(iq), .in_xy(in1), .out_xy(out_xy),
	`AUTOMATIC_dut);

// Used for tests where analyzed is based on inputs and outputs in Cartesian coordinates
reg signed [17:0] out_xy_d, in1_d;
// Grab the input, set-point and error signals from the controller
wire signed [17:0] mp_err = dut.mp_proc.mp_err;
wire signed [17:0] in_mp = dut.mp_proc.in_mp;
wire signed [17:0] setmp = dut.mp_proc.setmp;
// Align signals with the associated sync
reg signed [17:0] in_mp_d, setmp_d, mp_err_d;
reg signed [17:0] in_mp_d2, setmp_d2, mp_err_d2;
wire sync3 = dut.sync3;
reg sync_d = 0, sync_d2=0;
integer count_syncs=0;

reg signed [17:0] m_err_scaling=18'b0;
reg signed [17:0] p_err_scaling=18'b0;

always @(posedge clk) begin
	// Make I and Q components available every clock tick

	// Output
	out_xy_d <= out_xy;
	in1_d <= in1;

	// Input
	in_mp_d <= in_mp;
	in_mp_d2 <= in_mp_d;

	// Set-point
	setmp_d <= setmp;
	setmp_d2 <= setmp_d;

	// Error
	mp_err_d <= mp_err;
	mp_err_d2 <= mp_err_d;

	// Trick to avoid having x's dumped onto the output file
	if(sync_d2) begin
		m_err_scaling <= mp_err_d;
		p_err_scaling <= mp_err;
	end

	sync_d <= sync3;
	sync_d2 <= sync_d;

	// Write aligned input, set-point and error signals onto file (set-point scaling test)
	if (out_file != 0 && sync_d2 && (test_type==0 || test_type==1)) $fwrite(out_file," %d %d %d %d %d %d\n", setmp_d2, setmp_d, in_mp_d2, in_mp_d, mp_err_d, mp_err);

	// Write aligned input and output signals onto file (feedback gain scaling test)
	if (out_file != 0 && ~iq && (test_type==2 || test_type==3)) $fwrite(out_file," %d %d %d %d %d %d %d %d\n", in1_d, in1, setmp_d, setmp, out_xy_d, out_xy, m_err_scaling, p_err_scaling);
	if (out_file != 0 && ~iq && test_type==4) $fwrite(out_file," %d %d %d %d %d %d\n", in1_d, in1, out_xy_d, out_xy, m_err_scaling, p_err_scaling);
	if (out_file != 0 && ~iq && test_type==5) $fwrite(out_file," %d %d %d %d %d %d %d %d\n", in1_d, in1, setmp_d, setmp, out_xy_d, out_xy, m_err_scaling, p_err_scaling);
	if (sync_d) count_syncs <= count_syncs + 1'b1;
end

endmodule
