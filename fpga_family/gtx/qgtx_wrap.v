`timescale 1ns / 1ps

// ------------------------------------
// QGTX_WRAP.v
// Low-level wrapper for Quad GTX with configurable number of GTX instances (through defines)
//
// ------------------------------------
`include "qgtx_wrap_pack.vh"

module qgtx_wrap # (
   parameter CPLL_RESET_WAIT = 60, // In clock cycles. Actual time must be >= 500 ns
   parameter GT0_WI = 20,
   parameter GT1_WI = 20,
   parameter GT2_WI = 20,
   parameter GT3_WI = 20
)(
   input         drpclk_in,
   input         soft_reset,
   input         gtrefclk0_n,
   input         gtrefclk0_p,
`ifdef GTREFCLK1_EN
   input         gtrefclk1_n,
   input         gtrefclk1_p,
`endif

`ifndef SIMULATE
   `ifdef GT0_ENABLE
   `GTi_PORTS(0, GT0_WI)
   `endif
   `ifdef GT1_ENABLE
   `GTi_PORTS(1, GT1_WI)
   `endif
   `ifdef GT2_ENABLE
   `GTi_PORTS(2, GT2_WI)
   `endif
   `ifdef GT3_ENABLE
   `GTi_PORTS(3, GT3_WI)
   `endif
`endif
   output        gt_cpll_locked,
   output        gt_txrx_resetdone
);

`ifdef GT0_ENABLE `GTi_WIRES(0) `endif
`ifdef GT1_ENABLE `GTi_WIRES(1) `endif
`ifdef GT2_ENABLE `GTi_WIRES(2) `endif
`ifdef GT3_ENABLE `GTi_WIRES(3) `endif

   // Transceiver reset sequence:
   // 1. Reset TX and RX PLLs and wait for lock
   // 2. Reset TX and RX transceiver paths
   // 3. Wait for TX and RX resetdone

   localparam FSM_SIZE = 3;
   localparam IDLE = 0, CPLL_WAIT = 1, DONE = 3;

   reg [FSM_SIZE-1:0] rst_state = IDLE;
   reg [FSM_SIZE-1:0] n_rst_state;
   reg [6:0]          reset_wait = 0;

   reg  gt_cpll_reset = 0;
   wire gt_cpll_locked_l, gt_txrxresetdone_l;

   reg gt_txrx_reset = 0;

   reg gt_txrx_resetdone_r = 0;
   reg gt_txrx_resetdone_n;


   assign gt_cpll_locked_l = &{1'b1,
             `ifdef GT0_ENABLE gt0_cpll_locked, `endif
             `ifdef GT1_ENABLE gt1_cpll_locked, `endif
             `ifdef GT2_ENABLE gt2_cpll_locked, `endif
             `ifdef GT3_ENABLE gt3_cpll_locked, `endif
                               1'b1};

   assign gt_txrxresetdone_l = &{1'b1,
               `ifdef GT0_ENABLE gt0_txresetdone, gt0_rxresetdone, `endif
               `ifdef GT1_ENABLE gt1_txresetdone, gt1_rxresetdone, `endif
               `ifdef GT2_ENABLE gt2_txresetdone, gt2_rxresetdone, `endif
               `ifdef GT3_ENABLE gt3_txresetdone, gt3_rxresetdone, `endif
                                 1'b1};


   always @(posedge drpclk_in) begin
      rst_state <= n_rst_state;

      if (reset_wait <= CPLL_RESET_WAIT) begin
         reset_wait <= reset_wait + 1;
      end

      if (gt_txrx_resetdone_n) begin
         gt_txrx_resetdone_r <= 1; // Latch status
      end
   end

   always @(rst_state, reset_wait,
            gt_cpll_locked_l, gt_txrxresetdone_l)
   begin
      n_rst_state         <= rst_state;

      gt_cpll_reset       <= 0;
      gt_txrx_reset       <= 0;
      gt_txrx_resetdone_n <= 0;

      case (rst_state)
         IDLE :
            if (reset_wait == CPLL_RESET_WAIT) begin
               gt_cpll_reset <= 1;
               n_rst_state   <= CPLL_WAIT;
            end
         CPLL_WAIT :
            if (gt_cpll_locked_l) begin
               gt_txrx_reset <= 1;
               n_rst_state   <= DONE;
            end
         default : // DONE
            if (gt_txrxresetdone_l) begin
               gt_txrx_resetdone_n <= 1;
               n_rst_state         <= IDLE;
            end
      endcase
   end

   // Map output pins
   assign gt_cpll_locked    = gt_cpll_locked_l;
   assign gt_txrx_resetdone = gt_txrx_resetdone_r;

   // Generate single-ended clocks from differential inputs
   // This conversion must use a transceiver-specific Diff-to-Single buffer
   wire gtrefclk0, gtrefclk1;

   ds_clk_buf #(
      .GTX (1)) // Use GTX-specific primitive
   i_ds_gtrefclk0 (
      .clk_p   (gtrefclk0_p),
      .clk_n   (gtrefclk0_n),
      .clk_out (gtrefclk0)
   );

`ifdef GTREFCLK1_EN
   ds_clk_buf #(
      .GTX (1))
   i_ds_gtrefclk1 (
      .clk_p   (gtrefclk1_p),
      .clk_n   (gtrefclk1_n),
      .clk_out (gtrefclk1)
   );
`endif

`ifndef SIMULATE
   // Instantiate wizard-generated Quad GTX
   // Configured by gtx_gen.tcl

   `ifdef Q1_ENABLE
      `define GTX_MODULE(GT) q1_gtx``GT``
   `else
      `define GTX_MODULE(GT) q0_gtx``GT``
   `endif

   `ifdef GT0_ENABLE
      `GTX_MODULE(0) i_gtx0 (
         `GTi_PORT_MAP (0)
      );

      `GTX_OUTCLK_BUF(0)
   `endif

   `ifdef GT1_ENABLE
      `GTX_MODULE(1) i_gtx1 (
         `GTi_PORT_MAP (1)
      );

      `GTX_OUTCLK_BUF(1)
   `endif

   `ifdef GT2_ENABLE
      `GTX_MODULE(2) i_gtx2 (
         `GTi_PORT_MAP (2)
      );

      `GTX_OUTCLK_BUF(2)
   `endif

   `ifdef GT3_ENABLE
      `GTX_MODULE(3) i_gtx3 (
         `GTi_PORT_MAP (3)
      );

      `GTX_OUTCLK_BUF(3)
   `endif

`endif // `ifndef SIMULATE

endmodule
