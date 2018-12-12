`timescale 1ns / 1ns

module iq_chain4_tb;

reg clk;
integer cc;
reg fail=0;
initial begin
	if ($test$plusargs("vcd")) begin
		$dumpfile("iq_chain4.vcd");
		$dumpvars(5,iq_chain4_tb);
	end
	for (cc=0; cc<350; cc=cc+1) begin
		clk=0; #5;
		clk=1; #5;
	end
	$display("%s", fail ? "FAIL" : "PASS");
	$finish();
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

always @(negedge clk) if (~iq) $display("%d %d   %d %d   %d %d   %d %d   out",
	out1_d, out1, out2_d, out2, out3_d, out3, out4_d, out4);

// Conceptual group delay should be 5 CIC stages (2 in, 3 out) of 4 cycles each.
// Actually see ~30 cycles, which includes computational pipelining.

endmodule
