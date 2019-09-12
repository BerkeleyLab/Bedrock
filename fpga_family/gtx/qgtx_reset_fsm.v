`timescale 1ns / 1ps

// ------------------------------------
// QGTX_RESET_FSM.v
// Reset FSM for Quad GTX with configurable number of individual transceivers.
// Transceiver bringup performed in parallel.
//
// Transceiver reset sequence:
// 1. Reset TX and RX PLLs and wait for lock
// 2. Reset TX and RX transceiver paths
// 3. Wait for TX and RX resetdone
//
// ------------------------------------

module qgtx_reset_fsm # (
   parameter PLL_RESET_WAIT = 60 // In clock cycles. Actual time must be >= 500 ns
) (
   input  drpclk_in,

   input  gt0_pll_locked,
   input  gt1_pll_locked,
   input  gt2_pll_locked,
   input  gt3_pll_locked,

   input  gt0_txresetdone,
   input  gt1_txresetdone,
   input  gt2_txresetdone,
   input  gt3_txresetdone,

   input  gt0_rxresetdone,
   input  gt1_rxresetdone,
   input  gt2_rxresetdone,
   input  gt3_rxresetdone,

   output gt_pll_powerdown,

   output gt_pll_reset,
   output gt_txrx_reset,

   output gt_pll_locked,
   output gt_txrx_resetdone

);
   localparam FSM_LEN = 2;
   localparam IDLE = 0, POWER_UP = 1, PLL_WAIT = 2, DONE = 3;

   reg [FSM_LEN-1:0] rst_state = IDLE;
   reg [FSM_LEN-1:0] n_rst_state;
   reg [6:0]         reset_wait = 0;

   reg gt_pll_powerdown_r = 1;
   reg gt_pll_reset_r = 0;
   reg gt_txrx_reset_r = 0;
   reg gt_txrx_resetdone_r = 0;
   reg gt_txrx_resetdone_n;

   wire gt_pll_locked_l, gt_txrxresetdone_l;

   assign gt_pll_locked_l = &{gt0_pll_locked,
                               gt1_pll_locked,
                               gt2_pll_locked,
                               gt3_pll_locked};

   assign gt_txrxresetdone_l = &{gt0_txresetdone, gt0_rxresetdone,
                                 gt1_txresetdone, gt1_rxresetdone,
                                 gt2_txresetdone, gt2_rxresetdone,
                                 gt3_txresetdone, gt3_rxresetdone};

   always @(posedge drpclk_in) begin
      rst_state <= n_rst_state;

      if (reset_wait <= PLL_RESET_WAIT) begin
         reset_wait <= reset_wait + 1;
      end
      if (gt_txrx_resetdone_n) begin
         gt_txrx_resetdone_r <= 1; // Latch status
      end
   end

   always @(rst_state, reset_wait,
            gt_pll_locked_l, gt_txrxresetdone_l)
   begin
      n_rst_state         <= rst_state;

      gt_pll_reset_r     <= 0;
      gt_txrx_reset_r     <= 0;
      gt_txrx_resetdone_n <= 0;

      case (rst_state)
         IDLE :
            if (reset_wait == PLL_RESET_WAIT) begin
               gt_pll_reset_r <= 1;
               n_rst_state     <= POWER_UP;
            end
         POWER_UP :
            gt_pll_powerdown_r <= 0;
            n_rst_state        <= PLL_WAIT;
         PLL_WAIT :
            if (gt_pll_locked_l) begin
               gt_txrx_reset_r <= 1;
               n_rst_state     <= DONE;
            end
         default : // DONE
            if (gt_txrxresetdone_l) begin
               gt_txrx_resetdone_n <= 1;
               n_rst_state         <= IDLE;
            end
      endcase
   end

   // Drive output pins
   assign gt_pll_powerdown  = gt_pll_powerdown_r;
   assign gt_pll_reset      = gt_pll_reset_r;
   assign gt_txrx_reset     = gt_txrx_reset_r;
   assign gt_pll_locked     = gt_pll_locked_l;
   assign gt_txrx_resetdone = gt_txrx_resetdone_r;

endmodule
