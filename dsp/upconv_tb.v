`timescale 1ns / 1ns
`include "constants.vams"

module upconv_tb;

reg clk;
integer cc;
reg fail=0;
initial begin
	if ($test$plusargs("vcd")) begin
		$dumpfile("upconv.vcd");
		$dumpvars(5,upconv_tb);
	end
	for (cc=0; cc<1000; cc=cc+1) begin
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

reg [5:0] state=0;
reg strobe=0;
reg signed [15:0] in_d, in_i, in_q;
reg [15:0] cos, cosx, sin, sinx;
always @(posedge clk) begin
	state <= (state==46) ? 0 : (state+1);
	// in_d <= (state==1||state==2) ? $random : 18'bx;
	in_d <= 18'bx;
	if (state==1) in_d <= (cc>300) ? 32767 : 0;
	if (state==2) in_d <= (cc>600) ? 32767 : 0;
	strobe <= state==1;
	if (state==2) in_i <= in_d;
	if (state==3) in_q <= in_d;
	// 30377 < 2^26/47^2
	// corresponds to nominal out_amp_set = 73785; 73785*1.64676/4
	cosx = $floor(30377*$cos(state/47.0*`M_TWO_PI)+0.5); cos <= cosx;
	sinx = $floor(30377*$sin(state/47.0*`M_TWO_PI)+0.5); sin <= sinx;
end

wire signed [15:0] out_d;
upconv dut(.clk(clk), .in_strobe(strobe), .in_d(in_d),
	.sin(sin), .cos(cos), .out_d(out_d)
);

always @(negedge clk) if (cc>6) begin
end

endmodule
