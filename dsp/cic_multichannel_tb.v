`timescale 1ns / 1ns
`include "constants.vams"

module cic_multichannel_tb;

   // Configurable parameters
   parameter n_chan = 12;

   // Testbench stimulus
   localparam ADC_DWI = 16;
   localparam MULT_GUARD_BITS = 3; // Guard bits to keep in output of mixer
   localparam OSC_WIDTH = 18; // Width of local oscillator

   localparam CLK_PERIOD = 10;
   localparam CLK_SLOW_RATIO = 2; // TODO: Make this programmable
   localparam CLK_PER_SLOW = CLK_PERIOD*CLK_SLOW_RATIO;

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

   reg clk, slow_clk;
   integer cc, errors;

   initial begin
      if ($test$plusargs("vcd")) begin
         $dumpfile("cic_multichannel.vcd");
         $dumpvars(5,cic_multichannel_tb);
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

   integer cc_s;

   initial begin
      for (cc_s=0; cc_s <64*den*CLK_SLOW_RATIO; cc_s = cc_s + 1) begin
         slow_clk=0; #(CLK_PER_SLOW/2);
         slow_clk=1; #(CLK_PER_SLOW/2);
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
   reg signed [OSC_WIDTH-1:0]  cosa=0, sina=0, cosb=0, sinb=0;
   reg signed [OSC_WIDTH-1:0] xcosa,  xsina,  xcosb,  xsinb;
   integer ax;  // can be huge in the face of clipping.  Don't be stupid and
           // set amplitude larger than 2^31 in ADC sine wave below.
           // 100 X overdrive is plenty for this purpose.
   reg sample=0;

   reg stb_in=0;

   // Generate stimulus at half rate to test strobe capability
   // Stimulus code based on mon_12_tb.v
   // TODO: Make this configurable
   always @(posedge clk) begin
      stb_in <= ~stb_in;
   end
   always @(posedge slow_clk) begin
      noise = $dist_normal(nseed,0,1024);
      th0 = (cc_s)*`M_TWO_PI*fnum/fden - phsi;
      ax = $floor(ampi*$cos(th0)+0.5+noise/1024.0);
      if (ax >  32767) ax =  32767;
      if (ax < -32678) ax = -32768;
      adc <= ax;
      // $display("%d adc", adc);
      ccmod = cc_s%den;
      tha = ccmod*`M_TWO_PI*fnum/fden;
      // Scaling of LO is non-obvious.  Set such that a square-wave input
      // can't overflow CIC.  Conceptually that's pi/2, so set to pi/4 of full
      // scale and absorb a factor of two later.
      // 2^17 = 131072 - a little bit to cover rounding
      xcosa = $floor(131070.0*$cos(tha)+0.5);  cosa <= xcosa;
      xsina = $floor(131070.0*$sin(tha)+0.5);  sina <= xsina;
      thb = ccmod*`M_TWO_PI*7.0/fden;
      xcosb = $floor(13107.00*$cos(tha)+0.5);  cosb <= xcosb;
      xsinb = $floor(13107.00*$sin(tha)+0.5);  sinb <= xsinb;
      sample <= ccmod==0;
   end

   // ---------------------
   // Instantiate Mixers
   // ---------------------

   wire signed [ADC_DWI+MULT_GUARD_BITS-1:0] adc_a_cos, adc_a_sin, adc_b_cos, adc_b_sin;

   mixer #(
      .dwi(ADC_DWI),
      .davr(MULT_GUARD_BITS),
      .dwlo(OSC_WIDTH))
   i_mixer_a_cos (
      .clk(slow_clk),
      .adcf(adc),
      .mult(cosa),
      .mixout(adc_a_cos)
   );

   mixer #(
      .dwi(ADC_DWI),
      .davr(MULT_GUARD_BITS),
      .dwlo(OSC_WIDTH))
   i_mixer_a_sin (
      .clk(slow_clk),
      .adcf(adc),
      .mult(sina),
      .mixout(adc_a_sin)
   );

   // ---------------------
   // Instantiate Sampler
   // ---------------------
   wire cic_sample, cc_sample;

   multi_sampler #(
      .sample_period_wi(8),
      .dsample0_en(1),
      .dsample0_wi(8),
      .dsample1_en(0),
      .dsample1_wi(8),
      .dsample2_en(0),
      .dsample2_wi(8))
   i_multi_sampler (
      .clk(clk),
      .reset(1'b0),
      .ext_trig(1'b1),
      .sample_period({den[6:0],1'b0}),
      .dsample0_period(8'h1),
      .dsample1_period(8'h1),
      .dsample2_period(8'h1),
      .sample_out(cic_sample),
      .dsample0_stb(cc_sample),
      .dsample1_stb(), // Unused output
      .dsample2_stb()  // Unused output
   );

   // ---------------------
   // Instantiate DUT
   // ---------------------

   wire sr_val;
   wire [19:0] sr_out;
   wire [n_chan*(ADC_DWI+MULT_GUARD_BITS)-1:0] d_in_flat;

   wire di_stb_out;
   wire [31:0] di_sr_out;

   assign d_in_flat = {{(n_chan-4)*(ADC_DWI+MULT_GUARD_BITS){1'b0}},
                       adc_a_sin,
                       adc_a_cos,
                       adc_a_sin,
                       adc_a_cos};

   cic_multichannel #(
      .n_chan        (n_chan),

      // DI parameters
      .di_dwi        (ADC_DWI+MULT_GUARD_BITS),  // data width
      .di_rwi        (32),  // result width
                            // Difference between above two widths should be N*log2 of the maximum number
                            // of samples per CIC sample, where N=2 is the order of the CIC filter.

      .di_noise_bits (1),   // NOTE: Setting to 1 to compensate for removed /2 from double_inte
      .cc_outw       (20),  // CCFilt output width; Must be 20 if using half-band filter
      .cc_halfband   (1),
      .cc_use_delay  (0),   // Match pipeline length of filt_halfband=1
      .cc_shift_base (0))   // Bits to discard from previous acc step
   dut
   (
      .clk           (clk),
      .reset         (1'b0),
      .stb_in        (stb_in),
      .d_in          (d_in_flat),    // Flattened array of unprocessed data streams. CH0 in LSBs
      .cic_sample    (cic_sample),

      .cc_sample     (cc_sample),
      .cc_shift      ({shift,1'b1}), // controls scaling of filter result

      .di_stb_out    (di_stb_out),   // TODO: Test Double Integrator tap
      .di_sr_out     (di_sr_out),

      .cc_stb_out    (sr_val),
      .cc_sr_out     (sr_out)
   );


   reg strobe1=0;
   integer col=0;
   reg signed [19:0] out_set[0:n_chan-1];

   always @(posedge clk) begin
      strobe1 <= sr_val;
      if (sr_val) begin
         col <= (col==n_chan-1) ? 0 : col+1;
         out_set[col] <= sr_out;
         // $display("%d: out[%d] <= %d", cc, col, result);
      end
   end

   real xr, xi, ampo, phso;
   reg amp_pass, phs_pass, fault, use_row;

   always @(negedge clk) if (cc_s/den > 18) begin
      //if (strobe & ~strobe1) $display("#");
      //if (strobe) $display("%d", result);
      xr=out_set[0];
      xi=out_set[1];
      ampo=$sqrt(xr*xr+xi*xi)/(fden*fden)*(1<<(2*shift));
      ampo=ampo*131072.0/131070.0;
      phso=$atan2(xi,xr);
      amp_pass = overload ? ampo > ampo_expect :
                 ((ampo > ampo_expect*0.99995-0.7) & (ampo < ampo_expect*1.00005+0.7));
      phs_pass = (phso>phsi-phs_marg) & (phso<phsi+phs_marg);

      if (sr_val && (col==0)) begin
         num_tx <= num_tx + 1;
         $display("%d %d %d %d  %8.2f %b %8.5f %b %s.",
                  out_set[0], out_set[1], out_set[2], out_set[3],
                  ampo, amp_pass, phso, phs_pass, fault ? "FAULT" : "");
         fault = (~amp_pass | ~phs_pass);
         if (fault) errors=errors+1;
      end
   end

endmodule
