`timescale 1ns / 1ns

module dec_forward_tb;

reg clk;
integer cc, passed=0;
reg fail=0;
initial begin
	if ($test$plusargs("vcd")) begin
		$dumpfile("dec_forward.vcd");
		$dumpvars(5,dec_forward_tb);
	end
	for (cc=0; cc<1400 ; cc=cc+1) begin
		clk=0; #4;
		clk=1; #4;
	end
	$display("%d tests passed", passed);
	if (fail) begin
		$display("FAIL");
		$stop();
	end else begin
		$display("PASS");
		$finish(0);
	end
end

reg [15:0] bdata, new_bdata, old_bdata;
reg load=0;
always @(posedge clk) begin
	bdata <= 16'bx;
	load <= 0;
	if (cc%240 == 10) begin
		old_bdata = new_bdata;
		load <= 1;
		new_bdata = 123;
		if (cc > 300) new_bdata = 60875;  // 0xEDCB
		if (cc > 570) new_bdata = $random;
		bdata <= new_bdata;
	end
end

wire [3:0] nib_out;
wire rts;
reg cts=1;
dec_forward dut(.clk(clk), .bdata(bdata), .load(load),
	.dig_cnt(4'd8),
	.nib_out(nib_out), .rts(rts), .cts(cts));

integer result;
always @(posedge clk) begin
	if (load) begin
		$display("result %d for input %d", result, old_bdata);
		if (result != old_bdata) begin $display("FAULT"); fail=1; end
		else passed = passed+1;
		result = 0;
	end
	if (rts) result = result*10 + nib_out;
end

endmodule
