`timescale 1ns/100ps

module axi_cdc_tb;

localparam XACT_CYCLES = 8;
// See mem_gate.md's note about MTU-limited single-beat transactions
localparam N_XACTS = 183;
localparam FIFO_AW = $clog2(N_XACTS);
// The number of cycles to delay before "opening" the read FIFO.
// Higher latency supports slower clocks on the "M" side.
localparam LATENCY_CYCLES = 640;

localparam S_AXI_ACLK_HALFPERIOD = 4;
localparam M_AXI_ACLK_HALFPERIOD = 2;
reg [9:0] m_axi_aclk_halfperiod = M_AXI_ACLK_HALFPERIOD;

localparam STEP = 2*S_AXI_ACLK_HALFPERIOD;
localparam LONGEST_PERIOD = S_AXI_ACLK_HALFPERIOD > M_AXI_ACLK_HALFPERIOD ?
                            2*S_AXI_ACLK_HALFPERIOD : 2*M_AXI_ACLK_HALFPERIOD;
reg s_axi_aclk=1'b1, m_axi_aclk=1'b1;
always #S_AXI_ACLK_HALFPERIOD s_axi_aclk <= ~s_axi_aclk;
reg ghz_clk = 1'b1;
always #0.5 ghz_clk <= ~ghz_clk;
reg [9:0] ghz_counter=0;
always @(posedge ghz_clk) begin
  if (ghz_counter == m_axi_aclk_halfperiod) begin
    ghz_counter <= 0;
    m_axi_aclk <= ~m_axi_aclk;
  end else begin
    ghz_counter <= ghz_counter + 1;
  end
end

// VCD dump file for gtkwave
initial begin
  if ($test$plusargs("vcd")) begin
    $dumpfile("axi_cdc.vcd");
    $dumpvars();
  end
end

localparam TOW = 12;
localparam TOSET = {TOW{1'b1}};
reg [TOW-1:0] timeout_r=0;
always @(posedge s_axi_aclk) begin
  if (timeout_r > 0) timeout_r <= timeout_r - 1;
end
wire to = ~(|timeout_r);

`define wait_timeout(sig) timeout_r = TOSET; #STEP wait ((to) || sig)

localparam C_M_AXI_ADDR_WIDTH = 16;
localparam C_M_AXI_DATA_WIDTH = 32;
localparam RESPONSE_TIMEOUT = 255;

// AXI4LITE signals from Host to CDC
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
wire m_axi_aresetn = axi_aresetn;
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
wire read_stb, write_stb;
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
  .m_axi_aclk(s_axi_aclk), // input
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

reg read_enable=1'b1;
axi_cdc #(
  .C_AXI_DATA_WIDTH(C_M_AXI_DATA_WIDTH),
  .C_AXI_ADDR_WIDTH(C_M_AXI_ADDR_WIDTH),
  .FIFO_AW(FIFO_AW)
) axi_cdc_i (
  .s_read_enable(read_enable),
  // AXI4LITE Ports from Host
  .s_axi_aclk(s_axi_aclk), // input
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
  .m_axi_aclk(m_axi_aclk), // input
  .m_axi_aresetn(m_axi_aresetn), // input
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
  .s_axi_aclk(m_axi_aclk), // input
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

localparam XACT_TIMER_W = $clog2(XACT_CYCLES);
reg [XACT_TIMER_W-1:0] xact_timer=XACT_CYCLES;
reg reset=1'b1;
reg read_mask=1'b0;
reg write_mask=1'b0;
wire trig = xact_timer == 1;
wire pre_trig = xact_timer == 0;
assign read_stb = trig & read_mask;
assign write_stb = trig & write_mask;
always @(posedge s_axi_aclk) begin
  if ((xact_timer == XACT_CYCLES-1) | reset) xact_timer <= 0;
  else xact_timer <= xact_timer + 1;
end
// ========= Xact Counter ===========
reg [4:0] outstanding_xacts=0;
reg m_axi_rvalid_d=1'b0;
wire m_axi_rvalid_re = m_axi_rvalid & ~m_axi_rvalid_d;
reg m_axi_arvalid_d=1'b0;
wire m_axi_arvalid_re = m_axi_arvalid & ~m_axi_arvalid_d;
always @(posedge m_axi_aclk) begin
  m_axi_rvalid_d <= m_axi_rvalid;
  m_axi_arvalid_d <= m_axi_arvalid;
  if (m_axi_arvalid_re & m_axi_rvalid_re) begin
    outstanding_xacts <= outstanding_xacts; // +1-1
  end else if (m_axi_arvalid_re) begin
    outstanding_xacts <= outstanding_xacts + 1;
  end else if (m_axi_rvalid_re) begin
    outstanding_xacts <= outstanding_xacts - 1;
  end
end

// =========== Stimulus =============
integer N, lastN=0;
real timestamp;
wire [31:0] M = (N<<4); // clobber scheme
wire [31:0] lastM = (lastN<<4); // clobber scheme
integer errors=0;
integer phase=0;
reg break=1'b0;
always @(posedge s_axi_aclk) begin
  if (phase == 0) begin
    if (rvalid) begin
      if (rdata != {{C_M_AXI_DATA_WIDTH-9{1'b0}}, 1'b1, lastN[7:0]}) begin
        $display("ERROR! Readback %x != %x", rdata[8:0], {1'b1, lastN[7:0]});
        errors = errors + 1;
        break = 1'b1;
      end
      lastN <= lastN+4;
    end
  //end else if (phase == 1) begin
  end else if (phase == 2) begin
    if (rvalid) begin
      if (rdata[11:0] != lastM[11:0]) begin
        $display("ERROR! Readback %x != %x", rdata[11:0], lastM[11:0]);
        errors = errors + 1;
        break = 1'b1;
      end
      lastN <= lastN+4;
    end
  end
end

// Keep an average of the time between 'rvalid' pulses
integer clk_count=0;
integer last_clk_count=0;
integer count_min=32'h7fffffff;
integer count_max=0;
integer sum=0;
integer rvalid_counts=0;
reg reset_stats=1'b0;
always @(posedge s_axi_aclk) begin
  if (reset_stats) begin
    clk_count <= 0;
    rvalid_counts <= 0;
    sum <= 0;
    read_enable <= 1'b0;
    last_clk_count <= 0;
  end else begin
    clk_count <= clk_count + 1;
    if (read_enable & rvalid) begin
      if ((clk_count-last_clk_count) < count_min) count_min <= clk_count - last_clk_count;
      if ((clk_count-last_clk_count) > count_max) count_max <= clk_count - last_clk_count;
      rvalid_counts <= rvalid_counts + 1;
      sum <= sum + (clk_count-last_clk_count);
      last_clk_count <= clk_count;
    end
  end
  if (~read_enable && (clk_count == LATENCY_CYCLES-1)) begin
    read_enable <= 1'b1;
    clk_count <= 0;
    last_clk_count <= 0;
  end
end


integer MCLK_HALFPERIOD=2;
integer READOUT_LIMIT=1;
integer WRITE_LIMIT=1;
initial begin
  @(posedge s_axi_aclk) $display("==== Readout Speed Limit Test ====");
          reset = 1'b0;
          reset_stats = 1'b1;
  wait (trig);
  for (MCLK_HALFPERIOD=2; (MCLK_HALFPERIOD<50) && ~break; MCLK_HALFPERIOD=MCLK_HALFPERIOD+1) begin
          lastN = 0;
          m_axi_aclk_halfperiod = MCLK_HALFPERIOD[9:0];
          `wait_timeout(~busy);
          `wait_timeout(outstanding_xacts==0);
          $display("f(m_clk) = %.02f MHz", 1000.0/(2*MCLK_HALFPERIOD));
    @(posedge s_axi_aclk) reset = 1'b1;
    @(posedge s_axi_aclk) reset = 1'b0;
          //read_enable = 1'b0;
          reset_stats = 1'b0;
    for (N=0; (N<4*N_XACTS) && ~break; N=N+4) begin
          addr = N[C_M_AXI_ADDR_WIDTH-1:0];
          read_mask = 1'b1;
      `wait_timeout(busy_r);
          //$display("%t: N = %d", $time, N);
          if (to) begin
            $display("  ERROR! Timeout waiting for busy_r %x", addr);
            break=1'b1;
          end
      `wait_timeout(pre_trig);
          if (to) begin
            $display("  ERROR! Timeout waiting for ~busy_r %x", addr);
            break=1'b1;
          end
          if (busy_r) begin
            $display("  Limit reached. Can't keep up with XACT_CYCLES = %d", XACT_CYCLES[3:0]);
            break=1'b1;
          end
    end // for (N...)
          read_mask = 1'b0;
          //read_enable = 1'b1;
    `wait_timeout(lastN == 4*N_XACTS);
          $display("rvalid average clock cycles: %.02f (%d, %d)", $itor(sum)/rvalid_counts, count_min, count_max);
          reset_stats = 1'b1;
          if (sum > rvalid_counts*XACT_CYCLES) break = 1'b1;
  end // for (MCLK_HALFPERIOD...)
          //$display("  Completed in %.2f cycles of the slower clock.", ($realtime-STEP)/LONGEST_PERIOD);
          //$display("    %.2f cycles of the bus clock.", ($realtime-STEP)/(2*S_AXI_ACLK_HALFPERIOD));
          //$display("    %.2f bus cycles per transaction.", (($realtime-STEP)/(2*S_AXI_ACLK_HALFPERIOD))/64);
          read_mask = 1'b0;
          `wait_timeout(~busy);
          if (break) begin
            READOUT_LIMIT = MCLK_HALFPERIOD-1;
          end else begin
            READOUT_LIMIT = MCLK_HALFPERIOD;
          end
          $display("Readout minimum frequency: %.02f MHz", 1000.0/(2*READOUT_LIMIT));
          $finish();
  @(posedge s_axi_aclk) $display("==== Write Speed Limit Test ====");
          timestamp = $realtime;
          phase = phase + 1;
          break = 1'b0;
  for (MCLK_HALFPERIOD=2; (MCLK_HALFPERIOD<50) && ~break; MCLK_HALFPERIOD=MCLK_HALFPERIOD+1) begin
          lastN = 0;
          m_axi_aclk_halfperiod = MCLK_HALFPERIOD[9:0];
          `wait_timeout(~busy);
          `wait_timeout(outstanding_xacts==0);
          $display("f(m_clk) = %.02f MHz", 1000.0/(2*MCLK_HALFPERIOD));
    @(posedge s_axi_aclk) reset = 1'b1;
    @(posedge s_axi_aclk) reset = 1'b0;
    for (N=0; (N<256) && ~break; N=N+4) begin
          addr = N[C_M_AXI_ADDR_WIDTH-1:0];
          wdata = M;
          write_mask = 1'b1;
      `wait_timeout(busy_w);
          if (to) begin
            $display("ERROR! Timeout waiting for busy_w %x", addr);
            break=1'b1;
          end
      `wait_timeout(pre_trig);
          if (to) begin
            $display("ERROR! Timeout waiting for ~busy_w %x", addr);
            break=1'b1;
          end
          if (busy_w) begin
            $display("  Limit reached. Can't keep up with XACT_CYCLES = %d", XACT_CYCLES[3:0]);
            break=1'b1;
          end
    end // for (N...)
  end // for (MCLK_HALFPERIOD...)
          write_mask = 1'b0;
          `wait_timeout(lastN == 256);
          `wait_timeout(~busy);
          if (break) begin
            WRITE_LIMIT = MCLK_HALFPERIOD-1;
          end else begin
            WRITE_LIMIT = MCLK_HALFPERIOD;
          end
          $display("Write minimum frequency: %.02f MHz", 1000.0/(2*WRITE_LIMIT));
          $finish();

  // TODO - Perform write and readback to confirm data gets through
          timestamp = $realtime;
          $display("Reading clobbered registers");
  for (N=0; N<256; N=N+4) begin
          addr = N[C_M_AXI_ADDR_WIDTH-1:0];
    #STEP read_mask = 1'b1;
    `wait_timeout(busy_r);
          if (to) begin
            $display("ERROR! Timeout waiting for busy_r %x", addr);
            $stop(0);
          end
    `wait_timeout(~busy_r);
          if (to) begin
            $display("ERROR! Timeout waiting for ~busy_r %x", addr);
            $stop(0);
          end
  end
          $display("  Completed in %.2f cycles of the slower clock.", ($realtime-timestamp)/LONGEST_PERIOD);
          $display("    %.2f cycles per transaction.", (($realtime-timestamp)/LONGEST_PERIOD)/64);
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
