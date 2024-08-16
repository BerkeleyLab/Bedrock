/* An AXI4Lite Interposer which crosses clock domains
 */

module axi_cdc #(
  parameter C_AXI_DATA_WIDTH = 32,
  parameter C_AXI_ADDR_WIDTH = 21,
  // If FIFO_AW == 0, stretches handshake signals across the clock boundary,
  // guaranteeing the transaction at the cost of additional cycles delay
  // Else, uses best effort (FIFO-based) transactions, which could
  // overflow.
  parameter FIFO_AW = 0
) (
  input  s_read_enable,
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
  // AXI4LITE Ports to Peripheral
  input  m_axi_aclk,
  input  m_axi_aresetn,
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

// ===================== Write Address Channel: AWVALID AWREADY AWADDR AWPROT =================
// htop
wire [C_AXI_ADDR_WIDTH+2: 0] s_aw_info, m_aw_info;
assign s_aw_info = {s_axi_awprot, s_axi_awaddr};
assign {m_axi_awprot, m_axi_awaddr} = m_aw_info;
axi_channel_xdomain #(
  .WIDTH(C_AXI_ADDR_WIDTH+3),
  .FIFO_AW(FIFO_AW)
) xdomain_awaddr (
  .clka(s_axi_aclk), // input
  .dataa(s_aw_info), // input [WIDTH-1:0]
  .valida(s_axi_awvalid), // input
  .readya(s_axi_awready), // output
  .clkb(m_axi_aclk), // input
  .datab(m_aw_info), // output [WIDTH-1:0]
  .validb(m_axi_awvalid), // output
  .readyb(m_axi_awready), // input
  .enb(1'b1) // input
);
// ==================== Read Address Channel: ARVALID ARREADY ARADDR ARPROT ===================
// htop
wire [C_AXI_ADDR_WIDTH+2: 0] s_ar_info, m_ar_info;
assign s_ar_info = {s_axi_arprot, s_axi_araddr};
assign {m_axi_arprot, m_axi_araddr} = m_ar_info;
wire s_axi_arready;
axi_channel_xdomain #(
  .WIDTH(C_AXI_ADDR_WIDTH+3),
  .FIFO_AW(FIFO_AW)
) xdomain_araddr (
  .clka(s_axi_aclk), // input
  .dataa(s_ar_info), // input [WIDTH-1:0]
  .valida(s_axi_arvalid), // input
  .readya(s_axi_arready), // output
  .clkb(m_axi_aclk), // input
  .datab(m_ar_info), // output [WIDTH-1:0]
  .validb(m_axi_arvalid), // output
  .readyb(m_axi_arready), // input
  .enb(1'b1) // input
);
// ====================== Write Data Channel: WVALID WREADY WDATA WSTRB =======================
// htop
wire [C_AXI_DATA_WIDTH+(C_AXI_DATA_WIDTH/8)-1: 0] s_w_info, m_w_info;
assign s_w_info = {s_axi_wstrb, s_axi_wdata};
assign {m_axi_wstrb, m_axi_wdata} = m_w_info;
axi_channel_xdomain #(
  .WIDTH(C_AXI_DATA_WIDTH+(C_AXI_DATA_WIDTH/8)),
  .FIFO_AW(FIFO_AW)
) xdomain_wdata (
  .clka(s_axi_aclk), // input
  .dataa(s_w_info), // input [WIDTH-1:0]
  .valida(s_axi_wvalid), // input
  .readya(s_axi_wready), // output
  .clkb(m_axi_aclk), // input
  .datab(m_w_info), // output [WIDTH-1:0]
  .validb(m_axi_wvalid), // output
  .readyb(m_axi_wready), // input
  .enb(1'b1) // input
);
// ======================= Write Response Channel: BVALID BREADY BRESP ========================
// ptoh
axi_channel_xdomain #(
  .WIDTH(2),
  .FIFO_AW(FIFO_AW)
) xdomain_bresp (
  .clka(m_axi_aclk), // input
  .dataa(m_axi_bresp), // input [WIDTH-1:0]
  .valida(m_axi_bvalid), // input
  .readya(m_axi_bready), // output
  .clkb(s_axi_aclk), // input
  .datab(s_axi_bresp), // output [WIDTH-1:0]
  .validb(s_axi_bvalid), // output
  .readyb(s_axi_bready), // input
  .enb(1'b1) // input
);

// ======================= Read Data Channel: RVALID RREADY RDATA RRESP =======================
// ptoh
wire [C_AXI_DATA_WIDTH+1: 0] s_r_info, m_r_info;
assign m_r_info = {m_axi_rresp, m_axi_rdata};
assign {s_axi_rresp, s_axi_rdata} = s_r_info;
axi_channel_xdomain #(
  .WIDTH(C_AXI_DATA_WIDTH+2),
  .FIFO_AW(FIFO_AW)
) xdomain_rdata (
  .clka(m_axi_aclk), // input
  .dataa(m_r_info), // input [WIDTH-1:0]
  .valida(m_axi_rvalid), // input
  .readya(m_axi_rready), // output
  .clkb(s_axi_aclk), // input
  .datab(s_r_info), // output [WIDTH-1:0]
  .validb(s_axi_rvalid), // output
  .readyb(s_axi_rready), // input
  .enb(s_read_enable) // input
);

endmodule
