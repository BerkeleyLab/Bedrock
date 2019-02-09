`timescale 1ns / 1ns

module freq_count_tb;

reg clk, usbclk;
integer cc;
wire [27:0] frequency;
initial begin
	if ($test$plusargs("vcd")) begin
		$dumpfile("freq_count.vcd");
		$dumpvars(5,freq_count_tb);
	end
	for (cc=0; cc<300; cc=cc+1) begin
		usbclk=0; #10;
		usbclk=1; #10;
	end
	// Simulated accumulation interval is 20*64 = 1280 ns
	// Should catch an average of 1280/6 = 213.33 clk edges in that time
	if (frequency>212 && frequency < 215) $display("PASS");
	else $display("FAIL");
	$finish();
end

always begin
	clk=0; #3;
	clk=1; #3;
end

wire [15:0] diff_stream;
wire diff_stream_strobe;
freq_count #(.refcnt_width(6)) mut(.clk(clk), .usbclk(usbclk),
	.frequency(frequency),
	.diff_stream(diff_stream), .diff_stream_strobe(diff_stream_strobe)
);

always @(negedge usbclk) if (diff_stream_strobe && cc<40) $display("%x",diff_stream);

endmodule
