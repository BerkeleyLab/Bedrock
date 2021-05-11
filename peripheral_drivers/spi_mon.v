module spi_mon #(
   parameter AW=24,
   parameter DW=8,
   parameter CMD_LEN=3, // Must match length of SEQ_INIT
   parameter RD_LEN=4, // Saves up to RD_LEN data elements
   parameter SEQ_INIT=0
) (
   input          clk,
   input          en, // external; enable monitoring

   // Mechanism for arbitration across spi_mon instances
   output         req,
   input          grant,

   // To spi_master
   output          spi_start,
   input           spi_busy,
   output [AW-1:0] spi_addr,
   output [DW-1:0] spi_data,
   output          spi_rnw,
   input           spi_rvalid,
   input  [DW-1:0] spi_rdata,

   // Data readout
   input  [RD_WI-1:0] rd_addr,
   output [DW-1:0]    rd_data
);
   localparam CMD_WI = $clog2(CMD_LEN);
   localparam RD_WI = $clog2(RD_LEN);
   localparam SPI_LEN = AW+DW+1;

   reg done=0, start=0;
   reg [SPI_LEN-1:0] spi_cmd;

   reg [CMD_WI-1:0] cmd_idx=0;
   always @(posedge clk) begin
      start <= 0;
      done <= 0;
      if (req && grant && !spi_busy && !start) begin
         start   <= 1;
         spi_cmd <= SEQ_INIT[(CMD_LEN-1-cmd_idx)*SPI_LEN+:SPI_LEN];
         cmd_idx <= cmd_idx + 1;
         if (cmd_idx == CMD_LEN-1) begin
            start <= 0;
            done <= 1;
            cmd_idx <= 0;
         end
      end
   end

   assign req = en & ~done;
   assign spi_start = start;
   assign {spi_addr, spi_data, spi_rnw} = spi_cmd;

   reg [RD_WI-1:0] save_addr=0;
   always @(posedge clk) begin
      if (!en)
         save_addr <= 0;
      else if (spi_rvalid)
         save_addr <= (save_addr == RD_LEN-1) ? 0 : save_addr + 1;
   end

   dpram #(.aw(RD_WI), .dw(DW)) i_dpram (
      .clka  (clk),
      .clkb  (clk),
      .addra (save_addr),
      .douta (), // Unused
      .dina  (spi_rdata),
      .wena  (spi_rvalid),
      .addrb (rd_addr),
      .doutb (rd_data));

endmodule
