// Ethernet PCS autonegotiation
// https://www.iol.unh.edu/sites/default/files/knowledgebase/ge/Clause_37_Auto-Negotiation.pdf

// lacr == Link Autonegotiation Configuration Register
// module can clock over 180 MHz (need 125 MHz)
//
// Full-duplex only
// Next-page functionality not supported
// Pause frames not supported

module negotiate(
   input             rx_clk, // timespec 5.55 ns
   input             los,    // loss of signal
   // data received
   input [15:0]      lacr_in,
   input             lacr_in_stb,
   // data to be sent
   input             tx_clk,
   output reg [15:0] lacr_out,
   output reg        lacr_send,
   // mode control
   output reg        operate,
   output reg [8:0]  an_status
);
   // 10 ms link_timer = 10e6/8
   parameter TIMER_TICKS = 1250000;
   localparam TIMER_LOG2 = 21;

   // 16-bit Ethernet Configuration Register
   localparam NP_BITPOS   = 15,
              ACK_BITPOS  = 14,
              RF2_BITPOS  = 13,
              RF1_BITPOS  = 12,
              PS2_BITPOS  = 8,
              PS1_BITPOS  = 7,
              HD_BITPOS   = 6,
              FD_BITPOS   = 5,
              RSV1_HIGH   = 4,
              RSV1_LOW    = 0,
              RSV2_HIGH   = 11,
              RSV2_LOW    = 9;

   // Autonegotiation state machine
   localparam [2:0] AN_RESTART = 0,
                    AN_ABILITY = 1,
                    AN_ACK     = 2,
                    AN_IDLE    = 3,
                    AN_LINK_OK = 4,
                    AN_ABORT   = 5;

   reg [2:0] an_state = AN_RESTART, n_an_state;

   initial lacr_send=0;
   initial operate=0;

   wire an_rst;
   // Detect physical link
   reg link_det=0;
   always @(posedge rx_clk) begin
      if (lacr_in_stb)
         link_det <= 1;
      if (los)
         link_det <= 0;
   end

   // Process the input from the LACR receiver, looking for
   // three in a row of the same value.
   reg [15:0] lacr_prev_val=0;
   reg lacr_match=0, lacr_change=0;
   reg [2:0] lacr_match_cnt=0;

   wire match_ok = (lacr_match_cnt==3);

   always @(posedge rx_clk) begin
      if (an_state != AN_RESTART) begin
         if (lacr_in_stb) lacr_prev_val <= lacr_in;
         lacr_match  <= lacr_in_stb & (lacr_prev_val == lacr_in);
         lacr_change <= lacr_in_stb & (lacr_prev_val != lacr_in);

         if (lacr_match)
            lacr_match_cnt <= lacr_match_cnt + 1;
         if (lacr_change || match_ok || an_rst) begin
            lacr_match_cnt <= 0;
         end
      end
   end

   // Ack/Abl and consistency flags
   reg [15:0] lacr_ability;
   reg ack_match=0, abl_match=0;
   reg consistency_match=0;
   always @(posedge rx_clk) begin
      if (an_rst) begin
         ack_match <= 0;
         abl_match <= 0;
         consistency_match <= 0;
      end else begin
         if (an_state==AN_ACK && match_ok && lacr_prev_val[ACK_BITPOS])
            ack_match <= 1;
         if (an_state==AN_ABILITY && match_ok && !lacr_prev_val[ACK_BITPOS]) begin
            abl_match <= 1;
            lacr_ability <= lacr_prev_val;
            lacr_ability[ACK_BITPOS] <= 1; // Consistency check done against acked version
         end

         if (ack_match)
            consistency_match <= (lacr_ability == lacr_prev_val) ? 1 : 0;
      end
   end

   // Look for 3 consecutive breaklink words, signalling a restart
   reg [1:0] breaklink_cnt=0;
   always @(posedge rx_clk) begin
      if (an_rst) breaklink_cnt <= 0;
      if (lacr_in_stb) begin
         if (lacr_in == 0) breaklink_cnt <= breaklink_cnt + 1;
         else breaklink_cnt <= 0;
      end
   end
   assign an_rst = (breaklink_cnt==3);

   // Flags Remote Faults and unavailability of full-duplex mode
   wire [1:0] remote_fault = {lacr_prev_val[RF2_BITPOS], lacr_prev_val[RF1_BITPOS]};
   wire abl_mismatch = ~lacr_ability[FD_BITPOS];

   reg [TIMER_LOG2-1:0] link_timer = 0;
   reg link_timer_on=0, link_timer_done;
   reg link_timer_start;
   reg wdog_an_disable=0;
   wire wdog_timeout;

   always @(posedge rx_clk) begin
      link_timer_done <= 0;
      if (link_timer_start) begin
         link_timer <= TIMER_TICKS;
         link_timer_on <= 1;
      end else if (link_timer_on) begin
         link_timer <= link_timer - 1;
         if (link_timer == 1) begin
            link_timer_done <= 1;
            link_timer_on <= 0;
         end
      end
   end

   always @(posedge rx_clk) begin
      if ((an_rst & ~wdog_an_disable) | los | wdog_timeout) begin
         an_state <= AN_RESTART;
      end else begin
         an_state <= n_an_state;
      end
   end

   wire idle_match = 1; // TODO: Perform actual idle marker check

   reg n_lacr_send; // lacr_send in the rx clock domain
   reg n_send_ack;
   reg n_send_breaklink;
   reg n_operate;
   always @(*) begin
      n_lacr_send      = 0;
      n_send_ack       = 0;
      n_send_breaklink = 0;
      link_timer_start = 0;
      n_operate        = 0;
      n_an_state       = an_state;
      case (an_state)
         AN_RESTART: begin
            n_lacr_send = 1;
            n_send_breaklink = 1;
            if (!link_timer_on && !link_timer_done)
               link_timer_start = 1;
            if (link_timer_done && link_det)
               n_an_state = wdog_an_disable ? AN_ABORT : AN_ABILITY;
         end
         AN_ABILITY: begin // Ability detect
            n_lacr_send = 1;
            if (abl_match)
               n_an_state = AN_ACK;
         end
         AN_ACK: begin // Acknowledge detect + complete acknowledge
            n_lacr_send = 1;
            n_send_ack = 1;
            if (!link_timer_on && !link_timer_done)
               link_timer_start = 1;
            if (link_timer_done && ack_match)
               if (consistency_match)
                  n_an_state = AN_IDLE;
               else
                  n_an_state = AN_RESTART;
         end
         AN_IDLE: begin // Transmit (and check?) idle
            n_send_ack = 1; // Ensure that delayed PCS transmission is an ack
            if (!link_timer_on && !link_timer_done)
               link_timer_start = 1;
            if (link_timer_done && idle_match)
               n_an_state = AN_LINK_OK;
         end
         AN_LINK_OK: begin // Enable upper layers
            n_operate = 1;
         end
         default: begin // AN_ABORT Abort failed auto negotiation
            n_lacr_send = 0;
            n_operate = 1;
         end
      endcase
   end

   // Watchdog to recover from failed AN
   localparam WATCHDOG_TIME = TIMER_TICKS*8;
   localparam WATCHDOG_LOG2 = TIMER_LOG2+3;

   reg [WATCHDOG_LOG2-1:0] wdog_cnt=0;
   always @(posedge rx_clk) begin
      // Clear on FWD progress or on first pulse in after last AN
      if ((n_an_state > an_state && an_state != AN_RESTART) || los)
      begin
         wdog_cnt <= 0; // Reset on fwd progress
         wdog_an_disable <= 0;
      end else if (link_det) begin
         if (an_state != AN_LINK_OK) begin
            if (wdog_an_disable == 0)
               wdog_cnt <= wdog_cnt + 1;
            if (wdog_timeout)
               wdog_an_disable <= 1;
         end
      end
   end

   assign wdog_timeout = (wdog_cnt==WATCHDOG_TIME);

   wire [8:0] an_status_l = {an_state==AN_ABORT, an_state==AN_ABILITY,
                             wdog_an_disable, remote_fault, abl_mismatch,
                             an_state==AN_ACK, an_state==AN_IDLE, an_state==AN_LINK_OK};

   // Register comb signals in rx_clk before transferring to tx_clk
   reg lacr_send_r=0; // lacr_send in the rx clock domain
   reg send_ack_r;
   reg send_breaklink_r;
   reg operate_r=0;
   reg [8:0] an_status_r=0;
   always @(posedge rx_clk) begin
       operate_r        <= n_operate;
       lacr_send_r      <= n_lacr_send;
       send_ack_r       <= n_send_ack;
       send_breaklink_r <= n_send_breaklink;
       an_status_r      <= an_status_l;
   end

   reg send_ack, send_breaklink;
   always @(posedge tx_clk) begin
      operate        <= operate_r;
      lacr_send      <= lacr_send_r;
      send_ack       <= send_ack_r;
      send_breaklink <= send_breaklink_r;
      an_status      <= an_status_r;
   end

   // 16-bit Ethernet configuration register as documented in
   // Networking Protocol Fundamentals, by James Long
   // and http://grouper.ieee.org/groups/802/3/z/public/presentations/nov1996/RTpcs8b_sum5.pdf
   reg  FD=1;   // Full Duplex capable
   wire HD=0;   // Half Duplex capable
   wire PS1=0;  // Pause 1
   wire PS2=0;  // Pause 2
   wire RF1=0;  // Remote Fault 1
   wire RF2=0;  // Remote Fault 2
   //   ACK     // Acknowledge -- important! defined above
   wire NP=0;   // Next Page
   // Set "Reserved" bits to 0

   always @(*) begin
      lacr_out = 16'b0;
      if (!send_breaklink) begin
         lacr_out[NP_BITPOS]  = NP;
         lacr_out[ACK_BITPOS] = send_ack;
         lacr_out[RF2_BITPOS] = RF2;
         lacr_out[RF1_BITPOS] = RF1;
         lacr_out[PS2_BITPOS] = PS2;
         lacr_out[PS1_BITPOS] = PS1;
         lacr_out[HD_BITPOS]  = HD;
         lacr_out[FD_BITPOS]  = FD;
      end
   end

   // {PS1,PS2} indicate supported flow-control.  Coding:
   //   00 - no pause
   //   01 - asymmetric pause toward link partner
   //   10 - symmetric pause
   //   11 - both symmetric and asymmetric pause toward local device
   // {RF1,RF2} indicate to the remote device whether a fault has been
   // detected by the local device.  Coding:
   //   00 - No error, link OK
   //   01 - Offline
   //   10 - Link Failure
   //   11 - Link Error
   // ACK reception of at least three consecutive matching config_reg
   // NP  parameter information follows, either message page or unformatted page

endmodule
