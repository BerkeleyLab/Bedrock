`timescale 1ns / 1ns

module gps_test_tb;

integer cc;
reg clk, fail=0;
initial begin
	if ($test$plusargs("vcd")) begin
		$dumpfile("gps_test.vcd");
		$dumpvars(5,gps_test_tb);
	end
	$display("Non-checking testbench.  Will always PASS");
	for (cc=0; cc<800; cc=cc+1) begin
		clk=0; #4;
		clk=1; #4;
	end
	if (fail) begin
		$display("FAIL");
		$stop(0);
	end else begin
		$display("PASS");
		$finish(0);
	end
end

reg pps=0;
wire [3:0] gps_pins={pps, 3'b000};
always @(posedge clk) begin
	pps <= (cc ==  20) || (cc == 145) || (cc == 149) ||
	       (cc == 270) || (cc == 520) || (cc == 645);
end

parameter dw=7;
wire [dw:0] f_read;
wire [3:0] pps_cnt;
gps_test #(.dw(dw), .arms(dw-3)) dut(.gps_pins(gps_pins),
	.clk(clk), .lb_addr(10'd0), .buf_reset(1'b0),
	.f_read(f_read), .pps_cnt(pps_cnt)
);
wire [dw-1:0] f_out = f_read[dw-1:0];
wire f_ovf = f_read[dw];

endmodule
