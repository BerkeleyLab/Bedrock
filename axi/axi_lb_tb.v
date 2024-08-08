`timescale 1ns/1ns

module axi_lb_tb;

localparam AXI_PIPELINE_NSTAGES = 0;
localparam LB_PIPELINE_NSTAGES = 0;

// 100 MHz
localparam AXI_CLK_HALFPERIOD = 5;

reg axi_aclk=1'b0;
always #AXI_CLK_HALFPERIOD axi_aclk <= ~axi_aclk;
wire lb_clk=axi_aclk;

// VCD dump file for gtkwave
initial begin
  if ($test$plusargs("vcd")) begin
    $dumpfile("axi_lb.vcd");
    $dumpvars();
  end
end

localparam TOW = 12;
localparam TOSET = {TOW{1'b1}};
reg [TOW-1:0] timeout_r=0;
always @(posedge axi_aclk) begin
  if (timeout_r > 0) timeout_r <= timeout_r - 1;
end
wire to = ~(|timeout_r);

`define wait_timeout(sig) timeout_r = TOSET; #10 wait ((to) || sig)

localparam AXI_ADDR_WIDTH = 16;
localparam AXI_DATA_WIDTH = 32;
localparam LB_AW = 16;
localparam LB_DW = 32;
localparam LB_RDELAY = 2;

reg wnr=1'b0;
reg [AXI_ADDR_WIDTH-1:0] addr=0;
reg [AXI_DATA_WIDTH-1:0] wdata=0;
wire [AXI_DATA_WIDTH-1:0] rdata;
reg start=1'b0;
wire busy;
wire rvalid;
wire timeout;

wire axi_aresetn;
wire [AXI_ADDR_WIDTH-1:0] axi_awaddr;
wire [2:0] axi_awprot;
wire axi_awvalid;
wire axi_awready;
wire [AXI_DATA_WIDTH-1:0] axi_wdata;
wire [3:0] axi_wstrb;
wire axi_wvalid;
wire axi_wready;
wire [1:0] axi_bresp;
wire axi_bvalid;
wire axi_bready;
wire [AXI_ADDR_WIDTH-1:0] axi_araddr;
wire [2:0] axi_arprot;
wire axi_arvalid;
wire axi_arready;
wire [AXI_DATA_WIDTH-1:0] axi_rdata;
wire [1:0] axi_rresp;
wire axi_rvalid;
wire axi_rready;
wire [LB_AW-1:0] lb_addr;
wire [LB_DW-1:0] lb_data_htop;
wire [LB_DW-1:0] lb_data_ptoh;
wire lb_wen;

axi_host #(
  .C_M_AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
  .C_M_AXI_DATA_WIDTH(AXI_DATA_WIDTH)
) axi_host_i (
  .m_axi_aclk(axi_aclk), // input
  .m_axi_aresetn(axi_aresetn), // output
  .m_axi_awaddr(axi_awaddr), // output [AXI_ADDR_WIDTH-1:0]
  .m_axi_awprot(axi_awprot), // output [2:0]
  .m_axi_awvalid(axi_awvalid), // output
  .m_axi_awready(axi_awready), // input
  .m_axi_wdata(axi_wdata), // output [AXI_DATA_WIDTH-1:0]
  .m_axi_wstrb(axi_wstrb), // output [3:0]
  .m_axi_wvalid(axi_wvalid), // output
  .m_axi_wready(axi_wready), // input
  .m_axi_bresp(axi_bresp), // input [1:0]
  .m_axi_bvalid(axi_bvalid), // input
  .m_axi_bready(axi_bready), // output
  .m_axi_araddr(axi_araddr), // output [AXI_ADDR_WIDTH-1:0]
  .m_axi_arprot(axi_arprot), // output [2:0]
  .m_axi_arvalid(axi_arvalid), // output
  .m_axi_arready(axi_arready), // input
  .m_axi_rdata(axi_rdata), // input [AXI_DATA_WIDTH-1:0]
  .m_axi_rresp(axi_rresp), // input [1:0]
  .m_axi_rvalid(axi_rvalid), // input
  .m_axi_rready(axi_rready), // output
  .wnr(wnr), // input
  .addr(addr), // input [AXI_ADDR_WIDTH-1:0]
  .wdata(wdata), // input [AXI_DATA_WIDTH-1:0]
  .rdata(rdata), // output [AXI_DATA_WIDTH-1:0]
  .start(start), // input
  .busy(busy), // output
  .rvalid(rvalid), // output
  .timeout(timeout) // output
);

axi_lb #(
  .C_S_AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
  .C_S_AXI_DATA_WIDTH(AXI_DATA_WIDTH),
  .LB_AW(LB_AW),
  .LB_DW(LB_DW),
  .LB_RDELAY(LB_RDELAY),
  .SHIFT(0),
  .AXI_PIPELINE(AXI_PIPELINE_NSTAGES),
  .LB_PIPELINE(LB_PIPELINE_NSTAGES)
) axi_lb_i (
  .s_axi_aclk(axi_aclk), // input
  .s_axi_aresetn(axi_aresetn), // input
  .s_axi_awaddr(axi_awaddr), // input [AXI_ADDR_WIDTH-1:0]
  .s_axi_awprot(axi_awprot), // input [2:0]
  .s_axi_awvalid(axi_awvalid), // input
  .s_axi_awready(axi_awready), // output
  .s_axi_wdata(axi_wdata), // input [AXI_DATA_WIDTH-1:0]
  .s_axi_wstrb(axi_wstrb), // input [3:0]
  .s_axi_wvalid(axi_wvalid), // input
  .s_axi_wready(axi_wready), // output
  .s_axi_bresp(axi_bresp), // output [1:0]
  .s_axi_bvalid(axi_bvalid), // output
  .s_axi_bready(axi_bready), // input
  .s_axi_araddr(axi_araddr), // input [AXI_ADDR_WIDTH-1:0]
  .s_axi_arprot(axi_arprot), // input [2:0]
  .s_axi_arvalid(axi_arvalid), // input
  .s_axi_arready(axi_arready), // output
  .s_axi_rdata(axi_rdata), // output [AXI_DATA_WIDTH-1:0]
  .s_axi_rresp(axi_rresp), // output [1:0]
  .s_axi_rvalid(axi_rvalid), // output
  .s_axi_rready(axi_rready), // input
  .lb_addr(lb_addr), // output [LB_AW-1:0]
  .lb_wdata(lb_data_htop), // output [LB_DW-1:0]
  .lb_rdata(lb_data_ptoh), // input [LB_DW-1:0]
  .lb_wen(lb_wen) // output
);

lb_dummy #(
  .LB_AW(LB_AW),
  .LB_DW(LB_DW)
) lb_dummy_i (
  .lb_clk(lb_clk), // input
  .reset(1'b0), // input
  .lb_addr(lb_addr), // input [15:0]
  .lb_din(lb_data_htop), // input [31:0]
  .lb_dout(lb_data_ptoh), // output [31:0]
  .lb_wen(lb_wen) // input
);

// =========== Stimulus =============
localparam STEP = 2*AXI_CLK_HALFPERIOD;
integer N;
wire [31:0] M = (N<<4); // clobber scheme
integer errors=0;
initial begin
  #STEP   $display("Reading 64 registers");
  for (N=0; N<64; N=N+1) begin
    #STEP wnr = 1'b0;
          addr = N[AXI_ADDR_WIDTH-1:0];
          start = 1'b1;
    `wait_timeout(busy);
          start = 1'b0;
          if (to) begin
            $display("ERROR! Timeout waiting for busy on read %x", addr);
            $finish();
          end
    `wait_timeout(~busy);
          if (to) begin
            $display("ERROR! Timeout waiting for ~busy after read %x", addr);
            $finish();
          end
          if (rdata != {{AXI_DATA_WIDTH-9{1'b0}}, 1'b1, N[7:0]}) begin
            $display("ERROR! Readback on addr %x. %x != %x", addr, rdata[8:0], {1'b1, N[7:0]});
            errors = errors + 1;
          end
  end
  #STEP   $display("Writing 64 registers");
  for (N=0; N<64; N=N+1) begin
    #STEP wnr = 1'b1;
          addr = N[AXI_ADDR_WIDTH-1:0];
          wdata = M;
          start = 1'b1;
    `wait_timeout(busy);
          start = 1'b0;
          if (to) begin
            $display("ERROR! Timeout waiting for busy on write %x", addr);
            $finish();
          end
    `wait_timeout(~busy);
          if (to) begin
            $display("ERROR! Timeout waiting for ~busy after write %x", addr);
            $finish();
          end
          if (timeout) begin
            $display("ERROR! Timeout on write %x", addr);
            errors = errors + 1;
          end
  end
  #STEP   $display("Reading clobbered registers");
  for (N=0; N<64; N=N+1) begin
    #STEP wnr = 1'b0;
          addr = N[AXI_ADDR_WIDTH-1:0];
          start = 1'b1;
    `wait_timeout(busy);
          start = 1'b0;
          if (to) begin
            $display("ERROR! Timeout waiting for busy on read %x", addr);
            $finish();
          end
    `wait_timeout(~busy);
          if (to) begin
            $display("ERROR! Timeout waiting for ~busy after read %x", addr);
            $finish();
          end
          if (rdata[11:0] != M[11:0]) begin
            $display("ERROR! Readback on addr %x. %x != %x", addr, rdata[11:0], M[11:0]);
            errors = errors + 1;
          end
  end
  #STEP   if (errors == 0) begin
            $display("PASS");
            $finish(0);
          end else begin
            $display("FAIL: %d errors", errors);
            $stop(0);
          end

end

endmodule
