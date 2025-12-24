// Test bench for the mem_gateway client,
// See hello_tb.v for more comments.
//
`timescale 1ns / 1ns
module mem_gateway_tb;

parameter n_lat=10;

initial begin
	if ($test$plusargs("vcd")) begin
		$dumpfile("mem_gateway.vcd");
		$dumpvars(5, mem_gateway_tb);
	end
end

// Gateway to UDP, client interface test generator
wire [10:0] len_c;
wire [7:0] idata, odata;
wire clk, raw_l, raw_s;
client_sub #(.n_lat(n_lat)) net(.clk(clk), .len_c(len_c), .idata(idata),
	.raw_l(raw_l), .raw_s(raw_s), .odata(odata), .thinking(1'b0));

// DUT
wire [23:0] addr;
wire [31:0] data_out, data_in;
wire control_strobe, control_rd, control_rd_valid;
mem_gateway #(.read_pipe_len(4), .n_lat(n_lat), .enable_bursts(1)) dut(.clk(clk),
	.len_c(len_c), .idata(idata), .raw_l(raw_l), .raw_s(raw_s),
	.odata(odata),
	.addr(addr), .control_strobe(control_strobe),
	.control_rd(control_rd), .control_rd_valid(control_rd_valid),
	.data_out(data_out), .data_in(data_in)
);

// Fake/trivial localbus slave
lb_demo_slave slave(.clk(clk), .addr(addr),
	.control_strobe(control_strobe), .control_rd(control_rd),
	.data_out(data_out), .data_in(data_in),
	.ibadge_clk(1'b0),
	.ibadge_stb(1'b0), .ibadge_data(8'b0),
	.obadge_stb(1'b0), .obadge_data(8'b0),
	.tx_mac_done(1'b0), .rx_mac_data(16'b0),
	.rx_mac_buf_status(2'b0), .scratch_in(32'hdeadf00d),
	.xdomain_fault(1'b0),
	.rx_category_s(1'b0), .rx_category(4'b0)
);

endmodule
