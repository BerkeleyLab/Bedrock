`timescale 1ns / 1ns

module iq_chain4_tb;

reg clk;
integer cc;
reg fail=0;
reg trace;
initial begin
	if ($test$plusargs("vcd")) begin
		$dumpfile("iq_chain4.vcd");
		$dumpvars(5,iq_chain4_tb);
	end
	trace = $test$plusargs("trace");
	for (cc=0; cc<350; cc=cc+1) begin
		clk=0; #5;
		clk=1; #5;
	end
	$display("%s", fail ? "FAIL" : "PASS");
	if (fail) begin
		$display("FAIL");
		$stop();
	end else begin
		$display("PASS");
		$finish();
	end
end

reg [2:0] state=0;
wire iq=state[0];
real cval, sval;
reg signed [17:0] in1=0, in2=0, in3=0, in4=0;
reg signed [17:0] cos_r=0, sin_r=0, gauss=0;
reg [7:0] rbits;
always @(posedge clk) begin
	state <= state+1;
	in1 <= (~iq          ) ? 1000 : (cc>50) ? 600 : 0;
	in2 <= (~iq && cc>101) ? 1200 : (cc>101) ? -1200 : 0;
	in3 <= (~iq && cc>151) ? 1400 : (cc>151) ? gauss : 0;
	in4 <= 0;
	if (cc>199) in4 <= ~iq ? cos_r : sin_r;
	if (iq) begin
		// 1.1 MHz * 10 ns = 0.011
		cval = $floor(130000*$cos(2*3.14159*0.011*cc)+0.5);
		sval = $floor(130000*$sin(2*3.14159*0.011*cc)+0.5);
		cos_r <= cval;
		sin_r <= sval;
		rbits = $random;
		gauss <= rbits[0]+rbits[1]+rbits[2]+rbits[3]+rbits[4]+rbits[5]+rbits[6]+rbits[7]-4;
	end
end

wire sync1=(state==7);
wire signed [21:0] ser_data;
iq_chain4 dut(.clk(clk), .sync(sync1), .in1(in1), .in2(in2), .in3(in3), .in4(in4), .out(ser_data));
// output is three cycles delayed

wire sync2=(state==2);
wire signed [17:0] out1, out2,  out3, out4;
// add 4 to ser_data to remove quantization bias?
iq_intrp4 foo(.clk(clk), .sync(sync2), .in(ser_data), .out1(out1), .out2(out2), .out3(out3), .out4(out4));

reg signed [17:0] out1_d=0, out2_d=0, out3_d=0, out4_d=0;
always @(posedge clk) begin
	out1_d <= out1;
	out2_d <= out2;
	out3_d <= out3;
	out4_d <= out4;
end

reg signed [17:0] tst_cos, tst_sin;
integer diff_cos, diff_sin;
always @(negedge clk) if (~iq) begin
	if (trace) $display("%d %d   %d %d   %d %d   %d %d   %3d  out",
		out1_d, out1, out2_d, out2, out3_d, out3, out4_d, out4, cc);
	if (cc >  47 && out1_d !=  1000) fail=1;
	if (cc >  97 && out1   !=   600) fail=1;
	if (cc > 147 && out2_d !=  1200) fail=1;
	if (cc > 197 && out2   != -1200) fail=1;
	if (cc > 247 && out3_d !=  1400) fail=1;
	if (out3 > 1 || out3 < -1) fail=1;
	if (cc > 250) begin
		tst_cos = $floor(122450*$cos(2*3.14159*0.011*(cc-34))+0.5);
		tst_sin = $floor(122450*$sin(2*3.14159*0.011*(cc-34))+0.5);
		diff_cos = out4_d - tst_cos;
		diff_sin = out4   - tst_sin;
		if (0) $display("%d %d   %d %d   %d %d   trig", out4_d, out4,
			tst_cos, tst_sin, diff_cos, diff_sin);
		if (diff_cos > 250 || diff_cos < -250) fail=1;
		if (diff_sin > 250 || diff_sin < -250) fail=1;
	end
end

// Conceptual group delay should be 5 CIC stages (2 in, 3 out) of 4 cycles each.
// Actually see ~30 cycles, which includes computational pipelining.

endmodule
