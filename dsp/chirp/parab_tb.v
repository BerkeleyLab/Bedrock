`timescale 1ns / 1ns

module parab_tb;

reg clk, trace;
integer cc, endcc;
initial begin
	if ($test$plusargs("vcd")) begin
		$dumpfile("parab.vcd");
		$dumpvars(5, parab_tb);
	end
	trace = $test$plusargs("trace");
	endcc = 3300;
	if (trace) endcc = 410000;
	for (cc=0; cc<endcc; cc=cc+1) begin
		clk=0; #5;
		clk=1; #5;
	end
	$display("WARNING: Not a self-checking testbench. Will always pass.");
	$display("PASS");
	$finish(0);
end

reg gate=0, reset=0;
always @(posedge clk) begin
	gate <= cc%4==3;
	reset <= cc%393216==3;
end

// See explanation in parab.v
parameter dw = 20;
parameter dx = 16;
parameter ow = 20;
parameter cw = 24;

// Ignore the test bench clock rate and gate rate.  Estimate the real-life
// use case is 10000 gates/sec, and a typical sweep will cover 100 to 220 Hz
// in 9.83 seconds (393216 clock cycles in simulation).
// Thus initial dphase is 100/10000 revolutions/gate
// and ddphase is 120/10000/(9.83*10000) revolutions/gate/gate
reg [dw-1:0] dphase = 10490;  // 100/10000*2^dw
reg [dw-1:0] ddphase = 8385;  // 120/10000/(9.83*10000)*2^(dw+dx)

wire [ow-1:0] phase;
wire error, gate_o;
parab #(.dw(dw), .dx(dx), .ow(ow)) dut(
	.clk(clk), .gate(gate), .reset(reset),
	.dphase(dphase), .ddphase(ddphase),
	.gate_o(gate_o), .phase(phase), .error(error)
);

reg [dw-1:0] amp_max = 20000;
reg [dw-1:0] amp_slope = 5;
reg [cw-1:0] chirp_len = 98304;

wire [dw-1:0] amp;
wire ramp_error;
ramps #(.dw(dw), .cw(cw)) rut(
	.clk(clk), .gate(gate), .reset(reset),
	.duration(chirp_len), .amp_slope(amp_slope), .amp_max(amp_max),
	.amp(amp), .error(ramp_error)
);

always @(negedge clk) if (trace & gate_o) $display("%d %d", phase, amp);

endmodule
