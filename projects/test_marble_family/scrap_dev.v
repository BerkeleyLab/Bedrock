
/*
 * An overly complicated Baud clock generator which extends the time accuracy
 * of the desired clock frequency by a factor of 8.
 * Suppose you want 115200 baud and you have a 32MHz sysclk.
 * A simple divider could get you close:
 *   32MHz/277 = 115523.5 Hz    ~ 17 chars before drifting by half-period
 *   32MHz/278 = 115107.9 Hz    ~ 61 chars
 * This module gets you the precision of an 8x higher clock speed, i.e.:
 *   8*32MHz/2222 = 115211.5 Hz ~ 523 chars
 *   8*32MHz/2223 = 115159.7 Hz ~ 140 chars
 *
 * Note:
 *  Formula for num chars before drift between clocks is half-period assuming
 *  no clock recovery.
 *    f0 = receiver baud clock
 *    f1 = transmitter baud clock
 *    fmax = max(f0, f1)
 *    fmin = min(f0, f1)
 *    n = 1/(2*10*(fmax/fmin - 1))    # Assuming 10 bits per transmitted char
 */

module baudclk
  #(
    parameter SYSCLK_FREQ_HZ = 100000000,   // System clock freq
    parameter BAUD_FREQ_HZ = 115200,        // Baud clock freq
    parameter COUNT_WIDTH = 16              // Counter width (number of bits)
  )(
    input wire clk,                 // System clock
    input wire rst,                 // Synchronous reset
    output wire bclk,               // Baud clock output (50% duty)
    output wire re,                  // Baud clock rising edge (one clk cycle long)
    output wire fe                   // Baud clock falling edge (one clk cycle long)
  );

  localparam COUNTER_MAX_INT = SYSCLK_FREQ_HZ / BAUD_FREQ_HZ;
  localparam [COUNT_WIDTH-1:0] COUNTER_MAX = COUNTER_MAX_INT[COUNT_WIDTH-1:0];
  localparam [COUNT_WIDTH-1:0] HALF_MAX = COUNTER_MAX / 2;
  localparam NDELAY = ((8 * SYSCLK_FREQ_HZ) / BAUD_FREQ_HZ) - (8 * COUNTER_MAX); // I can fold BETA into here if this works.


  function [7:0] delay_vector(input [3:0] ndelay);
    begin
      case (ndelay)
        0:
          delay_vector = 8'b00000000;
        1:
          delay_vector = 8'b00000001;
        2:
          delay_vector = 8'b00010001;
        3:
          delay_vector = 8'b00100101;
        4:
          delay_vector = 8'b01010101;
        5:
          delay_vector = 8'b01010111;
        6:
          delay_vector = 8'b01110111;
        7:
          delay_vector = 8'b01111111;
        default:
          delay_vector = 8'b11111111;
      endcase
    end
  endfunction

  reg baudclk;
  assign bclk = baudclk;
  reg [COUNT_WIDTH-1:0] clk_counter;
  reg [2:0] dphase;
  assign re = (clk_counter == 1) ? 1'b1 : 1'b0;
  assign fe = (clk_counter == HALF_MAX) ? 1'b1 : 1'b0;

`ifdef SIMULATE
  // Seems like verilator has trouble with the DELAY_VECTOR scheme below
  wire [COUNT_WIDTH-1:0] count_max = COUNTER_MAX;
`else
  localparam DELAY_VECTOR = delay_vector(NDELAY[3:0]); // TODO - implement
  wire [COUNT_WIDTH-1:0] count_max = DELAY_VECTOR[dphase] == 1'b1 ? COUNTER_MAX + 1 : COUNTER_MAX;
`endif

  initial
  begin
    clk_counter = 0;
    baudclk = 1'b0;
    dphase = 0;
  end

  always @ (posedge clk)
  begin
    if (rst) begin
      clk_counter <= 0;
      baudclk <= 1'b0;
    end else begin
      // Added extra check because I want a rising edge immediately after
      // start of count
      clk_counter <= clk_counter + 1;
      if (clk_counter == 1) begin
        baudclk <= 1'b1;
      //end else if (clk_counter == COUNTER_MAX) begin
      end else if (clk_counter == count_max) begin
        clk_counter <= 0;
        //baudclk = 1'b0;
        dphase <= dphase + 1;  // Intentional rollover
      end else if (clk_counter == HALF_MAX) begin
        baudclk <= 1'b0;
      end
    end
  end

endmodule
/*  crc_hqx.v
 *  This module, based off a machine-generated crc16.v from crc_derive.c (see
 *  bedrock), is a slight modification that generates the same values as
 *  Python's binascii.crc_hqx() function.
 *  Width = 16-bit
 *  Polynomial = 0x1021
 */

module crc_hqx #(parameter C = "0")
(
  input             clk,
  input             ce,     // Clock-enable
  input       [7:0] din,    // Upper 8 bits of 16-bit CRC are zero in "byte mode"
  input             zero,
  output reg [15:0] crc
);

  wire [15:0] O = zero ? 16'b0 : crc;
  wire [15:0] D = {8'b0, din};

  wire [15:0] y = D^(O>>8);

  always @(posedge clk) begin
    if (zero) begin
      crc <= 0;
    end else if (ce) begin
      //$display("  ## CRC [%s] din = 0x%h; crc = 0x%h", C, din, crc);
      crc[0]  <=                              y[0]       ^y[4]             ^y[8] ^y[11]^y[12];
      crc[1]  <=                              y[1]       ^y[5]             ^y[9] ^y[12]^y[13];
      crc[2]  <=                              y[2]       ^y[6]             ^y[10]^y[13]^y[14];
      crc[3]  <=                              y[3]       ^y[7]             ^y[11]^y[14]^y[15];
      crc[4]  <=                              y[4]       ^y[8]             ^y[12]^y[15];
      crc[5]  <=            y[0]       ^y[4] ^y[5] ^y[8] ^y[9] ^y[11]^y[12]^y[13];
      crc[6]  <=            y[1]       ^y[5] ^y[6] ^y[9] ^y[10]^y[12]^y[13]^y[14];
      crc[7]  <=            y[2]       ^y[6] ^y[7] ^y[10]^y[11]^y[13]^y[14]^y[15];
      crc[8]  <=            y[3]       ^y[7] ^y[8] ^y[11]^y[12]^y[14]^y[15]        ^O[0];
      crc[9]  <=            y[4]       ^y[8] ^y[9] ^y[12]^y[13]^y[15]              ^O[1];
      crc[10] <=            y[5]       ^y[9] ^y[10]^y[13]^y[14]                    ^O[2];
      crc[11] <=            y[6]       ^y[10]^y[11]^y[14]^y[15]                    ^O[3];
      crc[12] <= y[0]^y[4] ^y[7] ^y[8]             ^y[15]                          ^O[4];
      crc[13] <= y[1]^y[5] ^y[8] ^y[9]                                             ^O[5];
      crc[14] <= y[2]^y[6] ^y[9] ^y[10]                                            ^O[6];
      crc[15] <= y[3]^y[7] ^y[10]^y[11]                                            ^O[7];
    end
  end

  initial crc = 0;

endmodule

/*
 * Simple de-bouncing based on looking for certain bit patterns to latch into
 * complementary state.
 * If in state HIGH:
 *   If din_r == 1000...0, state => LOW
 * Else (in state LOW):
 *   If din_r == 0111...1, state => HIGH
 *
 * This scheme is insensitive to glitches of duration < LEN due to the state
 * latching.  In the HIGH state, we would glitch low and could easily
 * encounter the rising bit pattern (0111...1) but that would put us into the
 * HIGH state (which we're already in).
 *
 * Usage:
 *  To be successful, the debounce duration (t_db) needs to meet the following
 *  criteria:
 *    1. t_db < 1/f_din.  The debounce duration must be less than the minimum
 *                        duration of valid data coming across din.
 *    2. t_db > t_bounce. The debounce duration must be greater than the
 *                        maximum pulse (high or low) created by
 *                        a bounce/glitch
 */

module debounce #(
  parameter LEN = 8,
  parameter INITIAL_STATE = 1'b0  // Initial state of dout
  )(
    input wire clk,
    input wire din,
    output wire dout
  );

  reg r_dout;
  assign dout = r_dout;
  reg [LEN-1:0] din_r;

  localparam [LEN-1:0] BP_FALLING = {1'b1, {LEN-1{1'b0}}};
  localparam [LEN-1:0] BP_RISING  = {1'b0, {LEN-1{1'b1}}};

  initial begin
    din_r = {LEN{1'b0}};
    r_dout = INITIAL_STATE;
  end

  always @(posedge clk) begin
    din_r <= {din_r[LEN-2:0], din};  // Shift in din
    if (din_r == BP_RISING)
      r_dout <= 1'b1;
    else if (din_r == BP_FALLING)
      r_dout <= 1'b0;
  end

endmodule
/* Convert vector value from hex-encoded ASCII to binary
 */

module dehexer #(
  parameter WIDTH_HEX_BYTES = 4
)(
  input [8*WIDTH_HEX_BYTES-1:0] hexin,
  output [4*WIDTH_HEX_BYTES-1:0] binout,
  output [WIDTH_HEX_BYTES-1:0] decode_errors
);

//`include "hex.vh" -- Deprecating for convenience
/* Conversion functions to and from hex-ASCII characters
 */

function [7:0] ToHexChar (input [3:0] n);
  begin
    case (n)
      4'h0: ToHexChar = "0";
      4'h1: ToHexChar = "1";
      4'h2: ToHexChar = "2";
      4'h3: ToHexChar = "3";
      4'h4: ToHexChar = "4";
      4'h5: ToHexChar = "5";
      4'h6: ToHexChar = "6";
      4'h7: ToHexChar = "7";
      4'h8: ToHexChar = "8";
      4'h9: ToHexChar = "9";
      4'hA: ToHexChar = "A";
      4'hB: ToHexChar = "B";
      4'hC: ToHexChar = "C";
      4'hD: ToHexChar = "D";
      4'hE: ToHexChar = "E";
      4'hF: ToHexChar = "F";
      default: ToHexChar = "-";
    endcase
  end
endfunction

// NOTE! The MSb returned here is high when a decoding error is detected
// (the input character is not hex-ascii)
function [4:0] FromHexChar (input [7:0] n);
  begin
    case (n)
      "0" : FromHexChar = 5'h0;
      "1" : FromHexChar = 5'h1;
      "2" : FromHexChar = 5'h2;
      "3" : FromHexChar = 5'h3;
      "4" : FromHexChar = 5'h4;
      "5" : FromHexChar = 5'h5;
      "6" : FromHexChar = 5'h6;
      "7" : FromHexChar = 5'h7;
      "8" : FromHexChar = 5'h8;
      "9" : FromHexChar = 5'h9;
      "A" : FromHexChar = 5'hA;
      "a" : FromHexChar = 5'hA;
      "B" : FromHexChar = 5'hB;
      "b" : FromHexChar = 5'hB;
      "C" : FromHexChar = 5'hC;
      "c" : FromHexChar = 5'hC;
      "D" : FromHexChar = 5'hD;
      "d" : FromHexChar = 5'hD;
      "E" : FromHexChar = 5'hE;
      "e" : FromHexChar = 5'hE;
      "F" : FromHexChar = 5'hF;
      "f" : FromHexChar = 5'hF;
      default: FromHexChar = 5'h10;
    endcase
  end
endfunction

generate
  genvar i;
  for (i = 0; i < WIDTH_HEX_BYTES; i = i + 1) begin
    assign {decode_errors[i], binout[4*(i+1)-1:4*i]} = FromHexChar(hexin[8*(i+1)-1:8*i]);
  end
endgenerate

endmodule
/* Convert vector value from binary to hex-encoded ASCII
 */

module hexer #(
  parameter WIDTH_HEX_BYTES = 4
)(
  input [4*WIDTH_HEX_BYTES-1:0] binin,
  output [8*WIDTH_HEX_BYTES-1:0] hexout
);

//`include "hex.vh" -- Deprecating for convenience
/* Conversion functions to and from hex-ASCII characters
 */

function [7:0] ToHexChar (input [3:0] n);
  begin
    case (n)
      4'h0: ToHexChar = "0";
      4'h1: ToHexChar = "1";
      4'h2: ToHexChar = "2";
      4'h3: ToHexChar = "3";
      4'h4: ToHexChar = "4";
      4'h5: ToHexChar = "5";
      4'h6: ToHexChar = "6";
      4'h7: ToHexChar = "7";
      4'h8: ToHexChar = "8";
      4'h9: ToHexChar = "9";
      4'hA: ToHexChar = "A";
      4'hB: ToHexChar = "B";
      4'hC: ToHexChar = "C";
      4'hD: ToHexChar = "D";
      4'hE: ToHexChar = "E";
      4'hF: ToHexChar = "F";
      default: ToHexChar = "-";
    endcase
  end
endfunction

// NOTE! The MSb returned here is high when a decoding error is detected
// (the input character is not hex-ascii)
function [4:0] FromHexChar (input [7:0] n);
  begin
    case (n)
      "0" : FromHexChar = 5'h0;
      "1" : FromHexChar = 5'h1;
      "2" : FromHexChar = 5'h2;
      "3" : FromHexChar = 5'h3;
      "4" : FromHexChar = 5'h4;
      "5" : FromHexChar = 5'h5;
      "6" : FromHexChar = 5'h6;
      "7" : FromHexChar = 5'h7;
      "8" : FromHexChar = 5'h8;
      "9" : FromHexChar = 5'h9;
      "A" : FromHexChar = 5'hA;
      "a" : FromHexChar = 5'hA;
      "B" : FromHexChar = 5'hB;
      "b" : FromHexChar = 5'hB;
      "C" : FromHexChar = 5'hC;
      "c" : FromHexChar = 5'hC;
      "D" : FromHexChar = 5'hD;
      "d" : FromHexChar = 5'hD;
      "E" : FromHexChar = 5'hE;
      "e" : FromHexChar = 5'hE;
      "F" : FromHexChar = 5'hF;
      "f" : FromHexChar = 5'hF;
      default: FromHexChar = 5'h10;
    endcase
  end
endfunction

generate
  genvar i;
  for (i = 0; i < WIDTH_HEX_BYTES; i = i + 1) begin
    assign hexout[8*(i+1)-1:8*i] = ToHexChar(binin[4*(i+1)-1:4*i]);
  end
endgenerate

endmodule
/*
 * Send bytes stored in a memory out across uart
 * Calculate and append crc_hqx in hex-ascii encoding
 * TODO:
 *   Add support for 7-bit data width
 */


module mem_tx_crc
  #(
    parameter SYSCLK_FREQ_HZ = 100000000,
    parameter BAUD_FREQ_HZ = 115200,
    parameter ADDR_WIDTH = 8,
    parameter STOP_BITS = 1             // UART stop bits
  )(
    input wire clk,                     // System clock
    input wire rst,                     // Synchronous reset
    input wire start,                   // Enable. Rising edge triggers start of transfer
    input wire [ADDR_WIDTH-1:0] nToSend, // Number of bytes to send. Latched at rising edge of 'start'
    input wire [7:0] wdata,             // Current byte to write (should come from memory indexed by 'addr')
    output wire [ADDR_WIDTH-1:0] addr,  // Address into memory where bytes are stored
    output wire rce,                    // Read clock enable (asserted for 1 clock cycle after addr is valid)
    output reg busy,                    // Transfer in progress
    // Debug
    output wire baudclk,
    // PHY
    output wire TxD                     // Actual TxD line to go out on the wire
  );

localparam [7:0] TERMINATOR_CHAR = "\n";

reg [ADDR_WIDTH-1:0] addr_r;  // Increments only up to CRC field
reg [ADDR_WIDTH:0] cntr_r;  // Mostly redundant to addr_r but counts through CRC
reg start_0, start_1;
wire start_re = (start_0 == 1'b1) && (start_1 == 1'b0) ? 1'b1 : 1'b0;
reg uart_go;
reg go_delay;
reg self_stop;
wire uart_busy, uart_busy_fe;
wire [7:0] uart_wdata;
reg uart_busy_0, uart_busy_1;
reg [ADDR_WIDTH:0] nlastdata; // Value latched at 'start' rising edge
wire [ADDR_WIDTH:0] nlast = nlastdata + 4; // CRC
wire uart_wdata_latched;
reg rce_r;
assign rce = rce_r;

assign addr = addr_r;
assign uart_busy_fe = ((uart_busy_0 == 1'b0) && (uart_busy_1 == 1'b1)) ? 1'b1 : 1'b0;

uart_tx #(
  .SYSCLK_FREQ_HZ(SYSCLK_FREQ_HZ),
  .BAUD_FREQ_HZ(BAUD_FREQ_HZ),
  .DATAWIDTH(8),
  .STOP_BITS(STOP_BITS)
) uart_tx_inst (
  .clk(clk),                 // System clock
  .rst(rst),     // Synchronous reset
  .wdata(uart_wdata),             // Byte to write
  .go(uart_go),              // Rising edge triggers byte going out on wire if not busy
  .busy(uart_busy),          // Asserted while write in progress
  .wdata_latched(uart_wdata_latched),
  .baudclk(baudclk),
  .TxD(TxD)                  // Actual TxD line to go out on the wire
);

reg crc_prelatch, crc_latch, crc_zero, crc_ce_r;
wire crc_ce_enable;
wire crc_ce = crc_ce_r & crc_ce_enable;
wire [15:0] crc_calc;
reg  [15:0] outcrc;
wire [7:0] crc_din = uart_wdata;
reg  [7:0] asciicrc [0:3];
crc_hqx #(.C("O")) crc_hqx_out (
  .clk(clk),
  .ce(crc_ce),
  .din(crc_din),
  .zero(crc_zero),
  .crc(crc_calc)
);
always @(posedge clk) begin
  crc_latch <= crc_prelatch;
  if (crc_latch) begin
    //$display("crc_calc = 0x%h", crc_calc);
    outcrc <= crc_calc;
  end
end
localparam CRC_HEX_WIDTH = 4; // 16 bits = 2 bytes = 2*2 chars in hex ASCII
wire [8*CRC_HEX_WIDTH-1:0] crchex;
hexer #(.WIDTH_HEX_BYTES(CRC_HEX_WIDTH)) hexer_crc (.binin(outcrc), .hexout(crchex));
always @(posedge clk) begin
  asciicrc[0] <= crchex[7-:8];
  asciicrc[1] <= crchex[15-:8];
  asciicrc[2] <= crchex[23-:8];
  asciicrc[3] <= crchex[31-:8];
end

initial
begin
  uart_go = 1'b0;
  start_0 = 1'b0;
  start_1 = 1'b0;
  uart_busy_0 = 1'b0;
  uart_busy_1 = 1'b0;
  go_delay = 1'b0;
  addr_r = 0;
  cntr_r = 0;
  self_stop = 1'b1;
  nlastdata = 1;
  crc_zero = 1'b0;
  crc_prelatch = 1'b0;
  crc_latch = 1'b0;
  busy = 1'b0;
  crc_ce_r = 1'b0;
end

wire [ADDR_WIDTH:0] nleft = nlast-cntr_r-1;
wire [1:0] crc_addr = cntr_r < nlastdata ? 2'b0 : nleft[1:0];
assign uart_wdata = cntr_r < nlastdata ? wdata : cntr_r == nlast ? TERMINATOR_CHAR : asciicrc[crc_addr];
assign crc_ce_enable = cntr_r < nlastdata ? 1'b1 : 1'b0;

// Address incrementer
always @(posedge clk) begin
  crc_prelatch <= 1'b0;
  crc_ce_r <= 1'b0;
  crc_zero <= 1'b0;
  start_0 <= start;
  start_1 <= start_0;
  uart_busy_1 <= uart_busy_0;
  uart_busy_0 <= uart_busy;
  rce_r <= 1'b0;
  //go_delay <= 1'b0;
  //uart_go <= 1'b0;
  if (start_re == 1'b1) begin
    nlastdata <= {1'b0, nToSend}; // Latch the number of bytes to send
    //$display("mem_tx self_stop disable (nlastdata = %d)", nToSend);
    crc_zero <= 1'b1;
    self_stop <= 1'b0;
    addr_r <= 0;
    cntr_r <= 0;
  end
  if ((~rst) && (~self_stop)) begin
    // If UART is not busy and we're not stopped, go ahead
    if ((~uart_busy) & (~uart_go)) begin
      //$display("nlast = %d, nlastdata = %d, addr_r = %d, nleft = %d", nlast, nlastdata, addr_r, nleft);
      //$display("mem_tx go");
      //go_delay <= 1'b1;
      crc_ce_r <= 1'b1;
      uart_go <= 1'b1;
      //go_delay <= 1'b1;
      //$display("addr_r => %d", addr_r);
    end
    if (uart_wdata_latched) begin
      //$display("mem_tx_crc: Got data 0x%h from addr 0x%h", uart_wdata, addr);
      cntr_r <= cntr_r + 1;
      if (cntr_r < nlastdata - 1) begin
        addr_r <= addr_r + 1;
        rce_r <= 1'b1;
      end else if (cntr_r == nlastdata - 1) begin
        crc_prelatch <= 1'b1;
      end
    end
    if (uart_busy) begin
      uart_go <= 1'b0;
    end
    if (cntr_r == nlast + 1) begin
      busy <= 1'b0;
      //$display("mem_tx self_stop enable");
      self_stop <= 1'b1;
    end
  end
end

endmodule
/*
 * Follower device implementing SCRAP protocol over UART
 */

/* Features currently implemented:
 * DONE:
 *  Test with UART (magic address, cmd, data lights LEDs)
 *  Byte-aligned (8-bit) write
 *  Generate response to write packet
 *  Generate response to read packet
 *  Byte-aligned (8-bit) read
 *  Interactive testbench via Verilator
 *  Implement CRC
 * TODO:
 *  Implement 'NACK_UNSUPPORTED' for SCRAPE commands sent to SCRAP device
 *  Improve testbench:
 *    Increment address/data, build packet, compare with decoded values
 *  Packet timeout (1s?)
 */

module scrap_dev #(
  parameter F_CLK_IN  = 1000000,
  parameter F_BAUD = 115200,
  parameter [5:0] ADDRESS_WIDTH = 8,  // <= 64
  parameter [5:0] DATA_WIDTH = 32,    // <= 64
  // LATCH_CYCLES = Additional clk cycles of delay between asserting addr and latching rdata (<= 7)
  // 0 = 1 cycle total delay; 1 = 2 cycles total delay, etc
  parameter [2:0] LATCH_CYCLES = 2,
  parameter TIMEOUT_MS = 1000       // Timeout happens TIMEOUT_MS after last byte received
)(
  input clk,
  input rst,
  // PHY interface
  input uart_rxd,
  output uart_txd,
  // Memory interface
  output [ADDRESS_WIDTH-1:0] addr,  // Address (for writes, only valid when we=1)
  input  [DATA_WIDTH-1:0] rdata,    // Read data (corresponding to address 'addr')
  output [DATA_WIDTH-1:0] wdata,    // Write data (only valid when we=1)
`ifdef SCRAP_ENABLE_MASK_OPS
  output [DATA_WIDTH-1:0] wmask,    // Write mask (only valid when we=1)
`endif
  output we,                      // Write-enable (single-cycle)
  output [1:0] op,                // Operation (00=write, 01=read, 10=clrmask, 11=setmask)
  // DEBUG
  //output reg rstrobe,
`ifdef SCRAPE
  output op_ex,
`endif
`ifdef SCRAP_SHARED_BUS
  output bus_claim,               // Asserted when attempting to control the 'addr' bus
  input bus_claimed,              // Must be asserted if successfully controlling the bus ('rdata' is valid)
`endif
  // Status
  output [31:0] error_count       // Error accumulator (reset when rst=1)
);

reg bus_claim_read;
wire bus_claim_write = we;
wire bus_claim_w = bus_claim_read | bus_claim_write;
`ifndef SCRAP_SHARED_BUS
// Bypass the bus claiming system if no shared bus
wire bus_claimed = bus_claim_w;
`else
assign bus_claim = bus_claim_w;
`endif
reg bus_contention;
initial begin
  bus_claim_read = 1'b0;
  bus_contention = 1'b0;
end
// Bypass bus_contention for packet_valid consideration if op is BREAD
wire bread_bus_contention = (cmd_op_ex == CMD_OP_EX_BREAD) ? 1'b0 : bus_contention;

// DEBUG
//initial rstrobe = 1'b0;

// With 32-bit bus
// 8-bit write 0xaf:
//    mask = 0xffffff00
//    data = 0x000000af
//    Simple:   ram[addr] = data;
//    Complete: ram[addr] = (ram[addr] & mask) | data;
// 8-bit setmask 0xaf:
//    mask = 0xffffffff
//    data = 0x000000af
//    ram[addr] = (ram[addr] & mask) | data;
// 8-bit clrmask 0xaf:
//    mask = ~0x000000af
//    data = 0xffffffff
//    ram[addr] = (ram[addr] & mask) | data;

//`include "scrap.vh" -- Deprecating this until otherwise needed
/* SCRAP Protocol Definitions
 */
localparam [7:0] BYTE_TERMINATOR = "\n";
localparam [1:0]
  CMD_OP_WRITE   = 2'b00,
  CMD_OP_READ    = 2'b01,
  CMD_OP_CLRMASK = 2'b10,
  CMD_OP_SETMASK = 2'b11;

localparam [2:0]
  CMD_OP_EX_WRITE   = {1'b0, CMD_OP_WRITE},
  CMD_OP_EX_READ    = {1'b0, CMD_OP_READ},
  CMD_OP_EX_CLRMASK = {1'b0, CMD_OP_CLRMASK},
  CMD_OP_EX_SETMASK = {1'b0, CMD_OP_SETMASK},
  CMD_OP_EX_BWRITE  = {1'b1, CMD_OP_WRITE},
  CMD_OP_EX_BREAD   = {1'b1, CMD_OP_READ};

localparam [7:0]
  CHAR_ACK = ".",
  CHAR_NACK_CRC = "!",
  CHAR_NACK_TERM = "*",
  CHAR_NACK_DECODE = "?",
  CHAR_NACK_CONTENTION = "$",
  CHAR_NACK_UNSUPPORTED = "~",
  CHAR_NACK_TIMEOUT = "@",
  CHAR_NACK_CMD = "#";

// Early definitions to avoid annoying warnings
`ifdef SCRAPE
localparam RESPONSE_ADDR_WIDTH = 10; // Max SCRAPE packet size is 525 bytes; 1<<10 = 1024
`else
localparam RESPONSE_ADDR_WIDTH = 6; // Max packet size is 38 bytes; 1<<6 = 64
`endif
localparam BYTE_COUNT_WIDTH = RESPONSE_ADDR_WIDTH;
localparam RDATA_HEX_WIDTH = 16;  // 64 bits = 8 bytes = 8*2 chars in hex ASCII
reg [7:0] cmd_byte;
wire [1:0] cmd_dw = cmd_byte[3:2];
wire [1:0] cmd_aw = cmd_byte[1:0];
wire [1:0] cmd_op  = {cmd_byte[6], cmd_byte[4]};
wire [2:0] cmd_op_ex  = {cmd_byte[7:6], cmd_byte[4]};
reg [63:0] pkt_addr;  // Accommodate max size
reg [63:0] pkt_addr_l;  // Accommodate max size
wire [BYTE_COUNT_WIDTH-1:0] last_addr_byte, last_data_byte, last_crc_byte;
wire [BYTE_COUNT_WIDTH-1:0] nbyte_addr, nbyte_data, nbyte_crc;
wire [8*RDATA_HEX_WIDTH-1:0] rdata_hexed;
wire [15:0] incrc;
reg crc_in_latch;
reg crc_in_enable;

// Fake enum type for state machine
localparam [3:0]
  STAGE_IDLE   = 4'b0000,
  STAGE_ADDR   = 4'b0001,
  STAGE_DATA   = 4'b0010,
  STAGE_CRC    = 4'b0011,
  STAGE_TERM   = 4'b0100,
  STAGE_ACK    = 4'b0101,
  STAGE_PRE_RECOVER= 4'b0110, // Enter Recovery state
  STAGE_RECOVER= 4'b0111, // Recover from mangled/unsupported packet
// SCRAPE-only
  STAGE_NDATA  = 4'b1000, // Receiving field 'ndata'
  STAGE_BWRITE = 4'b1001; // Receiving extended data field (Bulk Write)
//  STAGE_BREAD  = 4'b1010; // Composing extended data field (Bulk Read)
reg [3:0] receiver_stage;

reg [BYTE_COUNT_WIDTH-1:0] nbyte_inbuf, nbyte_outbuf, nbyte_stage; // Packet byte counter
reg  [7:0] rebuf_wdata;
reg  rebuf_wselect=1'b0, rebuf_we=1'b0;
wire [RESPONSE_ADDR_WIDTH-1:0] rebuf_raddr;
wire [7:0] rebuf_rdata;
wire rebuf_rce;
reg  rebuf_rselect;

wire [RESPONSE_ADDR_WIDTH-1:0] rebuf_waddr = nbyte_outbuf;

`ifdef SCRAPE
reg [RESPONSE_ADDR_WIDTH-1:0] pkt_offset;
initial pkt_offset = 0;
wire [3:0] bread_hex_max = ((1<<(cmd_dw+1))-1);
wire [3:0] bread_hex_index = bread_hex_max - ((rebuf_raddr[3:0] - pkt_offset[3:0]) & bread_hex_max);
// Bus addr
wire [ADDRESS_WIDTH-1:0] rebuf_raddr_w;
wire [ADDRESS_WIDTH-1:0] pkt_offset_w;
generate if (ADDRESS_WIDTH > RESPONSE_ADDR_WIDTH) begin : branch_a_gt_r
  assign rebuf_raddr_w = {{ADDRESS_WIDTH-RESPONSE_ADDR_WIDTH{1'b0}}, rebuf_raddr};
  assign pkt_offset_w = {{ADDRESS_WIDTH-RESPONSE_ADDR_WIDTH{1'b0}}, pkt_offset};
end else begin : branch_r_gt_a
  assign rebuf_raddr_w = rebuf_raddr[ADDRESS_WIDTH-1:0];
  assign pkt_offset_w = pkt_offset[ADDRESS_WIDTH-1:0];
end endgenerate
/*wire [ADDRESS_WIDTH-1:0] bread_bus_addr = (rebuf_raddr >= pkt_offset) ?
  pkt_addr[ADDRESS_WIDTH-1:0] + ((rebuf_raddr[ADDRESS_WIDTH-1:0] - pkt_offset[ADDRESS_WIDTH-1:0]) >> (cmd_dw+1)) :
  pkt_addr[ADDRESS_WIDTH-1:0];
*/
wire [ADDRESS_WIDTH-1:0] bread_bus_addr = (rebuf_raddr >= pkt_offset) ?
  pkt_addr[ADDRESS_WIDTH-1:0] + ((rebuf_raddr_w - pkt_offset_w) >> (cmd_dw+1)) :
  pkt_addr[ADDRESS_WIDTH-1:0];

wire test = (cmd_op_ex == CMD_OP_EX_BREAD) ? rebuf_raddr[cmd_dw] & bread_override & rebuf_rce : rdata_prelatch;

// Latch rdata on bus addr change
wire bread_bus_addr_ch = rebuf_raddr[cmd_dw] & bread_override & rebuf_rce;
wire bread_override = cmd_op_ex == CMD_OP_EX_BREAD ? rebuf_raddr > pkt_offset - 1 ? 1'b1 : 1'b0 : 1'b0;

wire [7:0] bread_rdata = rebuf_raddr < last_addr_byte + 2 ? "x" : rdata_hexed[8*(bread_hex_index+1)-1-:8];

`else
localparam [0:0] bread_bus_addr_ch = 1'b0;
//localparam [0:0] bread_override = 1'b0;
`endif

`ifdef USE_PINGPONG
pingpong #(
  .DATA_WIDTH(8),
  .ADDR_WIDTH(RESPONSE_ADDR_WIDTH)
) pingpong_inst_0 (
  .clk(clk),
  .waddr(rebuf_waddr),
  .wdata(rebuf_wdata),
  .wselect(rebuf_wselect),
  .we(rebuf_we),
  .raddr(rebuf_raddr),
  .rdata(rebuf_rdata),
  .rselect(rebuf_rselect)
);
`else   // NO PINGPONG
// Single RAM instead of pingpong buffer
//localparam REBUF_DEPTH = (1<<RESPONSE_ADDR_WIDTH);
localparam REBUF_ADDR_W = 6; // 6-bit
localparam REBUF_DEPTH = (1<<REBUF_ADDR_W);
reg [7:0] rebuf [0:REBUF_DEPTH-1];
reg [7:0] rebuf_rdata_r;
wire [REBUF_ADDR_W-1:0] rebuf_waddr_s = rebuf_waddr[REBUF_ADDR_W-1:0];
wire [REBUF_ADDR_W-1:0] rebuf_raddr_s = rebuf_raddr[REBUF_ADDR_W-1:0];
`ifdef SCRAPE
assign rebuf_rdata = bread_override == 1'b1 ? bus_contention ? CHAR_NACK_CONTENTION : bread_rdata : rebuf_rdata_r;
`else
assign rebuf_rdata = rebuf_rdata_r;
`endif
integer ln;
initial begin
  rebuf_rdata_r = 0;
  for (ln = 0; ln < REBUF_DEPTH; ln = ln + 1) begin
    rebuf[ln] = 0;
  end
end
always @(posedge clk) begin
  // Writes
  if (rebuf_we) begin
    rebuf[rebuf_waddr_s] <= rebuf_wdata;
  end
  // Reads
  rebuf_rdata_r <= rebuf[rebuf_raddr_s];
end
`endif  // USE_PINGPONG

// Read Data Hexer
reg rdata_prelatch;
reg [7:0] rdata_latch;
initial begin
  rdata_latch = 0;
end
wire rdata_latch_sel = rdata_latch[LATCH_CYCLES];

//wire rebuf_latch = (rebuf_raddr < last_addr_byte) ? 1'b0 : rebuf_rce;
wire [63-DATA_WIDTH:0] zero_rdata_pad = 0; // Annoying fix for verilator complaint
reg [63:0] rdata_max;    // Accomodate max rdata size
hexer #(.WIDTH_HEX_BYTES(RDATA_HEX_WIDTH)) hexer_rdata (.binin(rdata_max), .hexout(rdata_hexed));
integer I;
always @(posedge clk) begin
  rdata_latch[0] <= (cmd_op_ex == CMD_OP_EX_BREAD) ? bread_bus_addr_ch : rdata_prelatch;
  for (I = 0; I < 7; I = I + 1) begin
    rdata_latch[I+1] <= rdata_latch[I];
  end
  if (rdata_latch[0]) begin
    bus_claim_read <= 1'b1;
  end
  if (rst | self_reset) begin
    bus_contention <= 1'b0;
  end
  if (rdata_latch_sel) begin
    $display("rdata = 0x%h", rdata);
    rdata_max <= {zero_rdata_pad, rdata};
    // Log bus contention if bus not claimed during read
    bus_contention <= bus_contention | ~bus_claimed;
    bus_claim_read <= 1'b0;
  end
  if (we) begin
    // Log bus contention if bus not claimed during Write
    bus_contention <= bus_contention | ~bus_claimed;
  end
end

// Default (Recovery) Response
localparam RECOVER_RESPONSE_LENGTH = 5; // Not including CRC or termination
reg [7:0] recover_response [0:RECOVER_RESPONSE_LENGTH-1];
initial begin
  recover_response[0] = 8'h20; // Write; aw=dw=0
  // Nack char will be filled at response time
  for (I = 1; I < RECOVER_RESPONSE_LENGTH; I = I + 1) begin
    recover_response[I] = 8'h30;
  end
end

// Packet timeout (TODO)
// Timeout happens TIMEOUT_MS after the last byte received
localparam TIMEOUT_COUNTER_MAX = (F_CLK_IN*TIMEOUT_MS)/1000;
localparam TIMEOUT_BITS = $clog2(TIMEOUT_COUNTER_MAX);
reg [TIMEOUT_BITS-1:0] timeout_counter;
wire timeout = timeout_counter == TIMEOUT_COUNTER_MAX ? 1'b1 : 1'b0;
initial begin
  timeout_counter = 0;
end
always @(posedge clk) begin
  if (receiver_stage != STAGE_IDLE) begin
    if (uart_drdy) begin
      timeout_counter <= 0;
    end else begin
      if (timeout_counter < TIMEOUT_COUNTER_MAX) begin
        timeout_counter <= timeout_counter + 1;
      end
    end
  end else begin
    timeout_counter <= 0;
  end
end

// Command Decoder
assign op = cmd_op;
wire op_is_bulk = cmd_byte[7]; // Bulk Write/Read bit
reg [7:0] ex_ndata = 0; // SCRAPE-only, but still needed
`ifdef SCRAPE
//reg [BYTE_COUNT_WIDTH-1:0] ex_nbyte_temp; // Temp storage for nbyte
wire [BYTE_COUNT_WIDTH-1:0] ex_ndata_w = {2'b0, ex_ndata};
`else
wire [BYTE_COUNT_WIDTH-1:0] ex_ndata_w = ex_ndata[BYTE_COUNT_WIDTH-1:0];
`endif
assign last_addr_byte = (1 << (cmd_aw + 1)) + 1;
assign nbyte_addr     = nbyte_inbuf < last_addr_byte ? last_addr_byte - nbyte_inbuf - 1 : 0;
assign last_data_byte = cmd_op_ex == CMD_OP_EX_BWRITE ? last_addr_byte + 2 + (ex_ndata_w<<1) :
                        cmd_op_ex == CMD_OP_EX_BREAD  ? last_addr_byte + 2 :
                        last_addr_byte + (1 << (cmd_dw + 1));
assign nbyte_data     = nbyte_inbuf < last_data_byte ? last_data_byte - nbyte_inbuf - 1: 0;
assign last_crc_byte  = last_data_byte + 4;
assign nbyte_crc      = nbyte_inbuf < last_crc_byte ? last_crc_byte - nbyte_inbuf - 1: 0;
wire [BYTE_COUNT_WIDTH-1:0] nbytes_ack = op_is_bulk ? 8 + (1<<(cmd_aw+1)) : 6 + (1<<(cmd_aw+1)) + (1<<(cmd_dw+1));
`ifdef SCRAPE
assign op_ex = cmd_op_ex[2];
reg [3:0] ex_data_nbyte;  // Byte count within each data element (up to 8 bytes for 64-bit element)
wire [3:0] ex_data_nbyte_max = (1 << (cmd_dw+1)) - 1;
reg [7:0] ex_data_count;  // Count of number of data elements parsed in BWRITE phase
wire [7:0] ex_data_count_max = (ex_ndata >> cmd_dw) - 1;
reg [2:0] nbyte_ndata;  // = nbyte_inbuf == last_addr_byte + 4 ? 3'b1 : 3'b0; // 3-bit for annoying verilator warning
wire [BYTE_COUNT_WIDTH-1:0] nbytes_bulk = 6 + (1<<(cmd_aw+1)) + (1<<(cmd_dw+1)) + ex_ndata_w;
initial begin
  ex_ndata = 0;
  nbyte_ndata = 0;
end
`endif

wire        [BYTE_COUNT_WIDTH-1:0] field_addr_size  = (1 << (cmd_aw + 1));
wire        [BYTE_COUNT_WIDTH-1:0] field_data_size  = (1 << (cmd_dw + 1));
localparam  [BYTE_COUNT_WIDTH-1:0] field_ndata_size = 2; // Fixed
localparam  [BYTE_COUNT_WIDTH-1:0] field_crc_size   = 4; // Fixed
`ifdef SCRAPE
wire        [BYTE_COUNT_WIDTH-1:0] field_bdata_size = ex_ndata_w - 1;
`endif

// Address Field (up to 16 ASCII bytes)
`ifdef SCRAPE
assign addr = bread_override ? bread_bus_addr : pkt_addr_l[ADDRESS_WIDTH-1:0];
`else
assign addr = pkt_addr_l[ADDRESS_WIDTH-1:0];
`endif
// Data Field (up to 16 ASCII bytes)

reg [63:0] data;  // Accommodate max size
wire [63:0] wmask_write = cmd_dw == 2'b00 ? 64'hffffffffffffff00 :
                          cmd_dw == 2'b01 ? 64'hffffffffffff0000 :
                          cmd_dw == 2'b10 ? 64'hffffffff00000000 :
                          64'h0000000000000000;
`ifdef SCRAP_ENABLE_MASK_OPS
wire [63:0] wmask_clr   = cmd_dw == 2'b00 ? 64'hffffffffffffff00 | data :
                          cmd_dw == 2'b01 ? 64'hffffffffffff0000 | data :
                          cmd_dw == 2'b10 ? 64'hffffffff00000000 | data : data;
wire [63:0] wmask_r     = cmd_op == CMD_OP_WRITE ? wmask_write :
                          cmd_op == CMD_OP_SETMASK ? 64'hffffffffffffffff :
                          cmd_op == CMD_OP_CLRMASK ? ~wmask_clr : 64'h0;
wire [63:0] wdata_write = cmd_dw == 2'b00 ? 64'h00000000000000ff & data :
                          cmd_dw == 2'b01 ? 64'h000000000000ffff & data :
                          cmd_dw == 2'b10 ? 64'h00000000ffffffff & data : data;
wire [63:0] wdata_r     = cmd_op == CMD_OP_WRITE ? wdata_write :
                          cmd_op == CMD_OP_SETMASK ? wdata_write :
                          cmd_op == CMD_OP_CLRMASK ? 64'hffffffffffffffff : 64'h0;
assign wmask = wmask_r[DATA_WIDTH-1:0];
assign wdata = wdata_r[DATA_WIDTH-1:0];
//assign wmask = wmask_write[DATA_WIDTH-1:0];
`else
// wmask can be ignored when mask ops disabled or can still be used on host
// side as:
//  ram[addr] = (ram[addr] & wmask) | wdata
// which allows for writes of size less than a full register width
assign wdata = data[DATA_WIDTH-1:0];
`endif
// CRC Field (4 ASCII bytes)
reg [15:0] crc;

// Status
reg cmd_ok, addr_ok, data_ok, crc_ok, term_ok;
reg addr_err, data_err, crc_err;
`ifdef SCRAPE
reg ex_ndata_ok;  // SCRAPE compatibility
localparam protocol_ok = 1'b1;
`else
localparam ex_ndata_ok = 1'b1;
wire protocol_ok = (cmd_op_ex == CMD_OP_EX_BWRITE) | (cmd_op_ex == CMD_OP_EX_BREAD) ? 1'b0 : 1'b1;
`endif
wire packet_preterm_valid = op_is_bulk ? cmd_ok & protocol_ok & addr_ok & ex_ndata_ok & crc_ok : cmd_ok & addr_ok & data_ok & crc_ok;
//wire packet_preterm_valid = op_is_bulk ? cmd_ok  & addr_ok & ex_ndata_ok & crc_ok : cmd_ok & addr_ok & data_ok & crc_ok;
wire packet_valid = packet_preterm_valid & term_ok & ~bread_bus_contention;
reg we_r;
wire packet_we = packet_valid & we_r;
`ifdef SCRAPE
reg ex_we, ex_we_pre;
assign we = op_is_bulk ? ex_we : (cmd_op != CMD_OP_READ) ? packet_we : 1'b0;
`else
assign we = cmd_op != CMD_OP_READ ? packet_we : 1'b0;
`endif
reg [31:0] mangled;
assign error_count = mangled;

// Response sender
reg mem_tx_start;
initial begin
`ifdef SCRAPE
  ex_ndata_ok = 1'b0;
  ex_we = 1'b0;
  ex_we_pre = 1'b0;
`endif
  rebuf_wdata = 0;
  mem_tx_start = 1'b0;
end

// Assume bad command byte if no other condition is met
wire [7:0] nack_char = (protocol_ok == 1'b0) ? CHAR_NACK_UNSUPPORTED :
                      (timeout == 1'b1) ? CHAR_NACK_TIMEOUT :
                      (data_err == 1'b1) ? CHAR_NACK_DECODE :
                      (term_ok == 1'b0) ? CHAR_NACK_TERM :
                      (crc_ok == 1'b0) ? CHAR_NACK_CRC :
                      (bus_contention == 1'b1) ? CHAR_NACK_CONTENTION :
                      CHAR_NACK_CMD;
wire [7:0] ack_char = (protocol_ok == 1'b0) ? CHAR_NACK_UNSUPPORTED :
                      (timeout == 1'b1) ? CHAR_NACK_TIMEOUT :
                      (data_err == 1'b1) ? CHAR_NACK_DECODE :
                      (term_ok == 1'b0) ? CHAR_NACK_TERM :
                      (crc_ok == 1'b0) ? CHAR_NACK_CRC :
                      (bus_contention == 1'b1) ? CHAR_NACK_CONTENTION :
                      (cmd_ok == 1'b0) ? CHAR_NACK_CMD :
                      CHAR_ACK;

// Sequencer
wire uart_drdy;
wire [7:0] uart_rbyte;
wire term_detected = uart_rbyte == BYTE_TERMINATOR ? uart_drdy : 1'b0;
wire [3:0] uart_rbyte_dehexed;
wire dehex_error;
reg [RESPONSE_ADDR_WIDTH-1:0] mem_tx_to_send;
dehexer #(.WIDTH_HEX_BYTES(1)) dehexer_inst (
  .hexin(uart_rbyte),
  .binout(uart_rbyte_dehexed),
  .decode_errors(dehex_error)
);
reg self_reset;
reg addr_latch;
always @(posedge clk) begin
  // Default assignment
  rebuf_we <= 1'b0;
  mem_tx_start <= 1'b0;
  we_r <= 1'b0;
`ifdef SCRAPE
  ex_we <= 1'b0;
  ex_we_pre <= 1'b0;
`endif
  rdata_prelatch <= 1'b0;
  crc_in_latch <= 1'b0;
  addr_latch <= 1'b0;
  if (rst | self_reset) begin
    nbyte_inbuf <= 0;
    nbyte_outbuf <= 0;
    nbyte_stage <= 0;
    receiver_stage <= STAGE_IDLE;
    data <= 64'h00000000;
    self_reset <= 1'b0;
    cmd_ok <= 1'b0;
    addr_ok <= 1'b0;
    addr_err <= 1'b0;
    data_ok <= 1'b0;
    data_err <= 1'b0;
    crc_ok <= 1'b0;
    crc_err <= 1'b0;
    term_ok <= 1'b0;
    crc_in_enable <= 1'b1;
`ifdef SCRAPE
    ex_data_count <= 0;
    ex_data_nbyte <= 0;
    ex_ndata_ok <= 1'b0;
`endif
    if (self_reset == 1'b0) mangled <= 32'h0; // HACK - reset mangled only if not a self_reset
  // Advance sequencer when new data ready
  //end else if (uart_drdy) begin
  end else begin
    if (addr_latch) begin
      pkt_addr_l <= pkt_addr;
    end
`ifdef SCRAPE
    if (ex_we_pre) begin
      ex_we <= 1'b1;
    end
`endif
    case (receiver_stage)
      STAGE_IDLE:
      begin
        if (uart_drdy) begin
          nbyte_inbuf <= nbyte_inbuf + 1;
          //$display("cmd byte = 0x%h", uart_rbyte);
          nbyte_outbuf <= 0; //nbyte_outbuf + 1;
          cmd_byte <= uart_rbyte; // Do not dehex the cmd byte
          nbyte_stage <= 0;
          receiver_stage <= STAGE_ADDR; // This stage is always 1 byte
          pkt_addr <= 64'h00000000; // Clear address in preperation for ADDR stage
`ifdef SCRAPE
          // Enforce syntax rules (valid SCRAPE cmd_byte is any with bit 5=hi)
          if (uart_rbyte[5]) cmd_ok <= 1'b1;
          else begin
            cmd_ok <= 1'b0;
            $display("From IDLE to pre-recover");
            receiver_stage <= STAGE_PRE_RECOVER;
          end
          // Add cmd byte to response buffer
          // Mask out dw for response to CMD_OP_EX_BWRITE only
          rebuf_wdata <= (uart_rbyte & 8'hf0) == 8'ha0 ? uart_rbyte & 8'hf3 : uart_rbyte;
`else
          // Enforce syntax rules (valid SCRAP cmd_byte is any with bit 5=hi & bit 7=lo)
          if (uart_rbyte[5] & ~uart_rbyte[7]) cmd_ok <= 1'b1;
          else begin
            cmd_ok <= 1'b0;
            $display("From IDLE to pre-recover");
            receiver_stage <= STAGE_PRE_RECOVER;
          end
          rebuf_wdata <= uart_rbyte; // Do not dehex the cmd byte
`endif
          //$display("Adding cmd_byte = 0x%h = %s", uart_rbyte, uart_rbyte);
          rebuf_we <= 1'b1;
          // NACK if early terminated
          if (term_detected) begin
            nbyte_stage <= 0;
            crc_in_enable <= 1'b1;
            //receiver_stage <= STAGE_ACK;
            $display("From IDLE to pre-recover (early term)");
            receiver_stage <= STAGE_PRE_RECOVER;
            mangled <= mangled + 1;
          end
        end// if (uart_drdy)
      end
      STAGE_ADDR:
      begin
        if (uart_drdy) begin
          //$display("ADDR [%d] : 0x%h", nbyte_stage, uart_rbyte_dehexed);
          nbyte_inbuf <= nbyte_inbuf + 1;
          nbyte_outbuf <= nbyte_outbuf + 1;
          nbyte_stage <= nbyte_stage + 1;
          pkt_addr[4*(nbyte_addr+1)-1-:4] <= uart_rbyte_dehexed;
          addr_err <= addr_err | dehex_error;
          if (nbyte_stage == field_addr_size - 1) begin
            rdata_prelatch <= 1'b1;
            nbyte_stage <= 0;
            crc_in_enable <= 1'b1;
            //$display("STAGE_ADDR done: pkt_addr = 0x%h", pkt_addr);
            addr_latch <= 1'b1;
`ifdef SCRAPE
            if (op_is_bulk) begin
              //$display("Going to NDATA");
              receiver_stage <= STAGE_NDATA;
            end else begin
              receiver_stage <= STAGE_DATA;
            end
`else
            receiver_stage <= STAGE_DATA;
`endif
            if (~(addr_err | dehex_error)) addr_ok <= 1'b1;
            else begin
              $display("From ADDR to pre-recover");
              receiver_stage <= STAGE_PRE_RECOVER;
            end
          end
          // Add addr bytes to response buffer
          rebuf_wdata <= uart_rbyte;
          rebuf_we <= 1'b1;
          // NACK if early terminated
          if (term_detected) begin
            nbyte_stage <= 0;
            crc_in_enable <= 1'b0;
            //receiver_stage <= STAGE_ACK;
            $display("From ADDR to pre-recover (early term)");
            receiver_stage <= STAGE_PRE_RECOVER;
            mangled <= mangled + 1;
          end
        end else if (timeout) begin
          $display("From ADDR to pre-recover (timeout)");
          receiver_stage <= STAGE_PRE_RECOVER;
        end// if (uart_drdy)
      end
      STAGE_DATA:
      begin
        if (uart_drdy) begin
          //$display("DATA [%d] : 0x%h", nbyte_stage, uart_rbyte_dehexed);
          nbyte_inbuf <= nbyte_inbuf + 1;
          nbyte_outbuf <= nbyte_outbuf + 1;
          nbyte_stage <= nbyte_stage + 1;
          data[4*(nbyte_data+1)-1-:4] <= uart_rbyte_dehexed;
          data_err <= data_err | dehex_error;
          if (nbyte_stage == field_data_size - 1) begin
            nbyte_stage <= 0;
            crc_in_enable <= 1'b0;
            receiver_stage <= STAGE_CRC;
            if (~(data_err | dehex_error)) data_ok <= 1'b1;
            else begin
              $display("From DATA to pre-recover");
              receiver_stage <= STAGE_PRE_RECOVER;
            end
          end
          if ((cmd_op == CMD_OP_READ) & ~op_is_bulk) begin
            // Place read data (hexed) in response buffer
            rebuf_wdata <= rdata_hexed[8*(nbyte_data+1)-1-:8];
          end else begin
            // Assume ACK until proven otherwise
            if (nbyte_outbuf == last_addr_byte - 1) rebuf_wdata <= ".";
            else rebuf_wdata <= "0";  // TODO - support error count?
          end
          rebuf_we <= 1'b1;
          // NACK if early terminated
          if (term_detected) begin
            nbyte_stage <= 0;
            crc_in_enable <= 1'b0;
            //receiver_stage <= STAGE_ACK;
            $display("From DATA to pre-recover (early term)");
            receiver_stage <= STAGE_PRE_RECOVER;
            mangled <= mangled + 1;
          end
        end else if (timeout) begin
          $display("From DATA to pre-recover (timeout)");
          receiver_stage <= STAGE_PRE_RECOVER;
        end// if (uart_drdy)
      end
      STAGE_CRC:
      begin
        // CRC output is calculated automatically
        if (uart_drdy) begin
          //$display("CRC [%d] 0x%h", nbyte_crc, uart_rbyte_dehexed);
          nbyte_inbuf <= nbyte_inbuf + 1;
          nbyte_stage <= nbyte_stage + 1;
          crc[4*(nbyte_crc+1)-1-:4] <= uart_rbyte_dehexed;
          crc_err <= crc_err | dehex_error;
          if (nbyte_stage == field_crc_size - 1) begin
            nbyte_stage <= 0;
            crc_in_enable <= 1'b0;
            receiver_stage <= STAGE_TERM;
            crc_in_latch <= 1'b1;
            if (~(crc_err | dehex_error)) crc_ok <= 1'b1;
            else begin
              $display("From CRC to pre-recover");
              receiver_stage <= STAGE_PRE_RECOVER;
            end
          end
          // NACK if early terminated
          if (term_detected) begin
            nbyte_stage <= 0;
            crc_in_enable <= 1'b0;
            //receiver_stage <= STAGE_ACK;
            $display("From CRC to pre-recover (early term)");
            receiver_stage <= STAGE_PRE_RECOVER;
            mangled <= mangled + 1;
          end
        end else if (timeout) begin
          $display("From CRC to pre-recover (timeout)");
          receiver_stage <= STAGE_PRE_RECOVER;
        end// if (uart_drdy)
      end
      STAGE_TERM:
      begin
        if (uart_drdy) begin
          // Only execute this stage once. If termination not detected, will not overflow rebuf
          //$display("incrc = 0x%h, crc = 0x%h", incrc, crc);
          if (incrc == crc) crc_ok <= 1'b1;
          else crc_ok <= 1'b0;
          crc_in_enable <= 1'b0;
          if (term_detected) begin
            // ACK if terminated
            //$display("TERM nbyte_inbuf = %d, nbyte_outbuf = %d", nbyte_inbuf, nbyte_outbuf);
            nbyte_inbuf <= nbyte_inbuf + 1;
            // Terminate bytes to response buffer
            // Only exit from this stage is detecting termination
            term_ok <= 1'b1;
            nbyte_stage <= 0;
            if (cmd_op == CMD_OP_WRITE) begin
              we_r <= 1'b1;
            end
`ifdef SCRAPE
            if (cmd_op_ex == CMD_OP_EX_BREAD) begin
              ex_data_nbyte <= ex_data_nbyte_max;
              ex_data_count <= 0;
              pkt_offset <= nbyte_outbuf + 1;
              mem_tx_to_send <= nbyte_outbuf + 1 + (ex_ndata_w<<1);
              receiver_stage <= STAGE_ACK;
            end else begin
              mem_tx_to_send <= nbyte_outbuf + 1;
              receiver_stage <= STAGE_ACK;
            end
`else
            mem_tx_to_send <= nbyte_outbuf + 1;
            receiver_stage <= STAGE_ACK;
`endif
          end else begin
            // No term char detected
            term_ok <= 1'b0;
            mangled <= mangled + 1;
            //receiver_stage <= STAGE_ACK;
            $display("From TERM to pre-recover (no term)");
            receiver_stage <= STAGE_PRE_RECOVER;
          end // if (term_detected)
        end else if (timeout) begin
          $display("From TERM to pre-recover (timeout)");
          receiver_stage <= STAGE_PRE_RECOVER;
        end// if (uart_drdy)
      end
      STAGE_ACK:
      begin
        nbyte_stage <= nbyte_stage + 1;
        if (packet_valid == 1'b1) begin
          // Send response as-is if packet is valid
          //$display("ACK - mem_tx_start, mem_tx_to_send = %d", mem_tx_to_send);
          mem_tx_start <= 1'b1;
          rebuf_wselect <= ~rebuf_wselect; // Switch buffers
          nbyte_stage <= 0;
          receiver_stage <= STAGE_IDLE;
          self_reset <= 1'b1;
        end else begin
          // Change response to NACK if packet invalid
          //$display("NACK CHAR = %s", nack_char);
          if (nbyte_stage == 0) begin
            nbyte_outbuf <= last_addr_byte;
            rebuf_wdata <= ack_char;
            rebuf_we <= 1'b1;
            mangled <= mangled + 1;
          end else begin
            //$display("NACK, nack_char = %s", nack_char);
            nbyte_outbuf <= last_addr_byte + 1;
            rebuf_wdata <= "0"; // TODO - Add mangled error count
            rebuf_we <= 1'b1;
            mem_tx_start <= 1'b1;
            rebuf_wselect <= ~rebuf_wselect; // Switch buffers
            nbyte_stage <= 0;
            receiver_stage <= STAGE_IDLE;
            self_reset <= 1'b1;
          end // if (nbyte_stage == 0)
        end // if (packet_valid == 1'b1)
      end // STAGE_ACK
      STAGE_PRE_RECOVER:
      begin
        //$display("pre-recover");
        //$display("nbyte_outbuf <= 0; nbyte_stage <= 0");
        nbyte_outbuf <= 0;  // Rewind
        nbyte_stage <= 0;
        rebuf_wdata <= recover_response[0];
        rebuf_we <= 1'b1;
        receiver_stage <= STAGE_RECOVER;
      end
      STAGE_RECOVER:
      begin
        // Re-build response packet (clobber existing data)
        if (nbyte_outbuf < RECOVER_RESPONSE_LENGTH) begin
          //$display("recover byte %d = 0x%h", nbyte_outbuf, recover_response[nbyte_stage[2:0]]);
          rebuf_wdata <= recover_response[nbyte_stage[2:0]];
          rebuf_we <= 1'b1;
          if (nbyte_stage > 0) begin
            //$display("nbyte_outbuf <= %d", nbyte_outbuf+1);
            nbyte_outbuf <= nbyte_outbuf + 1;
          end
          //$display("nbyte_stage <= %d", nbyte_stage+1);
          nbyte_stage <= nbyte_stage + 1;
        end else begin
          // Wait for incoming packet to finish before sending response
          if (term_detected | timeout) begin
            //$display("term_detected ? %d; timeout ? %d", term_detected, timeout);
            mem_tx_to_send <= nbyte_outbuf;
            nbyte_stage <= 0;
            receiver_stage <= STAGE_ACK;
          end
        end
      end
`ifdef SCRAPE
      STAGE_NDATA:
      begin
        if (uart_drdy) begin
          nbyte_inbuf <= nbyte_inbuf + 1;
          nbyte_outbuf <= nbyte_outbuf + 1;
          nbyte_stage <= nbyte_stage + 1;
          //$display("NDATA[%d] uart_rbyte_dehexed = 0x%h", nbyte_stage, uart_rbyte_dehexed);
          ex_ndata[4*(2-nbyte_stage)-1-:4] <= uart_rbyte_dehexed;
          // NACK if early terminated
          if (term_detected) begin
            mangled <= mangled + 1;
            nbyte_stage <= 0;
            crc_in_enable <= 1'b0;
            receiver_stage <= STAGE_ACK;
          end else if (nbyte_stage == field_ndata_size - 1) begin
            nbyte_stage <= 0;
            if (cmd_op_ex == CMD_OP_EX_BWRITE) begin
              //$display("Going to BWRITE");
              crc_in_enable <= 1'b1;
              receiver_stage <= STAGE_BWRITE;
            end else begin
              //$display("BREAD - to CRC");
              crc_in_enable <= 1'b0;
              receiver_stage <= STAGE_CRC; // BREAD stage deferred until after packet received
            end
            ex_ndata_ok <= 1'b1;
            ex_data_count <= 0;
            ex_data_nbyte <= ex_data_nbyte_max;
          end
          // Assume ACK for now
          if (cmd_op_ex == CMD_OP_EX_BREAD) begin
            // Place 'ndata' in 'ndata' field, rather than ACK
            rebuf_wdata <= uart_rbyte;
          end else begin
            // Assume ACK until proven otherwise
            if (nbyte_stage == 0) rebuf_wdata <= ".";
            else rebuf_wdata <= "0";  // TODO - support error count?
          end
          rebuf_we <= 1'b1;
        end else if (timeout) begin
          $display("From NDATA to pre-recover (timeout)");
          receiver_stage <= STAGE_PRE_RECOVER;
        end// if (uart_drdy)
      end
      STAGE_BWRITE:
      begin
        if (uart_drdy) begin
          // Collect the hex bytes and bus write for each
          //$display("%d %d uart_rbyte_dehexed = 0x%h", ex_data_count, ex_data_nbyte, uart_rbyte_dehexed);
          //$display("BWRITE: ex_ndata = %d", ex_ndata);
          crc_in_enable <= 1'b1;
          nbyte_inbuf <= nbyte_inbuf + 1;
          nbyte_stage <= nbyte_stage + 1; // Unused in this stage
          data[4*(ex_data_nbyte+1)-1-:4] <= uart_rbyte_dehexed;
          data_err <= data_err | dehex_error;
          ex_data_nbyte <= ex_data_nbyte - 1;   // MSB-first, decrementing
          if (ex_data_nbyte == 0) begin
            ex_data_nbyte <= ex_data_nbyte_max;
            if (ex_data_count == ex_data_count_max) begin
              // BWRITE phase done
              nbyte_stage <= 0;
              crc_in_enable <= 1'b0;
              receiver_stage <= STAGE_CRC;
              if (~(data_err | dehex_error)) data_ok <= 1'b1;
            end else begin
              // Prepare to receive next write
              ex_data_count <= ex_data_count + 1;
            end
            // Perform bus write operation
            ex_we_pre <= 1'b1;
            if (ex_data_count > 0) begin
              pkt_addr <= pkt_addr + 1;
              addr_latch <= 1'b1;
            end
          end
        end else if (timeout) begin
          $display("From BWRITE to pre-recover (timeout)");
          receiver_stage <= STAGE_PRE_RECOVER;
        end// if (uart_drdy)
      end
`endif
      default: receiver_stage <= STAGE_IDLE;  // TODO - mangled?
    endcase
  end
end

// UARTs
reg uart_rst;
wire uart_busy;
reg mem_tx_rst;
wire mem_tx_busy;
wire baudclk_rx, baudclk_tx;

wire crc_in_zero = self_reset;
uart_rx_crc #(.SYSCLK_FREQ_HZ(F_CLK_IN),
  .BAUD_FREQ_HZ(F_BAUD),
  .DATAWIDTH(8),
  .DEBOUNCE_COUNT(8),
  .STOP_BITS(1)
) uart_rx_inst (
  .clk(clk),           // System clock
  .rst(uart_rst),      // Synchronous reset
  .rdata(uart_rbyte),  // Byte read
  .drdy(uart_drdy),    // Rising edge triggers byte going out on wire if not busy
  .busy(uart_busy),    // Asserted while write in progress
  // CRC
  .crc_zero(crc_in_zero),
  .crc_latch(crc_in_latch),
  .crc_enable(crc_in_enable),
  .crc(incrc),
  // Debug
  .baudclk(baudclk_rx),
  .RxD(uart_rxd)       // Actual RxD line from the wire
);

mem_tx_crc #(
  .SYSCLK_FREQ_HZ(F_CLK_IN),
  .BAUD_FREQ_HZ(F_BAUD),
  .ADDR_WIDTH(RESPONSE_ADDR_WIDTH),
  .STOP_BITS(2)
) mem_tx_inst (
  .clk(clk),                // System clock
  .rst(mem_tx_rst),         // Synchronous reset
  .start(mem_tx_start),     // Enable. Rising edge triggers start of transfer
  .nToSend(mem_tx_to_send), // Number of bytes to send. Latched at rising edge of 'start'
  .wdata(rebuf_rdata),      // Current byte to write (should come from memory indexed by 'addr')
  .addr(rebuf_raddr),       // Address into memory where bytes are stored
  .rce(rebuf_rce),          // Read clock enable (asserted for 1 clock cycle after addr is valid)
  .busy(mem_tx_busy),       // Transfer in progress
  // Debug
  .baudclk(baudclk_tx),
  // PHY
  .TxD(uart_txd)            // Actual TxD line to go out on the wire
);

// Watch for falling edge on mem_tx_busy
reg mem_tx_busy_0;
wire mem_tx_busy_fe = ((mem_tx_busy == 1'b0) && (mem_tx_busy_0 == 1'b1)) ? 1'b1 : 1'b0;
always @(posedge clk) begin
  mem_tx_busy_0 <= mem_tx_busy;
  if (mem_tx_busy_fe) rebuf_rselect <= ~rebuf_rselect; // Toggle buffer when write is finished
end

initial begin
  we_r = 1'b0;
  mem_tx_to_send = 0;
  mem_tx_rst = 1'b0;
  uart_rst = 1'b0;
  self_reset = 1'b0;
  cmd_byte = 8'b0;
  nbyte_inbuf = 0;
  nbyte_outbuf = 0;
  nbyte_stage = 0;
  cmd_ok = 1'b0;
  addr_ok = 1'b0;
  data_ok = 1'b0;
  crc_ok = 1'b1;
  term_ok = 1'b0;
  addr_err = 1'b0;
  data_err = 1'b0;
  crc_err = 1'b0;
  receiver_stage = STAGE_IDLE;
  mangled = 32'h0;
  data = 64'h00000000;
  pkt_addr = 64'h00000000;
  pkt_addr_l = 64'h00000000;
  addr_latch = 1'b0;
  crc = 16'h0000;
  //outcrc = 16'h0000;
  //incrc = 16'h0000;
  rdata_prelatch = 1'b0;
  rdata_max = 64'h0;
  crc_in_enable = 1'b1;
end

endmodule
/*
 * UART receiver with running 16-bit CRC calculation on reception
 * todo:
 *   Add support for 7-bit data width
 */

/*
* 0. De-bounce filter RxD
* 1. Watch for falling edge on RxD (start bit)
*    Start Baud Clk
* 2. Sample on baud clk falling edge
* -- Reset Baud clk count on RxD falling edge to re-synchronize (NO; debouncer)
* 3. Disable baud clk on STOP bit
*/

module uart_rx_crc
  #(
    parameter SYSCLK_FREQ_HZ = 100000000,
    parameter BAUD_FREQ_HZ = 115200,
    parameter DATAWIDTH = 8,        // Data width in bits. TODO - Support 7 bits
    parameter DEBOUNCE_COUNT = 8,   // Count in 'clk' periods to debounce RxD
    parameter STOP_BITS = 1         // 1 or 2
  )(
    input wire clk,                 // System clock
    input wire rst,                 // Synchronous reset ('1' = reset)
    output wire [DATAWIDTH-1:0] rdata,  // Byte read
    output reg drdy,                // Asserted for 1 'clk' cycle. '1' = New read byte ready to consume
    output wire busy,               // UART is receiving a byte (START detected, no STOP yet)
    // CRC
    input wire crc_zero,
    input wire crc_latch,
    input wire crc_enable,
    output [15:0] crc,
    // Debug
    output wire baudclk,
    input wire RxD                  // Actual RxD line from the wire
  );

wire baud_clk;
assign baudclk = baud_clk;
wire baud_re;
wire baud_fe;
reg baud_en;
wire rxd_db;
reg rxd_0, rxd_1;
wire rxd_fe;
reg [DATAWIDTH-1:0] r_rdata;
reg [4:0] state;

assign rdata = r_rdata;
assign rxd_fe = (rxd_0 == 1'b0) && (rxd_1 == 1'b1) ? 1'b1 : 1'b0;

localparam [4:0]
  STATE_BIT0    = 5'b00000,
  STATE_IDLE    = 5'b10000,
  STATE_START   = 5'b10001,
  STATE_STOP0   = 5'b01000, // Swap defs of STOP0/STOP1 to use only 1 stop bit
  STATE_STOP1   = 5'b01001;

assign busy = state == STATE_IDLE ? 1'b0 : 1'b1;

initial
begin
  state = STATE_IDLE;
  baud_en = 1'b0;
  r_rdata = {DATAWIDTH{1'b0}};
end

wire crc_ce = drdy & crc_enable;
wire [15:0] crc_calc;
reg  [15:0] outcrc;
assign crc = outcrc;
wire [7:0] crc_din = r_rdata;
crc_hqx #(.C("I")) crc_hqx_in (
  .clk(clk),
  .ce(crc_ce),
  .din(crc_din),
  .zero(crc_zero),
  .crc(crc_calc)
);
initial begin
  outcrc = 0;
end
always @(posedge clk) begin
  if (crc_latch) begin
    //$display("UART RX CRC = 0x%h", crc_calc);
    outcrc <= crc_calc;
  end
end

`ifdef SIMULATE
  // Don't debounce for simulation
wire debounce_nothing;
debounce #(
  .LEN(DEBOUNCE_COUNT),
  .INITIAL_STATE(1'b1)  // Initial state of dout
  ) debounce_rxd (
  .clk(clk),
  .din(RxD),
  .dout(debounce_nothing)
);
assign rxd_db = RxD;
`else
debounce #(
  .LEN(DEBOUNCE_COUNT),
  .INITIAL_STATE(1'b1)  // Initial state of dout
  ) debounce_rxd (
  .clk(clk),
  .din(RxD),
  .dout(rxd_db)
);
`endif

  // First need baud clk for clock-enable
baudclk #(
  .SYSCLK_FREQ_HZ(SYSCLK_FREQ_HZ),  // 100MHz
  .BAUD_FREQ_HZ(BAUD_FREQ_HZ),      // 1,152,000 # 10*115200
  .COUNT_WIDTH($clog2(SYSCLK_FREQ_HZ/BAUD_FREQ_HZ)+1) // TODO how calculate count width?  Needs to be ceil(log2(f_clk/f_baud))
  ) baudclk_inst (
  .clk(clk),
  .rst(~baud_en),
  .bclk(baud_clk),
  .re(baud_re),
  .fe(baud_fe)
);

always @(posedge clk)
begin
  if (rst) begin
    rxd_0 <= 1'b0;
    rxd_1 <= 1'b0;
    drdy <= 1'b0;
    state <= STATE_IDLE;
  end else begin
    rxd_1 <= rxd_0;
    rxd_0 <= rxd_db;
    drdy <= 1'b0;
    if ((state == STATE_IDLE) && rxd_fe) begin
      //$display("RX Starting");
      state <= STATE_START;
      baud_en <= 1'b1;
    end
    if (baud_fe) begin
      casez (state)
        STATE_IDLE: begin
          state <= STATE_IDLE;
        end
        STATE_START: begin
          // Start bit is ignored
          state <= STATE_BIT0;
        end
        5'b00???: begin // Matches STATE_BIT0 through STATE_BIT0+7
          r_rdata[state[2:0]] <= rxd_db;
          state <= state + 1;
        end
        STATE_STOP0: begin
          if (STOP_BITS == 1) begin
            //$display("RX going IDLE");
            state <= STATE_IDLE;
            drdy <= 1'b1;
            baud_en <= 1'b0;
          end else begin
            state <= STATE_STOP1;
          end
        end
        STATE_STOP1: begin
          state <= STATE_IDLE;
          //$display("RX going IDLE");
          drdy <= 1'b1;
          baud_en <= 1'b0;
        end
        default: begin
          state <= 0;
        end
      endcase
    end
  end
end

endmodule
/*
 * Simple UART transmitter application
 * TODO:
 *   Add support for 7-bit data width
 *   Add support for 1 stop bit
 */


module uart_tx
  #(
    parameter SYSCLK_FREQ_HZ = 100000000,
    parameter BAUD_FREQ_HZ = 115200,
    parameter DATAWIDTH = 8,        // Data width in bits. TODO - Support 7 bits
    parameter STOP_BITS = 1         // 1 or 2
  )(
    input wire clk,                 // System clock
    input wire rst,                 // Synchronous reset
    input wire [DATAWIDTH-1:0] wdata,  // Byte to write
    input wire go,                  // Rising edge triggers byte going out on wire if not busy
    output wire busy,               // Asserted while write in progress
    output reg wdata_latched,      // Single-cycle asserted when wdata has been latched
    // Debug
    output wire baudclk,
    output wire TxD                 // Actual TxD line to go out on the wire
  );

wire baud_clk;
assign baudclk = baud_clk;
wire baud_re;
wire baud_fe;
reg baud_en;
reg txd;
reg go_0, go_1;
wire go_re = (go_0 == 1'b1) && (go_1 == 1'b0) ? 1'b1 : 1'b0;
reg [DATAWIDTH-1:0] wdata_l;
reg [4:0] state;

localparam [4:0]
  STATE_BIT0    = 5'b00000,
  STATE_IDLE    = 5'b10000,
  STATE_START   = 5'b10001,
  STATE_STOP0   = 5'b01000, // Swap defs of STOP0/STOP1 to use only 1 stop bit
  STATE_STOP1   = 5'b01001;

assign TxD = txd;
assign busy = state == STATE_IDLE ? 1'b0 : 1'b1;

initial
begin
  wdata_l = 0;
  state = STATE_IDLE;
  baud_en = 1'b0;
  go_0 = 1'b0;
  go_1 = 1'b0;
  txd = 1'b1;
  wdata_latched = 1'b0;
end

  // First need baud clk for clock-enable
baudclk #(
  .SYSCLK_FREQ_HZ(SYSCLK_FREQ_HZ),  // 100MHz
  .BAUD_FREQ_HZ(BAUD_FREQ_HZ),      // 1,152,000 # 10*115200
  .COUNT_WIDTH($clog2(SYSCLK_FREQ_HZ/BAUD_FREQ_HZ)+1) // TODO how calculate count width?  Needs to be ceil(log2(f_clk/f_baud))
  ) baudclk_inst (
  .clk(clk),
  .rst(~baud_en),
  .bclk(baud_clk),
  .re(baud_re),
  .fe(baud_fe)
);

always @(posedge clk)
begin
  wdata_latched <= 1'b0;
  if (rst) begin
    txd <= 1'b1;
    state <= STATE_IDLE;
    baud_en <= 1'b0;
  end else begin
    go_1 <= go_0;
    go_0 <= go;
    if ((state == STATE_IDLE) && go_re) begin
      //$display("TX Starting");
      state <= STATE_START;
      txd <= 1'b1;
      baud_en <= 1'b1;
    end
    if (baud_re) begin
      casez (state)
        STATE_IDLE: begin
          txd <= 1'b1;
          state <= STATE_IDLE;
        end
        STATE_START: begin
          txd <= 1'b0; // Start bit is 0
          wdata_l <= wdata;
          wdata_latched <= 1'b1;
          state <= STATE_BIT0;
        end
        5'b00???: begin // Matches STATE_BIT0 through STATE_BIT0+7
          txd <= wdata_l[state[2:0]];
          state <= state + 1;
        end
        STATE_STOP0: begin
          txd <= 1'b1;
          if (STOP_BITS == 1) begin
            //$display("TX Going IDLE");
            state <= STATE_IDLE;
            baud_en <= 1'b0;
          end else begin
            state <= STATE_STOP1;
          end
        end
        STATE_STOP1: begin
          //$display("TX Going IDLE");
          txd <= 1'b1;
          state <= STATE_IDLE;
          baud_en <= 1'b0;
        end
        default: begin
          state <= 0;
        end
      endcase
    end
  end
end

endmodule
