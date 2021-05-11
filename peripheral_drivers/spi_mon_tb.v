`timescale 1ns / 1ns

module spi_mon_tb;

   localparam SIM_TIME = 50000; // ns

   reg clk=0;

   initial begin
      if($test$plusargs("vcd")) begin
         $dumpfile("spi_mon.vcd");
         $dumpvars(5, spi_mon_tb);
      end

      while ($time<SIM_TIME) @(posedge clk);
      $finish;
   end

   always #5 clk=~clk;

   localparam AW = 24;
   localparam DW = 8;
   localparam CMD_LEN = 5;
   localparam RD_LEN = 3;
   localparam RD_WI = $clog2(RD_LEN);
   localparam SEQ_INIT = {24'hA, 8'hF, 1'b1,
                          24'hB, 8'h0, 1'b0,
                          24'hFF, 8'h0, 1'b1,
                          24'h2, 8'h0, 1'b0,
                          24'hAA, 8'h0, 1'b1};

   wire             en=1;
   wire             req;
   wire             grant;
   wire             spi_start;
   wire             spi_busy;
   wire [AW-1:0]    spi_addr;
   wire [DW-1:0]    spi_data;
   wire             spi_rnw;
   wire             spi_rvalid;
   wire [DW-1:0]    spi_rdata;
   reg [RD_WI-1:0]  rd_addr=0;
   wire [DW-1:0]    rd_data;

   wire cs, sck;
   reg sdo=0;
   wire sdi;

   wire [1:0] req_bus;

   // Silly toggling to get non-zero stimulus
   always @(posedge cs) sdo <= ~sdo;

   // Continuously read-out spi_mon dpram
   always @(posedge clk) rd_addr <= rd_addr + 1;

   // Simulate another requester
   wire req2 = (req_cnt != 0);
   wire grant2;
   integer req_cnt=0;
   always @(posedge clk) begin
      if (req2 && grant2)
         req_cnt <= req_cnt - 1;
      else
         req_cnt <= 300;
   end

   spi_mon_arb #(.NREQ(2)) i_spi_mon_arb (
      .clk       (clk),
      .req_bus   ({req2, req}),
      .grant_bus ({grant2, grant})
   );

   spi_mon #(
      .AW       (AW),
      .DW       (DW),
      .CMD_LEN  (CMD_LEN),
      .RD_LEN   (RD_LEN),
      .SEQ_INIT (SEQ_INIT))
   i_dut (
      .clk        (clk),
      .en         (en),
      .req        (req),
      .grant      (grant),
      .spi_start  (spi_start),
      .spi_busy   (spi_busy),
      .spi_addr   (spi_addr),
      .spi_data   (spi_data),
      .spi_rnw    (spi_rnw),
      .spi_rvalid (spi_rvalid),
      .spi_rdata  (spi_rdata),
      .rd_addr    (rd_addr),
      .rd_data    (rd_data));

   spi_master #(
      .TSCKHALF(1),
      .ADDR_WIDTH(AW),
      .DATA_WIDTH(DW))
   i_spi_master (
      .clk       (clk),
      .spi_start (spi_start),
      .spi_busy  (spi_busy),
      .spi_read  (spi_rnw),
      .spi_addr  (spi_addr),
      .spi_data  (spi_data),
      .cs        (cs),
      .sck       (sck),
      .sdo       (sdo),
      .sdi       (sdi),
      .sdo_addr  (),
      .spi_ready (spi_rvalid),
      .spi_rdbk  (spi_rdata));


endmodule
