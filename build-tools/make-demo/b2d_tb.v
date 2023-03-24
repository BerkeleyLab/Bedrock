`timescale 1ns / 1ns

module b2d_tb;

reg clk;
integer cc, passed=0;
reg fail=0;
initial begin
	if ($test$plusargs("vcd")) begin
		$dumpfile("b2d.vcd");
		$dumpvars(5,b2d_tb);
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
		$finish();
	end
end

reg [15:0] bdata, new_bdata, old_bdata;
reg load=0;
always @(posedge clk) begin
	bdata <= 16'bx;
	load <= 0;
	if (cc%120 == 10) begin
		old_bdata = new_bdata;
		load <= 1;
		new_bdata = 123;
		if (cc > 150) new_bdata = 60875;  // 0xEDCB
		if (cc > 270) new_bdata = $random;
		bdata <= new_bdata;
	end
end

wire [3:0] nibble;
wire nstrobe;
b2d #(.sim_mode(1)) dut(.clk(clk), .bdata(bdata), .load(load),
	.nibble(nibble), .nstrobe(nstrobe));

integer result, power;
always @(negedge clk) begin
	// if (load) $display("input %d", bdata);
	// if (nstrobe) $display("output %d", nibble);
	if (load) begin
		$display("result %d for input %d", result, old_bdata);
		if (result != old_bdata) begin $display("FAULT"); fail=1; end
		else passed = passed+1;
		result = 0;
		power = 1;
	end else if (nstrobe) begin
		result = result + nibble * power;
		power = power * 10;
	end
end

endmodule
