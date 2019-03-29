`timescale 1ns / 1ns

module complex_freq_tb;

reg clk;
integer cc;
reg fail=0;
initial begin
	if ($test$plusargs("vcd")) begin
		$dumpfile("complex_freq.vcd");
		$dumpvars(5, complex_freq_tb);
	end
	for (cc=0; cc<5000; cc=cc+1) begin
		clk=0; #5;
		clk=1; #5;
	end
	if (fail) begin
		$display("FAIL");
		$stop();  // When run from Icarus vvp -N,
		// at least, this results in an exit code of 1
		// that can be detected as a failure by make(1).
	end else $display("PASS");
	$finish();
end

// White-noise generator
reg [19:0] noisebits;
integer noise, ix;
task new_noise;
begin
	noisebits = $random;
	noise = 0;
	for (ix=0; ix<20; ix=ix+2)
		noise = noise + noisebits[ix] - noisebits[ix+1];
end
endtask

// Create stimulus
reg signed [17:0] sdata;
reg sgate;
real theta, st, ct;
parameter tperiod=30;  // each sample pair needs about 22 cycles to process
integer amp=1000;
real dtheta=1.0;
always @(posedge clk) begin
	sdata <= 18'bx;
	sgate <= 0;
	if (cc%tperiod == 10) begin
		sgate <= 1;
		sdata <= st;
	end else if (cc%tperiod == 11) begin
		sgate <= 1;
		sdata <= ct;
	end else if (cc%tperiod == 9) begin
		theta = theta + dtheta;
		// sin
		new_noise;
		st = amp*$sin(theta) + noise;
		// cos
		new_noise;
		ct = amp*$cos(theta) + noise;
	end
	if (cc==tperiod*16*3) amp = 131060;
	if (cc==tperiod*16*4) dtheta = -0.5;
	if (cc==tperiod*16*7) amp = 0;
end

// Instantiate DUT
parameter refcnt_w = 4;
wire signed [refcnt_w-1:0] freq;
wire freq_valid, updated, timing_err;
wire [16:0] amp_max, amp_min;
complex_freq #(.refcnt_w(refcnt_w)) dut(
	.clk(clk), .sdata(sdata), .sgate(sgate),
	.freq(freq), .freq_valid(freq_valid),
	.amp_max(amp_max), .amp_min(amp_min),
	.updated(updated), .timing_err(timing_err)
);

// Check for transitions at the wrong time
reg [16:0] amp_max_d, amp_min_d;
reg [refcnt_w-1:0] freq_d;
reg bad=0;
always @(posedge clk) begin
	freq_d <= freq;
	amp_max_d <= amp_max;
	amp_min_d <= amp_min;
	bad <= 0;
	if (~updated) begin
		if (freq_d != freq) bad <= 1;
		if (amp_max_d != amp_max) bad <= 1;
		if (amp_min_d != amp_min) bad <= 1;
	end
	if (timing_err) bad <= 1;
	if (bad) fail = 1;
end

// Check the output
integer amp_d1, tmp;
reg fault;
always @(negedge clk) if (updated) begin
	fault = 0;
	tmp = amp;  if (amp_d1 > amp) tmp = amp_d1;  // $display(tmp, amp_max);
	tmp = amp_max - tmp - 3;  if (tmp < 0) tmp = -tmp;  if (tmp > 4) fault = 1;
	tmp = amp;  if (amp_d1 < amp) tmp = amp_d1;  // $display(tmp, amp_min);
	tmp = tmp - amp_min - 1;  if (tmp < 0) tmp = -tmp;  if (tmp > 4) fault = 1;
	$display("%d %d %d %d %d %d %s",
		freq, freq_valid, amp_max, amp_min, amp, amp_d1, fault ? "FAULT" : "    .");
	amp_d1 = amp;
	if (fault) fail = 1;
end

endmodule
