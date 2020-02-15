// Simplest possible Gray code counter with parameterized width
// http://en.wikipedia.org/wiki/Gray_code
module simplest_gray #(
	parameter gw=4
) (
	input clk,
	output [gw-1:0] gray
);

reg  [gw-1:0] gray1=0;
// The following three expressions compute the next Gray code based on
// the current Gray code.  Vivado 2016.1, at least, is capable of
// reducing them to the desired four LUTs when gw==4.
// If this _doesn't_ work for your synthesizer, you can replace this
// module with a more explicit construction.
// verilator lint_off UNOPTFLAT
wire [gw-1:0] bin1 = gray1 ^ {1'b0, bin1[gw-1:1]};  // Gray to binary
// verilator lint_on UNOPTFLAT
wire [gw-1:0] bin2 = bin1 + 1;  // add one
wire [gw-1:0] gray_next = bin2 ^ {1'b0, bin2[gw-1:1]};  // binary to Gray
always @(posedge clk) gray1 <= gray_next;
assign gray = gray1;

endmodule
