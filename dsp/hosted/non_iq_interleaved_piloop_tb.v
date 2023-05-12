// Test bench taken from piloop2_tb.v.
`timescale 1ns / 1ns

module non_iq_interleaved_piloop_tb;

reg clk;
integer cc;
reg trace, fail;
integer out_fd;
initial begin
	if ($test$plusargs("vcd")) begin
		$dumpfile("non_iq_interleaved_piloop.vcd");
		$dumpvars(5, non_iq_interleaved_piloop_tb);
	end
	$display("Non-checking testbench.  Will always PASS");
	trace = $test$plusargs("trace");
	out_fd = $fopen("non_iq_interleaved_piloop.out", "w");
	$fwrite(out_fd, "# cc kp ki x_i x_q setpoint_i setpoint_q y_i y_q\n");
	for (cc=0; cc<4000; cc=cc+1) begin
		clk=0; #5;
		clk=1; #5;
	end
	$display("PASS");
	$finish();
end

reg signed [17:0] xin=0, setpoint=5000;
reg [17:0] kp=0,ki=0,static_set=1000;
always @(posedge clk) begin
	if (cc ==  250)  kp <=  50000;
	if (cc ==  500)  kp <= 100000;
	if (cc == 1000) xin <= 1500;
	if (cc == 1300)  ki <= 10000;
	if (cc == 3500) xin <= 600;
	if (cc == 3900) xin <= 1000;
end

wire str_out;
wire signed [17:0] corr_i, corr_q;
reg [3:0] post_mult_shift=0;

reg signed [18:0] err_i=0, err_q=0;
reg reverse=0;


always @ (posedge clk) begin
	err_i <= reverse ? xin - setpoint : setpoint - xin;
	err_q <= reverse ? xin - setpoint : setpoint - xin;
end

non_iq_interleaved_piloop piloop (.clk(clk),
	.feedback_enable(1'b1),
	.Kp_I(kp), .Kp_Q(kp), .Ki_over_Kp(ki),
	.err_i(err_i), .err_q(err_q),
	.integrator_gate(1'b1),
	.integrator_reset(1'b0),
	.post_mult_shift(post_mult_shift),
	.fdfwd_i(17'b0),
	.fdfwd_q(17'b0),
	.pi_out_i(corr_i),
	.pi_out_q(corr_q)
);

always @(negedge clk) if (out_fd) begin
	#1; $fwrite(out_fd, "%d %d %d %d %d %d %d %d %d\n",
		    cc, kp, ki, xin, xin,
		    setpoint, setpoint,
		    corr_i, corr_q);
end

endmodule
