`timescale 1ns/1ns

//`define TEST_WIDE3
//`define TEST_WIDE2
//`define TEST_WIDE1
//`define TEST_WIDE0
//`define TEST_NORMAL

module wctrace_tb;

localparam CLK_HALFPERIOD = 5;
localparam TICK = 2*CLK_HALFPERIOD;
reg clk=1'b1;
always #CLK_HALFPERIOD clk <= ~clk;

// VCD dump file for gtkwave
initial begin
  if ($test$plusargs("vcd")) begin
    $dumpfile("wctrace.vcd");
    $dumpvars();
  end
end

localparam TOW = 12;
localparam TOSET = {TOW{1'b1}};
reg [TOW-1:0] r_timeout=0;
always @(posedge clk) begin
  if (r_timeout > 0) r_timeout <= r_timeout - 1;
end
wire to = ~(|r_timeout);
`define wait_timeout(sig) r_timeout = TOSET; #TICK wait ((to) || sig)

`define CHECK(bus, data) if (bus != data) begin $display("[%x] Miss: %x != %x", lb_addr, bus, data); pass <= 1'b0; end

localparam AW = 10;
reg [AW-1:0] lb_addr=0;
wire [31:0] lb_out;
reg pass=1'b1;

reg readback=1'b0;
reg vcd_write=1'b0, vcd_done=1'b0;

// ====================== Data definition and self-checks =====================
`ifdef TEST_WIDE3
localparam DW = 136;
localparam TW = 16;
localparam BW = 256;
// Four randomly generated test patterns (no special meaning here)
localparam [DW-1:0] DATA0 = 136'h1b0224d52b00ea2866a01ad68db689859e;
localparam [DW-1:0] DATA1 = 136'h74adc66bbbe87bbb0f95052122983e10fd;
localparam [DW-1:0] DATA2 = 136'h0e76d936a9924425c0ea546b57f487e4f1;
localparam [DW-1:0] DATA3 = 136'h6f673b0ac1d6dbf4e60e04a711e90673fd;
localparam S4 = DW-128;
localparam S3 = 32;
localparam S2 = 32;
localparam S1 = 32;
localparam S0 = 32;
wire [S0-1:0] R0_S0 = DATA0[S0-1:0];
wire [S0-1:0] R1_S0 = DATA1[S0-1:0];
wire [S0-1:0] R2_S0 = DATA2[S0-1:0];
wire [S0-1:0] R3_S0 = DATA3[S0-1:0];
wire [S1-1:0] R0_S1 = DATA0[S0+S1-1:S0];
wire [S1-1:0] R1_S1 = DATA1[S0+S1-1:S0];
wire [S1-1:0] R2_S1 = DATA2[S0+S1-1:S0];
wire [S1-1:0] R3_S1 = DATA3[S0+S1-1:S0];
wire [S2-1:0] R0_S2 = DATA0[S0+S1+S2-1:S0+S1];
wire [S2-1:0] R1_S2 = DATA1[S0+S1+S2-1:S0+S1];
wire [S2-1:0] R2_S2 = DATA2[S0+S1+S2-1:S0+S1];
wire [S2-1:0] R3_S2 = DATA3[S0+S1+S2-1:S0+S1];
wire [S3-1:0] R0_S3 = DATA0[S0+S1+S2+S3-1:S0+S1+S2];
wire [S3-1:0] R1_S3 = DATA1[S0+S1+S2+S3-1:S0+S1+S2];
wire [S3-1:0] R2_S3 = DATA2[S0+S1+S2+S3-1:S0+S1+S2];
wire [S3-1:0] R3_S3 = DATA3[S0+S1+S2+S3-1:S0+S1+S2];
wire [S4-1:0] R0_S4 = DATA0[DW-1:S0+S1+S2+S3];
wire [S4-1:0] R1_S4 = DATA1[DW-1:S0+S1+S2+S3];
wire [S4-1:0] R2_S4 = DATA2[DW-1:S0+S1+S2+S3];
wire [S4-1:0] R3_S4 = DATA3[DW-1:S0+S1+S2+S3];
initial begin
  // Read back
  `wait_timeout(readback);
  if (to) begin
    $display("ERROR: Timeout waiting for readback assertion.");
    $stop(0);
  end
        lb_addr = 0;
  #TICK `CHECK(lb_out, R0_S0)
  #TICK lb_addr = lb_addr + 1;
  #TICK `CHECK(lb_out[S1-1:0], R0_S1)
  #TICK lb_addr = lb_addr + 1;
  #TICK `CHECK(lb_out[S2-1:0], R0_S2)
  #TICK lb_addr = lb_addr + 1;
  #TICK `CHECK(lb_out[S3-1:0], R0_S3)
  #TICK lb_addr = lb_addr + 1;
  #TICK `CHECK(lb_out[S4-1:0], R0_S4)

  #TICK lb_addr = lb_addr + 4;
  #TICK `CHECK(lb_out, R1_S0)
  #TICK lb_addr = lb_addr + 1;
  #TICK `CHECK(lb_out[S1-1:0], R1_S1)
  #TICK lb_addr = lb_addr + 1;
  #TICK `CHECK(lb_out[S2-1:0], R1_S2)
  #TICK lb_addr = lb_addr + 1;
  #TICK `CHECK(lb_out[S3-1:0], R1_S3)
  #TICK lb_addr = lb_addr + 1;
  #TICK `CHECK(lb_out[S4-1:0], R1_S4)

  #TICK lb_addr = lb_addr + 4;
  #TICK `CHECK(lb_out, R2_S0)
  #TICK lb_addr = lb_addr + 1;
  #TICK `CHECK(lb_out[S1-1:0], R2_S1)
  #TICK lb_addr = lb_addr + 1;
  #TICK `CHECK(lb_out[S2-1:0], R2_S2)
  #TICK lb_addr = lb_addr + 1;
  #TICK `CHECK(lb_out[S3-1:0], R2_S3)
  #TICK lb_addr = lb_addr + 1;
  #TICK `CHECK(lb_out[S4-1:0], R2_S4)

  #TICK lb_addr = lb_addr + 4;
  #TICK `CHECK(lb_out, R3_S0)
  #TICK lb_addr = lb_addr + 1;
  #TICK `CHECK(lb_out[S1-1:0], R3_S1)
  #TICK lb_addr = lb_addr + 1;
  #TICK `CHECK(lb_out[S2-1:0], R3_S2)
  #TICK lb_addr = lb_addr + 1;
  #TICK `CHECK(lb_out[S3-1:0], R3_S3)
  #TICK lb_addr = lb_addr + 1;
  #TICK `CHECK(lb_out[S4-1:0], R3_S4)

  vcd_write = 1'b1;
  lb_addr = 0;
  `wait_timeout(vcd_done);
  vcd_write = 1'b0;
  #(10*TICK)
  if (pass) begin
    $display("PASS");
    $finish(0);
  end else begin
    $display("FAIL");
    $stop(0);
  end
end
`else
`ifdef TEST_WIDE2
localparam DW = 104;
localparam TW = 24;
localparam BW = 128;
// Four randomly generated test patterns (no special meaning here)
localparam [DW-1:0] DATA0 = 104'hc37b15f763c1c86d2a5180d393;
localparam [DW-1:0] DATA1 = 104'hcca7067778a630fbacbe62f8eb;
localparam [DW-1:0] DATA2 = 104'haffc3a65d0198029578cd23117;
localparam [DW-1:0] DATA3 = 104'he41e5db9246412707961ff5ae1;
localparam S3 = DW-96;
localparam S2 = 32;
localparam S1 = 32;
localparam S0 = 32;
wire [S0-1:0] R0_S0 = DATA0[S0-1:0];
wire [S0-1:0] R1_S0 = DATA1[S0-1:0];
wire [S0-1:0] R2_S0 = DATA2[S0-1:0];
wire [S0-1:0] R3_S0 = DATA3[S0-1:0];
wire [S1-1:0] R0_S1 = DATA0[S0+S1-1:S0];
wire [S1-1:0] R1_S1 = DATA1[S0+S1-1:S0];
wire [S1-1:0] R2_S1 = DATA2[S0+S1-1:S0];
wire [S1-1:0] R3_S1 = DATA3[S0+S1-1:S0];
wire [S2-1:0] R0_S2 = DATA0[S0+S1+S2-1:S0+S1];
wire [S2-1:0] R1_S2 = DATA1[S0+S1+S2-1:S0+S1];
wire [S2-1:0] R2_S2 = DATA2[S0+S1+S2-1:S0+S1];
wire [S2-1:0] R3_S2 = DATA3[S0+S1+S2-1:S0+S1];
wire [S3-1:0] R0_S3 = DATA0[DW-1:S0+S1+S2];
wire [S3-1:0] R1_S3 = DATA1[DW-1:S0+S1+S2];
wire [S3-1:0] R2_S3 = DATA2[DW-1:S0+S1+S2];
wire [S3-1:0] R3_S3 = DATA3[DW-1:S0+S1+S2];

initial begin
  // Read back
  `wait_timeout(readback);
  if (to) begin
    $display("ERROR: Timeout waiting for readback assertion.");
    $stop(0);
  end
        lb_addr = 0;
  #TICK `CHECK(lb_out, R0_S0)
  #TICK lb_addr = lb_addr + 1;
  #TICK `CHECK(lb_out[S1-1:0], R0_S1)
  #TICK lb_addr = lb_addr + 1;
  #TICK `CHECK(lb_out[S2-1:0], R0_S2)
  #TICK lb_addr = lb_addr + 1;
  #TICK `CHECK(lb_out[S3-1:0], R0_S3)

  #TICK lb_addr = lb_addr + 1;
  #TICK `CHECK(lb_out, R1_S0)
  #TICK lb_addr = lb_addr + 1;
  #TICK `CHECK(lb_out[S1-1:0], R1_S1)
  #TICK lb_addr = lb_addr + 1;
  #TICK `CHECK(lb_out[S2-1:0], R1_S2)
  #TICK lb_addr = lb_addr + 1;
  #TICK `CHECK(lb_out[S3-1:0], R1_S3)

  #TICK lb_addr = lb_addr + 1;
  #TICK `CHECK(lb_out, R2_S0)
  #TICK lb_addr = lb_addr + 1;
  #TICK `CHECK(lb_out[S1-1:0], R2_S1)
  #TICK lb_addr = lb_addr + 1;
  #TICK `CHECK(lb_out[S2-1:0], R2_S2)
  #TICK lb_addr = lb_addr + 1;
  #TICK `CHECK(lb_out[S3-1:0], R2_S3)

  #TICK lb_addr = lb_addr + 1;
  #TICK `CHECK(lb_out, R3_S0)
  #TICK lb_addr = lb_addr + 1;
  #TICK `CHECK(lb_out[S1-1:0], R3_S1)
  #TICK lb_addr = lb_addr + 1;
  #TICK `CHECK(lb_out[S2-1:0], R3_S2)
  #TICK lb_addr = lb_addr + 1;
  #TICK `CHECK(lb_out[S3-1:0], R3_S3)

  vcd_write = 1'b1;
  lb_addr = 0;
  `wait_timeout(vcd_done);
  vcd_write = 1'b0;
  #(10*TICK)
  if (pass) begin
    $display("PASS");
    $finish(0);
  end else begin
    $display("FAIL");
    $stop(0);
  end
end
`else
 `ifdef TEST_WIDE1
localparam DW = 72;
localparam TW = 24;
localparam BW = 128;
localparam [DW-1:0] DATA0 = 72'h98765432123456789a;
localparam [DW-1:0] DATA1 = 72'h98765432cecee6789a;
localparam [DW-1:0] DATA2 = 72'h98765432ceceebabee;
localparam [DW-1:0] DATA3 = 72'h98765432baedadface;
localparam S2 = DW-64;
localparam S1 = 32;
localparam S0 = 32;
wire [S0-1:0] R0_S0 = DATA0[S0-1:0];
wire [S0-1:0] R1_S0 = DATA1[S0-1:0];
wire [S0-1:0] R2_S0 = DATA2[S0-1:0];
wire [S0-1:0] R3_S0 = DATA3[S0-1:0];
wire [S1-1:0] R0_S1 = DATA0[S0+S1-1:S0];
wire [S1-1:0] R1_S1 = DATA1[S0+S1-1:S0];
wire [S1-1:0] R2_S1 = DATA2[S0+S1-1:S0];
wire [S1-1:0] R3_S1 = DATA3[S0+S1-1:S0];
wire [S2-1:0] R0_S2 = DATA0[DW-1:S0+S1];
wire [S2-1:0] R1_S2 = DATA1[DW-1:S0+S1];
wire [S2-1:0] R2_S2 = DATA2[DW-1:S0+S1];
wire [S2-1:0] R3_S2 = DATA3[DW-1:S0+S1];

initial begin
  // Read back
  `wait_timeout(readback);
  if (to) begin
    $display("ERROR: Timeout waiting for readback assertion.");
    $stop(0);
  end
        lb_addr = 0;
  #TICK `CHECK(lb_out, R0_S0)
  #TICK lb_addr = lb_addr + 1;
  #TICK `CHECK(lb_out[S1-1:0], R0_S1)
  #TICK lb_addr = lb_addr + 1;
  #TICK `CHECK(lb_out[S2-1:0], R0_S2)
  #TICK lb_addr = lb_addr + 1;
  #TICK `CHECK(lb_out, 32'h0)

  #TICK lb_addr = lb_addr + 1;
  #TICK `CHECK(lb_out, R1_S0)
  #TICK lb_addr = lb_addr + 1;
  #TICK `CHECK(lb_out[S1-1:0], R1_S1)
  #TICK lb_addr = lb_addr + 1;
  #TICK `CHECK(lb_out[S2-1:0], R1_S2)
  #TICK lb_addr = lb_addr + 1;
  #TICK `CHECK(lb_out, 32'h0)

  #TICK lb_addr = lb_addr + 1;
  #TICK `CHECK(lb_out, R2_S0)
  #TICK lb_addr = lb_addr + 1;
  #TICK `CHECK(lb_out[S1-1:0], R2_S1)
  #TICK lb_addr = lb_addr + 1;
  #TICK `CHECK(lb_out[S2-1:0], R2_S2)
  #TICK lb_addr = lb_addr + 1;
  #TICK `CHECK(lb_out, 32'h0)

  #TICK lb_addr = lb_addr + 1;
  #TICK `CHECK(lb_out, R3_S0)
  #TICK lb_addr = lb_addr + 1;
  #TICK `CHECK(lb_out[S1-1:0], R3_S1)
  #TICK lb_addr = lb_addr + 1;
  #TICK `CHECK(lb_out[S2-1:0], R3_S2)
  #TICK lb_addr = lb_addr + 1;
  #TICK `CHECK(lb_out, 32'h0)

  vcd_write = 1'b1;
  lb_addr = 0;
  `wait_timeout(vcd_done);
  vcd_write = 1'b0;
  #(10*TICK)
  if (pass) begin
    $display("PASS");
    $finish(0);
  end else begin
    $display("FAIL");
    $stop(0);
  end
end
 `else
  `ifdef TEST_WIDE0
localparam DW = 40;
localparam TW = 24;
localparam BW = 64;
localparam [DW-1:0] DATA0 = 40'h123456789a;
localparam [DW-1:0] DATA1 = 40'hcecee6789a;
localparam [DW-1:0] DATA2 = 40'hceceebabee;
localparam [DW-1:0] DATA3 = 40'hbaedadface;
localparam S1 = DW-32;
localparam S0 = 32;
wire [S0-1:0] R0_S0 = DATA0[S0-1:0];
wire [S0-1:0] R1_S0 = DATA1[S0-1:0];
wire [S0-1:0] R2_S0 = DATA2[S0-1:0];
wire [S0-1:0] R3_S0 = DATA3[S0-1:0];
wire [S1-1:0] R0_S1 = DATA0[DW-1:S0];
wire [S1-1:0] R1_S1 = DATA1[DW-1:S0];
wire [S1-1:0] R2_S1 = DATA2[DW-1:S0];
wire [S1-1:0] R3_S1 = DATA3[DW-1:S0];
initial begin
  // Read back
  `wait_timeout(readback);
  if (to) begin
    $display("ERROR: Timeout waiting for readback assertion.");
    $stop(0);
  end
        lb_addr = 0;
  #TICK `CHECK(lb_out, R0_S0)
  #TICK lb_addr = lb_addr + 1;
  #TICK `CHECK(lb_out[S1-1:0], R0_S1)

  #TICK lb_addr = lb_addr + 1;
  #TICK `CHECK(lb_out, R1_S0)
  #TICK lb_addr = lb_addr + 1;
  #TICK `CHECK(lb_out[S1-1:0], R1_S1)

  #TICK lb_addr = lb_addr + 1;
  #TICK `CHECK(lb_out, R2_S0)
  #TICK lb_addr = lb_addr + 1;
  #TICK `CHECK(lb_out[S1-1:0], R2_S1)

  #TICK lb_addr = lb_addr + 1;
  #TICK `CHECK(lb_out, R3_S0)
  #TICK lb_addr = lb_addr + 1;
  #TICK `CHECK(lb_out[S1-1:0], R3_S1)

  vcd_write = 1'b1;
  lb_addr = 0;
  `wait_timeout(vcd_done);
  vcd_write = 1'b0;
  #(10*TICK)
  if (pass) begin
    $display("PASS");
    $finish(0);
  end else begin
    $display("FAIL");
    $stop(0);
  end
end
  `else
   `ifdef TEST_NORMAL
localparam DW = 8;
localparam TW = 24;
localparam BW = 32;
localparam [DW-1:0] DATA0 = 8'h9a;
localparam [DW-1:0] DATA1 = 8'hce;
localparam [DW-1:0] DATA2 = 8'hba;
localparam [DW-1:0] DATA3 = 8'hed;
initial begin
  // Read back
  `wait_timeout(readback);
  if (to) begin
    $display("ERROR: Timeout waiting for readback assertion.");
    $stop(0);
  end
  #TICK `CHECK(lb_out[DW-1:0], DATA0)
  #TICK lb_addr = lb_addr + 1;

  #TICK `CHECK(lb_out[DW-1:0], DATA1)
  #TICK lb_addr = lb_addr + 1;

  #TICK `CHECK(lb_out[DW-1:0], DATA2)
  #TICK lb_addr = lb_addr + 1;

  #TICK `CHECK(lb_out[DW-1:0], DATA3)

  vcd_write = 1'b1;
  lb_addr = 0;
  `wait_timeout(vcd_done);
  vcd_write = 1'b0;
  #(10*TICK)
  if (pass) begin
    $display("PASS");
    $finish(0);
  end else begin
    $display("FAIL");
    $stop(0);
  end
end

     `endif // TEST_NORMAL
    `endif // TEST_WIDE0
   `endif // TEST_WIDE1
  `endif // TEST_WIDE2
`endif // TEST_WIDE3

// ======================== VCD Writer from wctrace memory ====================
reg [DW-1:0] data=0;
reg [TW-1:0] time_out=0;
reg [BW-1:0] block=0;
`ifdef TEST_NORMAL
wire [BW-1:0] block_out = lb_out[BW-1:0];
`else
wire [BW-1:0] block_out = {lb_out, block[BW-33:0]};
`endif

reg header=1'b1;
integer vcd_fd;
initial begin
  vcd_fd = $fopen("testbench.vcd", "w");
end
reg [1:0] rdcntr=0;
reg [2:0] nbyte=0;
integer current_time=0;
wire do_read = rdcntr == 3;
always @(posedge clk) begin
  if (vcd_write) begin
    if (header) begin
      current_time <= 0;
      $fwrite(vcd_fd, "$version wctrace_tb $end\n");
      $fwrite(vcd_fd, "$timescale 1ns $end\n");
      $fwrite(vcd_fd, "$scope module TOP $end\n");
      $fwrite(vcd_fd, "$var wire %d a data $end\n", DW);
      $fwrite(vcd_fd, "$upscope $end\n");
      header <= 1'b0;
    end else begin
      if (~vcd_done) begin
        if (do_read) begin
          if (lb_addr == pc_mon) vcd_done <= 1'b1;
          else begin
`ifdef TEST_NORMAL
            // TEST_NORMAL
            if (0) begin // 32-bit
`else
  `ifdef TEST_WIDE0
            // TEST_WIDE0
            if (nbyte<1) begin // 64-bit
  `else
    `ifdef TEST_WIDE3
            if (nbyte<7) begin // 256-bit
    `else
            // TEST_WIDE1 and TEST_WIDE2
            if (nbyte<3) begin // 128-bit
    `endif // TEST_WIDE3
  `endif // TEST_WIDE0
`endif // TEST_NORMAL
              block[(32*(nbyte+1))-1-:32] <= lb_out;
              lb_addr <= lb_addr + 1;
              nbyte <= nbyte + 1;
            end else begin
              $fwrite(vcd_fd, "#%0d\n", (current_time+block_out[DW+TW-1:DW])*10); // TODO - get actual CLK_PERIOD_NS
              $fwrite(vcd_fd, "b%b a\n", block_out[DW-1:0]);
              current_time <= current_time + block_out[DW+TW-1:DW];
              nbyte <= 0;
              lb_addr <= lb_addr + 1;
            end
          end
        end
        rdcntr <= rdcntr + 1;
      end
    end
  end
end
// ============================================================================

// =================================== DUT ====================================
reg start=1'b0;
wire running;
wire [AW-1:0] pc_mon;
wctrace #(
  .AW(AW)
  ,.DW(DW)
  ,.TW(TW)
  ,.LOCAL_VCD("local.vcd")
) wctrace_i (
  .clk(clk), // input
  .data(data), // input [DW-1:0]
  .start(start), // input
  .running(running), // output
  .pc_mon(pc_mon), // output [AW-1:0]
  .lb_clk(clk), // input
  .lb_addr(lb_addr), // input [AW-1:0]
  .lb_out(lb_out) // output [31:0]
);
// ============================================================================

// ================================= Stimulus =================================
initial begin
             data = 0;
  #TICK      start = 1'b1;
  #TICK      start = 1'b0;
  #(2*TICK)  data = DATA0;
  #(8*TICK)  data = DATA1;
  #(1*TICK)  data = DATA2;
  #(20*TICK) data = DATA3;
  #(5*TICK)  data = 0;
  #(10*TICK) readback = 1'b1;
end
// ============================================================================

endmodule
