`timescale 1ns/1ns

module adversary_negotiate_tb;

localparam CLK_HALFPERIOD = 5;
localparam TICK = 2*CLK_HALFPERIOD;
reg clk=1'b0;
always #CLK_HALFPERIOD clk <= ~clk;

// VCD dump file for gtkwave
initial begin
  if ($test$plusargs("vcd")) begin
    $dumpfile("adversary_negotiate.vcd");
    $dumpvars();
  end
end

localparam TOW = 12;
localparam TOSET = {TOW{1'b1}};
reg [TOW-1:0] r_timeout=0;
always @(posedge clk) begin
  if (r_timeout > 0) r_timeout <= r_timeout - 1;
end
wire to = ~(|r_timeout);
`define wait_timeout(sig) r_timeout = TOSET; #TICK wait ((to) || sig)

// ========================== 8b10b Decoder =========================
reg rx_rst=1'b1;
always @(posedge clk) rx_rst<=0;
reg dec_dispin=1'b0;
wire dec_dispout;
always @(posedge clk) dec_dispin <= dec_dispout & ~rx_rst;
reg [9:0] rx_code=0;
wire rx_is_k;
wire [7:0] rx_byte;
wire code_err;
wire disp_err;
dec_8b10b dec_8b10b_i (
  .datain(rx_code), // input [9:0]
  .dispin(dec_dispin), // input
  .dataout({rx_is_k, rx_byte}), // output [8:0]
  .dispout(dec_dispout), // output
  .code_err(code_err), // output
  .disp_err(disp_err) // output
);

// ========================== 8b10b Encoder =========================
reg tx_rst=1'b1;
always @(posedge clk) tx_rst<=0;
wire tx_is_k;
wire [7:0] tx_byte;
wire [9:0] tx_code;
reg enc_dispin=1'b0;
wire enc_dispout;
always @(posedge clk) enc_dispin <= enc_dispout & ~tx_rst;
enc_8b10b enc_8b10b_i (
  .datain({tx_is_k, tx_byte}), // input [8:0]
  .dispin(enc_dispin), // input
  .dataout(tx_code), // output [9:0]
  .dispout(enc_dispout) // output
);

wire negotiating;
adversary_negotiate adversary_negotiate_i (
  .clk(clk), // input
  .rst(1'b0), // input
  .rx_byte(rx_byte), // input [7:0]
  .rx_is_k(rx_is_k), // input
  .tx_byte(tx_byte), // output [7:0]
  .tx_is_k(tx_is_k), // output
  .negotiating(negotiating), // output
  .los(1'b0)
);

/* If tx_is_k:
 *   If RD:
 *     tx_code should be: 10'b1010_000011 = 10'h283
 *   Else:
 *     tx_code should be: 10'b0101_111100 = 10'h17c
 * Else:
 *   If RD:
 *     tx_code should be: 10'b0101_011100 = 10'h15c
 *   Else:
 *     same?
 *     tx_code should be: 10'b0101_011100 = 10'h15c
 * Confirmed.
 */

// =========== Stimulus =============
initial begin
  #1000;
  $display("Done");
  $finish(0);
end

endmodule
