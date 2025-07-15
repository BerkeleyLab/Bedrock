`timescale 1ns / 1ns
`include "constants.vams"

module lpass1_tb;

   localparam CLK_PER = 10; // ns

   reg clk;
   integer cc;
   integer trace=0, out_file, simtime;
   real phstep;
   initial begin
      if ($test$plusargs("vcd")) begin
         $dumpfile("lpass1.vcd");
         $dumpvars(5,lpass1_tb);
      end

      if (!$value$plusargs("phstep=%f", phstep)) phstep=0.01; // Default 1 MHz
      if (!$value$plusargs("simtime=%f", simtime)) simtime=20000; // Default 20000*10 ns
      if ($test$plusargs("trace")) begin
         trace = 1;
         out_file = $fopen("lpass1.dat", "w");
      end
      for (cc=0; cc<simtime; cc=cc+1) begin
         clk=0; #(CLK_PER/2);
         clk=1; #(CLK_PER/2);
      end

      if (!trace) $display("WARNING: Not a self-checking testbench. Will always pass.");
      $display("PASS");
      $finish(0);
   end

   reg signed [15:0] adc_in=0;
   wire signed [15:0] adc_out;

   real th0;
   integer ax;

   always @(posedge clk) begin
      th0 = (cc)*`M_TWO_PI*phstep;
      ax = $floor(15000.0*$cos(th0)+0.5);
      adc_in <= ax;
   end

   // Instantiate DUT
   lpass1 #(
      .dwi (16),
      .klog2 (8))
   dut (
      .clk     (clk),
      .trim_sh (2'd1), // (8-1) = 7: fc ~= 1e5 Hz
      .din     (adc_in),
      .dout    (adc_out));

   always @(posedge clk) if (trace) begin
      $fwrite(out_file, "%d %d\n", adc_in, adc_out);
   end

endmodule
