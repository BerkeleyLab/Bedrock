`timescale 1ns / 1ns
`include "constants.vams"

module iq_modulator_tb;

reg clk, trace, pass;
integer cc;
integer out_file;
real e_sum=0, e_sum2=0, e_min=0, e_max=0;
real e_mean, e_var;
integer npt=0;
initial begin
	if ($test$plusargs("vcd")) begin
		$dumpfile("iq_modulator.vcd");
		$dumpvars(5,iq_modulator_tb);
	end
	if ($test$plusargs("trace")) begin
		trace = 1;
		out_file = $fopen("iq_modulator.dat", "w");
	end else begin
		trace = 0;
	end
	for (cc=0; cc<1000; cc=cc+1) begin
		clk=0; #5;
		clk=1; #5;
	end
	// Currently mean is -0.25, var = 0.26, range is [-1.92, +1.14]
	// New zero_bias parameter allows fixing the -1/4 bit bias
	// Almost all of the variance comes from bit-flicker on input and output
	e_mean = e_sum/npt;
	e_var = e_sum2/npt - e_mean*e_mean;
	$display("npt %3d  mean %.3f  var %.3f  span (%.2f, %.2f)", npt, e_mean, e_var, e_min, e_max);
	pass = (npt > 200) && (e_mean < 0.3) && (e_mean > -0.3) &&
		(e_var < 0.3) && (e_min > -2.0) && (e_max < 2.0);
	if (!pass) begin
		$display("FAIL");
		$stop();
	end else begin
		$display("PASS");
		$finish(0);
	end
end

parameter WIDTH=8;
reg signed [WIDTH-1:0] sin, cos, ampi, ampq;
reg [15:0] p1=0, p2=0, p3=0;  real th1, th2, th3, ideal;
always @(posedge clk) begin
	p1 = p1 + 3999;
	th1 = p1*`M_TWO_PI/65536.0;
	cos <= $floor(127.0*$cos(th1)+0.5);
	sin <= $floor(127.0*$sin(th1)+0.5);
	p2 = p2 + 321;
	th2 = p2*`M_TWO_PI/65536.0;
	ampi <= $floor(127.0*$cos(th2)+0.5);
	ampq <= $floor(127.0*$sin(th2)+0.5);
	// Analytic result
	if (cc>1) p3 = p3 + 3999 - 321;
	th3 = p3*`M_TWO_PI/65536.0;
	ideal = 126.01*$cos(th3);
end

wire signed [WIDTH-1:0] d_out;
iq_modulator #(.WIDTH(WIDTH)) dut(.clk(clk),
	.sin(sin), .cos(cos),
	.ampi(ampi), .ampq(ampq),
	.d_out(d_out)
);

real err;
always @(negedge clk) if (cc>9) begin
	if (trace) $fwrite(out_file, "%d %d %d %d %d %.2f\n", cos, sin, ampi, ampq, d_out, ideal);
	err = d_out-ideal;
	e_sum += err;
	e_sum2 += err*err;
	npt += 1;
	if (err < e_min) e_min = err;
	if (err > e_max) e_max = err;
end

endmodule
