/* For lack of a better approach, I (ksp) am writing a completely separate
 * fiber-ethernet clause 37 auto-negotiation module to pit against our
 * existing module in an adversarial testing approach.
 *
 * This module is written entirely from the clause 37 documentation, not
 * based on any functionality of the existing module.
 */

module adversary_negotiate #(
  // 10 ms link_timer = 10e6/8
  parameter TIMER_TICKS = 1250000,
  parameter INDENT = ""
) (
  input  clk,
  input  rst,
  input  [7:0] rx_byte,
  input  rx_is_k,
  output reg [7:0] tx_byte=0,
  output reg tx_is_k,
  output negotiating,
  input  los, // loss-of-signal
  output [15:0] lacr_rx_val
);

localparam [7:0] K_28_5_DEC = 8'b101_11100, // 0xbc
                 D_21_5_DEC = 8'b101_10101, // 0xb5
                 D_2_2_DEC  = 8'b010_00010, // 0x42
                 D_5_6_DEC  = 8'b110_00101, // 0xc5
                 D_16_2_DEC = 8'b010_10000; // 0x50

wire rx_is_k28_5 = rx_is_k  & (rx_byte == K_28_5_DEC);
wire rx_is_d21_5 = ~rx_is_k & (rx_byte == D_21_5_DEC);
wire rx_is_d2_2  = ~rx_is_k & (rx_byte == D_2_2_DEC);
wire rx_is_d5_6  = ~rx_is_k & (rx_byte == D_5_6_DEC);
wire rx_is_d16_2 = ~rx_is_k & (rx_byte == D_16_2_DEC);

/* Auto-negotiation Ordered Sets are signaled by a K.28.5
 * How to make a K.28.5:
 *  |------- Input ------|-- RD=-1 --|-- RD=+1 -|
 *  Symbol  Hex HGF EDCBA abcdei fghj abcdei fghj
 *  ---------------------------------------------
 *  K.28.5  BC  101 11100 001111 1010 110000 0101     *Comma: Run of 5 1's or 5 0's
 */

localparam LINK_TIMER_AW = $clog2(TIMER_TICKS);
localparam [LINK_TIMER_AW-1:0] LINK_TIMER_MAX = TIMER_TICKS-1;
reg [LINK_TIMER_AW-1:0] link_timer=0;
wire link_timer_done = link_timer == LINK_TIMER_MAX;
reg link_timer_stb=1'b0, link_timer_enabled=1'b0;
always @(posedge clk) begin
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
localparam [3:0] AN_ENABLE              = 4'h0,
                 AN_RESTART             = 4'h1,
                 AN_DISABLE_LINK_OK     = 4'h2,
                 ABILITY_DETECT         = 4'h3,
                 ABILITY_DETECT_WAIT    = 4'h4,
                 ACKNOWLEDGE_DETECT     = 4'h5,
                 ACKNOWLEDGE_DETECT_WAIT= 4'h6,
                 COMPLETE_ACKNOWLEDGE   = 4'h7,
                 IDLE_DETECT            = 4'h8,
                 LINK_OK                = 4'h9;
reg [3:0] an_state = AN_ENABLE;
reg  FD=1;   // Full Duplex capable  XXX not used
localparam [16:0] mr_adv_ability = 17'b00000000001000000; // Only FD, no Next_Page, no Pause frames
// mr_adv_ability[16] = device supports next_page exchange (NP)
// mr_adv_ability[14:1] = tx_Config_Reg[13:0]
// mr_adv_ability[12] = tx_Config_Reg[11] = toggle_tx, only used for NP data synch
// mr_adv_ability[0] is never used or explained in the docs
/*  Bit Index  f   e   d   c   b   a   9   8   7   6   5   4   3   2   1   0
             |---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
    Bit Name |NP |ACK|RF2|RF1|    rsvd   |PS2|PS1|HD |FD |        rsvd       |
*/
// Do not support Next_Page

// TODO - This seems to refer to the "link partner" but this information comes
// from rx_Config_Reg, so I don't know why this is needed.
reg [15:0] tx_Config_Reg=16'h0, rx_Config_Reg=16'h0;
wire [16:0] mr_lp_adv_ability = {rx_Config_Reg, 1'b0};
assign lacr_rx_val = rx_Config_Reg;

assign negotiating = an_state != LINK_OK;
reg mr_an_complete = 1'b0;
reg mr_an_enable = 1'b1; // Enable auto-negotiation. Unused?
reg mr_np_loaded = 1'b0; // Next_Page loaded. Unused
reg toggle_tx=1'b0, toggle_rx=1'b0; // Used in Next_Page; unused in this implementation
wire mr_main_reset = rst;
wire mr_restart_an=1'b0;
wire an_sync_status=1'b0;

reg ability_match=1'b0;
reg resolve_priority=1'b0;
reg acknowledge_match=1'b0;
reg consistency_match=1'b0;
reg np_rx=1'b0; // Received Next_Page (not supported)

reg mr_page_rx = 1'b0; // ???

reg an_state_transition_stb = 1'b0;
reg xmit_rst_stb=1'b0;
`ifdef SIMULATE
reg [23*8-1:0] an_state_str [0:LINK_OK];
reg non_breaklink=1'b0;
initial begin
  an_state_str[AN_ENABLE]               = "AN_ENABLE              ";
  an_state_str[AN_RESTART]              = "AN_RESTART             ";
  an_state_str[AN_DISABLE_LINK_OK]      = "AN_DISABLE_LINK_OK     ";
  an_state_str[ABILITY_DETECT]          = "ABILITY_DETECT         ";
  an_state_str[ABILITY_DETECT_WAIT]     = "ABILITY_DETECT_WAIT    ";
  an_state_str[ACKNOWLEDGE_DETECT]      = "ACKNOWLEDGE_DETECT     ";
  an_state_str[ACKNOWLEDGE_DETECT_WAIT] = "ACKNOWLEDGE_DETECT_WAIT";
  an_state_str[COMPLETE_ACKNOWLEDGE]    = "COMPLETE_ACKNOWLEDGE   ";
  an_state_str[IDLE_DETECT]             = "IDLE_DETECT            ";
  an_state_str[LINK_OK]                 = "LINK_OK                ";
end
reg [3:0] old_an_state = AN_ENABLE;
initial begin
  $timeformat(-9, 0, "ns", 8);
end
always @(posedge clk) begin
  if (rx_Config_Reg != 0) non_breaklink = 1'b1;
  old_an_state <= an_state;
  if (old_an_state != an_state) begin
    if ((an_state != ABILITY_DETECT_WAIT) && (an_state != ACKNOWLEDGE_DETECT_WAIT)) begin
      if (non_breaklink) $display("%s(%t) -> %s", INDENT, $stime, an_state_str[an_state]);
    end
  end
end
`endif
// ==================== Auto-Negotiation State Machine =======================
always @(posedge clk) begin
  xmit_rst_stb <= 1'b0;
  link_timer_stb <= 1'b0;
  an_state_transition_stb <= 1'b0;
  if (mr_main_reset) an_state <= AN_ENABLE;
  case (an_state)
    AN_ENABLE: begin
      mr_page_rx <= 1'b0;
      mr_an_complete <= 1'b0;
      xmit_rst_stb <= 1'b1;
      if ((!los) & mr_an_enable) begin
        tx_Config_Reg <= 16'h0;
        xmit <= XMIT_CONFIGURATION;
        an_state <= AN_RESTART;
      end else begin
        xmit <= XMIT_IDLE;
        an_state <= AN_DISABLE_LINK_OK;
      end
      an_state_transition_stb <= 1'b1;
    end
    AN_RESTART: begin
      mr_np_loaded <= 1'b0;
      tx_Config_Reg <= 16'h0;
      xmit <= XMIT_CONFIGURATION;
      if (~link_timer_enabled) begin
        // Start the link timer
        link_timer_stb <= 1'b1;
      end else begin
        if (link_timer_done) begin
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
      toggle_tx <= mr_adv_ability[12];
      tx_Config_Reg <= {mr_adv_ability[16], 1'b0, mr_adv_ability[14:1]};
      an_state <= ABILITY_DETECT_WAIT;
      an_state_transition_stb <= 1'b1;
    end
    ABILITY_DETECT_WAIT: begin
      if (ability_match) begin
        if (|rx_Config_Reg) begin
          // No breaklink
          an_state <= ACKNOWLEDGE_DETECT;
          an_state_transition_stb <= 1'b1;
        end else begin
          `ifdef SIMULATE
            if (non_breaklink) $display("%s(%t) Received Breaklink", INDENT, $stime);
          `endif
          // Breaklink
          an_state <= AN_ENABLE;
          an_state_transition_stb <= 1'b1;
        end
      end
    end
    ACKNOWLEDGE_DETECT: begin
      tx_Config_Reg[14] <= 1'b1;
      an_state <= ACKNOWLEDGE_DETECT_WAIT;
      // No state transition strobe
    end
    ACKNOWLEDGE_DETECT_WAIT: begin
      if ((acknowledge_match & !consistency_match) || (ability_match & (rx_Config_Reg==0))) begin
        // Failed consistency check and/or breaklink
        `ifdef SIMULATE
          if (non_breaklink & (ability_match & (rx_Config_Reg==0))) $display("%s(%t) Received Breaklink", INDENT, $stime);
          else $display("%s(%t) Failed consistency check", INDENT, $stime);
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
        //np_rx <= rx_Config_Reg[15]; // Next_Page not supported
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
            (link_timer_done & (~mr_adv_ability[16] | ~mr_lp_adv_ability[16])) || // lp == "link partner"?
            (link_timer_done & mr_adv_ability[16] & mr_lp_adv_ability[16] & (~tx_Config_Reg[15]) & (~np_rx))
          ) & ((~ability_match) | (|rx_Config_Reg))
        ) begin
          an_state <= IDLE_DETECT;
          an_state_transition_stb <= 1'b1;
        end
      end
    end
    IDLE_DETECT: begin
      if (~link_timer_enabled) begin
        // Start the link timer
        link_timer_stb <= 1'b1;
        xmit_rst_stb <= 1'b1;
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
          xmit_rst_stb <= 1'b1;
          an_state <= LINK_OK;
          an_state_transition_stb <= 1'b1;
        end
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
end

// ======================== Config Reg State Machine =========================
// Manages ability_match, acknowledge_match, and consistency_match
localparam [2:0] CR_STATE_IDLE      = 3'h0,
                 CR_STATE_GOT_K     = 3'h1,
                 CR_STATE_CR_LOW    = 3'h4,
                 CR_STATE_CR_HIGH   = 3'h5;
reg [2:0] cr_state=CR_STATE_IDLE;
reg idle_stb=1'b0, idle_match=1'b0;
reg rx_cr_stb=1'b0;
reg [15:0] rx_cr_last=0, rx_cr_consistency=0;
reg [1:0] ability_match_counter=0, acknowledge_match_counter=0, idle_counter=0;
wire rx_cr_ack = rx_Config_Reg[14];
wire [14:0] rx_cr_last_ignore_ack = {rx_cr_last[15], rx_cr_last[13:0]};
wire [14:0] rx_Config_Reg_ignore_ack = {rx_Config_Reg[15], rx_Config_Reg[13:0]};
always @(posedge clk) begin
  idle_stb <= 1'b0;
  rx_cr_stb <= 1'b0;
  if (an_state_transition_stb) begin
    ability_match <= 1'b0;
    acknowledge_match <= 1'b0;
    consistency_match <= 1'b0;
    ability_match_counter <= 0;
    acknowledge_match_counter <= 0;
  end
  case (cr_state)
    default /* CR_STATE_IDLE */: begin
      if (rx_is_k28_5) cr_state <= CR_STATE_GOT_K;
    end
    CR_STATE_GOT_K: begin
      if (rx_is_d21_5 | rx_is_d2_2) cr_state <= CR_STATE_CR_LOW;
      else if (rx_is_d5_6 | rx_is_d16_2) begin
        cr_state <= CR_STATE_IDLE;
        idle_stb <= 1'b1;
      end else cr_state <= CR_STATE_IDLE;
    end
    CR_STATE_CR_LOW: begin
      rx_Config_Reg[7:0] <= rx_byte;
      cr_state <= CR_STATE_CR_HIGH;
    end
    CR_STATE_CR_HIGH: begin
      rx_Config_Reg[15:8] <= rx_byte;
      cr_state <= CR_STATE_IDLE;
      rx_cr_stb <= 1'b1;
    end
  endcase
  if (idle_stb) begin
    if (idle_counter == 2) begin
      idle_counter <= 0;
      idle_match <= 1'b1;
    end else idle_counter <= idle_counter + 1;
  end
  if (rx_cr_stb) begin
    // Always store the CR here
    rx_cr_last <= rx_Config_Reg;
    // And if we're in the ABILITY_DETECT state, also store it here for consistency check
    if ((an_state == ABILITY_DETECT_WAIT) || (an_state == ABILITY_DETECT)) rx_cr_consistency <= rx_Config_Reg;
    if (~ability_match) begin
      // If we haven't yet found an ability_match
      if (rx_cr_last_ignore_ack == rx_Config_Reg_ignore_ack) begin
        // If the past two CRs agree (ignoring ACK bit), increment the counter
        if (ability_match_counter == 2) begin
          ability_match_counter <= 0;
          ability_match <= 1'b1;
        end else begin
          ability_match_counter <= ability_match_counter + 1;
        end
      end else begin
        // If the past two CRs disagree (ignoring ACK bit), reset the counter
        ability_match_counter <= 0;
      end
    end else begin
      // If we've found the ability_match, just reset the counter and wait for
      // the next state change
      ability_match_counter <= 0;
    end
    if (~acknowledge_match) begin
      // If we haven't yet found an acknowledge_match
      if (rx_cr_ack && (rx_cr_last == rx_Config_Reg)) begin
        // If the past two CRs agree (including ACK bit), increment the counter
        if (acknowledge_match_counter == 2) begin
          acknowledge_match_counter <= 0;
          acknowledge_match <= 1'b1;
          // Do consistency_match check on successfuly acknowledge_match as well
          if (rx_cr_consistency == rx_Config_Reg) consistency_match <= 1'b1;
          else consistency_match <= 1'b0;
        end else begin
          acknowledge_match_counter <= acknowledge_match_counter + 1;
        end
      end else begin
        // If the past two CRs disagree (including ACK bit), reset the counter
        acknowledge_match_counter <= 0;
      end
    end else begin
      // If we've found the acknowledge_match, just reset the counter and wait for
      // the next state change
      acknowledge_match_counter <= 0;
    end
  end
end

// ========================= Transmit State Machine ==========================
// TODO - What kind of IDLE ordered set should I send?  I guess I'll just
//        alternate for now
// TODO - How fast should I send out IDLE ordered sets?  I guess I'll just
//        blast them out at full speed for now.
reg ordered_set_variant=1'b0;
reg [1:0] byte_counter=0;
reg in_loop=1'b0;
/*
* I1 = /K.28.5/D.5.6
*      Used to flip running disparity (RD, see 8b/10b)
* I2 = /K.28.5/D.16.2
*      Used to maintain running disparity (RD)
*/
`ifdef SIMULATE
  reg tx_non_breaklink=1'b0;
`endif
always @(posedge clk) begin
  if (xmit_rst_stb) begin
    byte_counter <= 0;
    ordered_set_variant <= 1'b0;
  end
  case (xmit)
    // TODO - State initialization is not handled here
    XMIT_IDLE: begin
      if (byte_counter == 1) begin
        if (ordered_set_variant) tx_byte <= D_16_2_DEC;
        else tx_byte <= D_5_6_DEC;
        tx_is_k <= 1'b0;
        ordered_set_variant <= ~ordered_set_variant;
      end else if (byte_counter == 0) begin
        tx_byte <= K_28_5_DEC;
        tx_is_k <= 1'b1;
      end
      byte_counter <= byte_counter + 1;
    end
    XMIT_CONFIGURATION: begin
      `ifdef SIMULATE
      if ((tx_Config_Reg != 0) && ~tx_non_breaklink) begin
        tx_non_breaklink <= 1'b1;
        $display("%s(%t) Transmitting 0x%x", INDENT, $stime, tx_Config_Reg);
      end else if ((tx_Config_Reg == 0) && tx_non_breaklink) begin
        tx_non_breaklink <= 1'b0;
        $display("%s(%t) Transmitting breaklink", INDENT, $stime);
      end
      `endif
      // Just blast out the CR
      /* C1 = /K.28.5/D.21.5/Config_Reg
       * C2 = /K.28.5/D.2.2/Config_Reg
       */
      if (byte_counter == 0) begin
        tx_byte <= K_28_5_DEC;
        tx_is_k <= 1'b1;
      end else if (byte_counter == 1) begin
        if (ordered_set_variant) tx_byte <= D_21_5_DEC;
        else tx_byte <= D_2_2_DEC;
        tx_is_k <= 1'b0;
        ordered_set_variant <= ~ordered_set_variant;
      end else if (byte_counter == 2) begin
        tx_byte <= tx_Config_Reg[7:0];
        tx_is_k <= 1'b0;
      end else begin
        tx_byte <= tx_Config_Reg[15:8];
        tx_is_k <= 1'b0;
      end
      byte_counter <= byte_counter + 1;
    end
    default: begin
      // Includes XMIT_DATA
      tx_byte <= 0;
      tx_is_k <= 1'b0;
    end
  endcase
end

endmodule
