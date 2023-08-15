`timescale 1ns / 1ns

module multiply_accumulate_tb;
reg clk;
integer cc;
reg trace, fail;
integer out_fd;
initial begin
	if ($test$plusargs("vcd")) begin
		 $dumpfile("multiply_accumulate.vcd");
		 $dumpvars(5, multiply_accumulate_tb);
	end
	$display("Non-checking testbench.  Will always PASS");
	trace = $test$plusargs("trace");
	out_fd = $fopen("multiply_accumulate.out", "w");
	$fwrite(out_fd, "# cc signal constant correction downscale enable reset accumulated\n");
	for (cc=0; cc<182; cc=cc+1) begin
		clk=0; #4;
		clk=1; #4;
	end
	$display("PASS");
	$finish(0);
end

reg signed [17:0] signal = 10000, constant = 200;
reg signed [16:0] correction = 0;
reg signed [3:0] downscale = 3;
reg reset=0, enable=0;
always @(posedge clk) begin
	if (cc == 10) enable <= 1;
	if (cc == 20) signal <= 20000;
	if (cc == 30) signal <= 10000;
	if (cc == 40) constant <= 500;
	if (cc > 50 && cc < 70) enable <= cc[0];
	if (cc == 80) downscale <= 5;
	if (cc == 90) constant <= -500;
	if (cc == 100) signal <= -10000;
	if (cc == 110) correction = 60;
	if (cc == 120) correction = -60;
	if (cc == 130) enable <= 0;
	if (cc == 140) reset <= 1;
	if (cc == 145) enable <= 1;
	if (cc == 150) reset <= 0;
	if (cc == 160) correction = 0;
	if (cc == 170) reset <= 1;
end


wire signed [20:0] accumulated;
multiply_accumulate dut (
	.clk(clk),
	.reset(reset),
	.enable(enable),
	.signal(signal),
	.constant(constant),
	.correction(correction),
	.downscale(downscale),
	.accumulated(accumulated)
);

always @(negedge clk) if (out_fd) begin
	#1; $fwrite(out_fd, "%d\t%d\t%d\t%d\t%d\t%d\t%d\t%d\n", cc, signal, constant, correction, downscale, enable, reset, accumulated);
end

endmodule
