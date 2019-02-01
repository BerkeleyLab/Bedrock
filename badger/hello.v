// Demo client
module hello(
	input clk,
	// client interface with RTEFI, see clients.eps
	input [10:0] len_c,
	input [7:0] idata,
	input raw_l,
	input raw_s,
	output [7:0] odata
);

parameter n_lat=2;

reg [255:0] test_msg_rom = "Hello world from Packet Badger!\n";
reg [4:0] a;
reg [7:0] test_msg=0;
always @(posedge clk) begin
	a <= len_c[4:0] - 9;
	test_msg <= test_msg_rom[{a,3'b0} +: 8];
end

// 13 bits input, 8 bits output, choose to pipeline output
reg_delay #(.len(n_lat-2), .dw(8)) align(.clk(clk), .gate(1'b1), .reset(1'b0),
	.din(test_msg), .dout(odata));


endmodule
