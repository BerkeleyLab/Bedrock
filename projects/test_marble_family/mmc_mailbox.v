/*  An encapsulation of the FPGA (responder) side of the Marble
 *  pseudo-SPI mailbox interface with the MMC.
 */

module mmc_mailbox #(
  parameter [0:0] DEFAULT_ENABLE_RX = 1
) (
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
  // Config pins for badger (rtefi) interface
  output        config_s,
  output        config_p,
  output [7:0]  config_a,
  output [7:0]  config_d,
`ifdef SIMULATE
  output [3:0]  a_hi,
  output [3:0]  a_lo,
`endif
  // Special pins
  output        enable_rx,  // Controlled via special mailbox commands
  output [3:0]  spi_pins_debug // {MISO, din, sclk_d1, csb_d1};
);

// SPI Naming convention: https://www.sparkfun.com/spi_signal_names

// Mailbox pseudo-SPI protocol
// 16-bit SPI word semantics:
//   0 0 0 1 a a a a d d d d d d d d  ->  set MAC/IP config[a] = D
//   0 0 1 0 0 0 0 0 x x x x x x x V  ->  set enable_rx to V
//   0 0 1 0 0 0 1 0 x d d d d d d d  ->  set 7-bit mailbox page selector
//   0 0 1 1 a a a a d d d d d d d d  ->  set UDP port config[a] = D
//   0 1 0 0 a a a a d d d d d d d d  ->  mailbox read
//   0 1 0 1 a a a a d d d d d d d d  ->  mailbox write

// Configuration port
wire config_w, config_r;
`ifndef SIMULATE
wire [3:0] a_hi;
wire [3:0] a_lo;
`endif
assign a_lo = config_a[3:0];
assign a_hi = config_a[7:4];
wire [7:0] spi_return;
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

reg enable_rx_r=DEFAULT_ENABLE_RX;  // special case initialization
assign enable_rx = enable_rx_r;
reg [6:0] mbox_page=0;
always @(posedge clk) begin
  // Enable Rx
  if (config_w && (config_a == 8'h20)) enable_rx_r <= config_d[0];
  // Mailbox page select
  if (config_w && (config_a == 8'h22)) begin
    //$display("MB: select page %d", config_d[6:0]);
    mbox_page <= config_d[6:0];
  end
end
wire config_mr = config_r && (a_hi == 4);
wire config_mw = config_w && (a_hi == 5);
assign config_s = config_w && (a_hi == 1);
assign config_p = config_w && (a_hi == 3);
wire [10:0] mbox_a = {mbox_page, a_lo};

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

endmodule
