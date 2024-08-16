`timescale 1ns/1ns

module axi_host_pipelined_tb;

localparam AXI_ACLK_HALFPERIOD = 5;
localparam STEP = 2*AXI_ACLK_HALFPERIOD;
reg clk=1'b1;
always #AXI_ACLK_HALFPERIOD clk <= ~clk;

// VCD dump file for gtkwave
initial begin
  if ($test$plusargs("vcd")) begin
    $dumpfile("axi_host_pipelined.vcd");
    $dumpvars();
  end
end

localparam TOW = 12;
localparam TOSET = {TOW{1'b1}};
reg [TOW-1:0] timeout_r=0;
always @(posedge clk) begin
  if (timeout_r > 0) timeout_r <= timeout_r - 1;
end
wire to = ~(|timeout_r);

`define wait_timeout(sig) timeout_r = TOSET; #STEP wait ((to) || sig)

localparam C_M_AXI_ADDR_WIDTH = 16;
localparam C_M_AXI_DATA_WIDTH = 32;
localparam RESPONSE_TIMEOUT = 255;

// AXI4LITE signals from Host to Peripheral
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

// Host control signals
reg read_stb=1'b0, write_stb=1'b0;
reg [C_M_AXI_ADDR_WIDTH-1:0] addr=0;
reg [C_M_AXI_DATA_WIDTH-1:0] wdata=0;
wire [C_M_AXI_DATA_WIDTH-1:0] rdata;
wire busy;
wire busy_r, busy_w;
wire rvalid;
wire timeout;
wire [1:0] resp;

axi_host_pipelined #(
  .C_M_AXI_ADDR_WIDTH(C_M_AXI_ADDR_WIDTH),
  .C_M_AXI_DATA_WIDTH(C_M_AXI_DATA_WIDTH),
  .RESPONSE_TIMEOUT(RESPONSE_TIMEOUT)
) axi_host_pipelined_i (
  .m_axi_aclk(clk), // input
  .m_axi_aresetn(axi_aresetn), // input
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
  .read_stb(read_stb), // input
  .write_stb(write_stb), // input
  .addr(addr), // input [C_M_AXI_ADDR_WIDTH-1:0]
  .wdata(wdata), // input [C_M_AXI_DATA_WIDTH-1:0]
  .rdata(rdata), // output [C_M_AXI_DATA_WIDTH-1:0]
  .busy_r(busy_r), // output
  .busy_w(busy_w), // output
  .busy(busy), // output
  .rvalid(rvalid), // output
  .timeout(timeout), // output
  .resp(resp) // output
);

axi_dummy #(
  .C_S_AXI_DATA_WIDTH(C_M_AXI_DATA_WIDTH),
  .C_S_AXI_ADDR_WIDTH(C_M_AXI_ADDR_WIDTH)
) axi_dummy_i (
  .s_axi_aclk(clk), // input
  .s_axi_aresetn(axi_aresetn), // input
  .s_axi_awaddr(axi_awaddr), // input [C_M_AXI_ADDR_WIDTH:0]
  .s_axi_awprot(axi_awprot), // input [2:0]
  .s_axi_awvalid(axi_awvalid), // input
  .s_axi_awready(axi_awready), // output
  .s_axi_wdata(axi_wdata), // input [C_M_AXI_DATA_WIDTH:0]
  .s_axi_wstrb(axi_wstrb), // input [3:0]
  .s_axi_wvalid(axi_wvalid), // input
  .s_axi_wready(axi_wready), // output
  .s_axi_bresp(axi_bresp), // output [1:0]
  .s_axi_bvalid(axi_bvalid), // output
  .s_axi_bready(axi_bready), // input
  .s_axi_araddr(axi_araddr), // input [C_M_AXI_ADDR_WIDTH:0]
  .s_axi_arprot(axi_arprot), // input [2:0]
  .s_axi_arvalid(axi_arvalid), // input
  .s_axi_arready(axi_arready), // output
  .s_axi_rdata(axi_rdata), // output [C_M_AXI_DATA_WIDTH:0]
  .s_axi_rresp(axi_rresp), // output [1:0]
  .s_axi_rvalid(axi_rvalid), // output
  .s_axi_rready(axi_rready) // input
);

// =========== Stimulus =============
integer N, lastN;
real timestamp;
wire [31:0] M = (N<<4); // clobber scheme
wire [31:0] lastM = (lastN<<4); // clobber scheme
integer errors=0;
integer phase=0;
always @(posedge clk) begin
  if (phase == 0) begin
    if (rvalid) begin
      if (rdata != {{C_M_AXI_DATA_WIDTH-9{1'b0}}, 1'b1, lastN[7:0]}) begin
        $display("ERROR! Readback %x != %x", rdata[8:0], {1'b1, lastN[7:0]});
        errors = errors + 1;
      end
    end
  //end else if (phase == 1) begin
  end else if (phase == 2) begin
    if (rvalid) begin
      if (rdata[11:0] != lastM[11:0]) begin
        $display("ERROR! Readback %x != %x", rdata[11:0], lastM[11:0]);
        errors = errors + 1;
      end
    end
  end
end
initial begin
  @(posedge clk) $display("Reading all 64 registers");
          read_stb = 1'b0;
  #STEP
  for (N=0; N<256; N=N+4) begin
          addr = N[C_M_AXI_ADDR_WIDTH-1:0];
          read_stb = 1'b1;
    `wait_timeout(busy_r);
          read_stb = 1'b0;
          if (to) begin
            $display("ERROR! Timeout waiting for busy_r %x", addr);
            $stop(0);
          end
    `wait_timeout(~busy_r);
          if (to) begin
            $display("ERROR! Timeout waiting for ~busy_r %x", addr);
            $stop(0);
          end
          lastN = N;
  end
          $display("  Completed in %.2f cycles.", (($realtime-STEP)/STEP) - 1);
          $display("    %.2f cycles per transaction.", (($realtime-STEP)/STEP)/64);
          `wait_timeout(~busy);
          timestamp = $realtime;
          $display("Writing all 64 registers");
          phase = phase + 1;
  for (N=0; N<256; N=N+4) begin
          addr = N[C_M_AXI_ADDR_WIDTH-1:0];
          wdata = M;
    #STEP write_stb = 1'b1;
    `wait_timeout(busy_w);
          write_stb = 1'b0;
          if (to) begin
            $display("ERROR! Timeout waiting for busy_w %x", addr);
            $stop(0);
          end
    `wait_timeout(~busy_w);
          if (to) begin
            $display("ERROR! Timeout waiting for ~busy_w %x", addr);
            $stop(0);
          end
          if (timeout) begin
            $display("ERROR! Timeout on write %x", addr);
            errors = errors + 1;
          end
          lastN = N;
  end
          $display("  Completed in %.2f cycles.", (($realtime-timestamp)/STEP));
          $display("    %.2f cycles per transaction.", (($realtime-timestamp)/STEP)/64);
          `wait_timeout(~busy);
          timestamp = $realtime;
          $display("Reading clobbered registers");
  for (N=0; N<256; N=N+4) begin
          addr = N[C_M_AXI_ADDR_WIDTH-1:0];
    #STEP read_stb = 1'b1;
    `wait_timeout(busy_r);
          read_stb = 1'b0;
          if (to) begin
            $display("ERROR! Timeout waiting for busy_r %x", addr);
            $stop(0);
          end
    `wait_timeout(~busy_r);
          if (to) begin
            $display("ERROR! Timeout waiting for ~busy_r %x", addr);
            $stop(0);
          end
          lastN = N;
  end
          $display("  Completed in %.2f cycles.", (($realtime-timestamp)/STEP) - 1);
          $display("    %.2f cycles per transaction.", (($realtime-timestamp)/STEP)/64);
          `wait_timeout(~busy);
          if (errors == 0) begin
            $display("PASS");
            $finish(0);
          end else begin
            $display("FAIL: %d errors", errors);
            $stop(0);
          end
end

endmodule
