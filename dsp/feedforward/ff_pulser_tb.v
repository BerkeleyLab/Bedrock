`timescale 1ns / 1ns

module ff_pulser_tb;

   localparam SIM_TIME = 50000; // ns
   localparam CLK_PER=10;

   reg clk=0;
   always begin clk = ~clk; #(CLK_PER/2); end

   integer start_cnt=0, pulse_cnt=0, faults=0;
   reg fail=0;
   integer seed_int=123;
   initial begin
      if ($test$plusargs("vcd")) begin
         $dumpfile("ff_pulser.vcd");
         $dumpvars(5, ff_pulser_tb);
      end

      while ($time < SIM_TIME) @(posedge clk);

      if (start_cnt != pulse_cnt) begin
         $display("FAIL (%t): Start trigger and pulse mismatch", $time);
         fail |= 1;
      end
      if (faults>0) fail |= 1;
      if (!fail) begin
         $display("PASS");
         $finish;
      end else begin
         $display("FAIL");
         $stop;
      end
   end

   localparam LWI = 32, DWI=18;

   // ----------------------
   // Generate stimulus
   // ----------------------
   function integer abs;
      input integer a;
   begin
      abs = a<0 ? -a : a;
   end endfunction

   function integer max_abs;
      input integer a, b;
   begin
      a = abs(a);
      b = abs(b);
      max_abs = a>b ? a : b;
   end endfunction

   reg start=0;
   wire busy;
   reg [LWI-1:0] ff_length=100;
   reg [DWI-2:0] ff_slew_lim=400;
   reg signed [DWI-1:0] ff_setp_x=200, ff_setp_y=-300;

   integer stim_mode;
   integer max_setp;
   always begin
      while (busy) @(posedge clk);
      #((10 + $urandom(seed_int)%20)*CLK_PER);
      @(posedge clk)

      // Setup pulse
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

      max_setp = max_abs(ff_setp_x, ff_setp_y);
      ff_slew_lim = max_setp/(1+$urandom(seed_int)%9);
      ff_length = 10 + 2*max_setp/ff_slew_lim + $urandom(seed_int)%100;

      #(10*CLK_PER); // Quasi-static settings

      @(posedge clk);
      start <= 1;
      @(posedge clk);
      start <= 0;
      while (!busy) @(posedge clk); // Wait for busy
   end

   wire signed [DWI-1:0] ff_out_x, ff_out_y;

   // ----------------------
   // DUT
   // ----------------------
   ff_pulser i_dut (
      .clk        (clk),
      .start      (start),
      .busy       (busy),
      .length     (ff_length),
      .slew_lim   (ff_slew_lim),
      .setp_x     (ff_setp_x),
      .setp_y     (ff_setp_y),
      .out_x      (ff_out_x),
      .out_y      (ff_out_y));

   // ----------------------
   // Scoreboard
   // ----------------------

   integer len_cnt=0;
   reg busy_r=0;
   reg pulsing=0, pulsing_r=0;
   reg x_rail=0, y_rail=0;

   wire x_zero = ff_out_x==0;
   wire y_zero = ff_out_y==0;
   always @(posedge clk) begin
      busy_r <= busy;
      if (~busy && (!x_zero || !y_zero)) begin
         $display("FAIL (%t): Non-zero output while not busy", $time);
         faults <= faults+1;
      end

      if ((abs(ff_out_x) > abs(ff_setp_x)) ||
          (abs(ff_out_y) > abs(ff_setp_y))) begin
         $display("FAIL (%t): Setpoint exceeded", $time);
         faults <= faults+1;
      end

      if (ff_out_x == ff_setp_x) x_rail <= 1;
      if (ff_out_y == ff_setp_y) y_rail <= 1;

      if (start) start_cnt <= start_cnt + 1;
      if (busy && ~busy_r) pulse_cnt <= pulse_cnt + 1;

      if (!x_zero || !y_zero) pulsing <= 1;
      if (x_zero && y_zero) pulsing <= 0;
      pulsing_r <= pulsing;

      len_cnt <= pulsing ? len_cnt + 1 : 0;

      if (!pulsing && pulsing_r) begin
         if (len_cnt != ff_length) begin
            $display("FAIL (%t): Incorrect pulse length. Expected (%d), got (%d)",
                     $time, ff_length, len_cnt);
            faults <= faults+1;
         end
         if (!x_rail || !y_rail) begin
            $display("FAIL (%t): X or Y setpoint not reached", $time);
            faults <= faults+1;
         end
         {y_rail, x_rail} <= 0;
      end
   end

endmodule
