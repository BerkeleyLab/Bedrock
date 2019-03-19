`timescale 1ns / 1ns

module visible_tb;

reg clk;
integer cc;
initial begin
	if ($test$plusargs("vcd")) begin
		$dumpfile("visible.vcd");
		$dumpvars(5,visible_tb);
	end
	for (cc=0; cc < 1300; cc=cc+1) begin
		clk=0; #5;
		clk=1; #5;
	end
end

wire [15:0] pattern;
// Note: parameter setting makes the simulation take a factor of 16 fewer
// cycles compared to the default value of 6.
visible #(.div(2)) dut (.clk(clk), .pattern(pattern));

endmodule
