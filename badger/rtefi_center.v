// Full RTEFI Rx/Tx pipeline
//
// Ports are abstract GMII (maybe should adjust their names?).
// Non-GMII hardware can and should add an adapter layer to get
// from GMII to RGMII or the MGT.  Actual GMII hardware can just
// connect these ports to the physical pins.
//
// Up to seven clients, each handling a UDP port, attach here.
//
module rtefi_center(
	// GMII Input (Rx)
	input rx_clk,
	input [7:0] rxd,
	input rx_dv,
	input rx_er,
	// GMII Output (Tx)
	input tx_clk,
	output [7:0] txd,
	output tx_en,
	// Configuration
	input enable_rx,
	input config_clk,
	input [3:0] config_a,
	input [7:0] config_d,
	input config_s,  // MAC/IP address write
	input config_p,  // UDP port number write
	// As documented in clients.eps
	output [10:0] len_c,
	output [6:0] raw_l,
	output [6:0] raw_s,
	output [7:0] idata,
	input [7*8-1:0] mux_data_in,  // collection of odata
	// Debugging
	output ibadge_stb,
	output [7:0] ibadge_data,
	output obadge_stb,
	output [7:0] obadge_data,
	output xdomain_fault,
	// Dumb stuff to get LEDs blinking
	output rx_mon,
	output tx_mon,
	// Simulation-only
	output in_use
);

parameter paw = 11;  // packet (memory) address width, nominal 11
parameter n_lat = 3;  // latency of client pipeline
// The following parameters set the synthesis-time default, but all
// can be overridden at run-time using the configuration port.
// UDP ports 0 through 7 represent the index given in udp_sel.
// While udp_port_cam.v is written parameterized, we limit it to
// three bits and 8 ports for timing reasons.  Port 0 is internally
// implemented as echo; the rest will be user-defined via synthesis-time
// plug-ins.  Generally the UDP port numbers should be "well known",
// but the case can be made to have them run-time override-able (without
// resynthesizing) to help cope with unexpected network issues.
parameter [31:0] ip = {8'd192, 8'd168, 8'd7, 8'd4};  // 192.168.7.4
parameter [47:0] mac = 48'h12555500012d;
parameter udp_port0 = 7;
parameter udp_port1 = 801;
parameter udp_port2 = 802;
parameter udp_port3 = 803;
parameter udp_port4 = 0;
parameter udp_port5 = 0;
parameter udp_port6 = 0;
parameter udp_port7 = 0;

// Overhead: make sure the tools can create an IOB on all GMII inputs
reg [7:0] eth_in_r=0;
reg eth_in_s_r=0, eth_in_e_r=0;
always @(posedge rx_clk) begin
	eth_in_r <= rxd;
	eth_in_s_r <= rx_dv;
	eth_in_e_r <= rx_er;
end

// First real step: scan the input packet
wire [3:0] ip_a;  reg [7:0] ip_d=0;  // MAC/IP config, Rx side
wire [3:0] pno_a; reg [7:0] pno_d;  // UDP port numbers
wire [7:0] sdata;
wire sdata_s, sdata_l;
wire [10:0] pack_len;
wire [7:0] status_vec; wire status_valid;
scanner a(.clk(rx_clk),
	.eth_in(eth_in_r), .eth_in_s(eth_in_s_r), .eth_in_e(eth_in_e_r),
	.enable_rx(enable_rx),
	.ip_a(ip_a), .ip_d(ip_d),
	.pno_a(pno_a), .pno_d(pno_d),
	.odata(sdata), .odata_s(sdata_s), .odata_f(sdata_l),
	.pack_len(pack_len), .status_vec(status_vec), .status_valid(status_valid)
);

// Second step: create data flow to DPRAM
wire [paw-1:0] pbuf_a_rx, gray_state;
wire [8:0] pbuf_din;
pbuf_writer #(.paw(paw)) b(.clk(rx_clk),
	.data_in(sdata), .data_s(sdata_s), .data_f(sdata_l),
	.pack_len(pack_len), .status_vec(status_vec), .status_valid(status_valid),
	.mem_a(pbuf_a_rx), .mem_d(pbuf_din),
	.gray_state(gray_state),
	.badge_stb(ibadge_stb)
);
assign ibadge_data = pbuf_din;

// 1 MTU DPRAM; note the ninth bit used to mark Start of Frame.
// Also note the lack of a write-enable, just write every cycle.
reg [8:0] pbuf[0:(1<<paw)-1];
reg [8:0] pbuf_out;
`ifndef YOSYS
initial pbuf_out=0;
`endif
wire [paw-1:0] mem_a2;  // see below
always @(posedge rx_clk) pbuf[pbuf_a_rx] <= pbuf_din;
always @(posedge tx_clk) pbuf_out <= pbuf[mem_a2];
integer jx;
initial for (jx=0; jx<(1<<paw); jx=jx+1) pbuf[jx]=0;

// Third step, sift through that packet's data to
// synthesize the reply packet's header
wire [3:0] ip_mem_a_tx;  reg[7:0] ip_mem_d_tx=0;  // MAC/IP config, Tx side
// Signals sent from construct to xformer
wire [5:0] pc;
wire [1:0] category;
wire [2:0] udp_sel;
wire [7:0] eth_data_out;
wire eth_strobe_short, eth_strobe_long;
construct #(.paw(paw)) c(.clk(tx_clk),
	.gray_state(gray_state),
	.ip_a(ip_mem_a_tx), .ip_d(ip_mem_d_tx),
	.addr(mem_a2), .pbuf_out(pbuf_out),
	.pc(pc), .category(category), .udp_sel(udp_sel),
	.badge_stb(obadge_stb), .badge_data(obadge_data),
	.xdomain_fault(xdomain_fault),
	.eth_data_out(eth_data_out), .eth_strobe_short(eth_strobe_short), .eth_strobe_long(eth_strobe_long)
);

// Data multiplexer
// Port structure to exchange data with various
// UDP packet handlers will go here.
wire xraw_s, xraw_l;  wire [7:0] raw_d;  // Output, still needs CRC
xformer #(.n_lat(n_lat)) xform(.clk(tx_clk),
	.pc(pc), .category(category), .udp_sel(udp_sel),
	.idata(eth_data_out), .eth_strobe_short(eth_strobe_short), .eth_strobe_long(eth_strobe_long),
	.len_c(len_c),
	.raw_l(raw_l), .raw_s(raw_s),
	.mux_data_in(mux_data_in),
	.odata(raw_d), .ostrobe_s(xraw_s), .ostrobe_l(xraw_l)
);
assign idata = eth_data_out;

// Finally, add Ethernet CRC and GMII preamble
wire opack_s;  wire [7:0] opack_d;
ethernet_crc_add crc(.clk(tx_clk),
	.raw_s(xraw_s), .raw_l(xraw_l), .raw_d(raw_d),
	.opack_s(opack_s), .opack_d(opack_d)
);

// Make sure these outputs can be put into an IOB
reg [7:0] eth_out_r=0;
reg eth_out_s_r=0;
always @(posedge tx_clk) begin
	eth_out_r <= opack_d;
	eth_out_s_r <= opack_s;
end
assign txd = eth_out_r;
assign tx_en = eth_out_s_r;

// Has to be distinct from the IOBs
assign rx_mon = eth_in_s_r;
assign tx_mon = opack_s;

// Hook for testing, not intended to be connected in hardware
reg [paw-1:0] in_use_timer=0;
assign in_use = |in_use_timer;
always @(posedge rx_clk) begin
	if (in_use) in_use_timer <= in_use_timer - 1;
	if (rx_mon) in_use_timer <= {paw{1'b1}};
end

// Memory for MAC/IP addresses
reg [7:0] ip_mem[0:15];
always @(posedge config_clk) if (config_s) ip_mem[config_a] <= config_d;
always @(posedge rx_clk) ip_d <= ip_mem[ip_a];
always @(posedge tx_clk) ip_mem_d_tx <= ip_mem[ip_mem_a_tx];
initial begin
	// Matches packets in at least arp3.dat, icmp3.dat, udp3.dat.
	ip_mem[0] = mac[47:40];  // Start of MAC
	ip_mem[1] = mac[39:32];
	ip_mem[2] = mac[31:24];
	ip_mem[3] = mac[23:16];
	ip_mem[4] = mac[15:8];
	ip_mem[5] = mac[7:0];  // End of MAC
	ip_mem[6] = ip[31:24];  // Start of IP
	ip_mem[7] = ip[23:16];
	ip_mem[8] = ip[15:8];
	ip_mem[9] = ip[7:0];  // End of IP
end

// Memory for UDP port numbers
reg [7:0] pno_mem[0:15];
always @(posedge config_clk) if (config_p) pno_mem[config_a] <= config_d;
always @(posedge rx_clk) pno_d <= pno_mem[pno_a];
initial begin
	pno_mem[0] = udp_port0[15:8];
	pno_mem[1] = udp_port0[7:0];
	pno_mem[2] = udp_port1[15:8];
	pno_mem[3] = udp_port1[7:0];
	pno_mem[4] = udp_port2[15:8];
	pno_mem[5] = udp_port2[7:0];
	pno_mem[6] = udp_port3[15:8];
	pno_mem[7] = udp_port3[7:0];
	pno_mem[8] = udp_port4[15:8];
	pno_mem[9] = udp_port4[7:0];
	pno_mem[10] = udp_port5[15:8];
	pno_mem[11] = udp_port5[7:0];
	pno_mem[12] = udp_port6[15:8];
	pno_mem[13] = udp_port6[7:0];
	pno_mem[14] = udp_port7[15:8];
	pno_mem[15] = udp_port7[7:0];
end

endmodule
