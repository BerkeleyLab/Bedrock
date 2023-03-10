`timescale 1ns / 1ns

`define ADDR_HIT_dut_kx 0
`define ADDR_HIT_dut_ky 0

`define LB_DECODE_lp_tb
`include "lp_tb_auto.vh"

module lp_tb;

reg clk;
integer cc;
initial begin
	if ($test$plusargs("vcd")) begin
		$dumpfile("lp.vcd");
		$dumpvars(5,lp_tb);
	end
	for (cc=0; cc<450; cc=cc+1) begin
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

reg signed [17:0] x=0;
reg [2:0] state=0;
wire iq=state[0];
always @(posedge clk) begin
	state <= state+1;
	if (cc>5 && cc<205)
	//          real   imag
	x  <= ~iq ? 20000 : 0; else x <= 0;
end

// Local bus (not used in this test bench)
wire lb_clk=clk;
reg signed [31:0] lb_data;
reg [15:0] lb_addr;
reg lb_write=0;

`AUTOMATIC_decode

wire signed [19:0] y;
lp dut // auto
	(.clk(clk), .iq(iq), .x(x), .y(y), `AUTOMATIC_dut);

// Set control registers from command line
// See also lp_setup in lp_notch_test.py or lp_2notch_test.py
reg signed [17:0] kxr, kxi, kyr, kyi;
initial begin
	if (!$value$plusargs("kxr=%d", kxr)) kxr =  71000;
	if (!$value$plusargs("kxi=%d", kxi)) kxi =      0;
	if (!$value$plusargs("kyr=%d", kyr)) kyr = -70000;
	if (!$value$plusargs("kyi=%d", kyi)) kyi =      0;
	#1;
	dp_dut_kx.mem[0] = kxr;  // k_X  real part
	dp_dut_kx.mem[1] = kxi;  // k_X  imag part
	dp_dut_ky.mem[0] = kyr;  // k_Y  real part
	dp_dut_ky.mem[1] = kyi;  // k_Y  imag part
end
// As further discussed in lp.v,
// y*z = y + ky*z^{-1}*y + kx*x
// k_X and k_Y are scaled by 2^{19} from their real values,
// for default (and historical equivalent) parameter shift=2.
// Thus a full-scale value of 131071 translates to 0.25.
// shift = 0: 2^{17}-1/2^{17} = 1
// shift = 2: 2^{17}-1/2^{19} = 0.25
// shift = 4: 2^{17}-1/2^{21} = 0.0625
// The new shift parameter is added to accommodate higher BWs.
// At a typical 50 Msample/sec (remember this processes pairs),
// that gives a maximum bandwidth of 50 MS/s * 0.25 = 12.5e6 rad/s = 1.99 MHz
// Configuring as a 300 kHz low-pass gives k_X = 0.0377, k_Y = -0.0377
// for a register value set of approximately +/- 19760.

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
