`timescale 1ns/1ns

module dna_tb;

localparam CLK_HALFPERIOD = 5;
localparam TICK = 2*CLK_HALFPERIOD;
reg clk=1'b0;
always #CLK_HALFPERIOD clk <= ~clk;

// VCD dump file for gtkwave
initial begin
  if ($test$plusargs("vcd")) begin
    $dumpfile("dna.vcd");
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

reg rst=1'b0;
reg start=1'b0;
wire done;
wire [31:0] dna_msb;
wire [31:0] dna_lsb;
dna dna_i (
  .clk(clk), // input
  .rst(rst), // input
  .start(start), // input
  .done(done), // output
  .dna_msb(dna_msb), // output [31:0]
  .dna_lsb(dna_lsb) // output [31:0]
);

reg [31:0] target_lsb;
reg [31:0] target_msb;

// =========== Stimulus =============
initial begin
  target_lsb = dna_i.r_dna_int[38:7];
  target_msb = dna_i.r_dna_int[63:39];
  #TICK start = 1'b1;
  #(4*TICK) `wait_timeout(~done);
  #(4*TICK) `wait_timeout(done);
  if (to) begin
    $display("ERROR: Timed out waiting for DNA readout.");
    $stop(0);
  end else begin
    if ((dna_msb != target_msb) || (dna_lsb != target_lsb)) begin
      $display("ERROR: DNA mismatch: ");
      $display("  dna_msb = 0x%x; target_msb = 0x%x", dna_msb, target_msb);
      $display("  dna_lsb = 0x%x; target_lsb = 0x%x", dna_lsb, target_lsb);
      $stop(0);
    end
  end
  $display("DNA Match.\nPASS");
  $finish(0);
end

endmodule
