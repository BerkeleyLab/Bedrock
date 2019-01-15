// Test bench for the speed_test client,
// See hello_tb.v for more comments.
//
`timescale 1ns / 1ns
module speed_test_tb;

parameter n_lat=12;

initial begin
	if ($test$plusargs("vcd")) begin
		$dumpfile("speed_test.vcd");
		$dumpvars(5, speed_test_tb);
	end
end

// Gateway to UDP, client interface test generator
wire [10:0] len_c;
wire [7:0] idata, odata;
wire clk, raw_l, raw_s;
client_sub #(.n_lat(n_lat)) net(.clk(clk), .len_c(len_c), .idata(idata),
	.raw_l(raw_l), .raw_s(raw_s), .odata(odata));

// DUT
speed_test #(.n_lat(n_lat)) dut(.clk(clk),
	.nomangle(1'b0),
	.len_c(len_c), .idata(idata), .raw_l(raw_l), .raw_s(raw_s),
	.odata(odata)
);

endmodule
