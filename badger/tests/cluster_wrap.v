// Highly experimental
// XXX learn how to loop this
//
module cluster_wrap(
	input clk,
	// client interface with RTEFI, see clients.eps
	input [10:0] len_c_0,
	input [7:0] idata_0,
	input raw_l_0,
	input raw_s_0,
	output [7:0] odata_0,
	// client interface with RTEFI, see clients.eps
	input [10:0] len_c_1,
	input [7:0] idata_1,
	input raw_l_1,
	input raw_s_1,
	output [7:0] odata_1,
	output [7:0] n_lat_expose  // work around a limitation in Verilator
);

parameter n_lat=10;
assign n_lat_expose = n_lat;
wire [31:0] s0to1, s1to0;

mem_gateway_wrap #(.n_lat(n_lat)) mg0(.clk(clk),
	.len_c(len_c_0), .idata(idata_0), .raw_l(raw_l_0), .raw_s(raw_s_0), .odata(odata_0),
	.scratch_out(s0to1), .scratch_in(s1to0)
);
mem_gateway_wrap #(.n_lat(n_lat)) mg1(.clk(clk),
	.len_c(len_c_1), .idata(idata_1), .raw_l(raw_l_1), .raw_s(raw_s_1), .odata(odata_1),
	.scratch_out(s1to0), .scratch_in(s0to1)
);

endmodule
