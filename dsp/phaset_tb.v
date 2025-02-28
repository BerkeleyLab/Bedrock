`timescale 1ns / 1ps

module phaset_tb;

// In real life, this clock is not coherent with the unknown clock
reg sclk;  // 200 MHz
integer cc;
reg glitch;
reg fail=0;
initial begin
	if ($test$plusargs("vcd")) begin
		$dumpfile("phaset.vcd");
		$dumpvars(5,phaset_tb);
	end
	glitch = $test$plusargs("glitch");
	for (cc=0; cc<24000; cc=cc+1) begin
		sclk=0; #2.5;
		sclk=1; #2.5;
	end
	$display("%s", fail ? "FAIL" : "PASS");
	if (fail) $stop(0);
	$finish(0);
end

// 94.286 MHz + epsilon
// divide by 33
// 174.9
reg uclk1;
always begin
	uclk1=0; #5.301;
	uclk1=1; #5.301;
end

// Device under test
wire [13:0] phaset_out;
wire fault;
// round(2**14*1320/14/2/200) = 3862 is the DDS frequency
// delta kinda sets the gain and resolution of the phase tracking loop
phaset #(.dw(14), .delta(16)) track(
	.uclk(uclk1), .uclkg(1'b1), .sclk(sclk), .adv(14'd3862),
	.phase(phaset_out), .fault(fault));

// Demonstration that changing internal divider state (not the uclk1 phase
// itself) will also toggle the msb of phaset_out.  That bit should therefore
// be ignored.  To exercise this feature,
// make phaset_view VCD_ARGS_phaset.vcd=+glitch
initial @(cc==3000) if (glitch) track.ishr[0] = ~track.ishr[0];

// Unwrapped phase
integer phase_unw=0, phase_diff, phase0;
reg [13:0] phaset_d=0;
reg first=1, rate_ok;
real rate, rate_want=1.42199585;  // see below
integer t0=3000, tlen=20000;
always @(posedge sclk) if (cc>1000) begin
	phaset_d <= phaset_out;
	phase_diff = phaset_out - phaset_d;
	if (phase_diff < -8192) phase_diff = phase_diff + 16384;
	if (~first && (phase_diff > 16) || (phase_diff < -16)) fail = 1;
	if (first) phase_unw = phaset_out;
	else phase_unw <= phase_unw + phase_diff;
	if (fault & ~glitch) fail = 1;
	if (cc==t0) phase0 = phase_unw;
	if (cc==(t0+tlen+1)) begin
		$display("Delta phase %d bits / %d cycles",
			phase_unw - phase0, tlen);
		rate = (phase_unw - phase0) * 1.0 / tlen;
		rate_ok = $abs(rate - rate_want) < 0.001*rate_want;
		$display("Rate %.5f bits/cycle vs. theory %.5f  %s",
			rate, rate_want, rate_ok ? " OK" : "BAD");
		if (!glitch && !rate_ok) fail = 1;
	end
	first = 0;
end
// 3862/2**14*200 MHz = 47.143555 MHz  DDS "local oscillator"
// 1/(2*5.301 ns)/2   = 47.160913 MHz  input to be measured
// 1/(2*5.301e-9)/2 - 3862/2**14*200e6 = 17358.35 Hz offset
// 17358.35 Hz * 16384 / 200 MHz = 1.42199585 bits/cycle

endmodule
