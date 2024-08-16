/* AXI4LITE bus controller supporting pipelined transactions, so a new
 * transaction can be initiated before the prior was completed as long
 * as the corresponding busy signal is deasserted.
 */

//`define CHATTER_AXI_HOST

module axi_host_pipelined #(
   parameter C_M_AXI_ADDR_WIDTH = 16
  ,parameter C_M_AXI_DATA_WIDTH = 32
  ,parameter [7:0] RESPONSE_TIMEOUT = 8'hff
) (
  // AXI4LITE controller interface
   input  m_axi_aclk
  ,input  m_axi_aresetn
  ,output [C_M_AXI_ADDR_WIDTH-1:0] m_axi_awaddr // write address
  ,output [2:0] m_axi_awprot // protection (unused)
  ,output m_axi_awvalid // asserts that m_axi_awaddr and m_axi_awprot are valid
  ,input  m_axi_awready // ready response to m_axi_awvalid
  ,output [C_M_AXI_DATA_WIDTH-1:0] m_axi_wdata // write data
  ,output [(C_M_AXI_DATA_WIDTH/8)-1:0] m_axi_wstrb // write strobe (1 for each byte)
  ,output m_axi_wvalid  // asserts that m_axi_wdata and m_axi_wstrb are valid
  ,input  m_axi_wready  // ready response to m_axi_wvalid
  ,input  [1:0] m_axi_bresp // write response (always 'OK' 2'b00)
  ,input  m_axi_bvalid  // asserts m_axi_bresp is valid
  ,output m_axi_bready  // controller is ready for a write response
  ,output [C_M_AXI_ADDR_WIDTH-1:0] m_axi_araddr // read address
  ,output [2:0] m_axi_arprot // protection (unused)
  ,output m_axi_arvalid // asserts that m_axi_araddr and m_axi_arprot are valid
  ,input  m_axi_arready // ready response to m_axi_arvalid
  ,input  [C_M_AXI_DATA_WIDTH-1:0] m_axi_rdata // read data
  ,input  [1:0] m_axi_rresp // read response (always 'OK' 2'b00)
  ,input  m_axi_rvalid  // asserts that m_axi_rdata and m_axi_rresp are valid
  ,output m_axi_rready  // controller is ready for read data
  // Bespoke host interface
  // read_stb is strobe starting a read transaction
  ,input  read_stb
  // write_stb is strobe starting a write transaction
  ,input  write_stb
  ,input  [C_M_AXI_ADDR_WIDTH-1:0] addr
  ,input  [C_M_AXI_DATA_WIDTH-1:0] wdata
  ,output [C_M_AXI_DATA_WIDTH-1:0] rdata
  // ~busy_r means we can accept another read transaction
  ,output busy_r
  // ~busy_w means we can accept another read transaction
  ,output busy_w
  // busy means a transaction is still in progress (awaiting a response)
  ,output busy
  // rvalid is strobe indicating when a read response is received
  ,output rvalid
  // timeout is strobe indicating transaction timed out
  ,output timeout
  // The 2-bit RRESP or BRESP value
  ,output reg [1:0] resp=2'b00
);

reg timeout_r=1'b0;
assign timeout=timeout_r;

reg rvalid_r=1'b0;
assign rvalid = rvalid_r;
reg [C_M_AXI_DATA_WIDTH-1:0] rdata_r=0;
assign rdata = rdata_r;
reg [C_M_AXI_ADDR_WIDTH-1:0] awaddr=0;
assign m_axi_awaddr = awaddr;
reg [2:0] awprot=0;
assign m_axi_awprot = awprot;
reg awvalid=1'b0;
assign m_axi_awvalid = awvalid;
reg [C_M_AXI_DATA_WIDTH-1:0] axi_wdata=0;
assign m_axi_wdata = axi_wdata;
localparam STROBE_WIDTH = C_M_AXI_DATA_WIDTH/8;
localparam [STROBE_WIDTH-1:0] STROBE_ALL = {STROBE_WIDTH{1'b1}};
localparam [STROBE_WIDTH-1:0] STROBE_NONE= {STROBE_WIDTH{1'b0}};
reg [STROBE_WIDTH-1:0] wstrb=0;
assign m_axi_wstrb = wstrb;
reg wvalid=1'b0;
assign m_axi_wvalid = wvalid;
reg bready=1'b0;
assign m_axi_bready = bready;
reg [C_M_AXI_ADDR_WIDTH-1:0] araddr=0;
assign m_axi_araddr = araddr;
reg [2:0] arprot=3'h0;
assign m_axi_arprot = arprot;
reg arvalid=1'b0;
assign m_axi_arvalid = arvalid;
reg rready=1'b0;
assign m_axi_rready = rready;

assign busy_r = arvalid;
assign busy_w = wvalid | awvalid;
reg awaiting_bresp=1'b0, awaiting_rdata=1'b0;
assign busy = awaiting_bresp | awaiting_rdata;
reg [7:0] response_counter=8'h00;

always @(posedge m_axi_aclk or negedge m_axi_aresetn) begin
  if (~m_axi_aresetn) begin
    // Bus signals; must be driven low in reset
    arvalid <= 1'b0;
    wvalid <= 1'b0;
    awvalid <= 1'b0;
    rvalid_r <= 1'b0;
    // These signals can have any value in reset
    resp <= 2'b00;
    bready <= 1'b0;
    rready <= 1'b0;
    // Status variables
    timeout_r <= 1'b0;
    awaiting_bresp <= 1'b0;
    awaiting_rdata <= 1'b0;
  end else begin
    timeout_r <= 1'b0;
    rvalid_r <= 1'b0;
    // ======================================= Handshakes =========================================
    // =================== Write Address Channel: AWVALID AWREADY AWADDR AWPROT ===================
    if (awvalid & m_axi_awready) begin
      awvalid <= 1'b0;
    end
    // ====================== Write Data Channel: WVALID WREADY WDATA WSTRB =======================
    if (wvalid & m_axi_wready) begin
      wvalid <= 1'b0;
      wstrb <= STROBE_NONE;
    end
    // ==================== Read Address Channel: ARVALID ARREADY ARADDR ARPROT ===================
    if (arvalid & m_axi_arready) arvalid <= 1'b0;
    if (awaiting_bresp | awaiting_rdata) begin
      if (response_counter == RESPONSE_TIMEOUT) begin
        timeout_r <= 1'b1;
        awaiting_bresp <= 1'b0;
        awaiting_rdata <= 1'b0;
        wvalid <= 1'b0;
        awvalid <= 1'b0;
        arvalid <= 1'b0;
        bready <= 1'b0;
        rready <= 1'b0;
      end else begin
        response_counter <= response_counter+1;
      end
    end
    if (awaiting_bresp) begin
      // ====================== Write Response Channel: BVALID BREADY BRESP =======================
      if (bready && m_axi_bvalid) begin
        resp <= m_axi_bresp;
        awaiting_bresp <= 1'b0;
      end
    //end else begin
    end
      // Look for a write start strobe
      if (write_stb) begin
        response_counter <= 0;
        // ================= Write Address Channel: AWVALID AWREADY AWADDR AWPROT =================
        // assert AWADDR, AWVALID, and AWPROT
        awaddr <= addr;
        awvalid <= 1'b1;
        awprot <= 3'h0; // Privileged
        // ==================== Write Data Channel: WVALID WREADY WDATA WSTRB =====================
        // assert WDATA, WVALID, and WSTRB
        axi_wdata <= wdata;
        wvalid <= 1'b1;
        wstrb <= STROBE_ALL;
        // ===================== Write Response Channel: BVALID BREADY BRESP ======================
        bready <= 1'b1;
        awaiting_bresp <= 1'b1;
      end
    //end
    // ====================== Read Data Channel: RVALID RREADY RDATA RRESP ======================
    if (rready && m_axi_rvalid) begin
      rdata_r <= m_axi_rdata;
      rvalid_r <= 1'b1;
      resp <= m_axi_rresp;
      awaiting_rdata <= 1'b0;
    end
    //end else begin
    //end
    // Look for a read start strobe
    if (~arvalid & read_stb) begin
      response_counter <= 0;
      // ================== Read Address Channel: ARVALID ARREADY ARADDR ARPROT =================
      // assert ARADDR, ARVALID, and ARPROT
      araddr <= addr;
      arvalid <= 1'b1;
      arprot <= 3'h0; // Privileged
      // ===================== Read Data Channel: RVALID RREADY RDATA RRESP =====================
      rready <= 1'b1;
      awaiting_rdata <= 1'b1;
    end
    //end
  end
end

`ifdef CHATTER_AXI_HOST
  always @(posedge m_axi_aclk) begin
    if (read_stb) begin
      $display("READ addr = 0x%x", addr);
    end
    if (write_stb) begin
      $display("WRITE addr = 0x%x; data = 0x%x", addr, wdata);
    end
  end
`endif

endmodule
