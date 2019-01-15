// Test bench for the hello world client,
// and in general a template for testing any client according
// to the timing diagram shown in clients.eps.
//
// rtefi_pipe_tb can do this too, and seven of them at once even,
// and that's great, but it's a lot of needless complexity if all
// you want to test is the client itself.
// Plus, it needs cooperation from root to set up the tap device.
//
`timescale 1ns / 1ns
module hello_tb;

parameter n_lat=12;

initial begin
	if ($test$plusargs("vcd")) begin
		$dumpfile("hello.vcd");
		$dumpvars(5, hello_tb);
	end
end

// Gateway to UDP, client interface test generator
wire [10:0] len_c;
wire [7:0] idata, odata;
wire clk, raw_l, raw_s;
client_sub #(.n_lat(n_lat)) net(.clk(clk), .len_c(len_c), .idata(idata),
	.raw_l(raw_l), .raw_s(raw_s), .odata(odata));

// DUT
hello #(.n_lat(n_lat)) dut(.clk(clk),
	.len_c(len_c), .idata(idata), .raw_l(raw_l), .raw_s(raw_s),
	.odata(odata)
);

endmodule
