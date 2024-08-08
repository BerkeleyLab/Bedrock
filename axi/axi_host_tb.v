`timescale 1ns/1ns

module axi_host_tb;

localparam DELAY_PIPELINE_NSTAGES = 3;
localparam AXI_ACLK_HALFPERIOD = 5;
localparam STEP = 2*AXI_ACLK_HALFPERIOD;
reg axi_aclk=1'b1;
always #AXI_ACLK_HALFPERIOD axi_aclk <= ~axi_aclk;

// VCD dump file for gtkwave
initial begin
  if ($test$plusargs("vcd")) begin
    $dumpfile("axi_host.vcd");
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

`define wait_timeout(sig) timeout_r = TOSET; #STEP wait ((to) || sig)

localparam C_M_AXI_ADDR_WIDTH = 16;
localparam C_M_AXI_DATA_WIDTH = 32;
localparam DEFAULT_XACT_TIMING = 17;
localparam RESPONSE_TIMEOUT = 255;

// AXI4LITE signals from Host to delay
reg axi_aresetn=1'b1;
wire [C_M_AXI_ADDR_WIDTH-1:0] axi_awaddr;
wire [2:0] axi_awprot;
wire axi_awvalid;
wire axi_awready;
wire [C_M_AXI_DATA_WIDTH-1:0] axi_wdata;
wire [3:0] axi_wstrb;
wire axi_wvalid;
wire axi_wready;
wire [1:0] axi_bresp;
wire axi_bvalid;
wire axi_bready;
wire [C_M_AXI_ADDR_WIDTH-1:0] axi_araddr;
wire [2:0] axi_arprot;
wire axi_arvalid;
wire axi_arready;
wire [C_M_AXI_DATA_WIDTH-1:0] axi_rdata;
wire [1:0] axi_rresp;
wire axi_rvalid;
wire axi_rready;
// AXI4LITE signals from delay to device
wire m_axi_aresetn;
wire [C_M_AXI_ADDR_WIDTH-1:0] m_axi_awaddr;
wire [2:0] m_axi_awprot;
wire m_axi_awvalid;
wire m_axi_awready;
wire [C_M_AXI_DATA_WIDTH-1:0] m_axi_wdata;
wire [3:0] m_axi_wstrb;
wire m_axi_wvalid;
wire m_axi_wready;
wire [1:0] m_axi_bresp;
wire m_axi_bvalid;
wire m_axi_bready;
wire [C_M_AXI_ADDR_WIDTH-1:0] m_axi_araddr;
wire [2:0] m_axi_arprot;
wire m_axi_arvalid;
wire m_axi_arready;
wire [C_M_AXI_DATA_WIDTH-1:0] m_axi_rdata;
wire [1:0] m_axi_rresp;
wire m_axi_rvalid;
wire m_axi_rready;

// Host control signals
reg wnr=1'b0;
reg [C_M_AXI_ADDR_WIDTH-1:0] addr=0;
reg [C_M_AXI_DATA_WIDTH-1:0] wdata=0;
wire [C_M_AXI_DATA_WIDTH-1:0] rdata;
reg start=1'b0;
wire busy;
wire rvalid;
wire timeout;

axi_host #(
  .C_M_AXI_ADDR_WIDTH(C_M_AXI_ADDR_WIDTH),
  .C_M_AXI_DATA_WIDTH(C_M_AXI_DATA_WIDTH),
  .DEFAULT_XACT_TIMING(DEFAULT_XACT_TIMING),
  .RESPONSE_TIMEOUT(RESPONSE_TIMEOUT)
) axi_host_i (
  .m_axi_aclk(axi_aclk), // input
  .m_axi_aresetn(axi_aresetn), // output
  .m_axi_awaddr(axi_awaddr), // output [C_M_AXI_ADDR_WIDTH-1:0]
  .m_axi_awprot(axi_awprot), // output [2:0]
  .m_axi_awvalid(axi_awvalid), // output
  .m_axi_awready(axi_awready), // input
  .m_axi_wdata(axi_wdata), // output [C_M_AXI_DATA_WIDTH-1:0]
  .m_axi_wstrb(axi_wstrb), // output [3:0]
  .m_axi_wvalid(axi_wvalid), // output
  .m_axi_wready(axi_wready), // input
  .m_axi_bresp(axi_bresp), // input [1:0]
  .m_axi_bvalid(axi_bvalid), // input
  .m_axi_bready(axi_bready), // output
  .m_axi_araddr(axi_araddr), // output [C_M_AXI_ADDR_WIDTH-1:0]
  .m_axi_arprot(axi_arprot), // output [2:0]
  .m_axi_arvalid(axi_arvalid), // output
  .m_axi_arready(axi_arready), // input
  .m_axi_rdata(axi_rdata), // input [C_M_AXI_DATA_WIDTH-1:0]
  .m_axi_rresp(axi_rresp), // input [1:0]
  .m_axi_rvalid(axi_rvalid), // input
  .m_axi_rready(axi_rready), // output
  .wnr(wnr), // input
  .addr(addr), // input [C_M_AXI_ADDR_WIDTH-1:0]
  .wdata(wdata), // input [C_M_AXI_DATA_WIDTH-1:0]
  .rdata(rdata), // output [C_M_AXI_DATA_WIDTH-1:0]
  .start(start), // input
  .busy(busy), // output
  .rvalid(rvalid), // output
  .timeout(timeout) // output
);

axi_delay #(
  .NSTAGES(DELAY_PIPELINE_NSTAGES),
  .C_AXI_DATA_WIDTH(C_M_AXI_DATA_WIDTH),
  .C_AXI_ADDR_WIDTH(C_M_AXI_ADDR_WIDTH)
) axi_delay_i (
  // AXI4LITE Ports from Host
  .s_axi_aclk(axi_aclk), // input
  .s_axi_aresetn(axi_aresetn), // input
  .s_axi_awaddr(axi_awaddr), // input [C_AXI_ADDR_WIDTH-1 : 0]
  .s_axi_awprot(axi_awprot), // input [2 : 0]
  .s_axi_awvalid(axi_awvalid), // input
  .s_axi_awready(axi_awready), // output
  .s_axi_wdata(axi_wdata), // input [C_AXI_DATA_WIDTH-1 : 0]
  .s_axi_wstrb(axi_wstrb), // input [(C_AXI_DATA_WIDTH/8)-1 : 0]
  .s_axi_wvalid(axi_wvalid), // input
  .s_axi_wready(axi_wready), // output
  .s_axi_bresp(axi_bresp), // output [1 : 0]
  .s_axi_bvalid(axi_bvalid), // output
  .s_axi_bready(axi_bready), // input
  .s_axi_araddr(axi_araddr), // input [C_AXI_ADDR_WIDTH-1 : 0]
  .s_axi_arprot(axi_arprot), // input [2 : 0]
  .s_axi_arvalid(axi_arvalid), // input
  .s_axi_arready(axi_arready), // output
  .s_axi_rdata(axi_rdata), // output [C_AXI_DATA_WIDTH-1 : 0]
  .s_axi_rresp(axi_rresp), // output [1 : 0]
  .s_axi_rvalid(axi_rvalid), // output
  .s_axi_rready(axi_rready), // input
  // AXI4LITE Ports to device
  .m_axi_aclk(), // output
  .m_axi_aresetn(m_axi_aresetn), // output
  .m_axi_awaddr(m_axi_awaddr), // output [C_AXI_ADDR_WIDTH-1 : 0]
  .m_axi_awprot(m_axi_awprot), // output [2 : 0]
  .m_axi_awvalid(m_axi_awvalid), // output
  .m_axi_awready(m_axi_awready), // input
  .m_axi_wdata(m_axi_wdata), // output [C_AXI_DATA_WIDTH-1 : 0]
  .m_axi_wstrb(m_axi_wstrb), // output [(C_AXI_DATA_WIDTH/8)-1 : 0]
  .m_axi_wvalid(m_axi_wvalid), // output
  .m_axi_wready(m_axi_wready), // input
  .m_axi_bresp(m_axi_bresp), // input [1 : 0]
  .m_axi_bvalid(m_axi_bvalid), // input
  .m_axi_bready(m_axi_bready), // output
  .m_axi_araddr(m_axi_araddr), // output [C_AXI_ADDR_WIDTH-1 : 0]
  .m_axi_arprot(m_axi_arprot), // output [2 : 0]
  .m_axi_arvalid(m_axi_arvalid), // output
  .m_axi_arready(m_axi_arready), // input
  .m_axi_rdata(m_axi_rdata), // input [C_AXI_DATA_WIDTH-1 : 0]
  .m_axi_rresp(m_axi_rresp), // input [1 : 0]
  .m_axi_rvalid(m_axi_rvalid), // input
  .m_axi_rready(m_axi_rready) // output
);

axi_dummy #(
  .C_S_AXI_DATA_WIDTH(C_M_AXI_DATA_WIDTH),
  .C_S_AXI_ADDR_WIDTH(C_M_AXI_ADDR_WIDTH)
) axi_dummy_i (
  .s_axi_aclk(axi_aclk), // input
  .s_axi_aresetn(m_axi_aresetn), // input
  .s_axi_awaddr(m_axi_awaddr), // input [C_M_AXI_ADDR_WIDTH:0]
  .s_axi_awprot(m_axi_awprot), // input [2:0]
  .s_axi_awvalid(m_axi_awvalid), // input
  .s_axi_awready(m_axi_awready), // output
  .s_axi_wdata(m_axi_wdata), // input [C_M_AXI_DATA_WIDTH:0]
  .s_axi_wstrb(m_axi_wstrb), // input [3:0]
  .s_axi_wvalid(m_axi_wvalid), // input
  .s_axi_wready(m_axi_wready), // output
  .s_axi_bresp(m_axi_bresp), // output [1:0]
  .s_axi_bvalid(m_axi_bvalid), // output
  .s_axi_bready(m_axi_bready), // input
  .s_axi_araddr(m_axi_araddr), // input [C_M_AXI_ADDR_WIDTH:0]
  .s_axi_arprot(m_axi_arprot), // input [2:0]
  .s_axi_arvalid(m_axi_arvalid), // input
  .s_axi_arready(m_axi_arready), // output
  .s_axi_rdata(m_axi_rdata), // output [C_M_AXI_DATA_WIDTH:0]
  .s_axi_rresp(m_axi_rresp), // output [1:0]
  .s_axi_rvalid(m_axi_rvalid), // output
  .s_axi_rready(m_axi_rready) // input
);

// =========== Stimulus =============
integer N;
wire [31:0] M = (N<<4); // clobber scheme
integer errors=0;
initial begin
  #STEP   $display("Reading all 64 registers");
  for (N=0; N<256; N=N+4) begin
    #STEP wnr = 1'b0;
          addr = N[C_M_AXI_ADDR_WIDTH-1:0];
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
          if (rdata != {{C_M_AXI_DATA_WIDTH-9{1'b0}}, 1'b1, N[7:0]}) begin
            $display("ERROR! Readback %x != %x", rdata[8:0], {1'b1, N[7:0]});
            errors = errors + 1;
          end
  end
  #STEP   $display("Writing all 64 registers");
  for (N=0; N<256; N=N+4) begin
    #STEP wnr = 1'b1;
          addr = N[C_M_AXI_ADDR_WIDTH-1:0];
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
  for (N=0; N<256; N=N+4) begin
    #STEP wnr = 1'b0;
          addr = N[C_M_AXI_ADDR_WIDTH-1:0];
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
            $display("ERROR! Readback %x != %x", rdata[11:0], M[11:0]);
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
