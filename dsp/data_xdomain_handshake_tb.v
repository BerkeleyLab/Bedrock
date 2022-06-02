`timescale 1ns/1ns

module data_xdomain_handshake_tb;

parameter CLK_IN_HALF_PERIOD = 10;
parameter CLK_OUT_HALF_PERIOD = 5;
parameter DATA_WIDTH = 18;

reg clk_in;
reg clk_out;
reg gate_in=0;
wire gate_out;
wire busy;
reg [DATA_WIDTH-1:0] data_in=0;
wire [DATA_WIDTH-1:0] data_out;
reg [31:0] error_count;

// Create the main clocks
initial begin
  clk_in = 0;
  #5;
  forever clk_in = #( CLK_IN_HALF_PERIOD ) ~clk_in;
end

initial begin
  clk_out = 0;
  #5;
  forever clk_out = #( CLK_OUT_HALF_PERIOD ) ~clk_out;
end

initial begin
  $dumpfile("data_xdomain_handshake_tb.vcd");
  $dumpvars(0,data_xdomain_handshake_tb);
  error_count = 0;
  repeat (4) @ (posedge clk_in);
  $display("%0t, Begin CDC Handshake test", $time);
  data_in <= 69;
  gate_in <= 1;
  repeat (2) @ (posedge clk_in);
  gate_in <= 0;
  repeat (20) @ (posedge clk_in);
  $display("%0t, Test Complete with %d errors", $time, error_count);
  $finish;
end


// DUT Instantiation
data_xdomain_handshake #(.width(DATA_WIDTH)) dut(
  .clk_in   (clk_in),
  .gate_in  (gate_in),
  .data_in  (data_in),
  .clk_out  (clk_out),
  .gate_out (gate_out),
  .data_out (data_out),
  .busy     (busy)
);

endmodule