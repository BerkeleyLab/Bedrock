module mac_subset #(
	parameter mac_aw=10,  // 16-bit words
	parameter big_endian=0,
	parameter latency=256,
	parameter stretch=4,  // minimum value 2, should be 4 for GMII
	parameter ifg=24   // must have more padding than just Ethernet IFG
) (
	// connect the 2 below to an external 16 bit dual port ram
	output [mac_aw - 1: 0] host_raddr,
	input [15:0] host_rdata,
	// address where we should start transmitting from
	input [mac_aw - 1: 0] buf_start_addr,
	// set start to trigger transmit, wait for done, reset start
	input tx_mac_start,
	output tx_mac_done,
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

reg host_start_=0;
always @(posedge tx_clk) begin
	host_start_ <= tx_mac_start;
end

// Instantiate MAC
wire req;
wire [10:0] len_req;
wire mac_strobe;
test_tx_mac #(
	.mac_aw(mac_aw)
) mac(
	.clk(tx_clk),
	.host_addr(host_raddr),
	.host_d(host_rdata),
	.start(host_start_),
	.buf_start_addr(buf_start_addr),
	.done(tx_mac_done),
	.req(req),
	.len_req(len_req),
	.strobe(mac_strobe),
	.mac_data(mac_data)
);

// Move scanner_busy to tx_clk domain for use by precog
(* ASYNC_REG = "TRUE" *) reg scanner_busy_tx0=0, scanner_busy_tx=0;
always @(posedge tx_clk) begin
	scanner_busy_tx0 <= scanner_busy;
	scanner_busy_tx <= scanner_busy_tx0;
end

// Instantiate precog
wire clear_to_send;
wire [10:0] precog_width = len_req + 2*ifg;
precog #(
	.PAW (11),
	.LATENCY (latency+ifg)
) precog (
	.clk (tx_clk),
	.tx_packet_width  (precog_width),
	.scanner_busy     (scanner_busy_tx),
	.request_to_send  (req),
	.clear_to_send    (clear_to_send)
);

// Manipulate simple strobe from precog
// final system wants 4 cycles lead (for GMII preamble) and
// 4 cycle trailer (for CRC) on strobe_l compared to strobe_s.
// TODO this should be moved to precog
reg [stretch-1:0] strobe_sr1=0;
always @(posedge tx_clk) strobe_sr1 <= {strobe_sr1[stretch-2:0], clear_to_send};
reg [stretch-1:0] strobe_sr2=0;
always @(posedge tx_clk) strobe_sr2 <= {strobe_sr2[stretch-2:0], req};
assign mac_strobe = strobe_sr1[stretch-1] & req;
assign strobe_s = mac_strobe;
assign strobe_l = clear_to_send & strobe_sr2[stretch-1];

endmodule
