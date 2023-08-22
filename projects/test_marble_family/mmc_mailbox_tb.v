`timescale 1ns / 1ns

/*  Mailbox testbench which simulates the MMC side of the pseudo-SPI
 *  mailbox interface
 */

module mmc_mailbox_tb;

reg clk;
initial begin
  clk = 1'b0;
end

always #5 clk <= ~clk;

reg [10:0] lb_addr;
reg [7:0] lb_din;
wire [7:0] lb_dout;
reg lb_write;
reg lb_control_strobe;
wire ncs;
wire sck;
wire pico;
wire poci;
wire [10:0] mb_addr;
wire mb_wen, mb_ren, mb_strobe;
wire enable_rx;
wire ip_valid;
wire [31:0] ip;
wire mac_valid;
wire [47:0] mac;
wire match;
wire [31:0] mmc_gitid;
wire mmc_gitid_valid;
localparam [31:0] hash_in = 32'h01234567;
wire [3:0] hash_valid;
mmc_mailbox #(
  .HASH(hash_in)
  ) mailbox_i (
  .clk(clk), // input
  .lb_addr(lb_addr), // input [10:0]
  .lb_din(lb_din), // input [7:0]
  .lb_dout(lb_dout), // output [7:0]
  .lb_write(lb_write), // input
  .lb_control_strobe(lb_control_strobe), // input
  .sck(sck), // input
  .ncs(ncs), // input
  .pico(pico), // input
  .poci(poci), // output
  .mb_addr(mb_addr),  // output [10:0]
  .mb_wen(mb_wen), // output
  .mb_ren(mb_ren), // output
  .mb_strobe(mb_strobe), // output
  .pno_a(3'h0), // input [2:0]
  .pno_d(), // output [15:0]
  .config_s(), // output
  .config_p(), // output
  .config_a(), // output [7:0]
  .config_d(), // output [7:0]
  .enable_rx(enable_rx), // output),
  .ip_valid(ip_valid), // output
  .ip(ip), // output [31:0]
  .mac_valid(mac_valid), // output
  .mac(mac), // output [47:0]
  .mmc_gitid_valid(mmc_gitid_valid), // output
  .mmc_gitid(mmc_gitid), // output [31:0]
  .match(match), // output
  .spi_pins_debug()
);

wire [31:0] hash_out = mailbox_i.hash;

reg spi_start;
wire spi_busy;
reg spi_read;
localparam SPI_AW = 8;
localparam SPI_DW = 8;
reg [SPI_AW-1:0] spi_addr;
reg [SPI_DW-1:0] spi_data;
wire [SPI_AW-1:0] sdo_addr;
wire [SPI_DW-1:0] spi_rdbk;
wire spi_ready;
wire sdio_as_sdo;
spi_master #(
  .TSCKHALF(10),
  .ADDR_WIDTH(SPI_AW),
  .DATA_WIDTH(SPI_DW),
  .SCK_RISING_SHIFT(1)
  ) spi_master_i (
  .clk(clk), // input
  .spi_start(spi_start), // input
  .spi_busy(spi_busy), // output
  .spi_read(spi_read), // input
  .spi_addr(spi_addr), // input [15:0]
  .spi_data(spi_data), // input [7:0]
  .cs(ncs), // output
  .sck(sck), // output
  .sdi(pico), // output
  .sdo(poci), // input
  .sdo_addr(sdo_addr), // output [15:0]
  .spi_rdbk(spi_rdbk), // output [7:0]
  .spi_ready(spi_ready), // output
  .sdio_as_sdo(sdio_as_sdo) // output
);

localparam TOW = 8;
localparam TOSET = {TOW{1'b1}};
reg [TOW-1:0] timeout;
initial begin
  timeout = 0;
end
wire to = 1'b0;
//wire to = ~(|timeout);

always @(posedge clk) begin
  if (timeout > 0) begin
    timeout <= timeout - 1;
  end
end

reg [31:0] ip_in = {8'd192, 8'd168, 8'd1, 8'd20};
reg [47:0] mac_in = 48'haabbccddeeff;
reg [31:0] gitid_in = 32'hbeefcafe;
wire [79:0] ipmac_in = {ip_in, mac_in};
reg pass=1'b1;

integer I;
initial begin
  spi_start = 1'b0;
  spi_read = 1'b0;
  #10 spi_read = 1'b0;
  // Send IP/MAC data
  $display("IP/MAC");
  for(I = 0; I < 10; I = I + 1) begin
    //$display("Byte %2d", I);
    spi_addr = 8'h10 + I;
    spi_data = ipmac_in[8*(I+1)-1-:8];
    #20 spi_start = 1'b1;
    #10 spi_start = 1'b0;
    timeout = TOSET;
    wait((spi_busy == 1'b1) | to);
    wait((spi_busy == 1'b0) | to);
  end
  #20 $display("ip_in = 0x%h, ip_out = 0x%h", ip_in, ip);
  #20 $display("mac_in = 0x%h, mac_out = 0x%h", mac_in, mac);

  if (~ip_valid) begin $display("IP not valid"); pass = 1'b0; end
  if (ip_in != ip) begin $display("IP does not match"); pass = 1'b0; end
  if (~mac_valid) begin $display("MAC not valid"); pass = 1'b0; end
  if (mac_in != mac) begin $display("MAC does not match"); pass = 1'b0; end

  // Select GITID page
  $display("GITID");
  $display("Select page %1d", mailbox_i.GITID_PAGE);
  spi_addr = 8'h22;
  spi_data = mailbox_i.GITID_PAGE;
  #20 spi_start = 1'b1;
  #10 spi_start = 1'b0;
  timeout = TOSET;
  wait((spi_busy == 1'b1) | to);
  wait((spi_busy == 1'b0) | to);

  // Send GITID (MSB-first)
  for(I = 0; I < 4; I = I + 1) begin
    //$display("Byte %2d", I);
    spi_addr = 8'h50 + I + mailbox_i.GITID_OFFSET;
    spi_data = gitid_in[8*(4-I)-1-:8];
    #20 spi_start = 1'b1;
    #10 spi_start = 1'b0;
    timeout = TOSET;
    wait((spi_busy == 1'b1) | to);
    wait((spi_busy == 1'b0) | to);
  end
  #20 $display("gitid_in = 0x%h; gitid_out = 0x%h", gitid_in, mmc_gitid);

  if (~mmc_gitid_valid) begin $display("GIT ID not valid"); pass = 1'b0; end
  if (gitid_in != mmc_gitid) begin $display("GIT ID does not match"); pass = 1'b0; end

  // Send HASH
  // Select HASH page
  $display("HASH");
  $display("Select page %1d", mailbox_i.HASH_PAGE);
  spi_addr = 8'h22;
  spi_data = mailbox_i.HASH_PAGE;
  #20 spi_start = 1'b1;
  #10 spi_start = 1'b0;
  timeout = TOSET;
  wait((spi_busy == 1'b1) | to);
  wait((spi_busy == 1'b0) | to);

  // Send HASH (MSB first)
  for(I = 0; I < 4; I = I + 1) begin
    //$display("Byte %2d", I);
    spi_addr = 8'h50 + I + mailbox_i.HASH_OFFSET;
    spi_data = hash_in[8*(4-I)-1-:8];
    #20 spi_start = 1'b1;
    #10 spi_start = 1'b0;
    timeout = TOSET;
    wait((spi_busy == 1'b1) | to);
    wait((spi_busy == 1'b0) | to);
  end
  #20 $display("hash_in = 0x%h; hash_out = 0x%h", hash_in, hash_out);

  if (~(&(mailbox_i.hash_valid))) begin $display("Hash invalid"); pass = 1'b0; end
  if (hash_in != hash_out) begin $display("Hash does not match"); pass = 1'b0; end

  #4000; // Let me see the results on the waveform without zooming in a bunch
  if (pass) begin $display("PASS"); $finish(); end 
  else begin $display("FAIL"); $stop(); end
end

// ========= Mandatory Include for GTKWave Support (see Makefile) ============
initial begin
  if ($test$plusargs("vcd")) begin
    $dumpfile("mmc_mailbox_tb.vcd");
    $dumpvars;
  end
end
// ============== End GTKWave Support Snippet (see Makefile) =================


endmodule
