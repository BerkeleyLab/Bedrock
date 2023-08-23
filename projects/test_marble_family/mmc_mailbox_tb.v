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

reg [10:0] lb_addr=0;
reg [7:0] lb_din=0;
wire [7:0] lb_dout;
wire [3:0] a_hi, a_lo;
reg lb_write=1'b0;
reg lb_control_strobe=1'b0;
wire ncs;
wire sck;
wire pico;
wire poci;
wire enable_rx;
wire config_s;
wire [7:0] config_d;
localparam [31:0] hash_in = 32'h01234567;
mmc_mailbox mailbox_i (
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
  .config_s(config_s), // output
  .config_p(), // output
  .config_a(), // output [7:0]
  .config_d(config_d), // output [7:0]
  .a_hi(a_hi), // output [3:0]
  .a_lo(a_lo), // output [3:0]
  .enable_rx(enable_rx), // output),
  .spi_pins_debug()
);

localparam [3:0] GITID_PAGE = 3;
localparam [3:0] GITID_OFFSET = 12;
localparam [3:0] HASH_PAGE = 4;
localparam [3:0] HASH_OFFSET = 12;

`define MBMEM(pg, entry)    mailbox_i.xmem.xmem.mem[{pg,entry}]
wire [31:0] hash_out = {`MBMEM(HASH_PAGE,HASH_OFFSET), `MBMEM(HASH_PAGE,HASH_OFFSET+4'd1),
                        `MBMEM(HASH_PAGE,HASH_OFFSET+4'd2), `MBMEM(HASH_PAGE,HASH_OFFSET+4'd3)};
wire [31:0] gitid_out = {`MBMEM(GITID_PAGE,GITID_OFFSET), `MBMEM(GITID_PAGE,GITID_OFFSET+4'd1),
                        `MBMEM(GITID_PAGE,GITID_OFFSET+4'd2), `MBMEM(GITID_PAGE,GITID_OFFSET+4'd3)};

reg [7:0] ipmac [0:15];
wire [31:0] ip_out = {ipmac[9], ipmac[8], ipmac[7], ipmac[6]};
wire [47:0] mac_out = {ipmac[5], ipmac[4], ipmac[3], ipmac[2], ipmac[1], ipmac[0]};
reg [15:0] ipmac_valid=0;  // Each bit is set to '1' as each byte of ipmac is latched
wire ip_valid = &ipmac_valid[9:6];
wire mac_valid = &ipmac_valid[5:0];

always @(posedge clk) begin
  // IP/MAC configuration
  if (config_s) begin
    ipmac[a_lo] <= config_d;
    if (a_lo == 0) ipmac_valid <= 1; // reset valid bits on address 0
    else ipmac_valid[a_lo] <= 1'b1;
  end
end

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
  #20 $display("ip_in = 0x%h, ip_out = 0x%h", ip_in, ip_out);
  #20 $display("mac_in = 0x%h, mac_out = 0x%h", mac_in, mac_out);

  if (~ip_valid) begin $display("IP not valid"); pass = 1'b0; end
  if (ip_in != ip_out) begin $display("IP does not match"); pass = 1'b0; end
  if (~mac_valid) begin $display("MAC not valid"); pass = 1'b0; end
  if (mac_in != mac_out) begin $display("MAC does not match"); pass = 1'b0; end

  // Select GITID page
  $display("GITID");
  $display("Select page %1d", GITID_PAGE);
  spi_addr = 8'h22;
  spi_data = GITID_PAGE;
  #20 spi_start = 1'b1;
  #10 spi_start = 1'b0;
  timeout = TOSET;
  wait((spi_busy == 1'b1) | to);
  wait((spi_busy == 1'b0) | to);

  // Send GITID (MSB-first)
  for(I = 0; I < 4; I = I + 1) begin
    //$display("Byte %2d", I);
    spi_addr = 8'h50 + I + GITID_OFFSET;
    spi_data = gitid_in[8*(4-I)-1-:8];
    #20 spi_start = 1'b1;
    #10 spi_start = 1'b0;
    timeout = TOSET;
    wait((spi_busy == 1'b1) | to);
    wait((spi_busy == 1'b0) | to);
  end
  #20 $display("gitid_in = 0x%h; gitid_out = 0x%h", gitid_in, gitid_out);

  if (gitid_in != gitid_out) begin $display("GIT ID does not match"); pass = 1'b0; end

  // Send HASH
  // Select HASH page
  $display("HASH");
  $display("Select page %1d", HASH_PAGE);
  spi_addr = 8'h22;
  spi_data = HASH_PAGE;
  #20 spi_start = 1'b1;
  #10 spi_start = 1'b0;
  timeout = TOSET;
  wait((spi_busy == 1'b1) | to);
  wait((spi_busy == 1'b0) | to);

  // Send HASH (MSB first)
  for(I = 0; I < 4; I = I + 1) begin
    //$display("Byte %2d", I);
    spi_addr = 8'h50 + I + HASH_OFFSET;
    spi_data = hash_in[8*(4-I)-1-:8];
    #20 spi_start = 1'b1;
    #10 spi_start = 1'b0;
    timeout = TOSET;
    wait((spi_busy == 1'b1) | to);
    wait((spi_busy == 1'b0) | to);
  end
  #20 $display("hash_in = 0x%h; hash_out = 0x%h", hash_in, hash_out);

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
