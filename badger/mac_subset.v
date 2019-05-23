module mac_subset #(
	parameter aw=10,  // 16-bit words
	parameter big_endian=0,
	parameter latency=256,
	parameter stretch=4,  // minimum value 2, should be 4 for GMII
	parameter ifg=24   // must have more padding than just Ethernet IFG
) (
	input host_clk,
	// note that the high-order bit of host_waddr is used to
	// select control registers
	input [aw:0] host_waddr,
	input host_write,
	input [15:0] host_wdata,
	output done,
	// crucial information from input scanner
	input scanner_busy,
	// Connection to output multiplexer, right after xformer.v,
	// data path will get routed to have CRC added, strobes are
	// as needed by that step: strobe_s includes data only,
	// strobe l includes time slots for GMII preamble and CRC.
	input tx_clk,
	output strobe_s,
	output strobe_l,
	output [7:0] mac_data
);

// Dual-port RAM
reg [15:0] host_mem[0:(1<<aw)-1];
wire host_dpram_write = host_write & ~host_waddr[aw];
always @(posedge host_clk) if (host_dpram_write)
	host_mem[host_waddr[aw-1:0]] <= host_wdata;
wire [aw-1:0] host_raddr;
reg [15:0] host_rdata=0;
always @(posedge tx_clk) host_rdata <= host_mem[host_raddr];

// Writing the start address triggers sending
reg [aw-1:0] buf_start_addr;
wire host_start_write = host_write & host_waddr[aw];
reg host_pre_start=0, host_start=0;
always @(posedge host_clk) begin
	if (host_start_write & ~host_waddr[0]) buf_start_addr <= host_wdata;
	if (host_start_write) host_pre_start <= ~host_waddr[0];
	host_start <= host_pre_start;
end

// Instantiate MAC
wire req;
wire [10:0] len_req;
wire mac_strobe;
test_tx_mac #(.aw(aw)) mac(.clk(tx_clk),
	.host_addr(host_raddr), .host_d(host_rdata),
	.start(host_start), .buf_start_addr(buf_start_addr), .done(done),
	.req(req), .len_req(len_req),
	.strobe(mac_strobe), .mac_data(mac_data)
);

// Instantiate precog
wire clear_to_send;
wire [10:0] precog_width = len_req + 2*ifg;
precog #(
	.PAW (11),
	.LATENCY (latency+ifg)
) precog (
	.clk (tx_clk),
	.tx_packet_width  (precog_width),
	.scanner_busy     (scanner_busy),
	.request_to_send  (req),
	.clear_to_send    (clear_to_send)
);

// Manipulate simple strobe from precog
// final system wants 4 cycles lead (for GMII preamble) and
// 4 cycle trailer (for CRC) on strobe_l compared to strobe_s.
reg [stretch-1:0] strobe_sr1=0;
always @(posedge tx_clk) strobe_sr1 <= {strobe_sr1[stretch-2:0], clear_to_send};
reg [stretch-1:0] strobe_sr2=0;
always @(posedge tx_clk) strobe_sr2 <= {strobe_sr2[stretch-2:0], req};
assign mac_strobe = strobe_sr1[stretch-1] & req;
assign strobe_s = mac_strobe;
assign strobe_l = clear_to_send & strobe_sr2[stretch-1];

endmodule
