`timescale 1ns / 1ns

module inverse_tb;

reg clk;
integer cc;
initial begin
	if ($test$plusargs("vcd")) begin
		$dumpfile("inverse.vcd");
		$dumpvars(5,inverse_tb);
	end
	for (cc=0; cc<307; cc=cc+1) begin
		clk=0; #5;
		clk=1; #5;
	end
end

parameter dw=22;

// create ALU "a" input test pattern, matches sim1.c
reg signed [dw-1:0] a=2500, b=0;
always @(posedge clk) if (cc>10 && a<2050000) a <= a+7*a/300;

wire [2:0] op = 5;  // inv
wire [1:0] sv = 0;
wire signed [dw-1:0] r;  // result
sf_alu #(.dw(dw)) dut(.clk(clk), .ce(1'b1),
	.a(a), .b(b), .op(op), .sv(sv), .r(r));

// Generate delayed copy of the input that's phase-aligned for printing
parameter delay = 3;
reg [dw*delay-1:0] a_sr;
always @(posedge clk) a_sr <= {a_sr[dw*(delay-1)-1:0], a};
wire signed [dw-1:0] a_d = a_sr[dw*delay-1:dw*(delay-1)];

always @(negedge clk) if (cc>13) $display("%d %d", a_d, r);

endmodule
