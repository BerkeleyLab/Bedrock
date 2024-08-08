/* AXI4LITE-host to localbus-peripheral adapter for a single clock domain
 * Latency-agnostic bus protocol to fixed-latency bus protocol adapter
 * This module ignores WSTRB (assumes all bytes are valid on every transaction).
 */

module axi_lb #(
  parameter C_S_AXI_DATA_WIDTH = 32,
  parameter C_S_AXI_ADDR_WIDTH = 16,
  parameter LB_AW = 16,
  parameter LB_DW = 32,
  parameter LB_RDELAY = 2,
  // lb_addr = axi_addr >> SHIFT
  // Use SHIFT to convert from i.e. word-addressable memory to
  // byte-addressable memory (SHIFT = 2)
  parameter SHIFT = 0,
  // In an SoC, sometimes your AXI bus controller is on one side of the
  // chip and needs to talk to something way on the other side.  Increasing
  // 'AXI_PIPELINE' will add pipeline registers to the AXI side while
  // increasing 'LB_PIPELINE' will add pipeline registers to the LB side
  // to ease routing timing constraints.  Setting either to 0 makes it a
  // transparent bypass.
  parameter AXI_PIPELINE = 0,
  parameter LB_PIPELINE = 0
)(
  // From AXI4LITE controller
   input  s_axi_aclk
  ,input  s_axi_aresetn
  ,input  [C_S_AXI_ADDR_WIDTH-1 : 0] s_axi_awaddr // write address
  ,input  [2 : 0] s_axi_awprot // protection (unused)
  ,input  s_axi_awvalid // asserts that s_axi_awaddr and s_axi_awprot are valid
  ,output s_axi_awready // ready response to s_axi_awvalid
  ,input  [C_S_AXI_DATA_WIDTH-1 : 0] s_axi_wdata // write data
  ,input  [(C_S_AXI_DATA_WIDTH/8)-1 : 0] s_axi_wstrb // write strobe (1 for each byte)
  ,input  s_axi_wvalid  // asserts that s_axi_wdata and s_axi_wstrb are valid
  ,output s_axi_wready  // ready response to s_axi_wvalid
  ,output [1 : 0] s_axi_bresp // write response (always 'OK' 2'b00)
  ,output s_axi_bvalid  // asserts s_axi_bresp is valid
  ,input  s_axi_bready  // controller is ready for a write response
  ,input  [C_S_AXI_ADDR_WIDTH-1 : 0] s_axi_araddr // read address
  ,input  [2 : 0] s_axi_arprot // protection (unused)
  ,input  s_axi_arvalid // asserts that s_axi_araddr and s_axi_arprot are valid
  ,output s_axi_arready // ready response to s_axi_arvalid
  ,output [C_S_AXI_DATA_WIDTH-1 : 0] s_axi_rdata // read data
  ,output [1 : 0] s_axi_rresp // read response (always 'OK' 2'b00)
  ,output s_axi_rvalid  // asserts thats_axi_rdata and s_axi_rresp are valid
  ,input  s_axi_rready  // controller is ready for read data
  // To localbus peripheral
  ,output [LB_AW-1:0] lb_addr
  ,output [LB_DW-1:0] lb_wdata
  ,input  [LB_DW-1:0] lb_rdata
  ,output lb_wen
);

wire axi_clk = s_axi_aclk;

// AXI4LITE signals from delay to device
wire m_axi_aresetn;
wire [C_S_AXI_ADDR_WIDTH-1:0] m_axi_awaddr;
wire [2:0] m_axi_awprot;
wire m_axi_awvalid;
wire m_axi_awready;
wire [C_S_AXI_DATA_WIDTH-1:0] m_axi_wdata;
wire [3:0] m_axi_wstrb;
wire m_axi_wvalid;
wire m_axi_wready;
wire [1:0] m_axi_bresp;
wire m_axi_bvalid;
wire m_axi_bready;
wire [C_S_AXI_ADDR_WIDTH-1:0] m_axi_araddr;
wire [2:0] m_axi_arprot;
wire m_axi_arvalid;
wire m_axi_arready;
wire [C_S_AXI_DATA_WIDTH-1:0] m_axi_rdata;
wire [1:0] m_axi_rresp;
wire m_axi_rvalid;
wire m_axi_rready;

axi_delay #(
  .NSTAGES(AXI_PIPELINE),
  .C_AXI_DATA_WIDTH(C_S_AXI_DATA_WIDTH),
  .C_AXI_ADDR_WIDTH(C_S_AXI_ADDR_WIDTH)
) axi_delay_i (
  // AXI4LITE Ports from Host
  .s_axi_aclk(axi_clk), // input
  .s_axi_aresetn(s_axi_aresetn), // input
  .s_axi_awaddr(s_axi_awaddr), // input [C_AXI_ADDR_WIDTH-1 : 0]
  .s_axi_awprot(s_axi_awprot), // input [2 : 0]
  .s_axi_awvalid(s_axi_awvalid), // input
  .s_axi_awready(s_axi_awready), // output
  .s_axi_wdata(s_axi_wdata), // input [C_AXI_DATA_WIDTH-1 : 0]
  .s_axi_wstrb(s_axi_wstrb), // input [(C_AXI_DATA_WIDTH/8)-1 : 0]
  .s_axi_wvalid(s_axi_wvalid), // input
  .s_axi_wready(s_axi_wready), // output
  .s_axi_bresp(s_axi_bresp), // output [1 : 0]
  .s_axi_bvalid(s_axi_bvalid), // output
  .s_axi_bready(s_axi_bready), // input
  .s_axi_araddr(s_axi_araddr), // input [C_AXI_ADDR_WIDTH-1 : 0]
  .s_axi_arprot(s_axi_arprot), // input [2 : 0]
  .s_axi_arvalid(s_axi_arvalid), // input
  .s_axi_arready(s_axi_arready), // output
  .s_axi_rdata(s_axi_rdata), // output [C_AXI_DATA_WIDTH-1 : 0]
  .s_axi_rresp(s_axi_rresp), // output [1 : 0]
  .s_axi_rvalid(s_axi_rvalid), // output
  .s_axi_rready(s_axi_rready), // input
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

reg  h_lb_wen=1'b0;
reg  [LB_AW-1:0] h_lb_addr=0;
reg  [LB_DW-1:0] h_lb_wdata=0;
wire [LB_DW-1:0] h_lb_rdata;
wire h_lb_readstart, p_lb_readstart;

lb_delay #(
  .LB_AW(LB_AW),
  .LB_DW(LB_DW),
  .NSTAGES(LB_PIPELINE)
) lb_delay_i (
  .clk(axi_clk), // input
  .h_lb_wen(h_lb_wen), // input
  .h_lb_addr(h_lb_addr), // input [LB_AW-1:0]
  .h_lb_wdata(h_lb_wdata), // input [LB_DW-1:0]
  .h_lb_rdata(h_lb_rdata), // output [LB_DW-1:0]
  .h_lb_wstb(h_lb_readstart), // input
  .h_lb_rstb(1'b0), // input
  .p_lb_wen(lb_wen), // output
  .p_lb_addr(lb_addr), // output [LB_AW-1:0]
  .p_lb_wdata(lb_wdata), // output [LB_DW-1:0]
  .p_lb_rdata(lb_rdata), // input [LB_DW-1:0]
  .p_lb_wstb(p_lb_readstart), // output
  .p_lb_rstb() // output
);

// ====================== AXI4LITE signals ==============================
reg [C_S_AXI_ADDR_WIDTH-1:0] axi_awaddr=0, axi_araddr=0;
reg [C_S_AXI_DATA_WIDTH-1:0] axi_wdata=0;
reg axi_awready=1'b0, axi_wready=1'b0, axi_bvalid=1'b0, axi_arready=1'b0, axi_rvalid=1'b0;
reg [1:0] axi_bresp=0, axi_rresp=0;
reg wdata_latched=1'b0;
reg awaddr_latched=1'b0;
wire write_trigger = ~axi_bvalid & ((axi_wready & m_axi_wvalid) | wdata_latched) & ((axi_awready & m_axi_awvalid) | awaddr_latched);
wire [C_S_AXI_DATA_WIDTH-1:0]     reg_awaddr = awaddr_latched ? axi_awaddr : m_axi_awaddr;
wire [C_S_AXI_DATA_WIDTH-1:0]     reg_wdata  = wdata_latched  ? axi_wdata  : m_axi_wdata;
wire read_trigger = ~axi_rvalid & axi_arready & m_axi_arvalid;

// Mux "waddr" and "raddr" into just "addr"
wire [C_S_AXI_ADDR_WIDTH-1:0] axi_addr = write_trigger ? reg_awaddr : m_axi_araddr;
// Shift by "SHIFT" (e.g. to translate from word-addressable to byte-addressable memory)
wire [C_S_AXI_ADDR_WIDTH-1:0] axi_addr_shift = axi_addr >> SHIFT;

assign h_lb_readstart = read_trigger;
always @(posedge axi_clk) begin
  h_lb_wen <= write_trigger;
  if (read_trigger | write_trigger) begin
    h_lb_addr <= axi_addr_shift[LB_AW-1:0];
    h_lb_wdata <= reg_wdata[LB_DW-1:0];
  end
  if (write_trigger) begin
    awaddr_latched <= 1'b0;
    wdata_latched <= 1'b0;
  end
end

localparam LB_RDSELECT = LB_PIPELINE + LB_RDELAY;
localparam RDPIPE_LEN = LB_RDSELECT+1;
reg [RDPIPE_LEN-1:0] rd_pipe=0;
reg [LB_DW-1:0] lb_rdata_r=0;
reg axi_rdata_ren=1'b0;
always @(posedge axi_clk) begin
  axi_rdata_ren <= 1'b0;
  rd_pipe <= {rd_pipe[RDPIPE_LEN-2:0], p_lb_readstart};
  if (rd_pipe[LB_RDSELECT]) begin
    axi_rdata_ren <= 1'b1;
    lb_rdata_r <= h_lb_rdata;
  end
end
assign m_axi_rdata = {{C_S_AXI_DATA_WIDTH-LB_DW{1'b0}}, lb_rdata_r};

// ============== AXI-4 Lite Bus Protocol Implementation ================
// I/O Connections assignments
assign m_axi_awready  = axi_awready;
assign m_axi_wready  = axi_wready;
assign m_axi_bresp  = axi_bresp;
assign m_axi_bvalid  = axi_bvalid;
assign m_axi_arready  = axi_arready;
assign m_axi_rresp  = axi_rresp;
assign m_axi_rvalid  = axi_rvalid;

always @(posedge axi_clk) begin
  if (s_axi_aresetn == 1'b0) begin
    // Must be driven low
    axi_awready <= 1'b0;
    axi_wready  <= 1'b0;
    axi_arready <= 1'b0;
    axi_bvalid  <= 1'b0;
    axi_rvalid  <= 1'b0;
    // Can have any value in reset
    axi_awaddr  <= 0;
    axi_bresp   <= 2'b0;
    axi_araddr  <= 0;
    axi_rresp   <= 0;
    axi_wdata   <= 0;
    // State signals
    wdata_latched <= 1'b0;
    awaddr_latched <= 1'b0;
  end else begin

    // ===================== Write Address Channel: AWVALID AWREADY AWADDR AWPROT =================
    // AWREADY: indicates we can accept a write address
    //          This scheme makes AWREADY wait for the entire transaction to complete
    //          before pulsing low synchronous with the write response BVALID.
    if (~axi_awready) begin
      axi_awready <= 1'b1;
    end else if (axi_bvalid && m_axi_bready) begin
      axi_awready <= 1'b0;
    end else begin
      axi_awready <= axi_awready;
    end
    // AWADDR:  the write address from the host
    //          Must be latched when AWVALID && AWREADY or when AWVALID and AWREADY is being asserted
    if (axi_awready && m_axi_awvalid) begin
      axi_awaddr <= m_axi_awaddr;
      awaddr_latched <= 1'b1;
    end
    // AWPROT:  Safely ignoring this protection signaling information.

    // ====================== Write Data Channel: WVALID WREADY WDATA WSTRB =======================
    // WREADY:  Indicates we can accept write data
    //          This scheme makes WREADY wait for the entire transaction to complete
    //          before pulsing low synchronous with the write response BVALID.
    if (~axi_wready) begin
      axi_wready <= 1'b1;
    end else if (axi_bvalid && m_axi_bready) begin
      axi_wready <= 1'b0;
    end else begin
      axi_wready <= axi_wready;
    end
    // WDATA:   the write data from the host
    // WSTRB:   indicates which byte lanes hold valid data
    if (axi_wready && m_axi_wvalid) begin
      axi_wdata <= m_axi_wdata;
      wdata_latched <= 1'b1;
    end

    // ======================= Write Response Channel: BVALID BREADY BRESP ========================
    // BVALID:  indicates write response information is valid.
    //          Must wait for AWVALID, AWREADY, WVALID, and WREADY to assert
    // BRESP:   This module always responds "OKAY"
    if (write_trigger) begin
      axi_bvalid <= 1'b1;
      axi_bresp  <= 2'b0; // 'OKAY' response
    end else if (m_axi_bready && axi_bvalid) begin
      axi_bvalid <= 1'b0;
    end else begin
      axi_bvalid <= axi_bvalid;
    end

    // ==================== Read Address Channel: ARVALID ARREADY ARADDR ARPROT ===================
    // ARREADY: indicates we are ready to accept read address information
    //          This scheme makes ARREADY wait for the entire transaction to complete
    //          before pulsing low synchronous with the read response RVALID.
    if (~axi_arready) begin
      axi_arready <= 1'b1;
    end else if (axi_rvalid && m_axi_rready) begin
      axi_arready <= 1'b0;
    end else begin
      axi_arready <= axi_arready;
    end
    // ARADDR:  the read address from the host
    //          Must be latched when ARVALID && ARREADY or when ARVALID and ARREADY is being asserted
    if (axi_arready && m_axi_arvalid) begin
      axi_araddr  <= m_axi_araddr;
    end

    // ======================= Read Data Channel: RVALID RREADY RDATA RRESP =======================
    // RVALID:  indicates read response information is valid
    //          Assert only after both ARVALID and ARREADY are asserted and RDATA and RRESP are valid
    //          Must only assert RVALID in response to a request for data
    if (~axi_rvalid && axi_rdata_ren) begin
      // RDATA is latched onto the bus at this point too
      axi_rvalid <= 1'b1;
      axi_rresp  <= 2'b0; // 'OKAY' response
    end else if (axi_rvalid && m_axi_rready) begin
      axi_rvalid <= 1'b0;
    end

  end
end


endmodule
