/* For lack of a better approach, I (ksp) am writing a completely separate
 * fiber-ethernet clause 37 auto-negotiation module to pit against our
 * existing module in an adversarial testing approach.
 *
 * This module is written entirely from the clause 37 documentation, not
 * based on any functionality of the existing module.
 *
 * Direct quotes from 802.3 Clause 37 are enclosed in matching <<< >>> braces
 */

module adversary_negotiate #(
  // 10 ms link_timer = 10e6/8
  parameter TIMER_TICKS = 1250000,
  parameter INDENT = ""
) (
  input  rx_clk,
  input  tx_clk, // TODO - Cross domains properly!
  input  rst,
  // Control
  input  mr_an_enable, // Enable auto-negotiation.
  input  los, // loss-of-signal
  // data received
  input  idle_stb, // Indicates an idle frame has been received
  input  [15:0] lacr_in,
  input  lacr_in_stb,
  // data to be sent
  output [15:0] lacr_out,
  output lacr_send,
  // Status
  output negotiating,
  output pcs_data,
  output [8:0] an_status   // debug; partial emulation of negotiate.v output
);

// Maybe stupid; cribbed from negotiate.v
// Detect physical link
reg link_det=0;
always @(posedge rx_clk) begin
   if (lacr_in_stb)
      link_det <= 1;
   if (los)
      link_det <= 0;
end

localparam LINK_TIMER_AW = $clog2(TIMER_TICKS);
localparam [LINK_TIMER_AW-1:0] LINK_TIMER_MAX = TIMER_TICKS-1;
reg [LINK_TIMER_AW-1:0] link_timer=0;
wire link_timer_done = link_timer == LINK_TIMER_MAX;
reg link_timer_stb=1'b0, link_timer_enabled=1'b0;
always @(posedge rx_clk) begin
  if (~link_timer_enabled) begin
    if (link_timer_stb) begin
      link_timer <= 0;
      link_timer_enabled <= 1'b1;
    end
  end else begin // link_timer_enabled
    if (link_timer_done) begin
      link_timer_enabled <= 1'b0;
    end else begin
      link_timer <= link_timer + 1;
    end
  end
end

localparam [1:0] XMIT_IDLE   = 2'h0,
                 XMIT_CONFIGURATION = 2'h1,
                 XMIT_DATA   = 2'h2,
                 XMIT_INVALID= 2'h3;
reg [1:0] xmit=XMIT_IDLE;
assign lacr_send = xmit == XMIT_CONFIGURATION;
localparam [3:0] AN_ENABLE              = 4'h0,
                 AN_RESTART             = 4'h1,
                 AN_DISABLE_LINK_OK     = 4'h2,
                 ABILITY_DETECT         = 4'h3,
                 ACKNOWLEDGE_DETECT     = 4'h4,
                 NEXT_PAGE_WAIT         = 4'h5,
                 COMPLETE_ACKNOWLEDGE   = 4'h6,
                 IDLE_DETECT            = 4'h7,
                 LINK_OK                = 4'h8;
reg [3:0] an_state = AN_ENABLE;

wire [1:0] remote_fault = {rx_Config_Reg[13], rx_Config_Reg[12]};
wire abl_mismatch = ~rx_Config_Reg[5];
wire [8:0] an_status_l = {
  an_state==AN_ENABLE,
  an_state==ABILITY_DETECT,
  link_timer_enabled,
  remote_fault, // 2 bits
  abl_mismatch,
  an_state==ACKNOWLEDGE_DETECT,
  an_state==IDLE_DETECT,
  an_state==LINK_OK
};
reg [8:0] an_status_r=0;
always @(posedge rx_clk) an_status_r <= an_status_l;
assign an_status = an_status_r;

reg [15:0] tx_Config_Reg=16'h0, rx_Config_Reg=16'h0000;
localparam [15:0] mr_adv_ability = 16'b1000000000100000; // Only FD, Next_Page support, no Pause frames
reg [15:0] mr_lp_adv_ability = 16'h0000;
// mr_adv_ability is the superset of what can be advertised via tx_Config_Reg
/*  Bit Index  f   e   d   c   b   a   9   8   7   6   5   4   3   2   1   0
             |---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
    Bit Name |NP |ACK|RF2|RF1|    rsvd   |PS2|PS1|HD |FD |        rsvd       |
*/
// Do not support Next_Page

assign lacr_out = tx_Config_Reg;

assign negotiating = an_state != LINK_OK;
reg mr_an_complete = 1'b0;
// <<< The variable mr_np_loaded is set to TRUE to indicate that the local device has loaded its
//     Auto-Negotiation Next Page transmit register with Next Page information for transmission.
// >>>
reg mr_np_loaded = 1'b0; // Next_Page loaded.
reg toggle_tx=1'b0, toggle_rx=1'b0; // Used in Next_Page;
wire mr_main_reset = rst;
wire mr_np_able = mr_adv_ability[15];
wire mr_restart_an=1'b0;
wire an_sync_status=1'b0;

reg resolve_priority=1'b0; // TODO ???
reg ability_match_r=1'b0;
reg acknowledge_match_r=1'b0;
reg consistency_match=1'b0;
reg an_state_transition_stb=1'b0;
wire ability_match = ability_match_r & (~an_state_transition_stb);
wire acknowledge_match = acknowledge_match_r & (~an_state_transition_stb);
reg reset_stb=1'b0;
reg np_rx=1'b0; // Received Next_Page

// <<< [mr_page_rx] Status indicating whether a new page has been received. A new page has been
//     successfully received when acknowledge_match=TRUE rx_Config_Reg<D15:D0> value has been and
//     consistency_match=TRUE written to andthe mr_lp_adv_ability<16:1>or mr_lp_np_rx<16:1>,
//     depending on whether the page received was a base or Next Page, respectively. >>>
reg mr_page_rx=1'b0;

`ifdef SIMULATE
reg [23*8-1:0] an_state_str [0:LINK_OK];
reg non_breaklink=1'b0;
initial begin
  an_state_str[AN_ENABLE]               = "AN_ENABLE              ";
  an_state_str[AN_RESTART]              = "AN_RESTART             ";
  an_state_str[AN_DISABLE_LINK_OK]      = "AN_DISABLE_LINK_OK     ";
  an_state_str[ABILITY_DETECT]          = "ABILITY_DETECT         ";
  an_state_str[ACKNOWLEDGE_DETECT]      = "ACKNOWLEDGE_DETECT     ";
  an_state_str[COMPLETE_ACKNOWLEDGE]    = "COMPLETE_ACKNOWLEDGE   ";
  an_state_str[IDLE_DETECT]             = "IDLE_DETECT            ";
  an_state_str[LINK_OK]                 = "LINK_OK                ";
end
reg [3:0] old_an_state = AN_ENABLE;
initial begin
  $timeformat(-9, 0, "ns", 8);
end
always @(posedge rx_clk) begin
  if (rx_Config_Reg != 0) non_breaklink = 1'b1;
  old_an_state <= an_state;
  if (old_an_state != an_state) begin
    $display("%s(%t) -> %s", INDENT, $stime, an_state_str[an_state]);
  end
end
`endif
// Manages ability_match, acknowledge_match, and consistency_match
reg idle_match=1'b0;
reg [15:0] rx_cr_consistency=0;
reg [1:0] ability_match_counter=0, acknowledge_match_counter=0, idle_counter=0;
wire rx_cr_ack = lacr_in[14];
wire [14:0] rx_Config_Reg_ignore_ack = {rx_Config_Reg[15], rx_Config_Reg[13:0]};
wire [14:0] lacr_in_ignore_ack = {lacr_in[15], lacr_in[13:0]};

// ==================== Auto-Negotiation State Machine =======================
always @(posedge rx_clk) begin
  reset_stb <= 1'b0;
  link_timer_stb <= 1'b0;
  an_state_transition_stb <= 1'b0;
  case (an_state)
    AN_ENABLE: begin
      mr_page_rx <= 1'b0;
      mr_an_complete <= 1'b0;
      if ((!los) & mr_an_enable) begin
        tx_Config_Reg <= 16'h0;
        xmit <= XMIT_CONFIGURATION;
        an_state <= AN_RESTART;
      end else begin
        xmit <= XMIT_IDLE;
        an_state <= AN_DISABLE_LINK_OK;
      end
      an_state_transition_stb <= 1'b1;
      reset_stb <= 1'b1;
    end

    AN_RESTART: begin
      mr_np_loaded <= 1'b1; // We need to pretend we have a Next Page to transmit
      tx_Config_Reg <= 16'h0;
      xmit <= XMIT_CONFIGURATION;
      if (~link_timer_enabled) begin
        // Start the link timer
        link_timer_stb <= 1'b1;
      end else begin
        if (link_timer_done) begin
          `ifdef SIMULATE
            $display("%s(%t) -> Timer done. Going to ABILITY_DETECT.", INDENT, $stime);
          `endif
          an_state <= ABILITY_DETECT;
          an_state_transition_stb <= 1'b1;
        end
      end
    end

    AN_DISABLE_LINK_OK: begin
      xmit <= XMIT_DATA;
      if ((!los) & mr_an_enable) an_state <= AN_ENABLE;
    end

    ABILITY_DETECT: begin
      toggle_tx <= mr_adv_ability[11];
      tx_Config_Reg <= {mr_adv_ability[15], 1'b0, mr_adv_ability[13:0]};
      if (ability_match) begin
        if (|rx_Config_Reg) begin
          // Received 3 consecutive non-breaklinks
          `ifdef SIMULATE
            $display("%s(%t) Received 0x%x. Going to ACKNOWLEDGE_DETECT.", INDENT, $stime, rx_Config_Reg);
          `endif
          an_state <= ACKNOWLEDGE_DETECT;
          an_state_transition_stb <= 1'b1;
        end else begin
          `ifdef SIMULATE
            //$display("%s(%t) Received (and ignored) breaklink.", INDENT, $stime);
          `endif
        end
      end
    end

    ACKNOWLEDGE_DETECT: begin
      tx_Config_Reg[14] <= 1'b1;
      if ((acknowledge_match & !consistency_match) || (ability_match & (rx_Config_Reg==0))) begin
        // Failed consistency check and/or breaklink
        `ifdef SIMULATE
          if (non_breaklink & (ability_match & (rx_Config_Reg==0))) $display("%s(%t) Received Breaklink", INDENT, $stime);
          else $display("%s(%t) Failed consistency check: 0x%x != 0x%x", INDENT, $stime, rx_cr_consistency, rx_Config_Reg);
        `endif
        an_state <= AN_ENABLE;
        an_state_transition_stb <= 1'b1;
      end else if (acknowledge_match & consistency_match) begin
        an_state <= COMPLETE_ACKNOWLEDGE;
        an_state_transition_stb <= 1'b1;
      end
    end

    COMPLETE_ACKNOWLEDGE: begin
      if (~link_timer_enabled) begin
        // Start the link timer
        link_timer_stb <= 1'b1;
        toggle_tx <= ~toggle_tx;
        toggle_rx <= rx_Config_Reg[11];
        np_rx <= rx_Config_Reg[15];
        mr_page_rx <= 1'b1;
      end else begin
        if (ability_match & (rx_Config_Reg==0)) begin
          `ifdef SIMULATE
            if (non_breaklink) $display("%s(%t) Received Breaklink", INDENT, $stime);
          `endif
          an_state <= AN_ENABLE; // Breaklink received
          an_state_transition_stb <= 1'b1;
        end else if (
          (
            (link_timer_done & (~mr_np_able | ~mr_lp_adv_ability[15])) || // lp == "link partner"?
            (link_timer_done & mr_np_able & mr_lp_adv_ability[15] & (~tx_Config_Reg[15]) & (~np_rx))
          ) & ((~ability_match) | (|rx_Config_Reg))
        ) begin
          an_state <= IDLE_DETECT;
          an_state_transition_stb <= 1'b1;
        end else if (
          link_timer_done && mr_np_able && mr_lp_adv_ability[15] && mr_np_loaded &&
          (tx_Config_Reg[15] || np_rx) & (!ability_match || (rx_Config_Reg != 0))
        ) begin
          an_state <= NEXT_PAGE_WAIT;
          an_state_transition_stb <= 1'b1;
        end
      end
    end

    IDLE_DETECT: begin
      if (~link_timer_enabled) begin
        // Start the link timer
        link_timer_stb <= 1'b1;
        xmit <= XMIT_IDLE;
        resolve_priority <= 1'b1;
      end else begin
        if (ability_match & (rx_Config_Reg==0)) begin
          `ifdef SIMULATE
            if (non_breaklink) $display("%s(%t) Received Breaklink", INDENT, $stime);
          `endif
          an_state <= AN_ENABLE; // Breaklink received
          an_state_transition_stb <= 1'b1;
        end else if (link_timer_done & idle_match) begin
          an_state <= LINK_OK;
          an_state_transition_stb <= 1'b1;
        end
      end
    end

    // <<< Once a local device has completed transmission of its Next Page information, if any, it
    //     shall transmit Message Pages with a Null message code (see Annex 28C) and the NP bit set
    //     to logic zero while its link partner continues to transmit valid Next Pages. >>> 
    NEXT_PAGE_WAIT: begin
      mr_np_loaded <= 1'b0;
      tx_Config_Reg[15] <= 1'b0; // NP bit
      tx_Config_Reg[14] <= 1'b0; // ACK bit
      tx_Config_Reg[13] <= 1'b1; // MP bit
      tx_Config_Reg[12] <= 1'b0; // ACK2 bit. For now, let's say we can't act on anything.
      tx_Config_Reg[11] <= toggle_tx;
      tx_Config_Reg[10:0] <= 11'h001; // Null message
      if (ability_match && (rx_Config_Reg == 0)) begin
        an_state <= AN_ENABLE;
        an_state_transition_stb <= 1'b1;
      end else if (ability_match && (toggle_rx ^ rx_Config_Reg[11]) && (rx_Config_Reg != 0)) begin
        an_state <= ACKNOWLEDGE_DETECT;
        an_state_transition_stb <= 1'b1;
      end
    end

    LINK_OK: begin
      xmit <= XMIT_DATA;
      mr_an_complete <= 1'b1;
      resolve_priority <= 1'b1;
      if (ability_match) begin
        `ifdef SIMULATE
          if (non_breaklink && (rx_Config_Reg==0)) $display("%s(%t) Received Breaklink", INDENT, $stime);
          else $display("%s(%t) Leaving LINK_OK with rx_Config_Reg = 0x%x", INDENT, $stime, rx_Config_Reg);
        `endif
        an_state <= AN_ENABLE;
        an_state_transition_stb <= 1'b1;
      end
    end
    default: begin
    end
  endcase
  if (mr_main_reset) an_state <= AN_ENABLE;

end

always @(posedge rx_clk) begin
  // ======================== Config Reg State Machine =========================
  if (reset_stb) begin
    ability_match_r <= 1'b0;
    ability_match_counter <= 0;
    acknowledge_match_r <= 1'b0;
    acknowledge_match_counter <= 0;
    consistency_match <= 1'b0;
    idle_match <= 1'b0;
    idle_counter <= 0;
    np_rx <= 1'b0;
  end

  // ======================================= idle_match ===========================================
  // <<< this function [idle_match] continuously indicates whether three consecutive
  //     /I/ ordered sets have been received >>>
  if (lacr_in_stb || an_state_transition_stb ) begin
    // <<< Idle_match evaluates to its default value upon state entry. >>>
    // <<< The match count is reset upon receipt of /C/. >>>
    idle_counter <= 0;
  end else if (idle_stb) begin
    if (idle_counter == 2) begin
      idle_match <= 1'b1;
    end else begin
      idle_counter <= idle_counter + 1;
      idle_match <= 1'b0;
    end
  end
  // ==============================================================================================

  if (lacr_in_stb) begin
    // Always store the CR here
    rx_Config_Reg <= lacr_in;
    if (an_state != NEXT_PAGE_WAIT) mr_lp_adv_ability <= lacr_in;

    // ==================================== ability_match =========================================
    // <<< this function [ability_match] continuously indicates whether the last three consecutive rx_Config_Reg<D15,D13:D0> values match >>>
    if ((lacr_in_ignore_ack != rx_Config_Reg_ignore_ack) || an_state_transition_stb) begin
      // If the past two CRs disagree (ignoring ACK bit) or we change states, reset the counter
      ability_match_r <= 1'b0;
      ability_match_counter <= 0;
    end else begin
      // If the past two CRs agree (ignoring ACK bit), increment the counter
      if (ability_match_counter == 2) begin
        // <<< [consistency_match] Indicates that the rx_Config_Reg<D15,D13:D0> value that caused
        //     ability_match to be set, for the transition from states ABILITY_DETECT or
        //     NEXT_PAGE_WAIT to state ACKNOWLEDGE_DETECT, is the same as the rx_Config_Reg<D15,D13:D0>
        //     value that caused acknowledge_match to be set. >>>
        if ((an_state == ABILITY_DETECT) || (an_state == NEXT_PAGE_WAIT)) rx_cr_consistency <= rx_Config_Reg;
        ability_match_r <= 1'b1;
      end else begin
        ability_match_counter <= ability_match_counter + 1;
        ability_match_r <= 1'b0;
      end
    end
    // ============================================================================================

    // ================================== acknowledge_match =======================================
    // <<< this function [acknowledge_match] continuously indicates whether the last three consecutive
    //     rx_Config_Reg<D15:D0> values match and have the Acknowledge bit set. >>>
    if (!rx_cr_ack || (lacr_in != rx_Config_Reg) || an_state_transition_stb) begin
      // If the past two CRs disagree or are not ACK or we change states, reset the counter
      acknowledge_match_counter <= 0;
      acknowledge_match_r <= 1'b0;
    end else begin
      // If the past two CRs agree (including ACK bit), increment the counter
      if (acknowledge_match_counter == 2) begin
        acknowledge_match_r <= 1'b1;
        //np_rx <= rx_Config_Reg[15];
        // ================================ consistency_match =====================================
        // <<< Indicates that the rx_Config_Reg<D15,D13:D0> value that caused ability_match to be set, for
        //     the transition from states ABILITY_DETECT or NEXT_PAGE_WAIT to state ACKNOWLEDGE_DETECT, is
        //     the same as the rx_Config_Reg<D15,D13:D0> value that caused acknowledge_match to be set. >>>
        if ((rx_cr_consistency&16'hbfff) == (rx_Config_Reg&16'hbfff)) consistency_match <= 1'b1;
        else consistency_match <= 1'b0;
      end else begin
        acknowledge_match_counter <= acknowledge_match_counter + 1;
        acknowledge_match_r <= 1'b0;
      end
    end
    // ============================================================================================
  end // if (lacr_in_stb)

  if (an_state_transition_stb || idle_stb) begin
    // <<< Ability_match evaluates to its default value upon state entry. >>>
    // <<< The match count is reset upon receipt of /I/ >>
    ability_match_r <= 1'b0;
    ability_match_counter <= 0;
    // <<< Acknowledge_match evaluates to its default value upon state entry. >>>
    // <<< The match count is reset upon receipt of /I/ >>
    acknowledge_match_r <= 1'b0;
    acknowledge_match_counter <= 0;
  end
end

assign pcs_data = xmit == XMIT_DATA;

endmodule
