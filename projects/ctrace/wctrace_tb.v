`timescale 1ns/1ns

//`define TEST_WIDE2
//`define TEST_WIDE1
//`define TEST_WIDE0
//`define TEST_NORMAL

module wctrace_tb;

localparam CLK_HALFPERIOD = 5;
localparam TICK = 2*CLK_HALFPERIOD;
reg clk=1'b0;
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

`ifdef TEST_WIDE2
localparam DW = 104;
reg [DW-1:0] data=0;
localparam TW = 24;
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
wire [S2-1:0] R0_S3 = DATA0[DW-1:S0+S1+S2];
wire [S2-1:0] R1_S3 = DATA1[DW-1:S0+S1+S2];
wire [S2-1:0] R2_S3 = DATA2[DW-1:S0+S1+S2];
wire [S2-1:0] R3_S3 = DATA3[DW-1:S0+S1+S2];

initial begin
  // Read back
  `wait_timeout(readback);
  if (to) begin
    $display("ERROR: Timeout waiting for readback assertion.");
    $stop(0);
  end
  #TICK lb_addr <= lb_addr + 1;
        data <= 0;
  #TICK lb_addr <= lb_addr + 1;
  #TICK lb_addr <= lb_addr + 1;
  #TICK lb_addr <= lb_addr + 1;

  #TICK `CHECK(lb_out, R0_S0)
  #TICK lb_addr <= lb_addr + 1;
  #TICK `CHECK(lb_out[S1-1:0], R0_S1)
  #TICK lb_addr <= lb_addr + 1;
  #TICK `CHECK(lb_out[S2-1:0], R0_S2)
  #TICK lb_addr <= lb_addr + 1;
  #TICK `CHECK(lb_out[S3-1:0], R0_S3)

  #TICK lb_addr <= lb_addr + 1;
  #TICK `CHECK(lb_out, R1_S0)
  #TICK lb_addr <= lb_addr + 1;
  #TICK `CHECK(lb_out[S1-1:0], R1_S1)
  #TICK lb_addr <= lb_addr + 1;
  #TICK `CHECK(lb_out[S2-1:0], R1_S2)
  #TICK lb_addr <= lb_addr + 1;
  #TICK `CHECK(lb_out[S3-1:0], R1_S3)

  #TICK lb_addr <= lb_addr + 1;
  #TICK `CHECK(lb_out, R2_S0)
  #TICK lb_addr <= lb_addr + 1;
  #TICK `CHECK(lb_out[S1-1:0], R2_S1)
  #TICK lb_addr <= lb_addr + 1;
  #TICK `CHECK(lb_out[S2-1:0], R2_S2)
  #TICK lb_addr <= lb_addr + 1;
  #TICK `CHECK(lb_out[S3-1:0], R2_S3)

  #TICK lb_addr <= lb_addr + 1;
  #TICK `CHECK(lb_out, R3_S0)
  #TICK lb_addr <= lb_addr + 1;
  #TICK `CHECK(lb_out[S1-1:0], R3_S1)
  #TICK lb_addr <= lb_addr + 1;
  #TICK `CHECK(lb_out[S2-1:0], R3_S2)
  #TICK lb_addr <= lb_addr + 1;
  #TICK `CHECK(lb_out[S3-1:0], R3_S3)

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
reg [DW-1:0] data=0;
localparam TW = 24;
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
  #TICK  lb_addr <= lb_addr + 1;
        data <= 0;
  #TICK lb_addr <= lb_addr + 1;
  #TICK lb_addr <= lb_addr + 1;
  #TICK lb_addr <= lb_addr + 1;

  #TICK `CHECK(lb_out, R0_S0)
  #TICK lb_addr <= lb_addr + 1;
  #TICK `CHECK(lb_out[S1-1:0], R0_S1)
  #TICK lb_addr <= lb_addr + 1;
  #TICK `CHECK(lb_out[S2-1:0], R0_S2)
  #TICK lb_addr <= lb_addr + 1;
  #TICK `CHECK(lb_out, 32'h0)

  #TICK lb_addr <= lb_addr + 1;
  #TICK `CHECK(lb_out, R1_S0)
  #TICK lb_addr <= lb_addr + 1;
  #TICK `CHECK(lb_out[S1-1:0], R1_S1)
  #TICK lb_addr <= lb_addr + 1;
  #TICK `CHECK(lb_out[S2-1:0], R1_S2)
  #TICK lb_addr <= lb_addr + 1;
  #TICK `CHECK(lb_out, 32'h0)

  #TICK lb_addr <= lb_addr + 1;
  #TICK `CHECK(lb_out, R2_S0)
  #TICK lb_addr <= lb_addr + 1;
  #TICK `CHECK(lb_out[S1-1:0], R2_S1)
  #TICK lb_addr <= lb_addr + 1;
  #TICK `CHECK(lb_out[S2-1:0], R2_S2)
  #TICK lb_addr <= lb_addr + 1;
  #TICK `CHECK(lb_out, 32'h0)

  #TICK lb_addr <= lb_addr + 1;
  #TICK `CHECK(lb_out, R3_S0)
  #TICK lb_addr <= lb_addr + 1;
  #TICK `CHECK(lb_out[S1-1:0], R3_S1)
  #TICK lb_addr <= lb_addr + 1;
  #TICK `CHECK(lb_out[S2-1:0], R3_S2)
  #TICK lb_addr <= lb_addr + 1;
  #TICK `CHECK(lb_out, 32'h0)

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
reg [DW-1:0] data=0;
localparam TW = 24;
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
  #TICK lb_addr <= lb_addr + 1;
  #TICK lb_addr <= lb_addr + 1;
        data <= 0;
  //#TICK if (lb_out != R0_S0) begin $display("[%x] Miss: %x != %x", lb_addr, lb_out, R0_S0); pass <= 1'b0; end
  #TICK `CHECK(lb_out, R0_S0)
  #TICK lb_addr <= lb_addr + 1;
  #TICK `CHECK(lb_out[S1-1:0], R0_S1)

  #TICK lb_addr <= lb_addr + 1;
  #TICK `CHECK(lb_out, R1_S0)
  #TICK lb_addr <= lb_addr + 1;
  #TICK `CHECK(lb_out[S1-1:0], R1_S1)

  #TICK lb_addr <= lb_addr + 1;
  #TICK `CHECK(lb_out, R2_S0)
  #TICK lb_addr <= lb_addr + 1;
  #TICK `CHECK(lb_out[S1-1:0], R2_S1)

  #TICK lb_addr <= lb_addr + 1;
  #TICK `CHECK(lb_out, R3_S0)
  #TICK lb_addr <= lb_addr + 1;
  #TICK `CHECK(lb_out[S1-1:0], R3_S1)

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
reg [DW-1:0] data=0;
localparam TW = 24;
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
  #TICK lb_addr <= lb_addr + 1;
        data <= 0;
  #TICK `CHECK(lb_out[DW-1:0], DATA0)

  #TICK lb_addr <= lb_addr + 1;
  #TICK `CHECK(lb_out[DW-1:0], DATA1)

  #TICK lb_addr <= lb_addr + 1;
  #TICK `CHECK(lb_out[DW-1:0], DATA2)

  #TICK lb_addr <= lb_addr + 1;
  #TICK `CHECK(lb_out[DW-1:0], DATA3)

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

reg start=1'b0;
wire running;
wire [AW-1:0] pc_mon;
wctrace #(
  .AW(AW)
  ,.DW(DW)
  ,.TW(TW)
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

// =========== Stimulus =============
initial begin
  #TICK      start = 1'b1;
  #TICK      start = 1'b0;
  #(2*TICK)  data = DATA0;
  #(8*TICK)  data = DATA1;
  #(10*TICK) data = DATA2;
  #(20*TICK) data = DATA3;
  #(10*TICK) readback = 1'b1;
end

endmodule
