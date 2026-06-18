/* spi_mon
   Simple SPI command sequencer for use with spi_master.v and its derivatives.
   Based on some of the ideas in i2c_chunk.v

   A programmable instruction memory provides the sequence that
   this module executes as fast as the downstream spi_master allows.
   The instruction memory is divided into 8-bit words and each
   SPI transaction is encoded as follows:
    39                                               7          0
   | OPTIONS | SPI_CMD(3) | SPI_CMD(2) | SPI_CMD(1) | SPI_CMD(0) |

   As spi_master.v operates at a 32-bit granularity, allowing two SPI
   transactions to be issued back-to-back, this module expects all SPI
   commands to be 32-bit long. A mandatory OPTIONS word provides the
   following additional settings:
      END - End of instruction stream;
      SEL - SPI target selection;
      RNW - Whether the SPI
   command returns data (1) or not (0). The encoding of the OPTIONS word
   is as follows:
    7    6   5   4   1   0
   | RSVD | END | SEL | RNW |

   Since this module always outputs a 32-bit SPI command, it is up the
   instantiation to correctly split the command into address and data,
   as required by the target spi_master.v instance.

   A Returned data is sequentially stored into a DPRAM that can be read
   by the host. The contents of the DPRAM are double-buffered so that
   the host reads a coherent set of values.

   This module iterates over the instruction memory in a loop.
   A runtime-controllable sleep control register sets the rate
   at which the SPI polling happens.
*/
`timescale 1ns / 1ns

module spi_mon #(
   parameter SLEEP_SHIFT = 20,
   parameter IMEM_WI = 9,
   parameter DMEM_WI = 7
) (
   input         clk,
   input         en,     // Enable monitoring
   input  [7:0]  sleep,  // In units of 1<<SLEEP_SHIFT clock cycles
   input  [7:0]  wr_dwell,  // Dwell after a write, in units of 1<<SLEEP_SHIFT clock cycles

   input                imem_we,
   input  [IMEM_WI-1:0] imem_waddr,
   input  [7:0]         imem_wdat,

   // To spi_master
   output [3:0]  spi_hw_sel,
   output        spi_start,
   input         spi_busy,
   output [31:0] spi_data_addr,
   output        spi_rnw,
   input         spi_rvalid,
   input  [31:0] spi_rdata,

   // Data readout
   input  [DMEM_WI-1:0] rd_addr,  // Stores up to 128 values
   output [31:0]        rd_data
);
   // --------
   // Dual-port instruction memory
   // --------
   reg [IMEM_WI-1:0] iaddr=0;
   wire [7:0] idat;
   dpram #(.aw(IMEM_WI), .dw(8)) i_imem (
      .clka  (clk),
      .clkb  (clk),
      .wena  (imem_we),
      .addra (imem_waddr),
      .dina  (imem_wdat),
      .douta (),
      .addrb (iaddr),
      .doutb (idat)
   );

   reg end_stream=0;
   reg sleep_on=0, sleep_on_r=0;
   reg [SLEEP_SHIFT+8-1:0] sleep_cnt=0;
   always @(posedge clk) if (en) begin
      sleep_on_r <= sleep_on;
      if (end_stream)
         sleep_on <= 1;
      if (sleep_on_r) begin
         sleep_cnt <= sleep_cnt + 1;
         if (sleep_cnt[SLEEP_SHIFT+7:SLEEP_SHIFT] == sleep) begin
            sleep_on <= 0;
            sleep_cnt <= 0;
         end
      end
   end

   // Gate spi_busy by DWELL cycles
   reg rnw_r=0;  // Assigned later
   reg spi_busy_r=0, spi_busy_gate=0;
   reg [SLEEP_SHIFT+8-1:0] dwell_cnt=0;
   always @(posedge clk) begin
      spi_busy_r <= spi_busy;
      if (!spi_busy && spi_busy_r)
         dwell_cnt <= 1;
      if (spi_busy && !spi_busy_r)
         spi_busy_gate <= 1'b1;
      if (dwell_cnt > 0) begin
         dwell_cnt <= dwell_cnt + 1;
         // Don't dwell on reads
         if (dwell_cnt[SLEEP_SHIFT+7:SLEEP_SHIFT] == (wr_dwell+1) || rnw_r) begin
            spi_busy_gate <= 1'b0;
            dwell_cnt <= 0;
         end
      end
   end

   // Instruction decoding
   reg start=0;
   reg [2:0] word=0, word_r=0;
   reg [1:0] rsvd=0;
   reg rnw=0;
   reg [3:0] hw_sel=0, hw_sel_r=0;
   reg [31:0] spi_cmd=0;
   reg spi_cmd_v=0;
   always @(posedge clk) begin
      if (!en) begin
         iaddr <= 0;
         word <= 0;
         word_r <= 0;
         spi_cmd_v <= 0;
      end else if (!sleep_on_r) begin
         end_stream <= 0;
         if (!spi_cmd_v) begin  // Don't fetch/decode if we have no storage left
            iaddr <= end_stream ? 0 : iaddr + 1;
            word <= (end_stream || word==4) ? 0 : word + 1;
            if (word_r == 0 && iaddr != 0)
               {rsvd, end_stream, hw_sel, rnw} <= idat;
            else begin
               spi_cmd <= {spi_cmd[23:0], idat};
               if (word_r == 4) begin
                  spi_cmd_v <= 1;
                  iaddr <= iaddr;  // Hold
                  word <= word;
               end
            end
         end
      end

      start <= 0;
      if (spi_cmd_v && !spi_busy_gate) begin
         start <= 1;
         hw_sel_r <= hw_sel;  // hw_sel cannot change until we send out new cmd
         rnw_r <= rnw;
         spi_cmd_v <= 0;  // Send command
      end
      word_r <= word;
   end

   assign spi_start = start;
   assign spi_data_addr = spi_cmd;
   assign spi_rnw = rnw;
   assign spi_hw_sel = hw_sel_r;

   // Return data storage and readout
   reg bank=0;
   reg [DMEM_WI-1:0] save_addr=0;
   wire sleep_off = ~sleep_on & sleep_on_r;
   always @(posedge clk) begin
      if (!en || sleep_off) begin
         save_addr <= 0;
         if (sleep_off) bank <= ~bank;  // Flip bank
      end else if (spi_rvalid)
         save_addr <= save_addr + 1;
   end

   dpram #(.aw(DMEM_WI+1), .dw(32)) i_dpram (
      .clka  (clk),
      .clkb  (clk),
      .addra ({bank, save_addr}),
      .douta (),  // Unused
      .dina  (spi_rdata),
      .wena  (spi_rvalid & en),  // Don't save if disabled
      .addrb ({~bank, rd_addr}),
      .doutb (rd_data));

endmodule
