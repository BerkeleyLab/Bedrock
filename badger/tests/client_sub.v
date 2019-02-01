// Helper module for client simulations
// Creates the master side of the interface shown in clients.eps
// using either a data file, or live from a UDP port
`timescale 1ns / 1ns
module client_sub(
	output clk,
	// Synthesized data to DUT
	output [10:0] len_c,
	output [7:0] idata,
	output raw_l,
	output raw_s,
	// Data returned from DUT
	input [7:0] odata
);

parameter msg_len=48;  // bytes
parameter n_lat=3;
parameter pst = 40;  // start time for packet stimulus
parameter preamble_cnt = 18;  // should be 44(?) but I'm easily bored.
parameter sim_length = 250;  // for off-line runs

reg clk_r, log;
integer cc;
integer udp_port;  // non-zero to enable UDP socket mode
reg [255:0] packet_file;  // file name
integer data_len;
reg [7:0] in_stream[0:msg_len-1];  // file contents
initial begin
	log = $test$plusargs("log");
	if (!$value$plusargs("packet_file=%s", packet_file)) packet_file="xfer1";
	if (!$value$plusargs("udp_port=%d", udp_port))  udp_port=0;
	if (udp_port!=0) $udp_init(udp_port);
	else $readmemh(packet_file, in_stream);
	if (!$value$plusargs("data_len=%d", data_len)) data_len=48;
	// Run forever (until interrupt) when connected to UDP socket
	for (cc=0; (udp_port!=0) || (cc<sim_length); cc=cc+1) begin
		clk_r=0; #4;
		clk_r=1; #4;
	end
end
assign clk = clk_r;

// Live only, also want capability to schlep packet from
// in_stream (as read from file) to DUT input.
integer jx;
reg [7:0] oxd=0;  // o for origin
reg payload_short=0, payload=0;
wire thinking=0;
reg udp_iflag=0;
reg [7:0] udp_idata;
reg [10:0] udp_count, len_c=0;
always @(posedge clk) begin
	len_c <= 11'bx;
	oxd <= 8'hxx;
	payload <= 0;
	payload_short <= 0;
	if (udp_port!=0 && cc>30) begin
		$udp_in(udp_idata, udp_iflag, udp_count, thinking);
		oxd <= udp_idata;
		payload <= udp_iflag;
		payload_short <= udp_iflag && udp_count>0;
		len_c <= udp_count==0 ? 8'bx : udp_count + 8;
	end else if (cc>=pst && cc<pst+data_len) begin
		oxd <= in_stream[cc-pst];
		payload <= 1;
		payload_short <= 1;
		len_c <= data_len+8+pst-cc;
	end else if (cc>=pst-preamble_cnt && cc<pst+data_len+4) begin
		payload <= 1;
	end
end

// Drive the named outputs; len_c is already taken care of
assign raw_s = payload_short;
assign raw_l = payload;
assign idata = oxd;

wire [7:0] txd = odata;

// Delay raw_s by n_lat cycles to get output strobe
reg [n_lat-1:0] txg_shift=0;
always @(posedge clk) txg_shift <= {txg_shift[n_lat-2:0], raw_s};
wire txg = txg_shift[n_lat-1];

// Send output back to the network
reg [7:0] udp_odata;
reg udp_oflag=0;
wire opack_complete = udp_oflag & ~ txg;
always @(posedge clk) begin
	udp_odata <= txd;
	udp_oflag <= txg;
	if ((udp_port!=0) & udp_oflag) begin
		$udp_out(udp_odata, opack_complete);
	end
end

// Option to print output
always @(negedge clk) begin
	if (log & txg) $display("%2x", txd);
end

endmodule
