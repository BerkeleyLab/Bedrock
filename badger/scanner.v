// scans input packet

// status_vec key:
// assign status_vec = {port_p, pass_ip, pass_ethmac, crc_zero, category};
//  bit 0-1  category: 3=UDP, 2=ICMP, 1=ARP, 0=other
//  bit 2  CRC32 passed
//  bit 3  Destination MAC matched our configuration
//  bit 4  valid IP packet of some kind
//  bit 5-7  UDP virtual port number, output of CAM

// I haven't yet started trying to handle authentication here.
// That can wait; we have the architecture ready.

// This is a relatively long file, but it helps that it is broken down
// into smaller modules:
//   scanner   top level, see doc/rtefi.eps
//    - arp_patt
//    - ip_patt
//    - icmp_patt
//    - udp_patt
// The four submodules have relatively consistent ports and semantics.

module scanner (
	input clk,
	input [7:0] eth_in,
	input eth_in_s,
	input eth_in_e,  // error flag from PHY
	// PSPEPS didn't do anything with eth_in_e, which is certainly
	// a mistake, but did work in practice.  Let's get this code working
	// and basically tested before adding that new feature.
	//
	// New port: async input to allow packet reception
	// Lets someone turn off the Ethernet subsystem during maintenance,
	// e.g., changing IP address.
	input enable_rx,
	// port to MAC/IP config, single-cycle latency
	output [3:0] ip_a,
	input [7:0] ip_d,
	// port to UDP port number config memory, single-cycle latency
	output [3:0] pno_a,
	input [7:0] pno_d,
	// Access to a single-cycle-latency RAM holding keys and masks,
	// necessarily also in the Rx clock domain.
	// output [9:0] key_addr,
	// input [15:0] key_data,
	//
	// Two-bit summary info available to precog
	// For a kept packet, busy has the full width of odata_s,
	// but is delayed one cycle.  Non-keep packets can have the busy
	// line de-asserted as soon as the dropping condition is detected.
	// When an incoming packet is categorized as causing a response,
	// the keep line is asserted one cycle before busy falls.
	// Also see doc/precog_upg.eps
	output busy,
	output keep,
	output [3:0] debug,
	//
	// Simple flow of data to the next processing stage (pbuf_writer).
	// somewhat conforms to AXI-stream-lite, if I adjust the names?
	output [7:0] odata,
	output odata_s,
	output odata_f,
	output status_valid,
	output [7:0] status_vec,
	output [10:0] pack_len
);
// Configuration
parameter handle_arp = 1;
parameter handle_icmp = 1;

// State machine mostly cribbed from head_rx.v
wire [7:0] eth_octet = eth_in;
wire eth_strobe = eth_in_s;
// exactly four states, one-hot encoded
reg h_idle=1, h_preamble=0, h_data=0, h_drop=0;
wire drop_packet;
reg [3:0] ifg_count=0;  // Inter-frame gap counter
wire ifg_inc = ~(&ifg_count[3:2]);  // saturate at 12
wire ifg_ok = ifg_count >= 10;  // slightly relaxed from spec of 12,
// this configuration guarantees 11 non-data cycles between frames
always @(posedge clk) begin
	if (h_idle | h_preamble) ifg_count <= ifg_count + ifg_inc;
	else ifg_count <= 0;
	if (h_idle & eth_strobe) begin
		h_idle <= 0;
		if (eth_octet==8'h55 && enable_rx) h_preamble <= 1;
		else h_drop <= 1;
	end
	if (h_preamble) begin
		if (eth_strobe & (eth_octet==8'hd5)) begin
			h_preamble <= 0;
			if (ifg_ok) h_data <= 1;
			else h_drop <= 1;  // IFG too small.
		end else if (eth_strobe & (eth_octet!=8'h55)) begin
			h_preamble <= 0; h_drop <= 1;
		end else if (~eth_strobe) begin
			h_preamble <= 0; h_idle <= 1;
		end
	end
	if (h_data) begin
		if (~eth_strobe) begin
			h_data <= 0; h_idle <= 1;
		end else if (drop_packet) begin   // poorly tested
			h_data <= 0; h_drop <= 1;
		end
	end
	if (h_drop & ~eth_strobe) begin
		h_drop <= 0; h_idle <= 1;
	end
end

// Debug helper
reg [1:0] debug1_r=0;
always @(posedge clk) begin
	if (h_idle) debug1_r <= 0;
	if (h_preamble) debug1_r <= 1;
	if (h_data) debug1_r <= 3;
	if (h_drop) debug1_r <= 2;
end

// Synchronization and pipelining step
// Squelch data that isn't being considered
reg h_data_d1=0, h_data_d2=0, data_first=0;
reg [7:0] data_d1=0, data_d2=0;
always @(posedge clk) begin
	h_data_d1 <= h_data;
	h_data_d2 <= h_data & h_data_d1;  // XXX horrible hack
	// Why does h_data last one octet past last Ethernet octet in data?
	data_first <= h_data & ~h_data_d1;
	data_d1 <= eth_strobe ? eth_octet : 8'b0;
	data_d2 <= data_d1;
end

// Unified handling of MAC/IP addresses via external config memory
//
// Ethernet
// Dest    MAC:  octets 0-5    match me (might be FF for broadcast)
// Source  MAC:  octets 6-11
//
// ARP (RFC 826)
// Sender  MAC:  octets 22-27
// Sender   IP:  octets 28-31
// Placeholder:  octets 32-37
// Dest     IP:  octets 38-41  match me
//
// IP (RFC 791)
// Source   IP:  octets 26-29
// Dest     IP:  octets 30-33  match me
//
// ICMP (RFC 792)
// UDP (RFC 768)
//
reg [10:0] pack_cnt=0;
always @(posedge clk) begin
	pack_cnt <= h_data ? pack_cnt+1 : 0;
end
assign drop_packet = pack_cnt >= 1536;
assign ip_a = pack_cnt > 36 || pack_cnt < 16 ? pack_cnt[3:0] : pack_cnt[3:0]+8;
wire ip_m = ip_d == data_d1;
// This pack_cnt decoding is synthesizable as is; we can make it more gate-
// efficient later, using synthesis measurements and good regression tests.
reg want_c_eth=0, want_c_arp=0, want_c_ip=0;
always @(posedge clk) begin
	want_c_eth <= pack_cnt < 6;
	want_c_arp <= pack_cnt >= 38 && pack_cnt < 42;
	want_c_ip  <= pack_cnt >= 30 && pack_cnt < 34;
end
// Accumulate state
wire pz = pack_cnt == 0;
reg pass_ethmac=0;  always @(posedge clk) begin if (want_c_eth & ~ip_m) pass_ethmac <= 0; if (pz) pass_ethmac <= 1; end
reg pass_arpip=0;   always @(posedge clk) begin if (want_c_arp & ~ip_m) pass_arpip  <= 0; if (pz) pass_arpip  <= 1; end
reg pass_ipdst=0;   always @(posedge clk) begin if (want_c_ip  & ~ip_m) pass_ipdst  <= 0; if (pz) pass_ipdst  <= 1; end

// Specific protocols; IP is a component of both ICMP and UDP
wire [15:0] ip_length, udp_length;

wire pass_arp0;
generate if (handle_arp) begin: find_arp
	arp_patt arp_p (.clk(clk), .cnt(pack_cnt), .data(data_d1), .pass(pass_arp0));
end else assign pass_arp0 = 0;
endgenerate

wire pass_icmp0;
generate if (handle_icmp) begin: find_icmp
	icmp_patt icmp_p(.clk(clk), .cnt(pack_cnt), .data(data_d1), .pass(pass_icmp0));
end else assign pass_icmp0 = 0;
endgenerate

wire pass_ip0;   ip_patt   ip_p  (.clk(clk), .cnt(pack_cnt), .data(data_d1), .pass(pass_ip0), .length(ip_length));
wire pass_udp0;  udp_patt  udp_p (.clk(clk), .cnt(pack_cnt), .data(data_d1), .pass(pass_udp0), .length(udp_length));
wire pass_sum;   cksum_chk chk_p (.clk(clk), .cnt(pack_cnt), .data(data_d1), .pass(pass_sum), .length(ip_length));

// CRC32
wire crc_zero;
crc8e_guts crc8e(.clk(clk), .gate(h_data_d1), .first(data_first),
	.d_in(data_d1), .zero(crc_zero));
wire final_octet = h_data_d1 & ~h_data;

// UDP port number
reg udp_port_stb=0;
always @(posedge clk) udp_port_stb <= pack_cnt == 36;
wire [2:0] port_p0;  wire port_h, port_v;
udp_port_cam #(.naw(3)) cam(.clk(clk),
	.port_s(udp_port_stb), .data(data_d1),
	.pno_a(pno_a), .pno_d(pno_d),
	.port_p(port_p0), .port_h(port_h), .port_v(port_v)
);

// Packet length (doesn't count GMII preamble)
reg [10:0] pack_len_r=0;
always @(posedge clk) if (h_data) pack_len_r <= pack_cnt;

// Weird place for this
reg ip_len_check=0, udp_len_check=0;
always @(posedge clk) if (h_data) begin
	ip_len_check <= pack_cnt >= ip_length + 18; // 18 = 14 Ethernet header + 4 CRC
	udp_len_check <= ip_length >= udp_length + 20; // 20 = IP header length
end

// One more oddball
reg unicast_src_mac=0;
always @(posedge clk) begin
	if (pack_cnt==1) unicast_src_mac <= 1;  // optimistic, needed to make busy flag work
	if (pack_cnt==7) unicast_src_mac <= ~data_d1[0];
end

// Summary bits don't leak irrelevant state
wire pass_arp  = unicast_src_mac & crc_zero & pass_arp0 & pass_arpip;
wire pass_ip   = unicast_src_mac & crc_zero & pass_ethmac & pass_ip0 & pass_ipdst & ip_len_check;
wire pass_icmp = pass_ip & pass_icmp0 & pass_sum;
wire pass_udp  = pass_ip & pass_udp0 & udp_len_check & port_h;
wire [1:0] category = pass_udp ? 3 : pass_icmp ? 2 : pass_arp ? 1 : 0;
wire [2:0] port_p = pass_udp ? port_p0 : 3'd0;

// Summary output
assign status_vec = {port_p, pass_ip, pass_ethmac, crc_zero, category};
assign status_valid = final_octet;
assign pack_len = pack_len_r;

// Other summary output
wire busy_with_arp = unicast_src_mac & pass_arp0;
wire busy_with_udp = unicast_src_mac & pass_ethmac & pass_ip0 & pass_udp0;
wire busy_with_icmp = unicast_src_mac & pass_ethmac & pass_ip0 & pass_icmp0;
reg busy_r=0, keep_r=0;
always @(posedge clk) begin
	busy_r <= odata_s & (busy_with_arp | busy_with_udp | busy_with_icmp);
	keep_r <= odata_s & (category != 0);
end
assign busy = busy_r;
assign keep = keep_r;

// Debug helper
reg [1:0] debug2_r=0;
always @(posedge clk) begin
	if (status_valid) debug2_r <= category;
end
assign debug = {debug2_r, debug1_r};

// Output ports
assign odata = data_d2;
assign odata_s = h_data_d2;
assign odata_f = final_octet;

endmodule

// New modules to get new name spaces

// =====
// UDP/ICMP Checksum checker
// Calculation structure is about the same, superficially looks like
// we just need a little stream selection logic based on the protocol,
// and a single one's-complement accumulator can handle both cases.
// This rosy scenario is stymied by UDP's pathological inclusion of
// _two_ copies of the UDP length.  At the moment, therefore, this
// module doesn't handle UDP.
module cksum_chk(
	input clk,
	input [10:0] cnt,
	input [7:0] data,
	input [15:0] length,  // IP length
	output pass
);

wire chksum_zero = cnt == 22;  // or earlier
wire icmp_gate = cnt >= 35;
// wire udp_gate = cnt >= 23;
wire chksum_gate = icmp_gate;

// Make sure length is known before using it
wire end_of_ip = cnt>32 && cnt == (length+14);

// Standard one's-complement checksum
wire ones;
ones_chksum ck(.clk(clk), .clear(chksum_zero), .gate(chksum_gate),
	.din(data), .all_ones(ones));

// Final state, should find FF FF at end of IP packet
reg eof=0, state=0;
always @(posedge clk) begin
	if (chksum_zero) state <= 0;
	if (end_of_ip) state <= ones;
	eof <= end_of_ip;
	if (eof) state <= state & ones;
end
assign pass = state;

endmodule // UDP/ICMP Checksum checker

// =====
// ARP pattern checker
module arp_patt(
	input clk,
	input [10:0] cnt,
	input [7:0] data,
	output pass
);

reg [7:0] template;
always @(posedge clk) case(cnt[3:0])
	// template starts at 12th byte of Ethernet packet,
	// after the two MAC addresses.
	4'd12: template <= 8'h08;
	4'd13: template <= 8'h06;
	4'd14: template <= 8'h00;   // ARP Ethernet hardware, octet 1
	4'd15: template <= 8'h01;   // ARP Ethernet hardware, octet 2
	4'd00: template <= 8'h08;   // ARP Protocol IP
	4'd01: template <= 8'h00;   // ARP Protocol IP
	4'd02: template <= 8'h06;   // ARP protocol address length
	4'd03: template <= 8'h04;   // ARP protocol address length
	4'd04: template <= 8'h00;   // ARP protocol operation
	4'd05: template <= 8'h01;   // ARP protocol operation (request)
	default: template <= 8'h00;
endcase

reg want=0, pass_r=0;
wire match = data == template;
always @(posedge clk) begin
	want <= cnt >= 12 && cnt < 22;
	if (cnt == 0) pass_r <= 1;
	if (want & ~match) pass_r <= 0;
end
assign pass = pass_r;

endmodule  // ARP pattern checker

// =====
// IP pattern checker
module ip_patt(
	input clk,
	input [10:0] cnt,
	input [7:0] data,
	output pass,
	output [15:0] length
);

reg [7:0] template;
always @(posedge clk) case(cnt[4:0])
	// template starts at 12th byte of Ethernet packet,
	// after the two MAC addresses.
	5'd12: template <= 8'h08;  // Bytes 12 and 13 are Ethertype IPv4
	5'd13: template <= 8'h00;  // https://en.wikipedia.org/wiki/Ethertype

	// Start of IPv4 header [https://en.wikipedia.org/wiki/IPv4#Header]
	5'd14: template <= 8'h45;  // Vers (4 for ipv4) / IHL (> 5 is a weird case)
	// 15  ignore  TOS (later changed to DSCP and ECN)
	// 16  ignore  length msb
	// 17  ignore  length lsb
	// 18  ignore  identification msb
	// 19  ignore  identification lsb
	5'd20: template <= 8'h00;  // Flags/Fragment
	5'd21: template <= 8'h00;
	// 22  ignore  TTL (but see below)
	// 23  ignore  Protocol
	// 24-33  header checksum, source address, destination address
	default: template <= 8'h00;
endcase

// Packet has expired when TTL hits zero
reg ttl_flag=0;
wire zero_ttl = ttl_flag & ~(|data);

reg want=0, mask_df_bit=0, pass_r=0;
wire [7:0] df_mask = {1'b1, ~mask_df_bit, 6'h3f};
wire match = (data&df_mask) == template;
always @(posedge clk) begin
	want <= cnt >= 12 && cnt < 15 || cnt >= 20 && cnt < 22;
	mask_df_bit <= cnt == 20;
	ttl_flag <= cnt == 22;
	if (cnt == 0) pass_r <= 1;
	if (want & ~match) pass_r <= 0;
	if (zero_ttl) pass_r <= 0;
end

// IP packet total length
// Quoting RFC 791, Total Length is the length of the datagram,
// measured in octets, including internet header and data.
reg [7:0] data_d=0;
reg [15:0] length_r=0;
always @(posedge clk) begin
	data_d <= data;
	if (cnt==18) length_r <= {data_d, data};
end
assign length = length_r;

// IP header checksum
reg out_chksum_gate=0, out_chksum_zero=0;
always @(posedge clk) begin
	out_chksum_gate <= cnt >= 14 && cnt < 34;
	out_chksum_zero <= cnt == 0;
end
wire chksum_all_ones;
ones_chksum ck(.clk(clk), .clear(out_chksum_zero), .gate(out_chksum_gate),
	.din(data), .all_ones(chksum_all_ones));
reg chksum_all_ones_d=0;
reg chksum_fail=0;
always @(posedge clk) begin
	chksum_all_ones_d <= chksum_all_ones;
	if (cnt==0) chksum_fail <= 0;
	if (cnt==35) chksum_fail <= ~chksum_all_ones | ~chksum_all_ones_d;
end
assign pass = pass_r & ~chksum_fail;

endmodule  // IP header

// =====
// ICMP pattern checker
// For ICMP checksum see module cksum_chk
module icmp_patt(
	input clk,
	input [10:0] cnt,
	input [7:0] data,
	output pass
);

reg [7:0] template;
always @(posedge clk) case(cnt[2:0])
	// Ethernet/IP header is not in our scope
	// template starts at 23rd byte of Ethernet packet,
	// after the two MAC addresses.
	3'd7: template <= 8'h01;  // cnt==23, Proto (ICMP)
	3'd2: template <= 8'h08;  // cnt==34, ICMP echo request
	3'd3: template <= 8'h00;  // cnt==35, ICMP code
	default: template <= 8'h00;
endcase

reg want=0, pass_r=0;
wire match = data == template;
always @(posedge clk) begin
	want <= cnt == 23 || cnt==34 || cnt==35;
	if (cnt == 0) pass_r <= 1;
	if (want & ~match) pass_r <= 0;
end
assign pass = pass_r;

endmodule  // ICMP pattern checker

// =====
// UDP pattern checker
module udp_patt(
	input clk,
	input [10:0] cnt,
	input [7:0] data,
	output pass,
	output [15:0] length
);

// Degenerate form of template ROM
// Moving this template and comparison to ip_patt would save 2 LUTs.
wire [7:0] template = 8'h11;  // cnt==23, Proto (UDP)

// Reject packets from source port number < 1024,
// as they come from "trusted" sources.
// This is part of the strategy to resist echo loops.
wire reject_low = cnt==35 & ~|data[7:2];

// Reject packets to destination port number 0
reg pzero_d=0, pzero_d1=0, pzero_t=0;
always @(posedge clk) begin
	pzero_d <= data == 8'h00;
	pzero_d1 <= pzero_d;
	pzero_t <= cnt == 36;
end
wire discard_port0 = pzero_t & pzero_d & pzero_d1;

reg want=0, pass_r=0;
wire match = data == template;
always @(posedge clk) begin
	want <= cnt == 23;
	if (cnt == 0) pass_r <= 1;
	if (want & ~match) pass_r <= 0;
	if (reject_low) pass_r <= 0;
	if (discard_port0) pass_r <= 0;
end
assign pass = pass_r;

// UDP packet length
// Length is the length in octets of this user datagram including [UDP]
// header and the data.
reg [7:0] data_d=0;
reg [15:0] length_r=0;
always @(posedge clk) begin
	data_d <= data;
	if (cnt==40) length_r <= {data_d, data};
end
assign length = length_r;

// XXX We don't yet compute the UDP checksum.
// That may not be a practical problem.

endmodule  // UDP pattern checker
