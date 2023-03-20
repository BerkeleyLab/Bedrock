`timescale 1ns / 1ns

module chirp_driver_tb;

   localparam SIM_TIME = 80000;

   reg clk, trace;
   integer cc, endcc;
   integer n_chirp, full_sim=0;
   initial begin
      if ($test$plusargs("vcd")) begin
         $dumpfile("chirp_driver.vcd");
         $dumpvars(5, chirp_driver_tb);
      end
      if (!$value$plusargs("n_chirp=%d", n_chirp)) n_chirp=1;
      if ($test$plusargs("full")) full_sim=1;
      trace = $test$plusargs("trace");
      for (cc=0; cc<SIM_TIME*n_chirp*(1+full_sim*3); cc=cc+1) begin
         clk=0; #5;
         clk=1; #5;
      end
      $finish();
   end

   reg chirp_start=0;
   integer chirp_cnt=0;
   always @(posedge clk) begin
      if (chirp_cnt < n_chirp)
         chirp_start <= (cc==(500+SIM_TIME*chirp_cnt));
      if (chirp_start) chirp_cnt <= chirp_cnt + 1;
   end

   localparam DD_SHIFT = 8;
   localparam AMP_WI = 20;
   localparam PH_WI = 32;
   localparam LEN_WI = 32;
   localparam CORDIC_WI = 18;

   // ---------------------
   // Generate stimulus
   // ---------------------

   // Want to model a 100 kHz span chirp; -50 kHz to 50 kHz
   // Sweep of roughly 9 ms
   // Aim for a cordic output rate of roughly 1320e6/(14*8)
   // dt = 8*(14/1320e6), sweep cycles = 9ms/dt ~= 106071
   // dphase0 = -50 kHz = -50k/(1320e6/14*8) ~= 0.00424 revolutions/gate
   // ddphase = 100 kHz/(1320e6/14*8)/106071 ~= 0.00000008  revolutions/gate/gate
   localparam SLOW_RUN_LEN = 106071;
   localparam SLOW_DPHASE  = -9105331; // -0.00424 * 2**(PH_WI-1)
   localparam SLOW_DDPHASE = 43980; // 8e-8 * 2**(PH_WI+DD_SHIFT-1)

   // Fast simulation: sweep = 1 ms
   // sweep cycles = 11780.5
   // dphase0 = -0.00424
   // ddphase = 0.00000072
   localparam FAST_RUN_LEN = 11780;
   localparam FAST_DPHASE  = -9105331; // -0.00424 * 2**(PH_WI-1)
   localparam FAST_DDPHASE = 395824; // 7.2e-7 * 2**(PH_WI+DD_SHIFT-1)

   localparam [15:0] CHIRP_RATE = 3; // Technically 8, but set as fast as possible for simulation. Min is 3
   wire [AMP_WI-1:0] amp_max = 600000;  // account for CORDIC gain
   wire [AMP_WI-1:0] amp_slope = 600000/(run_len/8); // .125 of total run length

   wire [LEN_WI-1:0] run_len = (full_sim) ? SLOW_RUN_LEN : FAST_RUN_LEN;
   wire signed [PH_WI-1:0] dphase = (full_sim) ? SLOW_DPHASE : FAST_DPHASE;
   wire signed [PH_WI-1:0] ddphase = (full_sim) ? SLOW_DDPHASE : FAST_DDPHASE;

   // ---------------------
   // Instantiate DUT
   // ---------------------

   wire                          cordic_trig;
   wire signed [CORDIC_WI-1:0]   cordic_amp;
   wire signed [CORDIC_WI+1-1:0] cordic_phase;
   wire                          chirp_status;
   wire [2:0]                    chirp_error;

   wire signed [CORDIC_WI-1:0] cosa, sina;

   chirp_driver #(
      .DD_SHIFT   (DD_SHIFT),
      .PH_WI      (PH_WI),
      .AMP_WI     (AMP_WI),
      .CHIRP_RATE (CHIRP_RATE)) // CORDIC update rate; minimum is 3
   i_dut (
      .clk             (clk),
      .chirp_start     (chirp_start),

      .chirp_en        (1'b1),
      .chirp_len       (run_len),
      .chirp_dphase    (dphase),
      .chirp_ddphase   (ddphase),
      .chirp_amp_slope (amp_slope),
      .chirp_amp_max   (amp_max),

      .cordic_cos      (cosa),
      .cordic_sin      (sina),
      .cordic_trig     (cordic_trig),
      .chirp_status    (chirp_status),
      .chirp_error     (chirp_error)
   );

   wire signed [17:0] dac_out = sina[CORDIC_WI-1:CORDIC_WI-18];

   localparam CORDIC_STAGE = 20; // Hardcoded in chirp_driver
   localparam CORDIC_LAT = CORDIC_STAGE + 1;
   wire [CORDIC_WI-1:0]   cordic_amp_r;
   wire [CORDIC_WI+1-1:0] cordic_phase_r;
   wire cordic_update;

   // Pipeline cordic_amp and cordic_phase to match latency of CORDIC engine
   reg_delay #(.dw(CORDIC_WI+(CORDIC_WI+1)), .len(CORDIC_LAT))
   i_delay_cordic_in (.clk(clk), .reset(1'b0),
                      .gate(1'b1), .din({i_dut.cordic_amp, i_dut.cordic_phase}),
                      .dout({cordic_amp_r, cordic_phase_r}));

   reg_delay #(.dw(1), .len(CORDIC_LAT))
   i_delay_cordic_trig (.clk(clk), .reset(1'b0),
                        .gate(1'b1), .din(cordic_trig),
                        .dout(cordic_update));

   always @(negedge clk) if (cordic_update & trace) $display(
      "%d %d %d", dac_out, cordic_amp_r, cordic_phase_r);

endmodule
