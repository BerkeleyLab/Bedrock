`timescale 1ns / 1ns

`define ADDR_HIT_dut_lp1a_kx 0
`define ADDR_HIT_dut_lp1a_ky 0
`define ADDR_HIT_dut_lp1b_kx 0
`define ADDR_HIT_dut_lp1b_ky 0

`define LB_DECODE_lp_notch_tb
`include "lp_notch_tb_auto.vh"

module lp_notch_tb;

reg clk;
integer cc;
real dth;  // delta theta, angle per pair of time steps
initial begin
	if ($test$plusargs("vcd")) begin
		$dumpfile("lp_notch.vcd");
		$dumpvars(5,lp_notch_tb);
	end
	if (!$value$plusargs("dth=%f", dth)) dth = 0.0;
	for (cc=0; cc<850; cc=cc+1) begin
		clk=0; #5;
		clk=1; #5;
	end
end

// Output file (if any) for dumping the results
integer out_file;
reg [255:0] out_file_name;
initial begin
	out_file = 0;
	if ($value$plusargs("out_file=%s", out_file_name))
		out_file = $fopen(out_file_name,"w");
end

reg signed [17:0] x=0, sint, cost;
reg [2:0] state=0;
wire iq=state[0];
integer dds=0;
always @(posedge clk) begin
	state <= state+1;
	if (~iq) begin
		cost = 20000*$cos(dds*dth) + 0.5;
		sint = 20000*$sin(dds*dth) + 0.5;
		dds <= dds+1;
	end
	if (cc>5 && cc<606) x <= ~iq ? cost : sint;
	else x <= 0;
end

// Local bus (not used in this test bench)
wire lb_clk=clk;
reg signed [31:0] lb_data;
reg [15:0] lb_addr;
reg lb_write=0;

`AUTOMATIC_decode

wire signed [19:0] y;
lp_notch dut // auto
	(.clk(clk), .iq(iq), .x(x), .y(y), `AUTOMATIC_dut);

// Set control registers from command line
// See also notch_setup.py
reg signed [17:0] kaxr, kaxi, kayr, kayi;
reg signed [17:0] kbxr, kbxi, kbyr, kbyi;
initial begin
	if (!$value$plusargs("kaxr=%d", kaxr)) kaxr =  71000;
	if (!$value$plusargs("kaxi=%d", kaxi)) kaxi =      0;
	if (!$value$plusargs("kayr=%d", kayr)) kayr = -70000;
	if (!$value$plusargs("kayi=%d", kayi)) kayi =      0;
	if (!$value$plusargs("kbxr=%d", kbxr)) kbxr =      0;
	if (!$value$plusargs("kbxi=%d", kbxi)) kbxi =      0;
	if (!$value$plusargs("kbyr=%d", kbyr)) kbyr =      0;
	if (!$value$plusargs("kbyi=%d", kbyi)) kbyi =      0;
	#1;
	dp_dut_lp1a_kx.mem[0] = kaxr;  // k_X  real part
	dp_dut_lp1a_kx.mem[1] = kaxi;  // k_X  imag part
	dp_dut_lp1a_ky.mem[0] = kayr;  // k_Y  real part
	dp_dut_lp1a_ky.mem[1] = kayi;  // k_Y  imag part
	dp_dut_lp1b_kx.mem[0] = kbxr;  // k_X  real part
	dp_dut_lp1b_kx.mem[1] = kbxi;  // k_X  imag part
	dp_dut_lp1b_ky.mem[0] = kbyr;  // k_Y  real part
	dp_dut_lp1b_ky.mem[1] = kbyi;  // k_Y  imag part
end

// Write a comprehensible output file
// One line per pair of clock cycles
// Also gives the timing diagram something comprehensible to look at and graph
reg signed [17:0] y1=0, y_i=0, y_q=0;
reg signed [17:0] x1=0, x_i=0, x_q=0;
always @(posedge clk) begin
	x1 <= x;
	y1 <= y;
	if (~iq) y_i <= y1;
	if (~iq) y_q <= y;
	if (~iq) x_i <= x1;
	if (~iq) x_q <= x;
	if (out_file != 0 && ~iq) $fwrite(out_file," %d %d %d %d\n", x_i, x_q, y_i, y_q);
end

endmodule
