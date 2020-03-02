`timescale 1ns / 1ns

module freq_demo_tb;

reg clk;
integer cc, passed=0;
reg fail=0;
initial begin
	if ($test$plusargs("vcd")) begin
		$dumpfile("freq_demo.vcd");
		$dumpvars(5,freq_demo_tb);
	end
	for (cc=0; cc<24000; cc=cc+1) begin
		clk=0; #4;
		clk=1; #4;
	end
	// $display("%d tests passed", passed);
	// $display("%s", fail ? "FAIL" : "PASS");
	if (fail) $stop();
	$finish();
end

// Create a couple of "unknown" clocks for freq_multi_count to measure
reg [3:0] unk_clk=0;
always begin
	unk_clk[0]=0; #3;
	unk_clk[0]=1; #3;
end
always begin
	unk_clk[2]=0; #7;
	unk_clk[2]=1; #7;
end

// Instantiate module under test
reg uart_rx=0;
wire uart_tx;
freq_demo #(.cfg_divider(20'd8), .rw(13), .rv(5000),
	.uw(13)
) dut(
	.refclk(clk), .unk_clk(unk_clk),
	.uart_tx(uart_tx), .uart_rx(uart_rx));

endmodule
