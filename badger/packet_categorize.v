// Reduce number of bits representing the category
// of a Packet Badger Rx packet from 8 to 4.
// Keep the categories here in-sync with badger_stat.py.
// Output is delayed one cycle; clock domain is unchanged.
// 0:  not used
// 1:  failed CRC
// 2:  ARP for us
// 3:  not MAC-addressed for us
// 4:  packet type is not IP
// 5:  other unrecognized
// 6:  ICMP
// 7:  not used
// 8-15:  UDP to a configured port

module packet_categorize(
	input clk,
	input strobe,
	input [7:0] status,  // from Badger's scanner.v
	output strobe_o,
	output [3:0] category
);

reg strobe_r=0;
reg [3:0] category_r;
always @(posedge clk) begin
	strobe_r <= strobe;
	// 0 not used
	if      (~status[2])            category_r <= 4'h1;  // failed CRC
	else if ( status[1:0] == 2'b01) category_r <= 4'h2;  // ARP
	else if (~status[3])            category_r <= 4'h3;  // not MAC-addressed for us
	else if (~status[4])            category_r <= 4'h4;  // not IP
	else if ( status[1:0] == 2'b00) category_r <= 4'h5;  // other unrecognized
	else if ( status[1:0] == 2'b10) category_r <= 4'h6;  // ICMP
	// 7 not used
	else                            category_r <= {1'b1, status[7:5]};  // UDP, status[1:0] == 2'b11
end

assign strobe_o = strobe_r;
assign category = category_r;

endmodule
