`timescale 1ns / 1ns

// Somewhat compatible with machine-generated freq.vh from FERMI builds
`define COHERENT_DEN (7)
`define RF_NUM (1)
// floor(32768*0.5*sec(2*pi*1/7/2)+0.5)
`define AFTERBURNER_COEFF (18185)
// needed by interpon.v to even pass syntax checks
`define CIC_CNTW (6)
`define CIC_PERIOD (14)
`define CIC_MULT 16'd0

`include "constants.vams"

module afterburner_tb;

// plot "foo" using 1:4 with lp, sin(11*(x-6)/196*2*3.14159265)*1000

reg clk=0, fail=0;
integer cc;
reg debug=0;
integer test_amp=65535;
real fourier_s=0, fourier_v;
integer fourier_n=0;
reg fourier_fault=0;
initial begin
	if ($test$plusargs("vcd")) begin
		$dumpfile("afterburner.vcd");
		$dumpvars(3,afterburner_tb);
	end
	if ($test$plusargs("debug")) debug=1;

	for (cc=0; cc<140; cc=cc+1) begin
		clk=0; #5;
		clk=1; #5;
	end
	// Normalized Fourier fundamental component should be basically unity,
	// even with a small amount of clipping
	fourier_v = 8.0*fourier_s/fourier_n/test_amp/test_amp;
	if (fourier_v < 0.9) begin
		fourier_fault=1;
		fail=1;
	end
	$display("# Fourier %d %f %s",fourier_n,fourier_v,fourier_fault?"FAULT":"    .");
	if (fail) $display("FAIL");
	else      $display("PASS");
	$finish();
end

integer wave;
reg signed [16:0] ind=0;
integer iph=0;
real ph;  initial ph=0;
always @(posedge clk) begin
	// The "10" in the denominator here (and in the similar stanza
	// that checks the output) represents the conversion between time
	// and clock cycles.
	iph = ($time*`RF_NUM) % (`COHERENT_DEN*10);
	ph = iph *`M_TWO_PI/(`COHERENT_DEN*10);
	wave = $floor(test_amp*$sin(ph)+0.5);
	if (wave> 65535) wave =  65535;
	if (wave<-65536) wave = -65536;
	if (cc==10) ind <= -1000;
	else if (cc>20 && cc<140) ind <= wave;
	else ind <= 0;
	if (cc==80) test_amp=75000;  // introduce a small amount of overdrive
end
wire [15:0] outd0, outd1;
reg [15:0] coeff = `AFTERBURNER_COEFF;

afterburner dut(clk, ind, coeff, outd0, outd1);

// Combine outd0 and outd1 to double-data-rate form.
// Don't use dac_cells and FDDRRSE here, because this is
// supposed to be hardware-independent.
reg [15:0] outd1x, outd;
always @(negedge clk) outd1x <= outd1;
always @(posedge clk) outd <= outd0;
always @(negedge clk) outd <= outd1x;

`ifdef AFTERBURNER_TRIPLE
`define COMPUTE_DELAY 60
`else
`define COMPUTE_DELAY 50
`endif

reg signed [15:0] outs;
integer iph2=0;
real ph2;  initial ph2=0;
reg signed [16:0] wave2;
reg fail1;
always @(clk) if (cc>3) begin
	// See note above to explain the extra "10" in the denominators.
	// The point is that time flows by half-cycles.
	// The "50" here represents the time delay of the computation.
	iph2 = (($time-`COMPUTE_DELAY)*`RF_NUM) % (`COHERENT_DEN*10);
	ph2 = iph2 *`M_TWO_PI/(`COHERENT_DEN*10);
	// Amplitude of output is half of the input signal
	wave2 = $floor(test_amp*0.5*$sin(ph2)+0.5);
	// Convert offset binary result of afterburner back to signed.
	outs=outd-32768;
	fail1=(outs > wave2+3) || outs < (wave2-3);
	if (cc>28 && cc<80) fail = fail|fail1;
	if (cc>88 && cc<140) begin
		fourier_s=fourier_s+outs*1.0*wave2;
		fourier_n=fourier_n+1;
	end
	if (debug) $display("%d %d %d %d %d %d %d %d", $time, clk, ind, outs, wave2, outs-wave2, fail1, cc);
end
endmodule
