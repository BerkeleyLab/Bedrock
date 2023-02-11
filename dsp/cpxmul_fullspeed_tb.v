`timescale 1ns / 1ns

module cpxmul_fullspeed_tb;

   localparam SIM_TIME = 50000; // ns
   localparam CLKP = 10; // ns

   // Purposefully narrow to cover more of the input state space
   localparam DWI = 8;
   localparam OUT_SHIFT = 7;
   localparam OWI = 8;

   reg clk;
   integer errors=0;

   initial begin
      if ($test$plusargs("vcd")) begin
         $dumpfile("cpxmul_fullspeed.vcd");
         $dumpvars(5, cpxmul_fullspeed_tb);
      end

      forever begin
         clk=0; #(CLKP/2);
         clk=1; #(CLKP/2);
         if ($time > SIM_TIME) begin
           if (errors == 0) begin
             $display("PASS");
             $finish();
           end else begin
             $display("FAIL");
             $stop();
           end
         end
      end

   end

   // ---------------------
   // Generate stimulus
   // ---------------------
   reg signed [DWI-1:0] re_a;
   reg signed [DWI-1:0] im_a;
   reg signed [DWI-1:0] re_b;
   reg signed [DWI-1:0] im_b;

   integer seed=1234;

   initial begin
      // Start with corner cases then move to (constrained) random
      re_a <= ~0; im_a <= $random(seed);
      re_b <= $random(seed); im_b <= ~0;
      @(posedge clk);
      re_a <= ~0; im_a <= ~0;
      re_b <= ~0; im_b <= ~0;
      @(posedge clk);
      re_a <= (1<<(DWI-1)); im_a <= ~0;
      re_b <= ~0; im_b <= (1<<(DWI-1));
      @(posedge clk);
      re_a <= (1<<(DWI-1)-1); im_a <= (1<<(DWI-1)-1);
      re_b <= (1<<(DWI-1)-1); im_b <= (1<<(DWI-1)-1);
      @(posedge clk);

      forever begin
         @(posedge clk);
         re_a <= $random(seed);
         im_a <= $random(seed);
         re_b <= $random(seed);
         im_b <= $random(seed);
      end
   end

   // ---------------------
   // DUT
   // ---------------------
   wire signed [OWI-1:0] re_out;
   wire signed [OWI-1:0] im_out;

   cpxmul_fullspeed #(
      .DWI       (DWI),
      .OUT_SHIFT (OUT_SHIFT),
      .OWI       (OWI)
   ) i_dut (
      .clk    (clk),
      .re_a   (re_a),
      .im_a   (im_a),
      .re_b   (re_b),
      .im_b   (im_b),
      .re_out (re_out),
      .im_out (im_out)
   );

   // ---------------------
   // Scoreboard
   // ---------------------

   // Truncate to OWI
   function [OWI-1:0] to_owi;
      input signed [DWI*2-1:0] dat;
   begin
      if (OWI >= (DWI*2))
         to_owi = dat; // Auto sign-extend
      else begin
         if (dat < (1<<(OWI-1)) && dat >= -(1<<(OWI-1)))
            to_owi = dat[OWI-1:0];
         else
            to_owi = {dat[DWI*2-1], {(OWI-1){~dat[DWI*2-1]}}}; // Saturate
      end
   end endfunction

   wire signed [DWI*2-1:0] cpx_re, cpx_im;
   wire signed [OWI-1:0] cpx_re_t, cpx_im_t;
   wire signed [OWI-1:0] cpx_re_r, cpx_im_r;

   // (re_a*re_b - im_a*im_b) + j(re_a*im_b + im_a*re_b)
   assign cpx_re = (re_a*re_b - im_a*im_b) >>> OUT_SHIFT;
   assign cpx_im = (re_a*im_b + im_a*re_b) >>> OUT_SHIFT;
   assign cpx_re_t = to_owi(cpx_re);
   assign cpx_im_t = to_owi(cpx_im);

   // Enforce 3-cycle pipeline delay
   reg_delay #(.dw(OWI*2), .len(3)) i_reg_delay (
      .clk   (clk),
      .reset (1'b0),
      .gate  (1'b1),
      .din   ({cpx_re_t, cpx_im_t}),
      .dout  ({cpx_re_r, cpx_im_r})
   );

   always @(posedge clk) begin
      if (cpx_re_r != re_out || cpx_im_r != im_out) begin
         errors <= errors + 1;
         $display("ERROR: (%d, %d), expected (%d, %d)", re_out, im_out, cpx_re_r, cpx_im_r);
         $fatal;
      end
   end

endmodule
