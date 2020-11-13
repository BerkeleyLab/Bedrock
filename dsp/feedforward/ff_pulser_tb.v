`timescale 1ns / 1ns

module ff_pulser_tb;

   reg clk;
   integer cc;
   reg fail=0;

   initial begin
      if ($test$plusargs("vcd")) begin
         $dumpfile("ff_pulser.vcd");
         $dumpvars(5, ff_pulser_tb);
      end

      for (cc=0; cc<(5000); cc=cc+1) begin
         clk=0; #5;
         clk=1; #5;
      end
      $display("%s", fail ? "FAIL" : "PASS");
      if (fail) $stop();
   end

   reg start=0;
   always @(posedge clk) start <= (cc == 10) || (cc == 1500);

   localparam LWI = 20, DWI=18;
   reg [LWI-1:0] ff_length=100;
   reg [DWI-2:0] ff_slew_limit=50;
   reg [DWI-1:0] ff_setp_x=200, ff_setp_y=-300;
   wire signed [DWI-1:0] ff_out_x, ff_out_y;

   ff_pulser #(.LENGTH_WI(LWI), .DWI(DWI)) i_dut (
      .clk    (clk),
      .start  (start),
      .busy   (),
      .length (ff_length),
      .slew_limit  (ff_slew_limit),
      .setp_x (ff_setp_x),
      .setp_y (ff_setp_y),
      .out_x  (ff_out_x),
      .out_y  (ff_out_y));

endmodule
