`timescale 1ns/1ns

module lb_test_host_tb;

localparam LBA_CLK_HALFPERIOD = 2; // fh = 250 MHz
localparam LBB_CLK_HALFPERIOD = 5; // fp = 100 MHz
localparam STEP = 2*LBA_CLK_HALFPERIOD;
reg lba_clk=1'b1;
always #LBA_CLK_HALFPERIOD lba_clk <= ~lba_clk;
reg lbb_clk=1'b1;
always #LBB_CLK_HALFPERIOD lbb_clk <= ~lbb_clk;

// VCD dump file for gtkwave
initial begin
  if ($test$plusargs("vcd")) begin
    $dumpfile("lb_test_host.vcd");
    $dumpvars();
  end
end

localparam TOW = 12;
localparam TOSET = {TOW{1'b1}};
reg [TOW-1:0] r_timeout=0;
always @(posedge lba_clk) begin
  if (r_timeout > 0) r_timeout <= r_timeout - 1;
end
wire to = ~(|r_timeout);
`define wait_timeout(sig) r_timeout = TOSET; #STEP wait ((to) || sig)

localparam AW = 24;
localparam DW = 32;
localparam RDELAY = 3;
localparam XACT_CYCLES = 8;
localparam MAX_XACTS = 183;

localparam FIFO_IN_AW = 7;
localparam FIFO_OUT_AW = 7;
localparam READ_ENABLE_DELAY = 994;

// Host interface
reg [AW-1:0] addr=0;
reg [DW-1:0] wdata=0;
wire [DW-1:0] rdata;
reg wnr=1'b0;
reg start_stb=1'b0;
wire busy, rvalid;
reg interpacket_reset=1'b1;

wire [AW-1:0] lbb_addr;
wire [DW-1:0] lbb_wdata;
wire [DW-1:0] lbb_rdata;
wire lbb_wen;
wire lbb_ren;
wire lbb_wstb;
wire lbb_rstb;

lb_test_host #(
  .AW(AW),
  .DW(DW),
  .FIFO_OUT_AW(FIFO_OUT_AW),
  .FIFO_IN_AW(FIFO_IN_AW),
  .MAX_XACTS(MAX_XACTS),
  .RDELAY(RDELAY),
  .READ_ENABLE_DELAY(READ_ENABLE_DELAY),
  .XACT_CYCLES(XACT_CYCLES)
) lb_test_host_i (
  .clk(lba_clk), // input
  .reset(interpacket_reset), // input
  .wnr(wnr), // input
  .addr(addr), // input [AW-1:0]
  .wdata(wdata), // input [DW-1:0]
  .rdata(rdata), // output [DW-1:0]
  .start_stb(start_stb), // input
  .busy(busy), // output
  .rvalid(rvalid), // output
  .lbb_clk(lbb_clk), // input
  .lbb_addr(lbb_addr), // output
  .lbb_wdata(lbb_wdata), // output
  .lbb_rdata(lbb_rdata), // input
  .lbb_wen(lbb_wen), // output
  .lbb_wstb(lbb_wstb), // output
  .lbb_ren(lbb_ren), // output
  .lbb_rstb(lbb_rstb) // output
);

lb_dummy #(
  .LB_AW(AW),
  .LB_DW(DW)
) lb_dummy_i (
  .lb_clk(lbb_clk), // input
  .reset(1'b0), // input
  .lb_addr(lbb_addr), // input [15:0]
  .lb_din(lbb_wdata), // input [31:0]
  .lb_dout(lbb_rdata), // output [31:0]
  .lb_wen(lbb_wen) // input
);

// ======= Readback Monitor =========
integer readN=0;
wire [11:0] readNw = {4'h1, readN[7:0]};
wire [11:0] readMw = {readN[7:0], 4'h0};
wire [11:0] compare = readback ? readMw : readNw;
wire [31:0] M = (N<<4); // clobber scheme
integer errors=0;
reg break=1'b0;
reg readback=1'b0; // Assert during readback phase
always @(posedge lba_clk) begin
  if (interpacket_reset) begin
    readN <= 0;
  end else begin
    if (rvalid) begin
      if (rdata != {{DW-12{1'b0}}, compare}) begin
        $display("ERROR! Readback %x != %x", rdata[11:0], compare);
        errors = errors + 1;
        break = 1'b1;
      end
      readN <= readN+1;
    end
  end
end

// =========== Stimulus =============
integer N;
real timestamp;
initial begin
  // Wait for fifo_2c to clear out its uninitialized registers
  #(10*STEP) $display("Reading %d registers", MAX_XACTS[7:0]);
          interpacket_reset = 1'b0;
  for (N=0; (N<MAX_XACTS) && ~break; N=N+1) begin
    #STEP wnr = 1'b0;
          addr = N[AW-1:0];
          start_stb = 1'b1;
    #STEP start_stb = 1'b0;
    #(6*STEP);
  end
  if (break) begin
    $display("FAIL");
    $stop(0);
  end
          `wait_timeout(~busy);
  if (to) $display("Timed out waiting for read transactions to complete");
          interpacket_reset = 1'b1;
  $display("Done reading");
  #(2*STEP) $display("Writing %d registers", MAX_XACTS[7:0]);
          interpacket_reset = 1'b0;
  for (N=0; (N<MAX_XACTS) && ~break; N=N+1) begin
    #STEP wnr = 1'b1;
          addr = N[AW-1:0];
          wdata = M;
          start_stb = 1'b1;
    #STEP start_stb = 1'b0;
    #(6*STEP);
  end
  if (break) begin
    $display("FAIL");
    $stop(0);
  end
          `wait_timeout(~busy);
  if (to) $display("Timed out waiting for write transactions to complete");
          interpacket_reset = 1'b1;
  $display("Done writing");
  #(2*STEP) $display("Reading %d registers again", MAX_XACTS[7:0]);
          readback = 1'b1;
          interpacket_reset = 1'b0;
  for (N=0; (N<MAX_XACTS) && ~break; N=N+1) begin
    #STEP wnr = 1'b0;
          addr = N[AW-1:0];
          start_stb = 1'b1;
    #STEP start_stb = 1'b0;
    #(6*STEP);
  end
  if (break) begin
    $display("FAIL");
    $stop(0);
  end
          `wait_timeout(~busy);
  if (to) $display("Timed out waiting for read transactions to complete");
  #(4*STEP) interpacket_reset = 1'b1;
  if (errors == 0) begin
    $display("PASS");
    $finish(0);
  end else begin
    $display("FAIL");
    $stop(0);
  end
end

endmodule
