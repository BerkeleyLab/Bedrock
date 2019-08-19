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
assign continue_sim = cc<3800;
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

// Local bus
wire lb_clk = clk;
wire [23:0] lb_addr;
wire [31:0] lb_wdata;
wire lb_control_strobe, lb_control_rd;

// MAC master - loop back from localbus, just like in hw_test.v
parameter mac_aw=10;
wire host_clk = lb_clk;
wire host_write = lb_control_strobe & ~lb_control_rd & (lb_addr[23:20]==1);
wire [mac_aw:0] host_waddr = lb_addr[mac_aw:0];
wire [15:0] host_wdata = lb_wdata[15:0];

reg [31:0] lb_rdata=0;
// DUT
rtefi_blob #(.ip(ip), .mac(mac), .paw(paw), .mac_aw(mac_aw)) a(
	.rx_clk(clk), .rxd(eth_in), .rx_dv(eth_in_s),
	.rx_er(1'b0), .enable_rx(1'b1),  // no tests for these functions
	.tx_clk(clk), .txd(eth_out), .tx_en(eth_out_s),
	.config_clk(clk), .config_a(4'd0), .config_d(8'd0),
	.config_s(1'b0), .config_p(1'b0),
	.host_clk(host_clk), .host_write(host_write),
	.host_waddr(host_waddr), .host_wdata(host_wdata),
	.p2_nomangle(1'b0),
	.p3_addr(lb_addr),
	.p3_control_strobe(lb_control_strobe),
	.p3_control_rd(lb_control_rd),
	.p3_data_in(lb_rdata),
	.p3_data_out(lb_wdata),
	.p4_spi_miso(1'b0),
	.in_use(thinking)
);
wire lb_read = lb_control_strobe && lb_control_rd;

// similar to lb_demo_slave.v
// First read cycle
wire [15:0] rom_data;
fake_config_romx rom(
	.clk(clk), .address(lb_addr[3:0]), .data(rom_data)
);

// match pipeline in first cycle
reg [23:0] lb_addr_r=0;
reg lb_read_r=0;
always @(posedge clk) begin
	lb_read_r <= lb_read;
	lb_addr_r <= lb_addr;
end

// second read cycle
always @(posedge clk) if (lb_read_r) casex(lb_addr_r[19:0])
	20'h1000x: lb_rdata <= {16'h0, rom_data};
	default: lb_rdata <= 32'hdeadbeaf;
endcase

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
