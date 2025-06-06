// Output packet construction

// Handles Ethernet, ARP, and IP layers, ready to hand over
// to the application-layer UDP content handling.
// The core of the data path is documented in doc/tx_path.eps,
// with the table generated by tx_gen.py based on
// tx_*_table.csv.

// Synthesized on its own, without the associated packet memory
// or MAC/IP config memory, it takes up about 74 LUTs.

module construct #(
	parameter paw=11,  // packet address width, 11 IRL, maybe less for simulations
	parameter p_offset = 480  // Keep an eye on this.
	// Has to be at least 6 for usual fp_offset of 0, but also
	// add -min(fp_offset)+guard.  The guard needs to include
	// allowance Rx/Tx frequency offset.
	// At the other end, p_offset + max(fp_offset) < (2048-MTU-guard)
) (
	input clk,  // timespec 6.8 ns
	input [paw-1:0] gray_state,
	// port to MAC/IP config, single-cycle latency
	output [3:0] ip_a,
	input [7:0] ip_d,
	// Read port of 1 MTU DPRAM, again single-cycle latency
	output [paw-1:0] addr,
	input [8:0] pbuf_out,
	// Debugging hook
	output badge_stb,
	output [7:0] badge_data,
	output xdomain_fault,
	output xcheck_fault,
	// Output to xformer
	output [5:0] pc,
	output [1:0] category,
	output [2:0] udp_sel,
	output [7:0] eth_data_out,
	output eth_strobe_long,  // includes GMII preamble and CRC32
	output eth_strobe_short  // doesn't
);

// Capture state across clock domains, then convert back to binary
wire [paw-1:0] gray_l;
// Better to pull this first step up to rtefi_center?
reg_tech_cdc gcx[paw-1:0] (.C(clk), .I(gray_state), .O(gray_l));
// verilator lint_save
// verilator lint_off UNOPTFLAT
wire [paw-1:0] new_state = gray_l ^ {1'b0, new_state[paw-1:1]};
// verilator lint_restore
reg [paw-1:0] state=0;
always @(posedge clk) state <= new_state;

// Debugging hook
reg [paw-1:0] old_state=0, state_diff=0;
reg xdomain_fault_r=0;
always @(posedge clk) begin
	old_state <= state;
	state_diff <= state - old_state;
	// state_diff must be 0, 1, or 2 for things to work right
	xdomain_fault_r <= |state_diff[paw-1:2] || &state_diff[1:0];
end
assign xdomain_fault = xdomain_fault_r;


// Construct frame pointer that tracks the one in scanner.v
wire packet_active;
wire [paw-1:0] fp;
`ifdef COMMON_CLOCKS
assign fp = state + p_offset;
`else
// cope with max 100 ppm frequency offset between input and output.
reg [paw-1:0] fp_r=0;
assign fp = packet_active ? fp_r+1 : state+p_offset;
always @(posedge clk) fp_r <= fp;
// This will be really slow.  Have to pack an increment, mux, add,
// and RAM access into a single cycle.
`endif
// XXX Deserves a consistency check to find out if fp drifts into
// a danger zone relative to state.

reg [5:0] pc_r=0;
// SOF: Start Of Frame
wire pre_sof = pbuf_out[8] & ~pbuf_out[7] && (pc_r==0);
wire sof = pbuf_out[8] & pbuf_out[7] && (pc_r==0);  // hack to get around x's in fp_offset
wire [7:0] pbuf_out8 = pbuf_out[7:0];
wire signed [5:0] fp_offset, cf_offset;
reg live=0;
assign packet_active = pre_sof | sof | live;
reg [10:0] pack_len_r=0;
wire pc_not_saturated = |(~pc_r[5:4]);  // check if pc < 48
wire [5:0] next_pc = sof ? 2 : live ? pc_r + pc_not_saturated : 0;

// reference: status_vec = {port_p, pass_ip, pass_ethmac, crc_zero, category};
reg [7:0] status_vec=0;
assign category = status_vec[1:0];
assign udp_sel = status_vec[7:5];
reg p_strobe=0;  // Reading packet content (including checksum)
reg o_strobe=0;  // ignores checksum
reg sof_d=0;
// Would it take fewer resources to replace sof_d with (live && pc_r == 2)?
// Or to replace (live && pc_r==3) with sof_dd?  Need to measure to find out.
// Could be worth breaking this up into 2 always blocks (badge and data)?
// Not really, they both have to touch the "live" register.
always @(posedge clk) begin
	pc_r <= next_pc;
	sof_d <= sof;
	if (sof) begin
		live <= 1;
		pack_len_r[6:0] <= pbuf_out8[6:0];
	end
	if (sof_d) pack_len_r[10:7] <= pbuf_out8[3:0];
	if (live && pc_r==3) status_vec <= pbuf_out8;
	// pc_r == 5 the badge has been read!
	if (live && pc_r==5 && category!=0) begin o_strobe <= 1; p_strobe <= 1; end
	if (live && pc_r==5 && category==0) begin live <= 0; pack_len_r <= 0; end
	if (p_strobe) pack_len_r <= pack_len_r-1;
	if (pack_len_r==5) o_strobe <= 0;
	if (pack_len_r==1) begin p_strobe <= 0; live <= 0; end
end

// Debug
reg [2:0] sof_chain=0;
always @(posedge clk) sof_chain <= {sof_chain[1:0], sof};
assign badge_stb = sof | (|sof_chain);
assign badge_data = pbuf_out8;

// Look up instruction and start using it
wire [1:0] out, chk_in;
wire [7:0] template;
construct_tx_table prog(.a({category, pc_r}),
	.v({out, fp_offset, cf_offset, chk_in, template}));
assign addr = fp + {{5{fp_offset[5]}}, fp_offset};
assign ip_a = pc_r + cf_offset;

// Align cycles with the one-cycle delay going through RAM
// (a bit wasteful, could mess with table generation instead?)
// Pipelining not shown in doc/tx_path.eps
reg [7:0] template_d=0;
reg [1:0] out_d=0, chk_in_d=0;
always @(posedge clk) begin
	template_d <= template;
	out_d <= out;
	chk_in_d <= chk_in;
end

// Multiplexers, need to stay consistent with tx_gen.py
reg [7:0] d_chk=0;
always @(posedge clk) case (chk_in_d)
	2'b00: d_chk <= pbuf_out8;
	2'b01: d_chk <= ip_d;
	2'b10: d_chk <= template_d;
	2'b11: d_chk <= 8'd0;
endcase
wire [7:0] ip_head_chksum_data;
// IP header checksum calculation
reg chksum_zero=0, chksum_gate=0;
always @(posedge clk) begin
	chksum_zero <= pc_r <= 3;
	chksum_gate <= (chk_in_d != 2'b11) & ~chksum_zero;
end
ones_chksum ck(.clk(clk), .clear(chksum_zero), .gate(chksum_gate),
	.din(d_chk), .sum(ip_head_chksum_data));

reg [7:0] d_out_pre=0;
always @(posedge clk) case (out_d)
	2'b00: d_out_pre <= pbuf_out8;
	2'b01: d_out_pre <= ip_d;
	2'b10: d_out_pre <= template_d;
	2'b11: d_out_pre <= 0;
endcase
// Last-minute insertion of IP header checksum result .. haha minute
reg out_d_chk_sub=0;
always @(posedge clk) out_d_chk_sub <= out_d == 2'b11;
wire [7:0] d_out = out_d_chk_sub ? ip_head_chksum_data : d_out_pre;
// This could create a critical speed path

// Close out timing within this module
reg [7:0] eth_data_out_r=0;   always @(posedge clk) eth_data_out_r <= d_out;
reg eth_strobe_short_r=0;     always @(posedge clk) eth_strobe_short_r <= o_strobe;
reg pack_len_nz=0;     always @(posedge clk) pack_len_nz <= pack_len_r != 0;
reg [5:0] pc_d=0;      always @(posedge clk) pc_d <= pc_r;

assign eth_data_out = eth_data_out_r;
assign eth_strobe_short = eth_strobe_short_r;
assign eth_strobe_long = pack_len_nz && pc_r > 3 && category != 0;
assign pc = pc_d;

// Debug only, will be dropped if you don't hook up the xcheck_fault port:
// Cross-check the IP header checksum we just computed
reg xcheck_zero=0, xcheck_gate=0, xcheck_ones_d=0;
reg xcheck_capture=0, xcheck_fault_r=0;
wire xcheck_ones;
always @(posedge clk) begin
	xcheck_zero <= pc_r <= 4;
	xcheck_gate <= pc_r >= 20 && pc_r < 40;
	xcheck_ones_d <= xcheck_ones;
	xcheck_capture <= pc_r == 40;
	xcheck_fault_r <= xcheck_capture & ~xcheck_ones & ~xcheck_ones_d;
end
ones_chksum xchk(.clk(clk), .clear(xcheck_zero), .gate(xcheck_gate),
	.din(eth_data_out), .all_ones(xcheck_ones));
assign xcheck_fault = xcheck_fault_r;

endmodule
