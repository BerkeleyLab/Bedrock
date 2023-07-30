`timescale 1ns / 1ns

module ctrace_tb;

reg clk;
integer cc;
initial begin
	if ($test$plusargs("vcd")) begin
		$dumpfile("ctrace.vcd");
		$dumpvars(5,ctrace_tb);
	end
	$display("Non-checking testbench.  Will always PASS");
	for (cc=0; cc<2000; cc=cc+1) begin
		clk=0; #5;
		clk=1; #5;
	end
	$display("PASS");
	$finish(0);
end

parameter dw = 4;
parameter tw = 8;
parameter aw = 6;

// Local bus not yet used
wire lb_clk = clk;
reg [aw-1:0] lb_addr = 0;
wire [dw+tw-1:0] lb_out;

reg [dw-1:0] data=0;
always @(posedge clk) begin
	if ((cc < 100) && (cc%10==0)) data <= data+1;
	if (cc > 1000) data <= $random;
end

reg start = 0;
always @(posedge clk) start <= cc == 5;

wire [15:0] pattern;
ctrace #(.dw(dw), .tw(tw), .aw(aw)) dut (
	.clk(clk), .start(start), .data(data),
	.lb_clk(lb_clk), .lb_addr(lb_addr), .lb_out(lb_out)
);

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
wire [tw-1:0] save_time = dut.saveme[dw+tw-1:dw];
wire [dw-1:0] save_data = dut.saveme[dw-1:0];
always @(negedge clk) begin
	if ((file1 != 0) && dut.wen) $fdisplay(file1, "%d %d %x",
		dut.pc, save_time, save_data);
end

endmodule
