`timescale 1ns / 1ps

// ------------------------------------
// QGTX_WRAP.v
// Low-level wrapper for Quad GTX with configurable number of GTX instances (through defines)
//
// ------------------------------------

`define GTi_PORTS(GT, DWI) input  [DWI-1:0] ``GT``_txdata_in,\
                           output [DWI-1:0] ``GT``_rxdata_out,\
                           input            ``GT``_txusrrdy_in,\
                           input            ``GT``_rxusrrdy_in,\
                           input            ``GT``_rxn_in,\
                           input            ``GT``_rxp_in,\
                           output           ``GT``_txn_out,\
                           output           ``GT``_txp_out,\
                           output           ``GT``_txfsm_resetdone_out,\
                           output           ``GT``_rxfsm_resetdone_out,\
                           output [2:0]     ``GT``_rxbufstatus,\
                           output [1:0]     ``GT``_txbufstatus,\
                           output           ``GT``_txusrclk_out,\
                           output           ``GT``_rxusrclk_out,

`define GTi_WIRES(GT) wire ``GT``_cpll_locked, ``GT``_txresetdone, ``GT``_rxresetdone;

`define GTi_PORT_MAP(GT) .``GT``_tx_fsm_reset_done_out (``GT``_txfsm_resetdone_out),\
                         .``GT``_rx_fsm_reset_done_out (``GT``_rxfsm_resetdone_out),\
                         .``GT``_data_valid_in         (1'b1),\
                         .``GT``_txusrclk_out          (``GT``_txusrclk_out),\
                         .``GT``_txusrclk2_out         (),\
                         .``GT``_rxusrclk_out          (``GT``_rxusrclk_out),\
                         .``GT``_rxusrclk2_out         (),\
                         .``GT``_cpllfbclklost_out     (),\
                         .``GT``_cplllock_out          (``GT``_cpll_locked),\
                         .``GT``_cpllreset_in          (gt_cpll_reset),\
                         .``GT``_drpaddr_in            (9'b0),\
                         .``GT``_drpdi_in              (16'b0),\
                         .``GT``_drpdo_out             (),\
                         .``GT``_drpen_in              (1'b0),\
                         .``GT``_drprdy_out            (),\
                         .``GT``_drpwe_in              (1'b0),\
                         .``GT``_dmonitorout_out       (),\
                         .``GT``_eyescanreset_in       (1'b0),\
                         .``GT``_rxuserrdy_in          (``GT``_rxusrrdy_in),\
                         .``GT``_eyescandataerror_out  (),\
                         .``GT``_eyescantrigger_in     (1'b0),\
                         .``GT``_rxdata_out            (``GT``_rxdata_out),\
                         .``GT``_gtxrxp_in             (``GT``_rxp_in),\
                         .``GT``_gtxrxn_in             (``GT``_rxn_in),\
                         .``GT``_rxdfelpmreset_in      (1'b0),\
                         .``GT``_rxbufstatus_out       (``GT``_rxbufstatus),\
                         .``GT``_rxmonitorout_out      (),\
                         .``GT``_rxmonitorsel_in       (1'b0),\
                         .``GT``_rxoutclkfabric_out    (),\
                         .``GT``_gtrxreset_in          (gt_txrx_reset),\
                         .``GT``_rxpmareset_in         (gt_txrx_reset),\
                         .``GT``_rxresetdone_out       (``GT``_rxresetdone),\
                         .``GT``_gttxreset_in          (gt_txrx_reset),\
                         .``GT``_txuserrdy_in          (``GT``_txusrrdy_in),\
                         .``GT``_txbufstatus_out       (``GT``_txbufstatus),\
                         .``GT``_txdata_in             (``GT``_txdata_in),\
                         .``GT``_gtxtxn_out            (``GT``_txn_out),\
                         .``GT``_gtxtxp_out            (``GT``_txp_out),\
                         .``GT``_txoutclkfabric_out    (),\
                         .``GT``_txoutclkpcs_out       (),\
                         .``GT``_txresetdone_out       (``GT``_txresetdone),

module qgtx_wrap # (
   parameter CPLL_RESET_WAIT = 60, // In clock cycles. Actual time must be >= 500 ns
   parameter GT0_WI = 20,
   parameter GT1_WI = 20,
   parameter GT2_WI = 20,
   parameter GT3_WI = 20
)(
   input         drpclk_in,
   input         soft_reset,
   input         gtrefclk0_p,
   input         gtrefclk0_n,
`ifdef GTREFCLK1
   input         gtrefclk1_p,
   input         gtrefclk1_n,
`endif
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
   gtwizard i_gtwizard
   (
      //____________________________COMMON PORTS________________________________
      .soft_reset_tx_in               (soft_reset),
      .soft_reset_rx_in               (soft_reset),
      .dont_reset_on_data_error_in    (1'b0),

      .q0_clk0_gtrefclk_pad_n_in      (gtrefclk0_n),
      .q0_clk0_gtrefclk_pad_p_in      (gtrefclk0_p),
`ifdef GTREFCLK1
      .q0_clk1_gtrefclk_pad_n_in      (gtrefclk1_n),
      .q0_clk1_gtrefclk_pad_p_in      (gtrefclk1_p),
`endif
`ifdef GT0_ENABLE `GTi_PORT_MAP(gt0) `endif
`ifdef GT1_ENABLE `GTi_PORT_MAP(gt1) `endif
`ifdef GT2_ENABLE `GTi_PORT_MAP(gt2) `endif
`ifdef GT3_ENABLE `GTi_PORT_MAP(gt3) `endif
      .gt0_qplloutclk_out             (),
      .gt0_qplloutrefclk_out          (),
      .sysclk_in                      (drpclk_in)
   );

`endif // `ifndef SIMULATE

endmodule
