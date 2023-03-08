// Highly experimental
//
typedef struct packed {
    bit [10:0] len_c;
    bit [7:0] idata;
    bit raw_l;
    bit raw_s;
} client_in;
typedef struct packed {
    bit [7:0] odata;
} client_out;

// 3 x 21 = 63, so some C++ works better when CLUSTER_N < 4
localparam CLUSTER_N = 2;  // XXX must match parameter in cluster_sim.cpp_

module cluster_wrap(
	input clk,
	input client_in [CLUSTER_N-1:0] cluster_in,
	output client_out [CLUSTER_N-1:0] cluster_out,
	output [7:0] n_lat_expose  // work around a limitation in Verilator
);

parameter n_lat=10;
assign n_lat_expose = n_lat;

wire [31:0] scratch_x[CLUSTER_N-1:0];
genvar jx;
generate for (jx=0; jx<CLUSTER_N; jx=jx+1) begin: bar
	integer kx = (jx==(CLUSTER_N-1)) ? 0 : (jx+1);
	mem_gateway_wrap #(.n_lat(n_lat)) mgx(.clk(clk),
		.len_c(cluster_in[jx].len_c), .idata(cluster_in[jx].idata),
		.raw_l(cluster_in[jx].raw_l), .raw_s(cluster_in[jx].raw_s),
		.odata(cluster_out[jx].odata),
		.scratch_out(scratch_x[jx]), .scratch_in(scratch_x[kx])
	);
end endgenerate

endmodule
