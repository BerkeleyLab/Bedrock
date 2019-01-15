`timescale 1ns / 1ns

`define ADDR_HIT_dut_sel_en 0
`define ADDR_HIT_dut_ph_offset 0
`define ADDR_HIT_dut_setmp 0
`define ADDR_HIT_dut_coeff 0
`define ADDR_HIT_dut_lim 0

`define LB_DECODE_mp_proc_tb
`include "mp_proc_tb_auto.vh"

module mp_proc_tb;

reg clk;
wire lb_clk = clk;
integer cc;
reg fail=0;
initial begin
	if ($test$plusargs("vcd")) begin
		$dumpfile("mp_proc.vcd");
		$dumpvars(5,mp_proc_tb);
	end
	for (cc=0; cc<350; cc=cc+1) begin
		clk=0; #5;
		clk=1; #5;
	end
	$display("%s", fail ? "FAIL" : "PASS");
	$finish();
end

reg [2:0] state=0;
reg signed [17:0] in_mp=0;
integer ccx;
reg sync=0;
always @(posedge clk) begin
	ccx <= cc-5;
	state <= state+1;
	sync <= state==7;
	in_mp <= 18'bx;
	case (state)
	7: in_mp <= 1000;
	0: in_mp <= 2000;
	endcase
	if (cc<5) in_mp <= 0;  // keep pipeline from getting corrupted at start-up
end

// Local bus (not used in this test bench)
reg signed [31:0] lb_data=0;
reg [2:0] lb_write=0;
reg [17:0] lb_addr=0;

`AUTOMATIC_decode

reg signed [17:0] out_x=0,out_y=0;
initial begin
	#1;
	dut_sel_en = 1;
	dut_ph_offset=200;
	dp_dut_setmp.mem[0] =    100;  // set X
	dp_dut_setmp.mem[1] =      0;  // set Y
	dp_dut_coeff.mem[0] =      0;  // coeff X I
	dp_dut_coeff.mem[1] =      0;  // coeff Y I
	dp_dut_coeff.mem[2] =      0;  // coeff X P
	dp_dut_coeff.mem[3] =      0;  // coeff Y P
	dp_dut_lim.mem[0] =      0;  // lim X hi
	dp_dut_lim.mem[1] =      0;  // lim Y hi
	dp_dut_lim.mem[2] =      0;  // lim X lo
	dp_dut_lim.mem[3] =      0;  // lim Y lo
	@(cc==20);
	dp_dut_lim.mem[0] = 1500;  // lim X hi
	@(cc==44); verify(0,0);
	dp_dut_lim.mem[2] =   1000;  // lim X lo
	@(cc==68); verify(1000,0);
	dp_dut_lim.mem[2] =      0;  // lim X lo
	@(cc==92); verify(1000,0);
	dp_dut_lim.mem[0] = 500;  // lim X hi
	@(cc==116); verify(500,0);
	dp_dut_lim.mem[0] = 2500;  // lim X hi
	dp_dut_coeff.mem[0] =  1800;  // coeff X I
	dp_dut_lim.mem[1] = 2000;  // lim Y hi
	@(cc==196); verify(2500,0);
	dp_dut_lim.mem[3] = 1000;  // lim Y lo
	@(cc==220); verify(2500,1000);
	dp_dut_lim.mem[3] = -1000;  // lim Y lo
	@(cc==244); verify(2500,1000);
	dp_dut_lim.mem[1] = 500;  // lim Y hi
	@(cc==268); verify(2500,500);
	dp_dut_coeff.mem[1] =   -450;  // coeff Y I
	@(cc==300); verify(2500,60);
	@(cc==340); verify(2500,-1000);
end

wire signed [17:0] out_xy;
wire signed [18:0] out_ph;
wire out_sync;
mp_proc dut  // auto
	(.clk(clk), .sync(sync), .in_mp(in_mp),
	.out_xy(out_xy), .out_ph(out_ph), .out_sync(out_sync),
	`AUTOMATIC_dut
);

reg out_sync1=0;
always @(posedge clk) begin
	if (out_sync) out_x <= out_xy;
	if (out_sync1) out_y <= out_xy;
	out_sync1 <= out_sync;
end

reg fault;
task verify;
	input signed [17:0] ck_x;
	input signed [17:0] ck_y;
	begin
		fault = ck_x != out_x || ck_y != out_y;
		if (fault) fail=1;
		$display("check point %d out_x %d == %d  out_y %d == %d  %s",
			cc,out_x,ck_x,out_y,ck_y,fault?"FAULT":"   ok");
	end
endtask

endmodule
