/*  An encapsulation of the FPGA (responder) side of the Marble
 *  pseudo-SPI mailbox interface with the MMC.
 */
module mmc_mailbox #(
  parameter [31:0] HASH = 0,
  parameter [0:0] DEFAULT_ENABLE_RX = 1,
  parameter [15:0] UDP_PORT0 = 7,
  parameter [15:0] UDP_PORT1 = 801,
  parameter [15:0] UDP_PORT2 = 802,
  parameter [15:0] UDP_PORT3 = 803,
  parameter [15:0] UDP_PORT4 = 0,
  parameter [15:0] UDP_PORT5 = 0,
  parameter [15:0] UDP_PORT6 = 0,
  parameter [15:0] UDP_PORT7 = 0
)(
  input clk,
  // localbus
  input [10:0]  lb_addr,    // 2kB total memory space
  input  [7:0]  lb_din,     // Data in
  output [7:0]  lb_dout,    // Data out
  input         lb_write,   // Write operation
  input         lb_control_strobe,  // Bus access strobe
  // SPI PHY
  input         sck,        // SCK
  input         ncs,        // formerly NSS
  input         pico,       // formerly MOSI
  output        poci,       // formerly MISO
  // Mailbox status
  output [10:0] mb_addr,    // Mailbox address being accessed (decoded from page/offset)
  output        mb_wen,     // SPI operation from remote host ('1' = write; '0' = read)
  output        mb_ren,     // SPI operation from remote host ('1' = write; '0' = read)
  output        mb_strobe,  // Asserted on each mailbox transaction (rising edge of ncs)
  // Port-Number Memory interface
  input  [2:0]  pno_a,      // Port address (config_port_num)
  output [15:0] pno_d,      // Port number byte (8 of 16 bits)
  // Config pins for badger (rtefi) interface
  output        config_s,
  output        config_p,
  output [7:0]  config_a,
  output [7:0]  config_d,
  // Special pins
  output        enable_rx,  // Controlled via special mailbox commands
  output        ip_valid,   // Asserted when output 'ip' is valid
  output [31:0] ip,         // IP address from mailbox
  output        mac_valid,  // Asserted when output 'mac' is valid
  output [47:0] mac,        // MAC address from mailbox
  output        mmc_gitid_valid,// Asserted when output 'mmc_gitid' is valid
  output [31:0] mmc_gitid,  // MMC 32-bit Git ID
  output        match,      // Asserted if hash from mailbox matches HASH
  output [3:0]  spi_pins_debug // {MISO, din, sclk_d1, csb_d1};
);

// SPI Naming convention: https://www.sparkfun.com/spi_signal_names

localparam GITID_PAGE = 3;
localparam GITID_OFFSET = 12;
localparam HASH_PAGE = 4;
localparam HASH_OFFSET = 12;

// Configuration port
wire config_w, config_r;
wire [3:0] a_lo = config_a[3:0];
wire [3:0] a_hi = config_a[7:4];
wire [7:0] spi_return;
//wire [3:0] spi_pins_debug;
spi_gate spi (
  .SCLK(sck),
  .CSB(ncs),
  .MOSI(pico),                    // input
  .MISO(poci),                    // output
  .config_clk(clk),               // input
  .config_w(config_w),            // output
  .config_r(config_r),            // output
  .config_a(config_a),            // output [7:0]
  .config_d(config_d),            // output [7:0]
  .tx_data(spi_return),           // input [7:0]
  .spi_pins_debug(spi_pins_debug) // output [3:0]
);

// Map generic configuration bus to application
// 16-bit SPI word semantics:
//   0 0 0 1 a a a a d d d d d d d d  ->  set MAC/IP config[a] = D
//   0 0 1 0 0 0 0 0 x x x x x x x V  ->  set enable_rx to V
//   0 0 1 0 0 0 1 0 x d d d d d d d  ->  set 7-bit mailbox page selector
//   0 0 1 1 a a a a d d d d d d d d  ->  set UDP port config[a] = D
//   0 1 0 0 a a a a d d d d d d d d  ->  mailbox read
//   0 1 0 1 a a a a d d d d d d d d  ->  mailbox write
reg enable_rx_r=DEFAULT_ENABLE_RX;  // special case initialization
assign enable_rx = enable_rx_r;
reg [6:0] mbox_page=0;
reg [7:0] ipmac [0:15];
reg [15:0] ipmac_valid;  // Each bit is set to '1' as each byte of ipmac is latched
reg [31:0] mmc_gitid_r;
assign mmc_gitid = mmc_gitid_r;
reg [3:0] mmc_gitid_valid_r;
assign mmc_gitid_valid = &mmc_gitid_valid_r;
reg [31:0] hash;
reg [3:0] hash_valid;
assign match = (&hash_valid) && (hash == HASH);
integer I;
initial begin
  ipmac_valid = 0;
  mmc_gitid_r = 0;
  mmc_gitid_valid_r = 0;
  hash = 0;
  hash_valid = 0;
  for (I = 0; I < 16; I = I+1) ipmac[I] = 0;
end
assign ip_valid = &ipmac_valid[9:6];
assign mac_valid = &ipmac_valid[5:0];
assign ip = {ipmac[9], ipmac[8], ipmac[7], ipmac[6]};
assign mac = {ipmac[5], ipmac[4], ipmac[3], ipmac[2], ipmac[1], ipmac[0]};
always @(posedge clk) begin
  // Enable Rx
  if (config_w && (config_a == 8'h20)) enable_rx_r <= config_d[0];
  // Mailbox page select
  if (config_w && (config_a == 8'h22)) begin
    //$display("MB: select page %d", config_d[6:0]);
    mbox_page <= config_d[6:0];
  end
  // IP/MAC configuration
  if (config_w && (a_hi == 1)) begin
    ipmac[a_lo] <= config_d;
    if (a_lo == 0) ipmac_valid <= 1; // reset valid bits on address 0
    else ipmac_valid[a_lo] <= 1'b1;
  end
  // Mailbox write
  if (config_w && (a_hi == 5)) begin
    if (mbox_page == GITID_PAGE) begin
      //$display("MB: gitid page");
      if ((a_lo >= GITID_OFFSET) && (a_lo < GITID_OFFSET+4)) begin
        //$display("gitid offset %d", a_lo-GITID_OFFSET);
        mmc_gitid_r[8*(GITID_OFFSET+4-a_lo)-1-:8] <= config_d;
        if (a_lo == GITID_OFFSET) mmc_gitid_valid_r <= 1;
        else mmc_gitid_valid_r[a_lo-GITID_OFFSET] <= 1'b1;
      end
    end
    // Note! Don't make these exclusive conditionals ('else if') to
    // catch the case where params resolve to the same page
    if (mbox_page == HASH_PAGE) begin
      //$display("MB: hash page");
      if ((a_lo >= HASH_OFFSET) && (a_lo < HASH_OFFSET+4)) begin
        //$display("gitid offset %d", a_lo-HASH_OFFSET);
        hash[8*(HASH_OFFSET+4-a_lo)-1-:8] <= config_d;
        if (a_lo == HASH_OFFSET) hash_valid <= 1;
        else hash_valid[a_lo-HASH_OFFSET] <= 1'b1;
      end
    end
  end
end
wire config_mr = config_r && (config_a[7:4] == 4);
wire config_mw = config_w && (config_a[7:4] == 5);
assign config_s = config_w && (config_a[7:4] == 1);
assign config_p = config_w && (config_a[7:4] == 3);
wire [10:0] mbox_a = {mbox_page, config_a[3:0]};
assign mb_addr = mbox_a;
assign mb_wen = config_mw;
assign mb_ren = config_mr;
assign mb_strobe = config_w;  // rising edge of ncs

wire error; // Reports bus contention. Do I want to do anything with this?
wire lb_mbox_wen = lb_write;
reg lb_mbox_ren=0;
always @(posedge clk) begin
  lb_mbox_ren <= lb_control_strobe & ~lb_write;
end
wire [7:0] mbox_out1;
fake_dpram #(.aw(11), .dw(8)) xmem (
  .clk(clk),  // must be the same as config_clk
  .addr1(mbox_a),
  .din1(config_d),
  .dout1(mbox_out1),
  .wen1(config_mw),
  .ren1(config_mr),
  .addr2(lb_addr),
  .din2(lb_din),
  .dout2(lb_dout),
  .wen2(lb_mbox_wen),
  .ren2(lb_mbox_ren),
  .error(error)
);
assign spi_return = mbox_out1;  // data sent back to MMC vis SPI

// Memory for UDP port numbers
reg [15:0] pno_mem[0:7];
reg [15:0] pno_d_r;
wire a_odd = config_a[0];
always @(posedge clk) begin
  if (config_p) begin
    if (config_a[0]) begin
      pno_mem[config_a[3:1]][15:8] <= config_d;
    end else begin
      pno_mem[config_a[3:1]][7:0] <= config_d;
    end
  end
end
assign pno_d = pno_mem[pno_a];
initial begin
  pno_mem[0] = UDP_PORT0;
  pno_mem[1] = UDP_PORT1;
  pno_mem[2] = UDP_PORT2;
  pno_mem[3] = UDP_PORT3;
  pno_mem[4] = UDP_PORT4;
  pno_mem[5] = UDP_PORT5;
  pno_mem[6] = UDP_PORT6;
  pno_mem[7] = UDP_PORT7;
end


endmodule
