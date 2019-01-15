`timescale 1ns / 1ns

// Adapted from core/aggregate_tb.v
module rtefi_pipe_tb;

parameter [31:0] ip = {8'd192, 8'd168, 8'd7, 8'd4};  // 192.168.7.4
parameter [47:0] mac = 48'h12555500012d;
parameter paw = 11;  // packet (memory) address width, nominal 11

reg clk;
integer cc;
reg trace;
wire continue_sim;
`ifdef LINUX_TUN
assign continue_sim = 1;
`else
assign continue_sim = cc<2900;
`endif
initial begin
	trace = $test$plusargs("trace");
	if ($test$plusargs("vcd")) begin
		$dumpfile("rtefi_pipe.vcd");
		$dumpvars(5,rtefi_pipe_tb);
	end
	for (cc=0; continue_sim; cc=cc+1) begin
		clk=0; #4;  // 125 MHz * 8bits/cycle -> 1 Gbit/sec
		clk=1; #4;
	end
end

// Create flow of packets
wire [7:0] eth_out;
wire eth_out_s;
wire thinking;  // hook to make things run efficiently
`ifdef LINUX_TUN
reg [7:0] eth_in=0, eth_in_=0;
reg eth_in_s=0, eth_in_s_=0;
always @(posedge clk) begin
	if (cc > 4) $tap_io(eth_out, eth_out_s, eth_in_, eth_in_s_, thinking);
	eth_in <= eth_in_;
	eth_in_s <= eth_in_s_;
end
`else
wire eth_in_s;
wire [7:0] eth_in;
// offline takes care of its own argument parsing and file opening
offline offline(.clk(clk), .rx_dv(eth_in_s), .rxd(eth_in));
`endif

// DUT
rtefi_blob #(.ip(ip), .mac(mac), .paw(paw)) a(
	.rx_clk(clk), .rxd(eth_in), .rx_dv(eth_in_s),
	.rx_er(1'b0), .enable_rx(1'b1),  // no tests for these functions
	.tx_clk(clk), .txd(eth_out), .tx_en(eth_out_s),
	.config_clk(clk), .config_a(4'd0), .config_d(8'd0),
	.config_s(1'b0), .config_p(1'b0),
	.p2_nomangle(1'b0), .p3_data_in(32'b0),
	.in_use(thinking)
);

// Some helpful output for regression testing,
// for use with file input?
reg eth_out_s_d=0;
always @(posedge clk) eth_out_s_d <= eth_out_s;
always @(negedge clk) if (trace) begin
	if (eth_out_s & ~eth_out_s_d) $display("start");
	if (eth_out_s) $display("%x", eth_out);
	if (~eth_out_s & eth_out_s_d) $display("end");
end

endmodule

// Stupid Xilinx cruft
// Only needed for the post-synthesis case if using Xilinx unisims.
// Harmless otherwise.
module glbl();
	reg GSR = 1;
	initial begin #10; GSR = 0; end
endmodule
