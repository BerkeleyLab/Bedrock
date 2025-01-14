/* localbus clock-domain crossing via dual-clock FIFO */

module lb_cdc #(
  parameter AW = 24,
  parameter DW = 32,
  parameter FIFO_OUT_AW = 4,
  parameter FIFO_IN_AW = 4,
  // clock cycles between asserting addr and latching data
  parameter RDELAY = 3
) (
  // Interface A: peripheral
  input  lba_clk,
  input  [AW-1:0] lba_addr,
  input  [DW-1:0] lba_wdata,
  output [DW-1:0] lba_rdata,
  input  lba_wen,
  input  lba_ren,
  input  lba_wstb,
  input  lba_rstb,
  // lba_clk controls
  input  rdata_enable,
  output rdata_rnw,
  // Interface B: host
  input  lbb_clk,
  output [AW-1:0] lbb_addr,
  output [DW-1:0] lbb_wdata,
  input  [DW-1:0] lbb_rdata,
  output lbb_wen,
  output lbb_ren,
  output lbb_wstb,
  output lbb_rstb
);

localparam FIFO_A2B_DW = AW + DW + 4;

// ============================== lba_clk domain ==============================
wire a2b_we = lba_wstb | lba_rstb;
wire [FIFO_A2B_DW-1:0] a2b_din, a2b_dout;
assign a2b_din = {lba_rstb, lba_wstb, lba_ren, lba_wen, lba_addr, lba_wdata};

reg b2a_re=1'b0;
wire b2a_empty;
always @(posedge lba_clk) begin
  b2a_re <= 1'b0;
  if (!b2a_empty) begin
    if (~b2a_re & rdata_enable) begin
      b2a_re <= 1'b1;
    end
  end
end

// ============================== lbb_clk domain ==============================
wire a2b_empty;
reg a2b_re=1'b0;
wire [AW-1:0] lbb_addr_w;
wire [DW-1:0] lbb_wdata_w;

reg [RDELAY-1:0] tlatch_sr=0;//, wlatch_sr=0;
wire ren = |tlatch_sr;
wire tlatch = tlatch_sr[RDELAY-1];

always @(posedge lbb_clk) begin
  a2b_re <= 1'b0;
  if (!a2b_empty && !ren) begin
    if (~a2b_re) a2b_re <= 1'b1;
  end
  tlatch_sr <= {tlatch_sr[RDELAY-2:0], lbb_rstb | lbb_wstb};
end

fifo_2c #(
  .aw(FIFO_OUT_AW),
  .dw(FIFO_A2B_DW)
) fifo_a2b (
  .wr_clk(lba_clk), // input
  .we(a2b_we), // input
  .din(a2b_din), // input [dw-1:0]
  .wr_count(), // output [aw:0]
  .full(), // output
  .rd_clk(lbb_clk), // input
  .re(a2b_re), // input
  .dout(a2b_dout), // output [dw-1:0]
  .rd_count(), // output [aw:0]
  .empty(a2b_empty) // output
);

wire [DW:0] b2a_din, b2a_dout;
assign b2a_din = {lbb_ren_w, lbb_rdata};
assign {rdata_rnw, lba_rdata} = b2a_dout;
fifo_2c #(
  .aw(FIFO_IN_AW),
  .dw(DW+1)
) fifo_b2a (
  .wr_clk(lbb_clk), // input
  .we(tlatch), // input
  .din(b2a_din), // input [dw-1:0]
  .wr_count(), // output [aw:0]
  .full(), // output
  .rd_clk(lba_clk), // input
  .re(b2a_re), // input
  .dout(b2a_dout), // output [dw-1:0]
  .rd_count(), // output [aw:0]
  .empty(b2a_empty) // output
);

wire lbb_rstb_w, lbb_wstb_w, lbb_ren_w, lbb_wen_w;
assign {lbb_rstb_w, lbb_wstb_w, lbb_ren_w, lbb_wen_w, lbb_addr_w, lbb_wdata_w} = a2b_dout;
assign lbb_wen  = lbb_wen_w  & a2b_re;
assign lbb_ren  = lbb_ren_w  & ren;
assign lbb_wstb = lbb_wstb_w & a2b_re;
assign lbb_rstb = lbb_rstb_w & a2b_re;
reg [AW-1:0] lbb_addr_r=0;
reg [DW-1:0] lbb_wdata_r=0;
//assign lbb_addr = lbb_addr_w;
//assign lbb_wdata = lbb_wdata_w;
assign lbb_addr = lbb_addr_r;
assign lbb_wdata = lbb_wdata_r;

always @(posedge lbb_clk) begin
  lbb_addr_r <= lbb_addr_w;
  lbb_wdata_r <= lbb_wdata_w;
end

endmodule
