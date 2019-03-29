`timescale 1ns / 1ns
`include "constants.vams"
module main_tb;

reg clk;
integer cc;
initial begin
	if ($test$plusargs("vcd")) begin
		$dumpfile("main.vcd");
		$dumpvars(5,main_tb);
	end
	for (cc=0; cc<300; cc=cc+1) begin
		clk=0; #5;
		clk=1; #5;
	end
end

reg [20:0] inst=0;
reg signed [17:0] meas=0;
real F = 131072.0;
real th = 11.0/47.0*`M_TWO_PI;
always @(posedge clk) begin
	case (cc)
`define FOO
`ifdef FOO
		0:  inst <= 0;
		1:  inst <= 21'b1_00_000_00001_00000_00000;
		2:  inst <= 21'b1_00_000_00010_00000_00000;
		3:  inst <= 21'b1_00_000_00011_00000_00000;
		4:  inst <= 21'b1_00_000_00100_00000_00000;
		5:  inst <= 21'b0_00_000_00000_00010_00001;
		6:  inst <= 21'b0_00_110_00000_00000_00000;
		7:  inst <= 21'b0_00_000_00000_00000_00000;
		8:  inst <= 21'b0_00_000_00000_00000_00000;
		9:  inst <= 21'b0_00_000_00101_00011_00010; // r[5]<=
		10: inst <= 21'b0_00_100_00000_00011_00010;
		11: inst <= 21'b0_00_100_00000_00011_00010;
		12: inst <= 21'b0_01_100_00000_00011_00010;
		13: inst <= 21'b0_10_100_00110_00000_00000; // r[6]<=
		14: inst <= 21'b0_11_000_00111_00000_00000; // r[7]<=
		15: inst <= 21'b0_00_000_00111_00000_00000; // r[7]<=
		16: inst <= 21'b0_00_000_00111_00000_00111; // r[7]<=
		17: inst <= 21'b0_00_101_00000_00000_00111;
		18: inst <= 21'b0_00_101_00000_00000_00111;
		19: inst <= 21'b0_00_101_00000_00000_00000;
		20: inst <= 21'b0_00_000_01000_00000_00000; // r[8]<=
		21: inst <= 21'b0_00_000_01000_00000_00000; // r[8]<=
		22: inst <= 21'b0_00_000_01000_00000_00000; // r[8]<=
		default: inst <= 0;
`else
`include "ops.vh"
`endif
	endcase
`ifdef FOO
	meas <= 50000+(cc+5)*(cc+6);
`else
	// XXX absolute, not supportable or bit-accurate.
	// See user_tb.v
	case (cc)
		0: meas = -0.00086*F;  // sL_r
		1: meas = -0.00053*F;  // sL_i
		2: meas =  0.52761*F;  // s1_r
		3: meas = -0.39069*F;  // s1_i
		4: meas = -0.11932*F;  // s2_r
		5: meas = -0.18239*F;  // s2_i
		6: meas =  0.00026*F;  // sH_r
		7: meas = -0.00025*F;  // sH_i
		8: meas = -F*$cos(th)/$sin(th);  // K1
		9: meas = F/$sin(th);  // K2
		10: meas = 0.5*F;  // D
		11: meas = 0.5*F;  // two
		12: meas = 0;
		13: meas = 0;
		default: meas = 0;
	endcase
`endif
end

wire signed [17:0] a, b;
wire collide, stray, discard;
sf_main dut(.clk(clk), .inst(inst), .meas(meas),
	.a_o(a), .b_o(b),
	.collide_o(collide), .stray_o(stray), .discard_o(discard));

real f;
always @(negedge clk) begin
	f = dut.d_in / 131072.0;
	if (dut.we) $display("%d:  r[%d] <= %d (%8.5f)", cc-1, dut.wa, dut.d_in, f);
end

endmodule
