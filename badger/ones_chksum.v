// 16-bit ones-complement checksum calculator
// Applies to all of IP header, ICMP, and UDP checksums
// Well, difficult to use with UDP because of its pathological
// inclusion of _two_ copies of the UDP length.
// mostly cribbed from core/assemble_eth.v

module ones_chksum(
	input clk,
	input ce,
	input clear,
	input gate,
	input [7:0] din,
	output [7:0] sum,
	output all_ones
);

reg [7:0] chksum=0, chksum1=0;
reg chksum_carry=0;
always @(posedge clk) if (ce) begin
	if (clear) {chksum_carry, chksum} <= 9'h0;
	else if (gate) {chksum_carry, chksum} <=
		chksum1 + din + chksum_carry;
	if (clear) chksum1 <= 8'h0;
	else if (gate) chksum1 <= chksum;
end
assign sum = ~(chksum1 + chksum_carry);
assign all_ones = &chksum;

endmodule
