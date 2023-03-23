// Wrapper for the mem_gateway client with the lb_demo_slave
// Needed for Verilator simulation.
//
module mem_gateway_wrap(
	input clk,
	// client interface with RTEFI, see clients.eps
	input [10:0] len_c,
	input [7:0] idata,
	input raw_l,
	input raw_s,
	output [7:0] odata,
	output [31:0] scratch_out,
	input [31:0] scratch_in,
	output [7:0] n_lat_expose  // work around a limitation in Verilator
);

parameter n_lat=10;
assign n_lat_expose = n_lat;

// DUT
wire [23:0] addr;
wire [31:0] data_out, data_in;
wire control_strobe, control_rd, control_rd_valid;
mem_gateway #(.n_lat(n_lat)) dut(.clk(clk),
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
	.scratch_out(scratch_out), .scratch_in(scratch_in),
	.tx_mac_done(1'b0),
	.xdomain_fault(1'b0)
);

// One weird hack, even works in Verilator!
always @(posedge clk) begin
	if (slave.stop_sim) begin
		$display("mem_gateway_wrap:  stopping based on localbus request");
		$finish();
	end
end


endmodule
