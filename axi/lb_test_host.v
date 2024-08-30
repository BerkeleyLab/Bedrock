// A localbus host made for testing the deterministic CDC scheme

module lb_test_host #(
  parameter AW = 12,
  parameter DW = 32,
  parameter XACT_CYCLES = 8,
  parameter FIFO_OUT_AW = 4,
  parameter FIFO_IN_AW = 4,
  // For a read, RDELAY determines when lb_rdata is latched
  // (i.e. read latency). lb_ren will be asserted from the cycle
  // lb_addr/lb_wen becomes valid until lb_rstb.
  parameter RDELAY = 3,
  // READ_ENABLE_DELAY is how many cycles to wait until we open the FIFO_IN flood gates
  parameter READ_ENABLE_DELAY = 100,
  parameter MAX_XACTS = 183
) (
  input  clk,
  input  reset,
  // Bespoke host interface
  input  wnr,
  input  [AW-1:0] addr,
  input  [DW-1:0] wdata,
  output [DW-1:0] rdata,
  input  start_stb,
  // busy means there are still transactions awaiting a response
  output busy,
  output rvalid,
  // Downstream lb interface
  input  lbb_clk,
  output [AW-1:0] lbb_addr,
  output [DW-1:0] lbb_wdata,
  input  [DW-1:0] lbb_rdata,
  // lb_wen is asserted for XACT_CYCLES
  output lbb_wen,
  // lb_wstb is a strobe at the start of the transaction
  output lbb_wstb,
  // lb_wen is asserted for XACT_CYCLES
  output lbb_ren,
  // lb_rstb is strobe indicating when a read value is latched
  output lbb_rstb
);

wire lba_clk = clk;
reg [AW-1:0] lba_addr=0;
reg [DW-1:0] lba_wdata=0;
wire [DW-1:0] lba_rdata;
assign rdata = lba_rdata;
reg lba_wen=1'b0;
reg lba_ren=1'b0;
reg lba_wstb=1'b0;
reg lba_rstb=1'b0;
reg rdata_enable=1'b0;
wire rdata_rnw;

localparam XACT_CW = $clog2(MAX_XACTS);
reg [XACT_CW-1:0] xact_counter=0;
localparam CYCLE_CW = $clog2(READ_ENABLE_DELAY);
reg [CYCLE_CW-1:0] cycle_counter=0;

reg response_strobe=1'b0;
assign rvalid = response_strobe & rdata_rnw;
//assign busy = xact_counter > 0;
reg busy_r=1'b0;
assign busy = busy_r;

always @(posedge clk) begin
  if (reset) begin
    busy_r <= 1'b0;
    xact_counter <= 0;
    cycle_counter <= 0;
    rdata_enable <= 1'b0;
    response_strobe <= 1'b0;
    lba_wen <= 1'b0;
    lba_wstb <= 1'b0;
    lba_ren <= 1'b0;
    lba_rstb <= 1'b0;
  end else begin
    busy_r <= xact_counter > 0;
    response_strobe <= 1'b0;
    lba_wstb <= 1'b0;
    lba_rstb <= 1'b0;
    if (rdata_enable) begin
      if (cycle_counter < XACT_CYCLES-1) begin
        cycle_counter <= cycle_counter + 1;
      end else begin
        cycle_counter <= 0;
      end
      if (cycle_counter == 0) begin
        response_strobe <= 1'b1;
      end
    end else begin // !rdata_enable
      if (xact_counter > 0) begin
        if (cycle_counter < READ_ENABLE_DELAY[CYCLE_CW-1:0]) begin
          cycle_counter <= cycle_counter + 1;
        end else begin
          rdata_enable <= 1'b1;
          cycle_counter <= 0;
        end
      end else begin // (xact_counter == 0)
        cycle_counter <= 0;
      end
    end
    if (start_stb) begin
      if (~response_strobe) begin
        xact_counter <= xact_counter + 1;
      end
      lba_addr <= addr;
      lba_wdata <= wdata;
      lba_wen <= wnr;
      lba_wstb <= wnr;
      lba_ren <= ~wnr;
      lba_rstb <= ~wnr;
    end else if (response_strobe) begin
      xact_counter <= xact_counter - 1;
      if (xact_counter == 1) begin
        rdata_enable <= 1'b0;
      end
    end
  end
end

lb_cdc #(
  .AW(AW),
  .DW(DW),
  .FIFO_OUT_AW(FIFO_OUT_AW),
  .FIFO_IN_AW(FIFO_IN_AW),
  .RDELAY(RDELAY)
) lb_cdc_i (
  .lba_clk(lba_clk), // input
  .lba_addr(lba_addr), // input [AW-1:0]
  .lba_wdata(lba_wdata), // input [DW-1:0]
  .lba_rdata(lba_rdata), // output [DW-1:0]
  .lba_wen(lba_wen), // input
  .lba_ren(lba_ren), // input
  .lba_wstb(lba_wstb), // input
  .lba_rstb(lba_rstb), // input
  .rdata_enable(response_strobe), // input
  .rdata_rnw(rdata_rnw), // output
  .lbb_clk(lbb_clk), // input
  .lbb_addr(lbb_addr), // output [AW-1:0]
  .lbb_wdata(lbb_wdata), // output [DW-1:0]
  .lbb_rdata(lbb_rdata), // input [DW-1:0]
  .lbb_wen(lbb_wen), // output
  .lbb_ren(lbb_ren), // output
  .lbb_wstb(lbb_wstb), // output
  .lbb_rstb(lbb_rstb) // output
);

endmodule
