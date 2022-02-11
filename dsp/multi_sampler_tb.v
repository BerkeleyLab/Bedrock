`timescale 1ns / 1ns
// A stupid simple test bench.
module multi_sampler_tb;

   localparam SIM_TIME = 8000;

   reg clk, trace;
   integer cc, endcc;
   initial begin
      if ($test$plusargs("vcd")) begin
         $dumpfile("multi_sampler.vcd");
         $dumpvars(5, multi_sampler_tb);
      end
      for (cc=0; cc<SIM_TIME; cc=cc+1) begin
         clk=0; #5;
         clk=1; #5;
      end
      $finish();
   end

   reg reset = 0, ext_trig = 0;
   always @(posedge clk) begin
       @(cc==30) begin
           reset <= 1;
           ext_trig <= 0;
       end

       @(cc==50) begin
            reset <= 0;
            ext_trig <= 1;
       end
    end

    wire sample_out, sample0, sample1, sample2;

   // ---------------------
   // Instantiate DUT
   // ---------------------

   multi_sampler #(
      .sample_period_wi (6),
      .dsample0_en      (1),
      .dsample0_wi      (6),
      .dsample1_en      (1),
      .dsample1_wi      (6),
      .dsample2_en      (1),
      .dsample2_wi      (6))
   i_dut (
      .clk             (clk),
      .reset           (reset),
      .ext_trig        (ext_trig),

      .sample_period        (6'd33),
      .dsample0_period      (6'd32),
      .dsample1_period      (6'd32), //LCLS-II values, piezo sample
      .dsample2_period      (6'd1),
      .sample_out           (sample_out),
      .dsample0_stb         (sample0),
      .dsample1_stb         (sample1),
      .dsample2_stb         (sample2)
   );

endmodule
