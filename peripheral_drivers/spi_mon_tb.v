`timescale 1ns / 1ns

module spi_mon_tb;

   localparam SIM_TIME = 500000;  // ns

   reg clk=0;
   integer fd, ix, rc;

   reg en=0;
   reg [8:0] maddr=0;
   reg [7:0] mdat;
   reg mwe=0;

   initial begin
      if($test$plusargs("vcd")) begin
         $dumpfile("spi_mon.vcd");
         $dumpvars(5, spi_mon_tb);
      end

      fd = $fopen("spi_mon.dat", "r");
      for (ix=0; ix<512; ix=ix+1) begin
         @(posedge clk);
         #1;
         mwe = 1;
         maddr = ix;
         rc = $fscanf(fd, "%x\n", mdat);
         if (rc != 1) begin
            $display("FAIL: parse error, aborting");
            $stop(0);
         end
      end
      mwe = 0;
      en = 1;

      while ($time<SIM_TIME) @(posedge clk);
      $display("WARNING: Not a self-checking testbench. Will always pass.");
      $display("PASS");
      $finish(0);
   end

   always #5 clk=~clk;

   localparam AW=8;
   localparam DW=24;

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

   // Exercise enable functionality
   initial begin
      #(SIM_TIME/4);
      en = 0;
      #(1000)
      @(posedge clk);
      en = 1;
      #(SIM_TIME/4);
      en = 0;
      #(1000)
      @(posedge clk);
      en = 1;
   end

   // Silly toggling to get non-zero stimulus
   always @(posedge cs) sdo <= ~sdo;

   // Continuously read-out spi_mon dpram
   always @(posedge clk) rd_addr <= rd_addr + 1;

   // Hack to make simulations more understandable;
   // also note the width change from DW to 32.
   wire [31:0] spi_rdata_x = en ? spi_rdata : {DW{1'bx}};

   spi_mon #(
      .SLEEP_SHIFT(4),
      .IMEM_WI (9),
      .DMEM_WI (7))
   i_dut (
      .clk        (clk),
      .en         (en),
      .sleep      (8'd20),
      .wr_dwell   (8'd10),
      .imem_we    (mwe),
      .imem_waddr (maddr),
      .imem_wdat  (mdat),
      .spi_hw_sel (spi_hw_sel),
      .spi_start  (spi_start),
      .spi_busy   (spi_busy),
      .spi_data_addr ({spi_data, spi_addr}),
      .spi_rnw    (spi_rnw),
      .spi_rvalid (spi_rvalid),
      .spi_rdata  (spi_rdata_x),
      .rd_addr    (rd_addr),
      .rd_data    (rd_data));

   spi_master #(
      .TSCKHALF(4),
      .ADDR_WIDTH(AW),
      .DATA_WIDTH(DW),
      .SCK_RISING_SHIFT(0))
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
