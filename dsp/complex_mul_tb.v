`timescale 1ns / 1ns

module complex_mul_tb;

reg clk;
integer cc;
reg fail=0;
initial begin
	if ($test$plusargs("vcd")) begin
		$dumpfile("complex_mul.vcd");
		$dumpvars(5,complex_mul_tb);
	end
	for (cc=0; cc<50; cc=cc+1) begin
		clk=0; #5;
		clk=1; #5;
	end
	if (fail) begin
		$display("FAIL");
		$stop();
	end else begin
		$display("PASS");
		$finish(0);
	end
end
parameter dw = 16;
reg signed [(dw-1):0] x=0, y=0, xo=0, yo=0, zo=0;
wire signed [(dw-1):0] z;
reg signed [(2*dw)-1:0] fi=0, fq=0, fqd=0;  // reference results
reg signed [(2*dw)-1:0] fr1=0, fr2=0;
//reg iq=0;
reg [2:0] state=0;
wire iq=state[0];
wire ena0=&state[2:1];
reg ena=0;
always @(posedge clk) begin
	x <= ena0 ? $random : 18'bx; xo <= x;
	y <= ena0 ? $random : 18'bx; yo <= y;
	state <= state+1;
	ena <= ena0;
	// iq <= ~iq;
	zo <= z;
	fi <= xo*yo-x*y;
	fq <= x*yo+y*xo;
	fqd <= fq;
	fr1 <= iq ? fi : fqd;
	fr2 <= fr1;
end

wire g_out;
complex_mul #(.dw(dw)) dut(.clk(clk), .gate_in(ena), .x(x), .y(y), .iq(iq&ena),
	.z(z), .gate_out(g_out));

reg signed [(2*dw)-1:0] frd, zx;
reg fault=0;
always @(negedge clk) if (cc>6 && g_out) begin
	zx = z*(2**(dw-1));
	frd = fr2;
	if (frd >  (2**(dw-1))*(2**(dw-1)-1)) frd = (2**(dw-1))*(2**(dw-1)-1);
	if (frd < -(2**(dw-1))*(2**(dw-1))) frd = -(2**(dw-1))*(2**(dw-1));
	fault = zx > frd+(2**(dw-1)) || zx < frd-(2**(dw-1));
	if (fault) fail=1;
	$display("%d %d %d %d %s",
	 iq, zx, frd, zx-frd, fault ? "FAULT" : "    .");
	if (~iq) $display("");
end

endmodule
