`timescale 1ns / 1ns

module spi_mon_tb;

   localparam SIM_TIME = 50000; // ns

   reg clk=0;
   integer fd, ix, rc;
   reg [7:0] mem[0:255];

   initial begin
      if($test$plusargs("vcd")) begin
         $dumpfile("spi_mon.vcd");
         $dumpvars(5, spi_mon_tb);
      end

      fd = $fopen("spi_mon.dat", "r");
      for (ix=0; ix<32; ix=ix+1) begin
         rc = $fscanf(fd, "%x\n", mem[ix]);
         if (rc != 1) begin
            $display("parse error, aborting");
            $stop();
         end
      end

      while ($time<SIM_TIME) @(posedge clk);
      $finish;
   end

   always #5 clk=~clk;

   localparam AW=8;
   localparam DW=24;

   wire             en=1;
   wire [3:0]       spi_hw_sel;
   wire             spi_start;
   wire             spi_busy;
   wire [AW-1:0]    spi_addr;
   wire [DW-1:0]    spi_data;
   wire             spi_rnw;
   wire             spi_rvalid;
   wire [DW-1:0]    spi_rdata;
   reg  [6:0]       rd_addr=0;
   wire [31:0]      rd_data;
   wire cs, sck;
   reg sdo=0;
   wire sdi;

   reg [7:0] mem_r;
   wire [7:0] addr;
   always @(posedge clk) mem_r <= mem[addr];

   // Silly toggling to get non-zero stimulus
   always @(posedge cs) sdo <= ~sdo;

   // Continuously read-out spi_mon dpram
   always @(posedge clk) rd_addr <= rd_addr + 1;

   spi_mon #(.SLEEP_SHIFT(4)) i_dut (
      .clk        (clk),
      .en         (en),
      .sleep      (8'd20),
      .imem_addr  (addr),
      .imem       (mem_r),
      .spi_hw_sel (spi_hw_sel),
      .spi_start  (spi_start),
      .spi_busy   (spi_busy),
      .spi_data_addr ({spi_data, spi_addr}),
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
