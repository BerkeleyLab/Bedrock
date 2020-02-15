`timescale 1ns / 1ns

module tmds_test_tb;

integer cc;
reg clk, fail=0;
initial begin
	if ($test$plusargs("vcd")) begin
		$dumpfile("tmds_test.vcd");
		$dumpvars(5,tmds_test_tb);
	end
	for (cc=0; cc<100; cc=cc+1) begin
		clk=0; #2;
		clk=1; #2;
	end
	if (fail) $stop();
	$finish();
end

tmds_test dut(.clk(clk), .enable(1'b1));

endmodule
