`timescale 1ns / 1ns

module gtx_noise_tb;

reg clk;
integer cc;
initial begin
	if ($test$plusargs("vcd")) begin
		$dumpfile("gtx_noise.vcd");
		$dumpvars(5, gtx_noise_tb);
	end
	#2;
	for (cc=0; cc<50; cc=cc+1) begin
		clk=0; #4;
		clk=1; #4;
	end
end

wire [15:0] gtx_d;
wire [1:0] gtx_k, gtx_e, gtx_n;
gtx_noise dut(.clk(clk), .gtx_d(gtx_d), .gtx_k(gtx_k), .gtx_e(gtx_e), .gtx_n(gtx_n));

endmodule
