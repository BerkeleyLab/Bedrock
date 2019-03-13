`timescale 1ns / 1ps

// ------------------------------------
// QGTX_WRAP.v
// Low-level wrapper for Quad GTX with configurable number of GTX instances (through defines)
//
// ------------------------------------

`define GTi_PORTS(GT, DWI) output           ``GT``_rxoutclk_out,\
                           input            ``GT``_rxusrclk_in,\
                           input            ``GT``_rxusrclk2_in,\
                           output           ``GT``_txoutclk_out,\
                           input            ``GT``_txusrclk_in,\
                           input            ``GT``_txusrclk2_in,\
                           input            ``GT``_rxusrrdy_in,\
                           output [DWI-1:0] ``GT``_rxdata_out,\
                           input            ``GT``_txusrrdy_in,\
                           input  [DWI-1:0] ``GT``_txdata_in,\
                           input            ``GT``_rxn_in,\
                           input            ``GT``_rxp_in,\
                           output           ``GT``_txn_out,\
                           output           ``GT``_txp_out,\
                           output           ``GT``_rxfsm_resetdone_out,\
                           output           ``GT``_txfsm_resetdone_out,\
                           output [2:0]     ``GT``_rxbufstatus,\
                           output [1:0]     ``GT``_txbufstatus,

`define GTi_WIRES(GT) wire ``GT``_cpll_locked, ``GT``_txresetdone, ``GT``_rxresetdone,\
                           ``GT``_txoutclk_out_l, ``GT``_rxoutclk_out_l;

`define GTi_PORT_MAP(GT) .sysclk_in                   (drpclk_in),\
                         .soft_reset_tx_in            (soft_reset),\
                         .soft_reset_rx_in            (soft_reset),\
                         .dont_reset_on_data_error_in (1'b0),\
                         .gt0_gtrefclk0_in            (gtrefclk0),\
                         .gt0_gtrefclk1_in            (gtrefclk1),\
                         .gt0_tx_fsm_reset_done_out   (``GT``_txfsm_resetdone_out),\
                         .gt0_rx_fsm_reset_done_out   (``GT``_rxfsm_resetdone_out),\
                         .gt0_data_valid_in           (1'b1),\
                         .gt0_cpllfbclklost_out       (),\
                         .gt0_cplllock_out            (``GT``_cpll_locked),\
                         .gt0_cplllockdetclk_in       (drpclk_in),\
                         .gt0_cpllreset_in            (gt_cpll_reset),\
                         .gt0_drpaddr_in              (9'b0),\
                         .gt0_drpclk_in               (drpclk_in),\
                         .gt0_drpdi_in                (16'b0),\
                         .gt0_drpdo_out               (),\
                         .gt0_drpen_in                (1'b0),\
                         .gt0_drprdy_out              (),\
                         .gt0_drpwe_in                (1'b0),\
                         .gt0_dmonitorout_out         (),\
                         .gt0_eyescanreset_in         (1'b0),\
                         .gt0_rxuserrdy_in            (``GT``_rxusrrdy_in),\
                         .gt0_eyescandataerror_out    (),\
                         .gt0_eyescantrigger_in       (1'b0),\
                         .gt0_rxusrclk_in             (``GT``_rxusrclk_in),\
                         .gt0_rxusrclk2_in            (``GT``_rxusrclk2_in),\
                         .gt0_rxdata_out              (``GT``_rxdata_out),\
                         .gt0_gtxrxp_in               (``GT``_rxp_in),\
                         .gt0_gtxrxn_in               (``GT``_rxn_in),\
                         .gt0_rxbufstatus_out         (``GT``_rxbufstatus),\
                         .gt0_rxdfelpmreset_in        (1'b0),\
                         .gt0_rxmonitorout_out        (),\
                         .gt0_rxmonitorsel_in         (1'b0),\
                         .gt0_rxoutclk_out            (``GT``_rxoutclk_out_l),\
                         .gt0_rxoutclkfabric_out      (),\
                         .gt0_gtrxreset_in            (gt_txrx_reset),\
                         .gt0_rxpmareset_in           (gt_txrx_reset),\
                         .gt0_rxresetdone_out         (``GT``_rxresetdone),\
                         .gt0_gttxreset_in            (gt_txrx_reset),\
                         .gt0_txuserrdy_in            (``GT``_txusrrdy_in),\
                         .gt0_txusrclk_in             (``GT``_txusrclk_in),\
                         .gt0_txusrclk2_in            (``GT``_txusrclk2_in),\
                         .gt0_txbufstatus_out         (``GT``_txbufstatus),\
                         .gt0_txdata_in               (``GT``_txdata_in),\
                         .gt0_gtxtxn_out              (``GT``_txn_out),\
                         .gt0_gtxtxp_out              (``GT``_txp_out),\
                         .gt0_txoutclk_out            (``GT``_txoutclk_out_l),\
                         .gt0_txoutclkfabric_out      (),\
                         .gt0_txoutclkpcs_out         (),\
                         .gt0_txresetdone_out         (``GT``_txresetdone),\
                         .gt0_qplloutclk_in           (1'b0),\
                         .gt0_qplloutrefclk_in        (1'b0)

`define GTX_OUTCLK_BUF(GT) BUFG i_``GT``_txoutclk_buf (.I (``GT``_txoutclk_out_l), .O (``GT``_txoutclk_out));\
                           BUFG i_``GT``_rxoutclk_buf (.I (``GT``_rxoutclk_out_l), .O (``GT``_rxoutclk_out));

module qgtx_wrap # (
   parameter CPLL_RESET_WAIT = 60, // In clock cycles. Actual time must be >= 500 ns
   parameter GT0_WI = 20,
   parameter GT1_WI = 20,
   parameter GT2_WI = 20,
   parameter GT3_WI = 20
)(
   input         drpclk_in,
   input         soft_reset,
   input         gtrefclk0,
   input         gtrefclk1,
`ifdef GT0_ENABLE
   `GTi_PORTS(gt0, GT0_WI)
`endif
`ifdef GT1_ENABLE
   `GTi_PORTS(gt1, GT1_WI)
`endif
`ifdef GT2_ENABLE
   `GTi_PORTS(gt2, GT2_WI)
`endif
`ifdef GT3_ENABLE
   `GTi_PORTS(gt3, GT3_WI)
`endif
   output        gt_cpll_locked,
   output        gt_txrx_resetdone
);

`ifdef GT0_ENABLE `GTi_WIRES(gt0) `endif
`ifdef GT1_ENABLE `GTi_WIRES(gt1) `endif
`ifdef GT2_ENABLE `GTi_WIRES(gt2) `endif
`ifdef GT3_ENABLE `GTi_WIRES(gt3) `endif

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
         `GTi_PORT_MAP (gt0)
      );

      `GTX_OUTCLK_BUF(gt0)
   `endif

   `ifdef GT1_ENABLE
      `GTX_MODULE(1) i_gtx1 (
         `GTi_PORT_MAP (gt1)
      );

      `GTX_OUTCLK_BUF(gt1)
   `endif

   `ifdef GT2_ENABLE
      `GTX_MODULE(2) i_gtx2 (
         `GTi_PORT_MAP (gt2)
      );

      `GTX_OUTCLK_BUF(gt2)
   `endif

   `ifdef GT3_ENABLE
      `GTX_MODULE(3) i_gtx3 (
         `GTi_PORT_MAP (gt3)
      );

      `GTX_OUTCLK_BUF(gt3)
   `endif

`endif // `ifndef SIMULATE

endmodule
