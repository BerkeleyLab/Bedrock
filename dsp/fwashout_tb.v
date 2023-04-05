`timescale 1ns / 1ns
`include "constants.vams"

module fwashout_tb;

   localparam CLK_PER = 10; // ns

   reg clk;
   integer cc;
   integer trace=0, out_file, simtime;
   real phstep;
   initial begin
      if ($test$plusargs("vcd")) begin
         $dumpfile("fwashout.vcd");
         $dumpvars(5,fwashout_tb);
      end

      if (!$value$plusargs("phstep=%f", phstep)) phstep=0.01; // Default 1 MHz
      if (!$value$plusargs("simtime=%f", simtime)) simtime=1000; // Default 1000*10 ns
      if ($test$plusargs("trace")) begin
         trace = 1;
         out_file = $fopen("fwashout.dat", "w");
      end
      for (cc=0; cc<simtime; cc=cc+1) begin
         clk=0; #(CLK_PER/2);
         clk=1; #(CLK_PER/2);
      end

      if (!trace) $display("WARNING: Not a self-checking testbench. Will always pass.");
      $display("PASS");
      $finish();
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
   fwashout #(
      .a_dw (16),
      .o_dw (16),
      .cut  (4)) // ~ 1e6 Hz
   dut (
      .clk      (clk),
      .rst      (1'b0),
      .track    (1'b1),
      .a_data   (adc_in),
      .a_gate   (1'b1), .a_trig (1'b0),
      .o_data   (adc_out),
      .o_gate   (), .o_trig (), // Ignore
      .time_err ()
   );

   always @(posedge clk) if (trace) begin
      $fwrite(out_file, "%d %d\n", adc_in, adc_out);
   end

endmodule
