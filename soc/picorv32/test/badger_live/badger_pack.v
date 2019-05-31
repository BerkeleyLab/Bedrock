// --------------------------------------------------------------
//  badger_pack.v
// --------------------------------------------------------------
// Packet Badger MAC for picorv32.

module badger_pack #(
    parameter BASE_ADDR = 8'h00,    // MSB of Picorv32 memory address
    parameter BUF_SIZE=1500         // [bytes]
) (
    input            sys_clk,       // picorv system clock / gtx clock (~125 MHz)
    input            rst,           // high = reset

    // PicoRV32 packed MEM Bus interface
    input  [68:0]    mem_packed_fwd,
    output [32:0]    mem_packed_ret,

    // Connect to pads of ethernet PHY chip
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

localparam BASE_SFR   = 8'h00;
localparam BASE_BUF0  = 8'h01;

assign eth_clocks_gtx = eth_clocks_rx;
wire [32:0] mem_packed_ret_0;
wire [32:0] mem_packed_ret_1;
assign mem_packed_ret = mem_packed_ret_0 | mem_packed_ret_1;

rtefi_blob #(
    .paw            (11)
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
    // Pass-through to user modules

    // Dumb stuff to get LEDs blinking
    .rx_mon         (),
    .tx_mon         (),
    // Simulation-only
    .in_use         ()
);

reg host_start = 0;
wire [31:0] buf_start_addr;
wire [31:0] sfRegsWrStr;
wire done;

always @(posedge sys_clk)
    if (done)
        host_start <= 1'b0;
    else if (sfRegsWrStr[16])
        host_start <= 1'b1;

sfr_pack #(
    .BASE_ADDR      (BASE_ADDR),
    .BASE2_ADDR     (BASE_SFR),
    .N_REGS         (1)
) sfrInst (
    .clk            (sys_clk),
    .rst            (rst),
    .mem_packed_fwd (mem_packed_fwd),
    .mem_packed_ret (mem_packed_ret_0),
    .sfRegsOut      (buf_start_addr),
    .sfRegsIn       ({15'h0, host_start, buf_start_addr[15:0]}),
    .sfRegsWrStr    (sfRegsWrStr)
);

// --------------------------------------------------------------
//  Unpack the MEM bus
// --------------------------------------------------------------
// What comes out of unpack
wire [31:0] mem_wdata;
wire [ 3:0] mem_wstrb;
wire        mem_valid;
wire [31:0] mem_addr;
wire [13:0] word_addr = mem_addr[15:2];  // [words] Addressing 4 byte words
reg  [31:0] mem_rdata;
reg         mem_ready;
wire is_addressed = mem_valid && !mem_ready && (mem_addr[31:16] == {BASE_ADDR, BASE_BUF0});
munpack mu (
    .mem_packed_fwd(mem_packed_fwd),
    .mem_packed_ret(mem_packed_ret_1),
    .mem_wdata (mem_wdata),
    .mem_wstrb (mem_wstrb),
    .mem_valid (mem_valid),
    .mem_addr  (mem_addr),
    .mem_ready (mem_ready),
    .mem_rdata (mem_rdata)
);

reg [31:0] buf0[(BUF_SIZE / 4 - 1):0];
integer i;
initial for (i=0; i<BUF_SIZE / 4; i=i+1) buf0[i] = 8'h0;

always @(posedge sys_clk) begin
    mem_ready <=  1'b0;
    mem_rdata <= 32'h0;
    if (is_addressed) begin
        mem_rdata <= buf0[word_addr];
        if (mem_wstrb[0]) buf0[word_addr][ 7: 0] <= mem_wdata[ 7: 0];
        if (mem_wstrb[1]) buf0[word_addr][15: 8] <= mem_wdata[15: 8];
        if (mem_wstrb[2]) buf0[word_addr][23:16] <= mem_wdata[23:16];
        if (mem_wstrb[3]) buf0[word_addr][31:24] <= mem_wdata[31:24];
        mem_ready <= 1;
    end
end

wire [9:0] host_raddr;  // [16 bit words]
reg [15:0] host_rdata;
always @(posedge eth_clocks_gtx) begin
    if (host_raddr[0])
        host_rdata <= buf0[host_raddr[9:1]] >> 16;
    else
        host_rdata <= buf0[host_raddr[9:1]];
end

endmodule
