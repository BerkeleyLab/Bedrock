`timescale 1ns / 1ns
`define TWO_PI 6.28318530717958647693

module down_5_12_tb;

reg clk;
integer cc;
reg fail=0;  // XXX need a real test!
initial begin
	if ($test$plusargs("vcd")) begin
		$dumpfile("down_5_12.vcd");
		$dumpvars(5,down_5_12_tb);
	end
	for (cc=0; cc<130; cc=cc+1) begin
		clk=0; #4;
		clk=1; #4;
	end
	$display("%s", fail ? "FAIL" : "PASS");
	if (fail) $stop();
	$finish();
end

// XXX exercise more phases and cross-check
reg signed [15:0] adc, mx;
reg [3:0] phase=0;
real ct, x;
reg [31:0] prng;  // sqrt(32)/sqrt(12)*3 = 4.9 bits rms noise added,
// approximate match to 4.9 bits rms implied by
// 76.5 dBFS SNR of AD9653 (2.0 V p-p input)
integer ix, gauss;
always @(posedge clk) begin
	phase <= (phase==11) ? 0 : phase+1;
	adc <= 16'bx;
	prng = $random;
	gauss = 0;
	for (ix=0; ix<16; ix=ix+1) gauss = gauss + prng[ix] - prng[ix+16];
	gauss = gauss*3;  // otherwise we need 288 coins
	ct = $cos((phase+6.5)*5*`TWO_PI/12.0);
	x = 1000 + 10000*ct + gauss;
	mx = (ct > 0) ? 32767 : -32768;
	if (cc>=6 && cc<12) adc <= x;
	if (cc>=24 && cc<42) adc <= x;
	if (cc>=54 && cc<60) adc <= -x*2;
	if (cc>=78 && cc<96) adc <= mx;
end

wire stb, sig_cl;
wire signed [16:0] sig_i, sig_q;
wire signed [15:0] sig_dc;
wire [15:0] sig_rms;
down_5_12 dut(.clk(clk), .adc(adc), .phase(phase),
	.stb(stb), .sig_cl(sig_cl), .sig_i(sig_i), .sig_q(sig_q),
	.sig_dc(sig_dc), .sig_rms(sig_rms)
);

always @(negedge clk) if (stb)
	$display("%d %d %d %d %d", sig_cl, sig_i, sig_q, sig_dc, sig_rms);

endmodule
