// ------------------------------------
// COMMS_TOP.v
//
// TODO: Better summary of what's going on here
//       WARNING: Compatible with QF2_PRE *only*. Older board versions are unsupported
//       Instantiates Ethernet, ChitChat and ICC cores and connects them
//       to an auto-generated Quad GTX.
//       Ethernet core/local-bus gives access to other cores, which will operate in loopback mode.
// ------------------------------------

`include comms_pack.vh

module comms_top
(
   input   sys_clk_p,       // 50 MHz clock
   input   sys_clk_n,
   input   kintex_data_in_p,
   input   kintex_data_in_n,
   output  kintex_data_out_p,
   output  kintex_data_out_n,
   output  kintex_done,

   // QSFP management pins
   input   K7_QSFP_SCL,
   input   K7_QSFP_SDA,

   // QSFP1, bank 116
   input   K7_QSFP1_PRSNTL,
   input   K7_QSFP1_INTL,
   output  K7_QSFP1_RESETL,
   output  K7_QSFP1_MODSEL,
   output  K7_QSFP1_LPMODE,

   input   K7_MGTREFCLK0_P, // D6 - Y4[2] - SIT9122
   input   K7_MGTREFCLK0_N, // D5 - Y4[1] - SIT9122
   input   K7_MGTREFCLK1_P,
   input   K7_MGTREFCLK1_N,
   input   K7_QSFP1_RX0_P,  // C4
   input   K7_QSFP1_RX0_N,  // C3
   output  K7_QSFP1_TX0_P,  // B2
   output  K7_QSFP1_TX0_N,  // B1

   input   K7_MGTREFCLK2_P,
   input   K7_MGTREFCLK2_N,
   input   K7_MGTREFCLK3_P,
   input   K7_MGTREFCLK3_N,

   output  K7_GTX_REF_CTRL,

   output [1:0] LEDS
);

   localparam IPADDR   = {8'd192, 8'd168, 8'd1, 8'd173};
   localparam MACADDR  = 48'h00105ad155b2;
   localparam JUMBO_DW = 14; 

   // selection of QSFP
   // on QF2-pre, REFCLK0 comes from D6/D5 from Y4 (SIT9122)
   wire gtrefclk_p = K7_MGTREFCLK0_P;
   wire gtrefclk_n = K7_MGTREFCLK0_N;
   
   wire sfp_tx_n;  assign K7_QSFP1_TX0_N = sfp_tx_n;
   wire sfp_tx_p;  assign K7_QSFP1_TX0_P = sfp_tx_p;
   wire sfp_rx_n   = K7_QSFP1_RX0_N;
   wire sfp_rx_p   = K7_QSFP1_RX0_P;
   
   // Enable Y4(SIT9122) for GTX_REF_CLK
   assign K7_GTX_REF_CTRL = 1'b1;
   
   assign kintex_done = 1'b1;

   // Not using Spartan-Kintex connection
   wire kintex_data_in, kintex_data_out;

   assign kintex_data_in    = kintex_data_in_p;
   assign kintex_data_out_p = 1'b0;
   assign kintex_data_out_n = 1'b1;

   // ----------------------------------
   // Clocking
   // ---------------------------------
   wire sys_clk;

   wire gtx_tx_out_clk, gtx_rx_out_clk;
   wire gmii_tx_clk, gmii_rx_clk;
   wire gtx_tx_usr_clk, gtx_rx_usr_clk;
   wire tx_pll_lock, rx_pll_lock;

   // Generate single clock from differential system clk
   ds_clk_buf i_ds_clk (
      .clk_p     (sys_clk_p),
      .clk_n     (sys_clk_n),
      .clk_out   (sys_clk),
   )
   
`ifdef SIMULATE
   assign gmii_tx_clk = gtrefclk_p; // Use positive end of 125 MHz clk
   assign gmii_rx_clk = gtrefclk_p;
`else

   // Pass 62.5 MHz TXOUTCLK through clock manager to generate 125 MHz clock

   // Ethernet clock managers
   gtx_eth_clks i_gtx_eth_clks_tx (
      .gtx_out_clk (gtx_tx_out_clk), // From transceiver
      .gtx_usr_clk (gtx_tx_usr_clk), // Buffered 62.5 MHz
      .gmii_clk    (gmii_tx_clk),    // Buffered 125 MHz
      .pll_lock    (tx_pll_lock)
   );

   gtx_eth_clks i_gtx_eth_clks_rx (
      .gtx_out_clk (gtx_rx_out_clk), // From transceiver
      .gtx_usr_clk (gtx_rx_usr_clk),
      .gmii_clk    (gmii_rx_clk),
      .pll_lock    (rx_pll_lock)
   );
`endif

   // ----------------------------------
   // GTX Instantiation
   // ---------------------------------

   // Instantiate wizard-generated GTX transceiver
   // Configured by gtx_ethernet.tcl and gtx_gen.tcl

   // Status signals
   wire gt_cpll_locked;
   wire gt_txrx_resetdone;

   wire gt0_rxfsm_resetdone, gt0_txfsm_resetdone;
   wire [2:0] gt0_rxbufstatus;
   wire [1:0] gt0_txbufstatus;

   `define GT0_ENABLE
   //`define GT1_ENABLE
   //`define GT2_ENABLE
   //`define GT3_ENABLE
   //`define GTREFCLK1

   qgtx_wrap #(
      .GT0_WI (GTX_ETH_WIDTH))
   i_qgtx_wrap (
      // Common Pins
      .drpclk_in               (sys_clk)
      .soft_reset              (1'b0),

      .gt_txrx_resetdone       (gt_txrx_resetdone),
      .gt_cpll_locked          (gt_cpll_locked),

      .gtrefclk0_p             (gtrefclk_p),
      .gtrefclk0_n             (gtrefclk_n),
      // GTX0 Pins
      .GT0_txdata_in           (gtx_txd),
      .GT0_rxdata_out          (gtx_rxd),
      .GT0_txusrrdy_in         (tx_pll_lock),
      .GT0_rxusrrdy_in         (rx_pll_lock),
      .GT0_rxn_in              (sfp_rx_n),
      .GT0_rxp_in              (sfp_rx_p),
      .GT0_txn_out             (sfp_tx_n),
      .GT0_txp_out             (sfp_tx_p),
      .GT0_rxresetdone         (gt0_rxresetdone),
      .GT0_txresetdone         (gt0_txresetdone),
      .GT0_txfsm_resetdone_out (gt0_txfsm_resetdone),
      .GT0_rxfsm_resetdone_out (gt0_rxfsm_resetdone),
      .GT0_rxbufstatus         (gt0_rxbufstatus),
      .GT0_txbufstatus         (gt0_txbufstatus),
      .GT0_txusrclk_out        (gtx_tx_out_clk),
      .GT0_rxusrclk_out        (gtx_rx_out_clk),
   );
   

   // ----------------------------------
   // GTX Ethernet to Local-Bus bridge
   // ---------------------------------
   wire lb_valid, lb_rnw, lb_rvalid;
   wire [LBUS_ADDR_WIDTH-1:0] lb_addr;
   wire [LBUS_DATA_WIDTH-1:0] lb_wdata, lb_rdata;

   wire [GTX_ETH_WIDTH-1:0] gtx_rxd, gtx_txd;

   eth_gtx_bridge #(
      .IP         (IPADDR),
      .MAC        (MACADDR),
      .JUMBO_DW   (JUMBO_DW),
   (
      .gtx_tx_clk  (gtx_tx_usr_clk), // Transceiver clock at half rate
      .gmii_tx_clk (gmii_tx_clk), // Clock for Ethernet fabric - 125 MHz for 1GbE 
      .gmii_rx_clk (gmii_rx_clk),
      .gtx_rxd     (gtx_rxd),
      .gtx_txd     (gtx_txd),

      // Local bus interface
      .lb_valid    (lb_valid),
      .lb_rnw      (lb_rnw),
      .lb_addr     (lb_addr),
      .lb_wdata    (lb_wdata),
      .lb_rvalid   (lb_rvalid),
      .lb_rdata    (lb_rdata)
   );

   // TODO: Temporary loopback code
   always @(posedge gmii_rx_clk) begin
      lb_rvalid <= lb_valid;
      lb_rdata  <= lb_wdata;
   end
   
   // LED[0] GT Initialization done
   // LED[1] Received and decoded packet
   assign LEDS = {gt_txrx_resetdone, lb_valid};

endmodule

