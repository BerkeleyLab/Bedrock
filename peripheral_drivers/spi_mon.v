/* spi_mon
   Simple SPI command sequencer for use with spi_master.v and its derivatives. Based on some
   of the ideas in i2c_chunk.v

   A programmable instruction memory provides the sequence that this module executes as fast
   as the downstream spi_master allows. The instruction memory is divided into 8-bit words and
   each SPI transaction is encoded as follows:
    39                                               7          0
   | OPTIONS | SPI_CMD(3) | SPI_CMD(2) | SPI_CMD(1) | SPI_CMD(0) |

   As spi_master.v operates at a 32-bit granularity, allowing two SPI transactions to be issued
   back-to-back, this module expects all SPI commands to be 32-bit long. A mandatory OPTIONS word
   provides the following additional settings:
      END - End of instruction stream;
      SEL - SPI target selection;
      RNW - Whether the SPI
   command returns data (1) or not (0). The encoding of the OPTIONS word is as follows:
    7    6   5   4   1   0
   | RSVD | END | SEL | RNW |

   Since this module always outputs a 32-bit SPI command, it is up the instantiation to correctly
   split the command into address and data, as required by the target spi_master.v instance.

   A Returned data is sequentially stored into a DPRAM that can be read by the host. No effort is
   made to guarantee that the host reads frozen/coherent values from the DPRAM. It is expected that
   the SPI readout rate is much faster than the host.

   This module iterates over the instruction memory in a loop. A runtime-controllable sleep control
   register sets the rate at which the SPI polling happens.
*/

module spi_mon #(
   parameter SLEEP_SHIFT = 20,
   parameter IMEM_WI = 9,
   parameter DMEM_WI = 7
) (
   input         clk,
   input         en,    // Enable monitoring
   input  [7:0]  sleep, // In units of 1<<SLEEP_SHIFT clock cycles

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
   input  [DMEM_WI-1:0] rd_addr, // Stores up to 128 values
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
   reg [20+8-1:0] sleep_cnt=0;
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

   // Instruction decoding
   reg [2:0] word=0, word_r=0;
   reg [1:0] rsvd;
   reg rnw;
   reg [3:0] hw_sel;
   reg [31:0] spi_cmd;
   reg spi_cmd_v=0;
   always @(posedge clk) begin
      if (!en) begin
         iaddr <= 0;
         word <= 0;
         word_r <= 0;
         spi_cmd_v <= 0;
      end else if (!sleep_on_r) begin
         end_stream <= 0;
         if (!spi_cmd_v) begin // Don't fetch/decode if we have no storage left
            iaddr <= end_stream ? 0 : iaddr + 1;
            word <= (end_stream || word==4) ? 0 : word + 1;
            if (word_r == 0 && iaddr != 0)
               {rsvd, end_stream, hw_sel, rnw} <= idat;
            else begin
               spi_cmd <= {spi_cmd[23:0], idat};
               if (word_r == 4) begin
                  spi_cmd_v <= 1;
                  iaddr <= iaddr; // Hold
                  word <= word;
               end
            end
         end
      end

      if (spi_start) spi_cmd_v <= 0; // Send command
      word_r <= word;
   end

   assign spi_start = spi_cmd_v & ~spi_busy;
   assign spi_data_addr = spi_cmd;
   assign spi_rnw = rnw;
   assign spi_hw_sel = hw_sel;

   reg [DMEM_WI-1:0] save_addr=0;
   always @(posedge clk) begin
      if (!en || (!sleep_on && sleep_on_r))
         save_addr <= 0;
      else if (spi_rvalid)
         save_addr <= save_addr + 1;
   end

   dpram #(.aw(DMEM_WI), .dw(32)) i_dpram (
      .clka  (clk),
      .clkb  (clk),
      .addra (save_addr),
      .douta (), // Unused
      .dina  (spi_rdata),
      .wena  (spi_rvalid & en), // Don't save is disabled
      .addrb (rd_addr),
      .doutb (rd_data));

endmodule
