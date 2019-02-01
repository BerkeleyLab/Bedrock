// Speed test client
// A lot like a UDP echo, but more satisfying because it actually
// changes the data that flows through it.
// Compatible with ethernet-core/core/client_thru.v
// and ethernet-core/runtime/udprtx.c
module speed_test(
	input clk,
	input nomangle,  // software settable
	// client interface with RTEFI, see clients.eps
	input [10:0] len_c,
	input [7:0] idata,
	input raw_l,
	input raw_s,
	output [7:0] odata
);

parameter n_lat=2;  // minimum value is 1

// len_c counts down to 9, but we need something that counts up from 0
reg [7:0] count=0;
reg [7:0] processed=0;
always @(posedge clk) begin
	count <= raw_s ? count+1 : 0;
	processed <= idata ^ (count & {8{~nomangle}});
end

// 13 bits input, 8 bits output, choose to pipeline output
reg_delay #(.len(n_lat-1), .dw(8)) align(.clk(clk), .gate(1'b1), .reset(1'b0),
	.din(processed), .dout(odata));


endmodule
