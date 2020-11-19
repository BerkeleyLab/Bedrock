`timescale 1ns / 1ns

module ff_pulser_tb;

   localparam SIM_TIME = 30000; // ns
   localparam CLK_PER=10;

   reg clk=0;
   always begin clk = ~clk; #(CLK_PER/2); end

   reg fail=0;
   integer seed_int=123;
   initial begin
      if ($test$plusargs("vcd")) begin
         $dumpfile("ff_pulser.vcd");
         $dumpvars(5, ff_pulser_tb);
      end

      while ($time < SIM_TIME) @(posedge clk);

      $display("%s", fail ? "FAIL" : "PASS");
      if (~fail) begin
         $display("PASS");
         $finish;
      end else begin
         $display("FAIL");
         $stop;
      end
   end

   localparam LWI = 20, DWI=18;

   // ----------------------
   // Generate stimulus
   // ----------------------
   reg start=0;
   wire busy;
   reg [LWI-1:0] ff_length=100;
   reg [DWI-2:0] ff_slew_limit=400;
   reg [DWI-1:0] ff_setp_x=200, ff_setp_y=-300;

   integer stim_mode;
   always begin
      while (busy) @(posedge clk);
      #((10 + $urandom(seed_int)%20)*CLK_PER);
      @(posedge clk)
      // Setup pulse
      ff_length = 100 + $urandom(seed_int)%100;

      stim_mode = $urandom(seed_int)%100;
      if (stim_mode < 20) begin // Around zero
         ff_setp_x = $urandom(seed_int)%300 - 150;
         ff_setp_y = $urandom(seed_int)%300 - 150;
      end else if (stim_mode > 80) begin // Around max
         ff_setp_x = (1<<(DWI-1)) - $urandom(seed_int)%300;
         ff_setp_y = (1<<(DWI-1)) - $urandom(seed_int)%300;
      end else begin // random
         ff_setp_x = $random(seed_int);
         ff_setp_y = $random(seed_int);
      end
      ff_slew_limit = 1 + $urandom(seed_int)%(1<<(DWI-3));
      #(10*CLK_PER); // Quasi-static settings
      @(posedge clk);

      start = 1;
      @(posedge clk);
      start = 0;
      while (!busy) @(posedge clk); // Wait for busy
   end

   wire signed [DWI-1:0] ff_out_x, ff_out_y;

   // ----------------------
   // DUT
   // ----------------------
   ff_pulser #(.LENGTH_WI(LWI), .DWI(DWI)) i_dut (
      .clk    (clk),
      .start  (start),
      .busy   (busy),
      .length (ff_length),
      .slew_limit  (ff_slew_limit),
      .setp_x (ff_setp_x),
      .setp_y (ff_setp_y),
      .out_x  (ff_out_x),
      .out_y  (ff_out_y));

   // ----------------------
   // Scoreboard
   // ----------------------


endmodule
