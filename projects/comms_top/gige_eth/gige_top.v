// ------------------------------------
// GIGE_TOP.v
//
// NOTE: Minimal example of Gigabit Ethernet / 100BASE-X over gigabit transceiver
// ------------------------------------

module gige_top (
   input   SYS_CLK_P,
   input   SYS_CLK_N,

   input   MGTREFCLK0_P,
   input   MGTREFCLK0_N,
   input   MGTREFCLK1_P,
   input   MGTREFCLK1_N,

   output  MGTREFCLK0_SEL1,
   output  MGTREFCLK0_SEL0,

   input   SFP_RXP,
   input   SFP_RXN,
   output  SFP_TXP,
   output  SFP_TXN,

   output [3:0] LED
);

`include "comms_features.vh"
`include "comms_pack.vh"

   localparam IPADDR   = {8'd192, 8'd168, 8'd1, 8'd179};
   localparam MACADDR  = 48'h00105ad155b5;

`define AC701
`ifdef AC701
   assign {MGTREFCLK0_SEL1, MGTREFCLK0_SEL0} = 2'b0; // 125 MHz clock
`endif

   // ----------------------------------
   // Clocking
   // ---------------------------------
   wire sys_clk_fast, sys_clk;
   wire gtrefclk0, gtrefclk1;

   wire gmii_tx_clk, gmii_rx_clk;
   wire gt0_tx_out_clk, gt0_rx_out_clk;
   wire gt0_tx_usr_clk, gt0_rx_usr_clk;
   wire tx0_pll_lock, rx0_pll_lock;

   // Generate single clock from differential system clk
   ds_clk_buf i_ds_sys_clk (
      .clk_p   (SYS_CLK_P),
      .clk_n   (SYS_CLK_N),
      .clk_out (sys_clk_fast)
   );

`ifndef SIMULATE
   // Convert from 200 MHz to 50 MHz to meet DRPCLK timing requirement of MGT
   gtp_sys_clk_mmcm i_gtp_sys_clk_mmcm (
      .clk_in  (sys_clk_fast),
      .sys_clk (sys_clk), // Buffered 50 MHz
      .locked  ()
   );
`else
   assign sys_clk = sys_clk_fast;
`endif

   // Generate single-ended reference clock from MGTREFCLK_N/P with Transceiver BUF
   ds_clk_buf #(
      .GTX (1)) // Use GTX-specific primitive
   i_ds_gtrefclk0 (
      .clk_p   (MGTREFCLK0_P),
      .clk_n   (MGTREFCLK0_N),
      .clk_out (gtrefclk0)
   );

   ds_clk_buf #(
      .GTX (1)) // Use GTX-specific primitive
   i_ds_gtrefclk1 (
      .clk_p   (MGTREFCLK1_P),
      .clk_n   (MGTREFCLK1_N),
      .clk_out (gtrefclk1)
   );

   // Status signals
   wire [3:0] gt_cpll_locked;
   wire [3:0] gt_txrx_resetdone;

   // Route 62.5 MHz TXOUTCLK through clock manager to generate 125 MHz clock
   // Ethernet clock managers
   mgt_eth_clks i_gt_eth_clks_tx (
      .reset       (~gt_cpll_locked[0]),
      .mgt_out_clk (gt0_tx_out_clk), // From transceiver
      .mgt_usr_clk (gt0_tx_usr_clk), // Buffered 62.5 MHz
      .gmii_clk    (gmii_tx_clk),     // Buffered 125 MHz
      .pll_lock    (tx0_pll_lock)
   );

   mgt_eth_clks i_gt_eth_clks_rx (
      .reset       (~gt_cpll_locked[0]),
      .mgt_out_clk (gt0_rx_out_clk), // From transceiver
      .mgt_usr_clk (gt0_rx_usr_clk),
      .gmii_clk    (gmii_rx_clk),
      .pll_lock    (rx0_pll_lock)
   );

   // ----------------------------------
   // GTP Instantiation
   // ---------------------------------

   // Instantiate wizard-generated GTP transceiver
   // Configured by gtx_ethernet.tcl and mgt_gen.tcl
   // Refer to qgt_wrap_pack.vh for port map

   wire [GTX_ETH_WIDTH-1:0]    gt0_rxd, gt0_txd;

   wire gt0_rxfsm_resetdone, gt0_txfsm_resetdone;
   wire [2:0] gt0_rxbufstatus;
   wire [1:0] gt0_txbufstatus;

`ifndef SIMULATE
   q0_gt_wrap #(
`else
   qgt_wrap #(
`endif
      .GT0_WI       (GTX_ETH_WIDTH))
   i_q0_gt_wrap (
      // Common Pins
      .drpclk_in               (sys_clk),
      .soft_reset              (1'b0),
      .gtrefclk0               (gtrefclk0),
      .gtrefclk1               (gtrefclk1),
`ifndef SIMULATE
      // GTP0 - Ethernet
      .gt0_rxoutclk_out        (gt0_rx_out_clk),
      .gt0_rxusrclk_in         (gt0_rx_usr_clk),
      .gt0_txoutclk_out        (gt0_tx_out_clk),
      .gt0_txusrclk_in         (gt0_tx_usr_clk),
      .gt0_rxusrrdy_in         (rx0_pll_lock),
      .gt0_rxdata_out          (gt0_rxd),
      .gt0_txusrrdy_in         (tx0_pll_lock),
      .gt0_txdata_in           (gt0_txd),
      .gt0_rxn_in              (SFP_RXN),
      .gt0_rxp_in              (SFP_RXP),
      .gt0_txn_out             (SFP_TXN),
      .gt0_txp_out             (SFP_TXP),
      .gt0_rxfsm_resetdone_out (gt0_rxfsm_resetdone),
      .gt0_txfsm_resetdone_out (gt0_txfsm_resetdone),
      .gt0_rxbufstatus         (gt0_rxbufstatus),
      .gt0_txbufstatus         (gt0_txbufstatus),
`endif

      .gt_txrx_resetdone       (gt_txrx_resetdone),
      .gt_cpll_locked          (gt_cpll_locked)
   );


   // ----------------------------------
   // GT Ethernet to Local-Bus bridge
   // ---------------------------------
   wire rx_mon, tx_mon;
   wire [8:0] an_status;

   wire lb_valid, lb_rnw, lb_renable;
   wire [C_LBUS_ADDR_WIDTH-1:0] lb_addr;
   wire [C_LBUS_DATA_WIDTH-1:0] lb_wdata, lb_rdata;

   eth_gtx_bridge #(
      .IP         (IPADDR),
      .MAC        (MACADDR),
      .GTX_DW     (GTX_ETH_WIDTH))
   i_eth_gtx_bridge (
      .gtx_tx_clk   (gt0_tx_usr_clk), // Transceiver clock at half rate
      .gmii_tx_clk  (gmii_tx_clk),     // Clock for Ethernet fabric - 125 MHz for 1GbE
      .gmii_rx_clk  (gmii_rx_clk),
      .gtx_rxd      (gt0_rxd),
      .gtx_txd      (gt0_txd),

      // Ethernet configuration interface
      .cfg_clk       (gmii_tx_clk),
      .cfg_enable_rx (1'b1),
      .cfg_valid     (1'b0),
      .cfg_addr      (5'b0),
      .cfg_wdata     (8'b0),
      .cfg_reg       (8'b0),
      // Auto-Negotiation
      .an_disable    (1'b1), // Keep disabled while not connecting to SFP switch
      .an_status     (an_status),

      // Status signals
      .rx_mon        (rx_mon),
      .tx_mon        (tx_mon),

      // Local bus interface in gmii_tx_clk domain
      .lb_valid      (lb_valid),
      .lb_rnw        (lb_rnw),
      .lb_addr       (lb_addr),
      .lb_wdata      (lb_wdata),
      .lb_renable    (lb_renable),
      .lb_rdata      (lb_rdata)
   );

   wire lb_clk = gmii_tx_clk;

   // ----------------------------------
   // Optional CTRACE debugging scope
   // ---------------------------------

wire [31:0] ctr_mem_out;
//`define CTRACE_EN
`ifdef CTRACE_EN

   // Capture live data with Ctrace;
   // Data is compressed with a form of run-length encoding. Max length
   // of a run is determined by CTRACE_TW.
   // CTRACE_AW determines the total number of unique data-points.

   localparam CTR_DW = 16;
   localparam CTR_TW = 16; // Determines maximum run length
   localparam CTR_AW = 16;

   wire ctr_clk = gmii_rx_clk;
   wire ctr_start = dbg_bus[16];
   wire [CTR_DW-1:0] ctr_data = dbg_bus[15:0];

   ctrace #(
      .dw   (CTR_DW),
      .tw   (CTR_TW),
      .aw   (CTR_AW))
   i_ctrace (
      .clk     (ctr_clk),
      .start   (ctr_start),
      .data    (ctr_data),
      .lb_clk  (lb_clk),
      .lb_addr (lb_addr[CTR_AW-1:0]),
      .lb_out  (ctr_mem_out)
);
`endif

   // ----------------------------------
   // Status LEDs
   // ---------------------------------
   wire lbus_led = lb_valid & lb_rnw;


   // LED[0] Auto-negotiation complete
   // LED[1] Received and decoded packet
   // LED[2] 125 MHz buffered clock heartbeat
   // LED[3] Lock

   reg [28:0] hb_count=0;
   wire heartbeat;

   always @(posedge lb_clk) hb_count <= hb_count + 1;
   assign heartbeat = hb_count[28]; // ~ 1 per second

   assign LED = {gt_cpll_locked[0],
                 heartbeat,
                 lbus_led,
                 an_status[0]};

endmodule
