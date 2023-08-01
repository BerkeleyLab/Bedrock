`timescale 1ns / 1ns

module complex_mul_tb;

reg clk;
integer cc;
reg fail=0;
initial begin
	if ($test$plusargs("vcd")) begin
		$dumpfile("complex_mul_flat.vcd");
		$dumpvars(5,complex_mul_tb);
	end
	for (cc=0; cc<50; cc=cc+1) begin
		clk=0; #5;
		clk=1; #5;
	end
	if (fail) begin
		$display("FAIL");
		$stop(0);
	end else begin
		$display("PASS");
		$finish(0);
	end
end

reg signed [17:0] x_I=0, x_Q=0, y_I=0, y_Q=0;
wire signed [17:0] z_I, z_Q;
reg signed [35:0] fi=0, fq=0, fi_d=0, fq_d=0, fi_d2=0, fq_d2=0;  // reference results
always @(posedge clk) begin
	x_I <= $random;
	x_Q <= $random;
	y_I <= $random;
	y_Q <= $random;
	fi <= x_I * y_I - x_Q * y_Q;
	fq <= x_I * y_Q + y_I * x_Q;
	fi_d <= fi;
	fq_d <= fq;
	fi_d2 <= fi_d;
	fq_d2 <= fq_d;
end

wire g_out;
complex_mul_flat dut(.clk(clk), .gate_in(cc%4 == 0),
	.x_I(x_I), .x_Q(x_Q),
	.y_I(y_I), .y_Q(y_Q),
	.z_I(z_I), .z_Q(z_Q), .gate_out(g_out));

reg signed [35:0] fi_test, fq_test, zx_I, zx_Q;
reg fault=0;
always @(negedge clk) if (cc>6 && g_out) begin
	zx_I = z_I * 131072;
	zx_Q = z_Q * 131072;
	fi_test = fi_d2;
	fq_test = fq_d2;
	if (fi_test >  131072*131071) fi_test =  131072*131071;
	if (fi_test < -131072*131072) fi_test = -131072*131072;
	if (fq_test >  131072*131071) fq_test =  131072*131071;
	if (fq_test < -131072*131072) fq_test = -131072*131072;
	fault = (zx_I > fi_test+131072 || zx_I < fi_test-131072 ||
		zx_Q > fq_test+131072  || zx_Q < fq_test-131072);
	if (fault) fail=1;
	$display("%d %d %d %d %d %d %s\n",
	 zx_I, fi_test, zx_I - fi_test,
	 zx_Q, fq_test, zx_Q - fq_test, fault ? "FAULT" : "    .");
end

endmodule
