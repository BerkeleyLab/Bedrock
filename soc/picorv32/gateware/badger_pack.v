// --------------------------------------------------------------
//  badger_pack.v
// --------------------------------------------------------------
// Packet Badger MAC for picorv32.

module badger_pack #(
    parameter BASE_ADDR = 8'h00     // MSB of Picorv32 memory address
) (
    input            sys_clk,       // picorv system clock / gtx clock (~125 MHz)
    input            rst,           // high = reset

    // PicoRV32 packed MEM Bus interface
    input  [68:0]    mem_packed_fwd,
    output [32:0]    mem_packed_ret,

    // Connect to pads of Ethernet PHY chip
    // https://en.wikipedia.org/wiki/Media-independent_interface#Gigabit_media-independent_interface
    input eth_clocks_rx,       // clock recovered from wire
    input eth_rx_dv,
    input eth_rx_er,           // Receive error
    input [7:0] eth_rx_data,
    // input eth_col,          // Collision
    // input eth_crs,          // Carrier sense
    // input eth_clocks_tx,    // 10 / 100 Mbit/s clock not supported
    output eth_clocks_gtx,     // 125 MHz clock to PHY for gigabit TX
    output eth_rst_n,
    output eth_tx_en,
    output eth_tx_er,
    output [7:0] eth_tx_data,
    output eth_mdc,            // Management clock
    inout eth_mdio             // Management data in / out
);

// Address width of the Ethernet mac [16 bit words]
localparam MAC_AW = 10;

// Size of the RX / TX buffers mapped into the picorv memory [32 bit words]
localparam BUF_SIZE = (1 << MAC_AW) / 2; // = 512 words
localparam BASE_SFR  = 8'h00;
localparam BASE_TX  = 8'h01;
localparam BASE_RX  = 8'h02;
integer i;

assign eth_clocks_gtx = eth_clocks_rx;
wire [32:0] mem_packed_ret_dpram;
wire [32:0] mem_packed_ret_sfr;
assign mem_packed_ret = mem_packed_ret_dpram | mem_packed_ret_sfr;

// Interface to send packets
wire [MAC_AW - 1:0] host_raddr;
wire [14:0] unused;
wire tx_mac_start, tx_mac_done;
reg [15:0] host_rdata;
wire [15:0] buf_start_addr;

wire [7:0] rx_mac_d;
wire [11:0] rx_mac_a;
wire rx_mac_wen;

reg rx_mac_hbank = 1;
wire mac_bank, rx_buffer_swap, rx_mac_hbank_r, rx_mac_accept, rx_mac_status_s;
wire [7:0] rx_mac_status_d;
reg [7:0] rx_mac_status = 8'h0;
wire rx_mac_new_data = mac_bank == rx_mac_hbank_r;
always @(posedge sys_clk) if(rx_buffer_swap) rx_mac_hbank <= !rx_mac_hbank;
always @(posedge eth_clocks_rx) if(rx_mac_status_s) rx_mac_status <= rx_mac_status_d;

// Let picorv32 control buf_start_addr, _start and read _done
wire [31:0] sfr_out, sfr_in, sfr_str;
sfr_pack #(
    .BASE_ADDR      (BASE_ADDR),
    .BASE2_ADDR     (BASE_SFR),
    .N_REGS         (1)
) sfrInst (
    .clk            (sys_clk),
    .rst            (rst),
    .mem_packed_fwd (mem_packed_fwd),
    .mem_packed_ret (mem_packed_ret_sfr),
    .sfRegsOut      (sfr_out),
    .sfRegsIn       (sfr_in),
    .sfRegsWrStr    (sfr_str)
);

assign buf_start_addr = sfr_out[15:0];
assign tx_mac_start = sfr_out[16];
assign rx_mac_accept = sfr_out[17];
assign sfr_in[17:0] = sfr_out[17:0];
assign sfr_in[18] =  tx_mac_done;
assign sfr_in[19] = 1'h0;
assign rx_buffer_swap = sfr_str[19];
assign sfr_in[20] = rx_mac_new_data;
assign sfr_in[23:21] = 3'h0;
assign sfr_in[31:24] = rx_mac_status;

rtefi_blob #(
    .paw            (11),
    // sets size (in 16-bit words) of DPRAM in Tx MAC
    .mac_aw         (MAC_AW)
) rtefi_blob_inst (
    // GMII Input (Rx)
    .rx_clk         (eth_clocks_rx),
    .rxd            (eth_rx_data),
    .rx_dv          (eth_rx_dv),
    .rx_er          (eth_rx_er),

    // GMII Output (Tx)
    .tx_clk         (eth_clocks_gtx),
    .tx_en          (eth_tx_en),
    .tx_er          (eth_tx_er),
    .txd            (eth_tx_data),

    // Configuration
    .enable_rx      (1'b1),
    .config_clk     (sys_clk),
    .config_a       (4'b0),
    .config_d       (8'b0),
    .config_s       (1'b0),  // MAC/IP address write
    .config_p       (1'b0),  // UDP port number write

    // Debugging
    .ibadge_stb     (),
    .ibadge_data    (),
    .obadge_stb     (),
    .obadge_data    (),
    .xdomain_fault  (),

    // ---------------------
    //  Host side of Tx MAC
    // ---------------------
    // connect the 2 below to an external 16 bit dual port ram
    .host_raddr(host_raddr),    // [16 bit words]
    .host_rdata(host_rdata),
    // offset in the above buffer to start transmitting from
    .buf_start_addr(buf_start_addr[MAC_AW - 1 : 0]),
    // 4 - way handshake control signals
    .tx_mac_start(tx_mac_start),
    .tx_mac_done(tx_mac_done),

    // ---------------------
    //  Host side of RX MAC
    // ---------------------
    // port to Rx MAC memory
    .rx_mac_d         (rx_mac_d),
    .rx_mac_a         (rx_mac_a),
    .rx_mac_wen       (rx_mac_wen),

    // port to Rx MAC handshake
    .rx_mac_hbank     (rx_mac_hbank),
    .rx_mac_buf_status({rx_mac_hbank_r, mac_bank}),

    // port to Rx MAC packet selector
    .rx_mac_accept    (rx_mac_accept),
    .rx_mac_status_s  (rx_mac_status_s),
    .rx_mac_status_d  (rx_mac_status_d),

    // Application ports
    .p2_nomangle(1'b0),
    .p3_data_in(32'b0),

    // Dumb stuff to get LEDs blinking
    .rx_mon         (),
    .tx_mon         (),
    // Simulation-only
    .in_use         ()
);

// --------------------------------------------------------------
//  Unpack the MEM bus
// --------------------------------------------------------------
// What comes out of unpack
wire [31:0] mem_wdata;
wire [ 3:0] mem_wstrb;
wire        mem_valid;
wire [31:0] mem_addr;
wire [13:0] word_addr = mem_addr[15:2];  // For addressing memory as [32 bit words]
reg  [31:0] mem_rdata;

reg         mem_ready;
reg         mem_ready_ = 0;
wire ready_sum = mem_ready || mem_ready_;

munpack mu (
    .clk           (sys_clk),
    .mem_packed_fwd(mem_packed_fwd),
    .mem_packed_ret(mem_packed_ret_dpram),
    .mem_wdata (mem_wdata),
    .mem_wstrb (mem_wstrb),
    .mem_valid (mem_valid),
    .mem_addr  (mem_addr),
    .mem_ready (mem_ready),
    .mem_rdata (mem_rdata)
);

// ---------------------
//  Host side of TX MAC
// ---------------------
// `buf_tx` stores 32 bit words
// This is how things should go down ...
// host does
//   * write size + payload packet to buf_tx
//   * set buf_start_addr
//   * set tx_mac_start high
// tx mac does
//   * read buf_tx at offset buf_start_addr
//   * get the packet length from the first word in [bytes]
//   * transmit the Ethernet preamble + SOF (55 55 55 55 55 55 55 D5)
//   * put the buffer content on the wire
//   * transmit the 4 byte CRC
// host does
//   * wait for tx_mac_done to go low
//   * reset tx_mac_start
// TODO why is the preamble only 5 bytes? should be 8!
reg [31:0] buf_tx[BUF_SIZE - 1: 0];
initial for (i=0; i<BUF_SIZE; i=i+1) buf_tx[i] = 32'h0;

// Let the TX Mac read `buf_tx` in 16 bit words
always @(posedge eth_clocks_gtx) begin
    if (host_raddr[0])
        host_rdata <= buf_tx[host_raddr >> 1] >> 16;
    else
        host_rdata <= buf_tx[host_raddr >> 1];
end

// Let picorv read and write `buf_tx` in 8, 16, 24 or 32 bit words
wire is_addressed_tx = mem_valid && !ready_sum && (mem_addr[31:16] == {BASE_ADDR, BASE_TX});

// ---------------------
//  Host side of RX MAC
// ---------------------
// Double buffering works as follows from the host point of view:
//   * rx_mac_buf_status = [rx_mac_hbank_r, mac_bank]
//   * rx_mac_hbank_r = points to the bank currently read (and blocked) by the host
//     mac_bank = points to the bank the badger will write the next packet to (highest address bit)
//  1) badger toggles mac_bank once a packet has been completely received
//  2) The host knows new data is available when rx_mac_hbank_r == mac_bank
//  3) Host toggles rx_mac_hbank and is allowed to read the slot indexed by rx_mac_hbank_r in the next cycle
//  4) This allows badger to receive and write to the other slot, cycle continues from 1
// Allocate RX buffer of 2 * 512 words of 32 bit size
reg [31:0] buf_rx[BUF_SIZE * 2 - 1: 0];
initial for (i = 0; i < BUF_SIZE * 2; i = i + 1) buf_rx[i] = 32'h0;

// Write 8 bit mac data to 32 bit memory
wire [1:0] bSel = rx_mac_a[1:0];
always @(posedge eth_clocks_gtx) begin
    if (rx_mac_wen)
        buf_rx[rx_mac_a >> 2][8 * bSel +: 8] <= rx_mac_d;
end

// Let picorv read and write `buf_rx` in 8, 16, 24 or 32 bit words
// how to select a 32 bit word from the buf_rx array:
//   * rx_mac_hbank_r is selecting the memory bank, it is the MSB of the address
//   * next 9 bits are from picorv32 `mem_addr`, which is addressing bytes
//   * lowest 2 bits of `mem_addr` we don't care as we only do 32 bit aligned access
//   * result is 10 bits = 1024 words = 4096 bytes, enough to hold 2 * MTU of 1500 bytes
wire [9:0] word_addr_rx = (rx_mac_hbank_r << 9) | mem_addr[10:2];
wire is_addressed_rx = mem_valid && !ready_sum && (mem_addr[31:16] == {BASE_ADDR, BASE_RX});
always @(posedge sys_clk) begin
    mem_ready <=  1'b0;
    mem_rdata <= 32'h0;

    if (is_addressed_rx) begin
        mem_rdata <= buf_rx[word_addr_rx];
        mem_ready <= 1'b1;
    end

    if (is_addressed_tx) begin
        mem_rdata <= buf_tx[word_addr];
        if (mem_wstrb[0]) buf_tx[word_addr][ 7: 0] <= mem_wdata[ 7: 0];
        if (mem_wstrb[1]) buf_tx[word_addr][15: 8] <= mem_wdata[15: 8];
        if (mem_wstrb[2]) buf_tx[word_addr][23:16] <= mem_wdata[23:16];
        if (mem_wstrb[3]) buf_tx[word_addr][31:24] <= mem_wdata[31:24];
        mem_ready <= 1;
    end

    mem_ready_ <= mem_ready;
end

endmodule
