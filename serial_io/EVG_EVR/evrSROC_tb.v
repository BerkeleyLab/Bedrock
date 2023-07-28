`timescale 1ns / 100ps

module evrSROC_tb;

   localparam SIM_SYS_CLK_FREQ = 133333333/1e4;
   real SYS_CLK_PER = 7.5; // ns
   localparam SIM_EVR_CLK_FREQ = 125000000/1e4;
   real EVR_CLK_PER = 8;

   localparam SIM_TIME = 1e6;

   reg fail=1;
   initial begin
      if ($test$plusargs("vcd")) begin
         $dumpfile("evrSROC.vcd");
         $dumpvars(5, evrSROC_tb);
      end
      while ($time < SIM_TIME) @(posedge sysClk);
      if (fail) begin
        $display("FAIL");
        $stop();
      end else begin
        $display("PASS");
        $finish(0);
      end
   end

   reg sysClk = 0;
   reg evrClk = 0;
   always #(SYS_CLK_PER/2) sysClk <= ~sysClk;
   always #(EVR_CLK_PER/2) evrClk <= ~evrClk;

   // -------------------------
   // Stimulus
   // -------------------------
   integer evr_pps_cnt=0;
   wire evr_pps = (evr_pps_cnt==SIM_EVR_CLK_FREQ-1);
   always @(posedge evrClk) evr_pps_cnt <= evr_pps ? 0 : evr_pps_cnt + 1;

   // Scaled down version of ALS-U AR timing relationships as example
   // EVG_CLK_PER_HB = 124640000
   // Harmonic number = 304
   // Turns per HB = 1640000
   // -----
   // EVG_CLK_PER_HB = 12464
   // Harmonic number = 304
   // Turns per HB = 164

   // Heartbeat marker is streamed at ~1 Hz and is always phase-locked to the machine orbit
   // clock. Its frequency may also jitter/drift w.r.t PPS
   localparam EVG_HB_PERIOD = 12464;
   // SROC_DIVIDER must be an exact subdivision of the heartbeat rate to achieve sync
   localparam SROC_DIVIDER = 304/4;

   integer turn_per_hb = EVG_HB_PERIOD/SROC_DIVIDER;

   integer evr_hb_cnt=533; // Arbitrary phase offset
   wire evr_hb = (evr_hb_cnt==EVG_HB_PERIOD-1);
   always @(posedge evrClk) evr_hb_cnt <= evr_hb ? 0 : evr_hb_cnt + 1;


   // -------------------------
   // DUT
   // -------------------------
   wire hb_valid, pps_valid;
   wire evr_SROC_valid, evr_SROC;

   evrSROC #(
      .SYSCLK_FREQUENCY(SIM_SYS_CLK_FREQ),
      .SROC_DIVIDER(SROC_DIVIDER))
   dut (
      .sysClk (sysClk),
      .evrClk (evrClk),
      .evrHeartbeatMarker      (evr_hb),
      .evrPulsePerSecondMarker (evr_pps),

      .heartBeatValid      (hb_valid),
      .pulsePerSecondValid (pps_valid),
      .evrSROCsynced       (evr_SROC_valid),
      .evrSROC             (evr_SROC));

   // -------------------------
   // Scoreboarding
   // -------------------------
   reg evr_SROC_r=0;
   integer evr_SROC_cnt=0;
   integer evr_SROC_max=0;
   always @(posedge evrClk) begin
      evr_SROC_r <= evr_SROC;
      if (evr_hb) begin
         evr_SROC_cnt <= 0;
         evr_SROC_max <= evr_SROC_cnt;
      end else if (evr_SROC && !evr_SROC_r)
         evr_SROC_cnt <= evr_SROC_cnt + 1;
   end

   always @(posedge evrClk) begin
      // Not strictly in evrClk domain; treat as quasi-static
      if (hb_valid && pps_valid && evr_SROC_valid) begin
         if (evr_SROC_max == turn_per_hb) fail <= 0;
         else fail <= 1;
      end
   end

endmodule
