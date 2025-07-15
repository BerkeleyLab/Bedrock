`timescale 1ns / 1ns

module i2c_analyze_tb;

reg clk;
integer cc;
initial begin
	if ($test$plusargs("vcd")) begin
		$dumpfile("i2c_analyze.vcd");
		$dumpvars(5,i2c_analyze_tb);
	end
	$display("Non-checking testbench.  Will always PASS");
	for (cc=0; cc<2000; cc=cc+1) begin
		clk=0; #5;
		clk=1; #5;
	end
	$display("PASS");
	$finish(0);
end

// Probably shouldn't change these
parameter dw = 2;
parameter tw = 6;

// Create stupid test pattern
reg [dw-1:0] data=0;
reg tick0=0, tick=0;
reg [1:0] tick_cnt=0;
always @(posedge clk) begin
	{tick0, tick_cnt} <= tick_cnt+1;
	if (tick0) begin
		if ((cc < 100) && (cc%10==0)) data <= data+1;
		if (cc > 1000) data <= $random;
	end
	tick <= tick0;
end

// Even stupider run control
reg run = 0;
always @(posedge clk) run <= cc > 30;

// Device under test
wire [7:0] trace;
wire trace_push;
i2c_analyze dut (
	.clk(clk), .tick(tick),
	.scl(data[1]), .sda(data[0]), .intp(1'b0), .rst(1'b0),
	.bit_adv(1'b0), .bit_cmd(2'b0),
	.trace(trace), .trace_push(trace_push),
	.run(run)
);

// Send trace to simple decimal ASCII file
integer file1;
reg [255:0] file1_name;
initial begin
	if ($value$plusargs("dfile=%s", file1_name)) begin
		$display("Will write trace to %s", file1_name);
		file1 = $fopen(file1_name,"w");
		$fdisplay(file1, "# %d %d", tw, dw);
	end else begin
		file1 = 0;
	end

end
integer pc=0;
always @(negedge clk) if ((file1 != 0) && trace_push) begin
	$fdisplay(file1, "%d %d %d", pc, trace[7:2], trace[1:0]);
	pc = pc+1;
end

endmodule
