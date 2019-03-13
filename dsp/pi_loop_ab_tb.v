// Test bench taken from piloop2_tb.v.
`timescale 1ns / 1ns

module pi_loop_ab_tb;

reg clk;
integer cc;
initial begin
	if ($test$plusargs("vcd")) begin
		$dumpfile("pi_loop_ab.vcd");
		$dumpvars(3,pi_loop_ab_tb.piloop);
	end
	for (cc=0; cc<4000; cc=cc+1) begin
		clk=0; #5;
		clk=1; #5;
	end
	$finish();
end

reg signed [17:0] xin=0, refin=1000;
reg [17:0] kp=0,ki=0,static_set=1000;
always @(posedge clk) begin
	if (cc==200)  ki<=16000;
	if (cc==200)  kp<=8000;
	if (cc==1000) xin<=14000;
	if (cc==3500) xin<=-1000;
	if (cc==3900) ki<=0;
end

wire str_out;
wire signed [17:0] corr;
pi_loop_ab piloop (.clk(clk),
	.Kp_I(kp), .Kp_Q(kp), .Ki_over_Kp(ki),
	.measured_iq(xin), .ref_iq(refin), .iq((cc%2) == 0),
	.reverse(1'b0),
	.integrator_enable(1'b1),
	.pi_out_iq(corr));

always @(negedge clk) begin
	$display("xin %d, pi_out, %d", xin, corr);
end

endmodule
