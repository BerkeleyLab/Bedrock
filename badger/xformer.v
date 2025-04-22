// Transitional/transformational module
// Uses the rearranged input packet and meta-information
// to create output packet, still sans CRC32.
module xformer(
	input clk,  // timespec 6.8 ns
	input [5:0] pc,
	input [1:0] category,
	input [2:0] udp_sel,
	input [7:0] idata,
	input eth_strobe_short,
	input eth_strobe_long,
	// As documented in doc/clients.eps
	output [10:0] len_c,
	// don't bother with data output port, it's the same as idata above
	// 7 of these strobes for the 7 possible clients
	output [6:0] raw_l,
	output [6:0] raw_s,
	// mass input from 7 possible clients
	input [7*8-1:0] mux_data_in,
	//
	output [7:0] odata,
	output ostrobe_s,
	output ostrobe_l
);

// Configuration
parameter n_lat=2;
parameter handle_icmp = 1;

wire icmp = (category == 2) & handle_icmp;
wire udp = category == 3;

// ICMP Echo Checksum (see RFC 792 p. 13)
// For causality reasons, can only be hacked based on
// assuming the input checksum was valid.
// This was the approach taken by Du in icmp_rx.v.
wire [7:0] d_out2;
// Desired pc cycle is 41 in the frame of tx_ip_table.txt,
// but we've accumulated two cycles of pipeline delay.
reg icmp_kick=0; always @(posedge clk) icmp_kick <= icmp & (pc==42);
wire [7:0] odata0;
// Always instantiate this; it turns into a simple pass-through
// (two cycles delayed) when not kicked.
hack_icmp_cksum hack_icmp_cksum(.clk(clk),
	.kick(icmp_kick), .idat(idata), .odat(odata0));

// Delay strobe to match 2-cycle delay in hack_icmp_chksum; refactor?
reg o_strobe1=0, o_strobe2=0;
reg l_strobe1=0, l_strobe2=0;
always @(posedge clk) begin
	o_strobe1 <= eth_strobe_short;
	o_strobe2 <= o_strobe1;
	l_strobe1 <= eth_strobe_long;
	l_strobe2 <= l_strobe1 && category != 0;
end

// Timing
// It's OK to pass-through the UDP checksum when udp_sel==0, because
// nothing has changed from Rx packet except the order of IP addresses
// and port numbers, and the checksum process is not sensitive to the
// order of 16-bit words.  For all other UDP packets, we have to disable
// the checksum by replacing it with zero.  See below.
reg pc_at_checksum=0;
reg use_zero=0, use_copy=0;
always @(posedge clk) begin
	use_copy <= ~udp || pc < 48 || udp_sel == 0;
	pc_at_checksum <= pc == 46 || pc == 47;
	use_zero <= udp && (udp_sel != 0) && pc_at_checksum;
end

// UDP length down-counter
reg [10:0] pdata_count=0;
reg [3:0] len_stb=0;
wire len_soon = pc==43 && udp;
reg pdata_down=0;
always @(posedge clk) begin
	len_stb <= {len_stb[2:0], len_soon};
	if (len_stb[0]) pdata_count[10:8] <= idata[2:0];
	if (len_stb[1]) pdata_count[7:0] <= idata;
	// a zero-length UDP packet must never assert data-valid
	if (len_stb[3] && pdata_count > 8) pdata_down <= 1;
	if (pdata_down) pdata_count <= pdata_count - 1;
	if (pdata_count == 9) pdata_down <= 0;
end

// Signals documented in doc/clients.eps
// Fan out the strobes based on udp_sel
wire [7:0] mask = 1 << udp_sel;
assign len_c = pdata_count;
assign raw_l = mask[7:1] & {7{eth_strobe_long}};
assign raw_s = mask[7:1] & {7{pdata_down}};

// Pipeline alignment
// Names are horrid
wire [11:0] pipe_in = {o_strobe2, l_strobe2, use_zero, use_copy, odata0};
wire use_zero1, use_copy1;  wire [7:0] odata1;
reg_delay #(.len(n_lat-2), .dw(12)) pipe(.clk(clk), .gate(1'b1), .reset(1'b0),
	.din(pipe_in),
	.dout({ostrobe_s, ostrobe_l, use_zero1, use_copy1, odata1}));

// Multiplexer
// Suppress UDP checksum for causality reasons; if there's a client
// that wants to fake it, we would need to give it an option to set
// the checksum to some non-zero (but still constant) value here.
reg [7:0] odatax;
wire [8*8-1:0] mux_data_in2 = {mux_data_in, odata1};
always @(*) begin
	if (use_zero1) odatax = 0;  // UDP checksum
	else if (use_copy1) odatax = odata1;
	else odatax = mux_data_in2[8*udp_sel +: 8];
end
assign odata = odatax;

endmodule
