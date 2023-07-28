`timescale 1ns / 1ns
`include "constants.vams"

module iq_deinterleaver_tb;

   // Configurable parameters
   parameter n_chan = 12;

   // Testbench stimulus
   localparam ADC_DWI = 18;
   localparam GUARD_BITS = 3; // Guard bits to keep in output of deinterleaver
   localparam SCALE_WI = 18;

   localparam ADC_DWI_EXT = ADC_DWI + GUARD_BITS;

   localparam CLK_PERIOD = 10;

   integer den, logden;
   reg [2:0] shift;
   real fden, fnum, ampi, ampo_expect, phsi, phs_marg;
   reg overload=0;

   integer num_tx=0;

   initial begin
      // Test not designed to work with phsi near pi
      // 4 <= den <= 128, no factor of fnum
      if (!$value$plusargs("amp=%f", ampi)) ampi=10000.0;
      if (!$value$plusargs("phs=%f", phsi)) phsi=0.0;
      if (!$value$plusargs("den=%d", den )) den=16;
      ampo_expect=ampi;
      phs_marg=0.00002;
      phs_marg=0.95/ampi;
      if (ampi > 32765.0) begin
         overload=1;
         ampo_expect=32764.0;
         phs_marg=0.2;
      end
      $display("ampi=%.2f  ampo_expect=%.2f  phsi=%.5f  phs_marg=%.5f",
               ampi, ampo_expect, phsi, phs_marg);
      fden=den;
      fnum=3.0;
      logden=$clog2(den);
      shift=logden-2;
      $display("den=%d  logden=%d  shift=%d", den, logden, shift);
   end

   reg clk;
   integer cc, errors;

   initial begin
      if ($test$plusargs("vcd")) begin
         $dumpfile("iq_deinterleaver.vcd");
         $dumpvars(5,iq_deinterleaver_tb);
      end
      errors=0;
      $display("    X1      Y1      X2      Y2     R1    OK   Phi1  OK");
      for (cc=0; cc<64*den; cc=cc+1) begin
         clk=0; #(CLK_PERIOD/2);
         clk=1; #(CLK_PERIOD/2);
      end

      if (num_tx == 0) begin
         $display("ERROR: No transactions, nothing was tested.");
         errors = errors + 1;
      end
      if (errors == 0) begin
        $display("PASS");
        $finish(0);
      end else begin
        $display("FAIL");
        $stop();
      end
   end

   // ---------------------
   // Generate stimulus
   // ---------------------

   reg signed [ADC_DWI-1:0] adc=0;
   integer noise;
   integer nseed=1234;

   integer ccmod;
   real th0, tha, thb;
   reg signed [ADC_DWI-1:0]  cosa=0, sina=0, cosb=0, sinb=0;
   reg signed [ADC_DWI-1:0] xcosa,  xsina,  xcosb,  xsinb;
   integer ax;  // can be huge in the face of clipping.  Don't be stupid and
           // set amplitude larger than 2^31 in ADC sine wave below.
           // 100 X overdrive is plenty for this purpose.

   // Stimulus code based on mon_12_tb.v
   always @(posedge clk) begin
      noise = $dist_normal(nseed,0,1024);
      th0 = (cc)*`M_TWO_PI*fnum/fden - phsi;
      ax = $floor(ampi*$cos(th0)+0.5+noise/1024.0);
      if (ax >  32767) ax =  32767;
      if (ax < -32678) ax = -32768;
      adc <= ax;
      // $display("%d adc", adc);
      ccmod = cc%den;
      tha = ccmod*`M_TWO_PI*fnum/fden;
      // Scaling of LO is non-obvious.  Set such that a square-wave input
      // can't overflow CIC.  Conceptually that's pi/2, so set to pi/4 of full
      // scale and absorb a factor of two later.
      // 2^17 = 131072 - a little bit to cover rounding
      xcosa = $floor(131070.0*$cos(tha)+0.5);  cosa <= xcosa;
      xsina = $floor(131070.0*$sin(tha)+0.5);  sina <= xsina;
   end

   // TODO: Make this pseudo-random
   reg signed [17:0] scale_in = 18'd65536;

   // Interleave I and Q
   wire [ADC_DWI-1:0] iq_data_in;
   reg                  iq_sel = 0;

   always @(posedge clk) begin
      iq_sel <= ~iq_sel;
   end

   assign iq_data_in = iq_sel ? cosa : sina;

   // ---------------------
   // Instantiate DUT
   // ---------------------

   wire [ADC_DWI_EXT-1:0] i_dout, q_dout;
   wire iq_valid_out;

   iq_deinterleaver #(
      .scale_wi (SCALE_WI),
      .dwi      (ADC_DWI),
      .davr     (GUARD_BITS))
   i_dut (
      .clk        (clk),
      .scale_in   (scale_in),
      .iq_data_in (iq_data_in),
      .iq_sel     (iq_sel),
      .valid_out  (iq_valid_out),
      .i_data_out (i_dout),
      .q_data_out (q_dout)
   );


   // ---------------------
   // Scoreboarding
   // ---------------------

   wire scb_full, scb_empty;
   reg  iq_model_valid = 0, iq_model_valid_r = 0;
   reg  signed [ADC_DWI+SCALE_WI-1:0] model_data;
   wire signed [ADC_DWI_EXT-1:0] model_data_shift;

   reg  [(ADC_DWI_EXT)*2-1:0] iq_model_in;
   wire [(ADC_DWI_EXT)*2-1:0] iq_model_out;
   wire [(ADC_DWI_EXT)-1:0]   i_model_out, q_model_out;

   always @(*) begin
      model_data = iq_sel ? cosa : sina;
      model_data = model_data*scale_in;
   end
   assign model_data_shift = model_data[ADC_DWI+SCALE_WI-2:SCALE_WI-GUARD_BITS-1];

   always @(posedge clk) begin
      iq_model_in      <= {iq_model_in[ADC_DWI_EXT-1:0], model_data_shift};
      iq_model_valid   <= iq_sel ? 1'b1 : 1'b0;
      iq_model_valid_r <= iq_model_valid;
   end

   // Push expected output to FIFO and pop on i_dut.valid_out
   shortfifo #(
      .aw (4), // Must cover latency of DUT
      .dw ((ADC_DWI_EXT)*2))
   i_scb_fifo (
      .clk         (clk),
      .din         (iq_model_in),
      .we          (iq_model_valid_r),
      .dout        ({i_model_out, q_model_out}),
      .re          (iq_valid_out),
      .full        (scb_full), // Should never go high
      .empty       (scb_empty),
      .last        (),
      .count       ()
   );

   always @(posedge clk) begin
      if (scb_full) begin
         $display("ERROR: FIFO went full");
         errors = errors + 1;
      end

      if (iq_valid_out) begin
         num_tx = num_tx + 1;

         if (scb_empty) begin
            $display("ERROR: FIFO empty when trying to pop");
            errors = errors + 1;
         end

         if (i_dout != i_model_out) begin
            $display("ERROR: I_DATA_OUT mismatch");
            errors = errors + 1;
         end
         if (q_dout != q_model_out) begin
            $display("ERROR: Q_DATA_OUT mismatch");
            errors = errors + 1;
         end

      end
   end

endmodule
