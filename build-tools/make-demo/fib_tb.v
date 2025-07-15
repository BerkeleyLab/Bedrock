`timescale 1ns / 1ns

module fib_tb;

reg clk;
integer cc;
initial begin
	if ($test$plusargs("vcd")) begin
		$dumpfile("fib.vcd");
		$dumpvars(5,fib_tb);
	end
	for (cc=0; cc<15 ; cc=cc+1) begin
		clk=0; #5;
		clk=1; #5;
	end
	$finish(0);
end

reg rst=1;
always @(posedge clk) rst <= cc< 5;

wire [15:0] data;
fib dut(.clk(clk), .rst(rst), .data(data));

always @(negedge clk) begin
	if (~rst) $display(data);
end

endmodule
