`timescale 1ns / 1ns

module badge_trace_tb;

reg clk;
integer cc;
initial begin
	if ($test$plusargs("vcd")) begin
		$dumpfile("badge_trace.vcd");
		$dumpvars(5,badge_trace_tb);
	end
	for (cc=0; cc<150; cc=cc+1) begin
		clk=0; #4;
		clk=1; #4;
	end
end

wire ibadge_clk=clk;
reg dbg_rst=0;
reg ibadge_stb=0;
reg [7:0] ibadge_data;
wire pre_stb = (cc+10) % 30 < 4;
always @(posedge clk) begin
	ibadge_stb <= pre_stb;
	ibadge_data <= pre_stb ? $random : 8'bx;
end

// Local bus not (yet?) used
wire lb_clk = clk;
reg [23:0] lb_addr=0;
reg do_rd=0;
wire [7:0] lb_result;
badge_trace dut(.badge_clk(ibadge_clk), .trace_reset(dbg_rst),
	.badge_stb(ibadge_stb), .badge_data(ibadge_data),
	.lb_clk(lb_clk), .lb_addr(lb_addr), .lb_rd(do_rd),
	.lb_result(lb_result)
);

endmodule
