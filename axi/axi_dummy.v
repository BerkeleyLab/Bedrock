/* A dummy AXI4LITE peripheral for testing the AXI4LITE host
 * Byte-addressable memory should be accessed aligned to word boundaries (addr[1:0] = 0)
 * 64 r/w registers spanning addresses 0x00-0xff
 * Registers are initialized with 0x100 | addr (i.e. 0x100-0x1ff)
 */

module axi_dummy #(
  // AXI4LITE Parameters
  parameter integer C_S_AXI_DATA_WIDTH  = 32,
  parameter integer C_S_AXI_ADDR_WIDTH  = 8
)(
  // AXI4LITE Ports
  input  s_axi_aclk,
  input  s_axi_aresetn,
  input  [C_S_AXI_ADDR_WIDTH-1 : 0] s_axi_awaddr,
  input  [2 : 0] s_axi_awprot,
  input  s_axi_awvalid,
  output s_axi_awready,
  input  [C_S_AXI_DATA_WIDTH-1 : 0] s_axi_wdata,
  input  [(C_S_AXI_DATA_WIDTH/8)-1 : 0] s_axi_wstrb,
  input  s_axi_wvalid,
  output s_axi_wready,
  output [1 : 0] s_axi_bresp,
  output s_axi_bvalid,
  input  s_axi_bready,
  input  [C_S_AXI_ADDR_WIDTH-1 : 0] s_axi_araddr,
  input  [2 : 0] s_axi_arprot,
  input  s_axi_arvalid,
  output s_axi_arready,
  output [C_S_AXI_DATA_WIDTH-1 : 0] s_axi_rdata,
  output [1 : 0] s_axi_rresp,
  output s_axi_rvalid,
  input  s_axi_rready
);

// Number of Host-Accessible Registers = (1<<HA_REG_AW) = 8
localparam integer HA_REG_AW = 6; // 64 registers spanning 256 addresses

// local parameter for addressing 32 bit / 64 bit C_S_AXI_DATA_WIDTH
// ADDR_LSB is used for addressing 32/64 bit registers/memories
// ADDR_LSB = 2 for 32 bits (n downto 2)
// ADDR_LSB = 3 for 64 bits (n downto 3)
localparam integer ADDR_LSB = (C_S_AXI_DATA_WIDTH/32) + 1;

// =================== Host-Accessible Registers ========================
// Note that they are implemented as a RAM for convenience/portability, but in
// general will not synthesize to block ram due to continuous access of individual
// elements.
localparam integer NUM_HA_REGS = (1 << HA_REG_AW);
reg [C_S_AXI_DATA_WIDTH-1:0] ha_ram [0:NUM_HA_REGS-1];
reg [NUM_HA_REGS-1:0] ha_strobes=0;
integer byte_index;
reg aw_en=1'b1;

integer nreg;
initial begin
  for (nreg = 0; nreg<NUM_HA_REGS; nreg=nreg+1) begin
    ha_ram[nreg] = {{C_S_AXI_DATA_WIDTH-9{1'b0}}, 1'b1, nreg[5:0], 2'b00};
  end
end

// ====================== AXI4LITE signals ==============================
reg [C_S_AXI_ADDR_WIDTH-1:0] axi_awaddr=0, axi_araddr=0;
reg [C_S_AXI_DATA_WIDTH-1:0] axi_rdata=0;
reg axi_awready=1'b0, axi_wready=1'b0, axi_bvalid=1'b0, axi_arready=1'b0, axi_rvalid=1'b0;
reg [1:0] axi_bresp=2'b0, axi_rresp=0;
reg wdata_latched=1'b0;
reg awaddr_latched=1'b0;
reg [C_S_AXI_DATA_WIDTH-1:0] axi_wdata=0;
reg [(C_S_AXI_DATA_WIDTH/8)-1:0] axi_wstrb=0;
//reg araddr_latched=1'b0;

// ========================= Bus Writes =================================
// The write-side configuration is a bit more complex since we need information from two channels
// (write address and write data) before we can act.  We could just wait until they are both
// latched to do the write, but that uses one extra cycle.  This scheme adds a bit more
// combinational logic to allow use either the latched or "live" version of both WDATA and AWADDR
// (and WSTRB) and perform the write as soon as both are available.  This should be (not tested)
// compatible with hosts that transfer in any order (i.e. WDATA before AWADDR, AWADDR before WDATA,
// or WDATA and AWADDR together)
wire ha_reg_wren = ~axi_bvalid & ((axi_wready & s_axi_wvalid) | wdata_latched) & ((axi_awready & s_axi_awvalid) | awaddr_latched);
wire [HA_REG_AW-1:0] w_reg_sel = awaddr_latched ? axi_awaddr[ADDR_LSB+HA_REG_AW-1:ADDR_LSB] : s_axi_awaddr[ADDR_LSB+HA_REG_AW-1:ADDR_LSB];
wire [C_S_AXI_DATA_WIDTH-1:0] reg_wdata = wdata_latched ? axi_wdata : s_axi_wdata;
wire [(C_S_AXI_DATA_WIDTH/8)-1:0] reg_wstrb = wdata_latched ? axi_wstrb : s_axi_wstrb;
always @(posedge s_axi_aclk) begin
  ha_strobes <= 0;
  if (s_axi_aresetn == 1'b0) begin
    for (nreg = 0; nreg<NUM_HA_REGS; nreg=nreg+1) begin
      ha_ram[nreg] = {{C_S_AXI_DATA_WIDTH-9{1'b0}}, 1'b1, nreg[5:0], 2'b00};
    end
  end else begin
    if (ha_reg_wren) begin
    //if (wdata_latched && awaddr_latched) begin
      wdata_latched <= 1'b0;
      awaddr_latched <= 1'b0;
      // Respective byte enables are asserted as per write strobes
      for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 ) begin
        if (reg_wstrb[byte_index] == 1) begin
          // Respective byte enables are asserted as per write strobes
          ha_ram[w_reg_sel][(byte_index*8) +: 8] <= reg_wdata[(byte_index*8) +: 8];
          ha_strobes[w_reg_sel] <= 1'b1;
        end
      end
    end
  end
end

// ========================== Bus Reads =================================
// Peripheral register read enable is asserted when valid address is available
// and the peripheral is ready to accept the read address.
wire [HA_REG_AW-1:0] r_reg_sel = s_axi_araddr[ADDR_LSB+HA_REG_AW-1:ADDR_LSB];
wire ha_reg_rden = ~axi_rvalid & axi_arready & s_axi_arvalid;
always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
  if (s_axi_aresetn == 1'b0) begin
    axi_rdata  <= 0;
  end else begin
    // When there is a valid read address (s_axi_arvalid) with
    // acceptance of read address by the peripheral (axi_arready),
    // output the read data
    if (ha_reg_rden) begin
    //if (~axi_rvalid && araddr_latched) begin
      axi_rdata <= ha_ram[r_reg_sel];
    end
  end
end

// ============== AXI-4 Lite Bus Protocol Implementation ================
// I/O Connections assignments
assign s_axi_awready = axi_awready;
assign s_axi_wready  = axi_wready;
assign s_axi_bresp   = axi_bresp;
assign s_axi_bvalid  = axi_bvalid;
assign s_axi_arready = axi_arready;
assign s_axi_rdata   = axi_rdata;
assign s_axi_rresp   = axi_rresp;
assign s_axi_rvalid  = axi_rvalid;

// Latching data here
always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
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
    axi_wstrb   <= 0;
    // State signals
    wdata_latched <= 1'b0;
    awaddr_latched <= 1'b0;
    //araddr_latched <= 1'b0;
  end else begin

    // ===================== Write Address Channel: AWVALID AWREADY AWADDR AWPROT =================
    // AWREADY: indicates we can accept a write address
    //          This scheme makes AWREADY wait for the entire transaction to complete
    //          before pulsing low synchronous with the write response BVALID.
    if (~axi_awready) begin
      axi_awready <= 1'b1;
    end else if (axi_bvalid && s_axi_bready) begin
      axi_awready <= 1'b0;
    end else begin
      axi_awready <= axi_awready;
    end
    // AWADDR:  the write address from the host
    //          Must be latched when AWVALID && AWREADY or when AWVALID and AWREADY is being asserted
    if (axi_awready && s_axi_awvalid) begin
      axi_awaddr <= s_axi_awaddr;
      awaddr_latched <= 1'b1;
    end
    // AWPROT:  Safely ignoring this protection signaling information.

    // ====================== Write Data Channel: WVALID WREADY WDATA WSTRB =======================
    // WREADY:  Indicates we can accept write data
    //          This scheme makes WREADY wait for the entire transaction to complete
    //          before pulsing low synchronous with the write response BVALID.
    if (~axi_wready) begin
      axi_wready <= 1'b1;
    end else if (axi_bvalid && s_axi_bready) begin
      axi_wready <= 1'b0;
    end else begin
      axi_wready <= axi_wready;
    end
    // WDATA:   the write data from the host
    // WSTRB:   indicates which byte lanes hold valid data
    if (axi_wready && s_axi_wvalid) begin
      axi_wdata <= s_axi_wdata;
      axi_wstrb <= s_axi_wstrb;
      wdata_latched <= 1'b1;
    end

    // ======================= Write Response Channel: BVALID BREADY BRESP ========================
    // BVALID:  indicates write response information is valid.
    //          Must wait for AWVALID, AWREADY, WVALID, and WREADY to assert
    // BRESP:   This module always responds "OKAY"
    //if (~axi_bvalid && axi_awready && s_axi_awvalid && axi_wready && s_axi_wvalid) begin
    if (ha_reg_wren) begin
      axi_bvalid <= 1'b1;
      axi_bresp  <= 2'b0; // 'OKAY' response
    end else if (s_axi_bready && axi_bvalid) begin
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
    end else if (axi_rvalid && s_axi_rready) begin
      axi_arready <= 1'b0;
    end else begin
      axi_arready <= axi_arready;
    end
    // ARADDR:  the read address from the host
    //          Must be latched when ARVALID && ARREADY or when ARVALID and ARREADY is being asserted
    if (axi_arready && s_axi_arvalid) begin
      //araddr_latched <= 1'b1;
      axi_araddr  <= s_axi_araddr;
    end

    // ======================= Read Data Channel: RVALID RREADY RDATA RRESP =======================
    // RVALID:  indicates read response information is valid
    //          Assert only after both ARVALID and ARREADY are asserted and RDATA and RRESP are valid
    //          Must only assert RVALID in response to a request for data
    if (~axi_rvalid && axi_arready && s_axi_arvalid) begin
    //if (~axi_rvalid && araddr_latched) begin
      // RDATA is latched onto the bus at this point too
      // See 'ha_reg_rden' above
      axi_rvalid <= 1'b1;
      axi_rresp  <= 2'b0; // 'OKAY' response
      //araddr_latched <= 1'b0;
    end else if (axi_rvalid && s_axi_rready) begin
      axi_rvalid <= 1'b0;
    end

  end
end

endmodule
