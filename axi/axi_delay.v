/* N stages of additional routing pipeline for an AXI4LITE interface
*/

module axi_delay #(
  parameter NSTAGES = 0,
  parameter C_AXI_DATA_WIDTH = 32,
  parameter C_AXI_ADDR_WIDTH = 21
) (
  // AXI4LITE Ports from Host
  input  s_axi_aclk,
  input  s_axi_aresetn,
  input  [C_AXI_ADDR_WIDTH-1 : 0] s_axi_awaddr,
  input  [2 : 0] s_axi_awprot,
  input  s_axi_awvalid,
  output s_axi_awready,
  input  [C_AXI_DATA_WIDTH-1 : 0] s_axi_wdata,
  input  [(C_AXI_DATA_WIDTH/8)-1 : 0] s_axi_wstrb,
  input  s_axi_wvalid,
  output s_axi_wready,
  output [1 : 0] s_axi_bresp,
  output s_axi_bvalid,
  input  s_axi_bready,
  input  [C_AXI_ADDR_WIDTH-1 : 0] s_axi_araddr,
  input  [2 : 0] s_axi_arprot,
  input  s_axi_arvalid,
  output s_axi_arready,
  output [C_AXI_DATA_WIDTH-1 : 0] s_axi_rdata,
  output [1 : 0] s_axi_rresp,
  output s_axi_rvalid,
  input  s_axi_rready,
  // AXI4LITE Ports to device
  output m_axi_aclk,
  output m_axi_aresetn,
  output [C_AXI_ADDR_WIDTH-1 : 0] m_axi_awaddr,
  output [2 : 0] m_axi_awprot,
  output m_axi_awvalid,
  input  m_axi_awready,
  output [C_AXI_DATA_WIDTH-1 : 0] m_axi_wdata,
  output [(C_AXI_DATA_WIDTH/8)-1 : 0] m_axi_wstrb,
  output m_axi_wvalid,
  input  m_axi_wready,
  input  [1 : 0] m_axi_bresp,
  input  m_axi_bvalid,
  output m_axi_bready,
  output [C_AXI_ADDR_WIDTH-1 : 0] m_axi_araddr,
  output [2 : 0] m_axi_arprot,
  output m_axi_arvalid,
  input  m_axi_arready,
  input  [C_AXI_DATA_WIDTH-1 : 0] m_axi_rdata,
  input  [1 : 0] m_axi_rresp,
  input  m_axi_rvalid,
  output m_axi_rready
);

assign m_axi_aclk = s_axi_aclk;

integer N;
generate
  if (NSTAGES == 0) begin : passthrough
    assign m_axi_aresetn = s_axi_aresetn;
    assign m_axi_awaddr  = s_axi_awaddr;
    assign m_axi_awprot  = s_axi_awprot;
    assign m_axi_awvalid = s_axi_awvalid;
    assign s_axi_awready = m_axi_awready;
    assign m_axi_wdata   = s_axi_wdata;
    assign m_axi_wstrb   = s_axi_wstrb;
    assign m_axi_wvalid  = s_axi_wvalid;
    assign s_axi_wready  = m_axi_wready;
    assign s_axi_bresp   = m_axi_bresp;
    assign s_axi_bvalid  = m_axi_bvalid;
    assign m_axi_bready  = s_axi_bready;
    assign m_axi_araddr  = s_axi_araddr;
    assign m_axi_arprot  = s_axi_arprot;
    assign m_axi_arvalid = s_axi_arvalid;
    assign s_axi_arready = m_axi_arready;
    assign s_axi_rdata   = m_axi_rdata;
    assign s_axi_rresp   = m_axi_rresp;
    assign s_axi_rvalid  = m_axi_rvalid;
    assign m_axi_rready  = s_axi_rready;
  end else begin :          pipeline
    (* KEEP="TRUE" *) reg [NSTAGES-1:0] axi_aresetn=0;
    assign m_axi_aresetn = axi_aresetn[NSTAGES-1];
    (* KEEP="TRUE" *) reg [C_AXI_ADDR_WIDTH-1:0] axi_awaddr [0:NSTAGES-1];
    assign m_axi_awaddr = axi_awaddr[NSTAGES-1];
    (* KEEP="TRUE" *) reg [2:0] axi_awprot [0:NSTAGES-1];
    assign m_axi_awprot = axi_awprot[NSTAGES-1];
    (* KEEP="TRUE" *) reg [NSTAGES-1:0] axi_awvalid=0;
    assign m_axi_awvalid = axi_awvalid[NSTAGES-1];
    (* KEEP="TRUE" *) reg [NSTAGES-1:0] axi_awready=0;
    assign s_axi_awready = axi_awready[NSTAGES-1]; // ptoh
    (* KEEP="TRUE" *) reg [C_AXI_DATA_WIDTH-1:0] axi_wdata [0:NSTAGES-1];
    assign m_axi_wdata = axi_wdata[NSTAGES-1];
    (* KEEP="TRUE" *) reg [(C_AXI_DATA_WIDTH/8)-1:0] axi_wstrb [0:NSTAGES-1];
    assign m_axi_wstrb = axi_wstrb[NSTAGES-1];
    (* KEEP="TRUE" *) reg [NSTAGES-1:0] axi_wvalid=0;
    assign m_axi_wvalid = axi_wvalid[NSTAGES-1];
    (* KEEP="TRUE" *) reg [NSTAGES-1:0] axi_wready=0;
    assign s_axi_wready = axi_wready[NSTAGES-1]; // ptoh
    (* KEEP="TRUE" *) reg [1:0] axi_bresp [0:NSTAGES-1];
    assign s_axi_bresp = axi_bresp[NSTAGES-1]; // ptoh
    (* KEEP="TRUE" *) reg [NSTAGES-1:0] axi_bvalid=0;
    assign s_axi_bvalid = axi_bvalid[NSTAGES-1]; // ptoh
    (* KEEP="TRUE" *) reg [NSTAGES-1:0] axi_bready=0;
    assign m_axi_bready = axi_bready[NSTAGES-1];
    (* KEEP="TRUE" *) reg [C_AXI_ADDR_WIDTH-1:0] axi_araddr [0:NSTAGES-1];
    assign m_axi_araddr = axi_araddr[NSTAGES-1];
    (* KEEP="TRUE" *) reg [2:0] axi_arprot [0:NSTAGES-1];
    assign m_axi_arprot = axi_arprot[NSTAGES-1];
    (* KEEP="TRUE" *) reg [NSTAGES-1:0] axi_arvalid=0;
    assign m_axi_arvalid = axi_arvalid[NSTAGES-1];
    (* KEEP="TRUE" *) reg [NSTAGES-1:0] axi_arready=0;
    assign s_axi_arready = axi_arready[NSTAGES-1]; // ptoh
    (* KEEP="TRUE" *) reg [C_AXI_DATA_WIDTH-1:0] axi_rdata [0:NSTAGES-1];
    assign s_axi_rdata = axi_rdata[NSTAGES-1]; // ptoh
    (* KEEP="TRUE" *) reg [1:0] axi_rresp [0:NSTAGES-1];
    assign s_axi_rresp = axi_rresp[NSTAGES-1]; // ptoh
    (* KEEP="TRUE" *) reg [NSTAGES-1:0] axi_rvalid=0;
    assign s_axi_rvalid = axi_rvalid[NSTAGES-1]; // ptoh
    (* KEEP="TRUE" *) reg [NSTAGES-1:0] axi_rready=0;
    assign m_axi_rready = axi_rready[NSTAGES-1];
    always @(posedge s_axi_aclk) begin
      axi_aresetn[0] <= s_axi_aresetn;
      axi_awaddr[0] <= s_axi_awaddr;
      axi_awprot[0] <= s_axi_awprot;
      axi_awvalid[0] <= s_axi_awvalid;
      axi_awready[0] <= m_axi_awready; // ptoh
      axi_wdata[0] <= s_axi_wdata;
      axi_wstrb[0] <= s_axi_wstrb;
      axi_wvalid[0] <= s_axi_wvalid;
      axi_wready[0] <= m_axi_wready; // ptoh
      axi_bresp[0] <= m_axi_bresp; // ptoh
      axi_bvalid[0] <= m_axi_bvalid; // ptoh
      axi_bready[0] <= s_axi_bready;
      axi_araddr[0] <= s_axi_araddr;
      axi_arprot[0] <= s_axi_arprot;
      axi_arvalid[0] <= s_axi_arvalid;
      axi_arready[0] <= m_axi_arready; // ptoh
      axi_rdata[0] <= m_axi_rdata; // ptoh
      axi_rresp[0] <= m_axi_rresp; // ptoh
      axi_rvalid[0] <= m_axi_rvalid; // ptoh
      axi_rready[0] <= s_axi_rready;
      for (N=1; N < NSTAGES; N = N + 1) begin
        axi_aresetn[N] <= axi_aresetn[N-1];
        axi_awaddr[N] <= axi_awaddr[N-1];
        axi_awprot[N] <= axi_awprot[N-1];
        axi_awvalid[N] <= axi_awvalid[N-1];
        axi_awready[N] <= axi_awready[N-1];
        axi_wdata[N] <= axi_wdata[N-1];
        axi_wstrb[N] <= axi_wstrb[N-1];
        axi_wvalid[N] <= axi_wvalid[N-1];
        axi_wready[N] <= axi_wready[N-1];
        axi_bresp[N] <= axi_bresp[N-1];
        axi_bvalid[N] <= axi_bvalid[N-1];
        axi_bready[N] <= axi_bready[N-1];
        axi_araddr[N] <= axi_araddr[N-1];
        axi_arprot[N] <= axi_arprot[N-1];
        axi_arvalid[N] <= axi_arvalid[N-1];
        axi_arready[N] <= axi_arready[N-1];
        axi_rdata[N] <= axi_rdata[N-1];
        axi_rresp[N] <= axi_rresp[N-1];
        axi_rvalid[N] <= axi_rvalid[N-1];
        axi_rready[N] <= axi_rready[N-1];
      end
    end
  end
endgenerate

endmodule
