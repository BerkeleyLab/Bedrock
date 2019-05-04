// ------------------------------------
// COMMS_TOP.v
//
// TODO: Better summary of what's going on here
//       WARNING: Compatible with QF2_PRE *only*. Older board versions are unsupported
//       Instantiates Ethernet, ChitChat and ICC cores and connects them
//       to an auto-generated Quad GTX.
//       Ethernet core/local-bus gives access to other cores, which will operate in loopback mode.
// ------------------------------------

module comms_top
(
   input   sys_clk_p,       // 50 MHz clock
   input   sys_clk_n,
   input   kintex_data_in_p,
   input   kintex_data_in_n,
   output  kintex_data_out_p,
   output  kintex_data_out_n,
   output  kintex_done,

   input   K7_MGTREFCLK0_P, // D6 - Y4[2] - SIT9122
   input   K7_MGTREFCLK0_N, // D5 - Y4[1] - SIT9122
   input   K7_MGTREFCLK1_P,
   input   K7_MGTREFCLK1_N,

   input   K7_QSFP1_RX0_P,  // C4
   input   K7_QSFP1_RX0_N,  // C3
   output  K7_QSFP1_TX0_P,  // B2
   output  K7_QSFP1_TX0_N,  // B1

   input   K7_QSFP1_RX1_P,  // B6
   input   K7_QSFP1_RX1_N,  // B5
   output  K7_QSFP1_TX1_P,  // A4
   output  K7_QSFP1_TX1_N,  // A3

   input   K7_MGTREFCLK2_P,
   input   K7_MGTREFCLK2_N,
   input   K7_MGTREFCLK3_P,
   input   K7_MGTREFCLK3_N,

   output  K7_GTX_REF_CTRL,

   output [1:0] LEDS
);

`include "comms_pack.vh"

   localparam IPADDR   = {8'd192, 8'd168, 8'd1, 8'd173};
   localparam MACADDR  = 48'h00105ad155b2;
   localparam JUMBO_DW = 14;

   // on QF2-pre, REFCLK0 comes from D6/D5 from Y4 (SIT9122)
   wire gtrefclk0_p = K7_MGTREFCLK0_P;
   wire gtrefclk0_n = K7_MGTREFCLK0_N;

   // Enable Y4(SIT9122) for GTX_REF_CLK
   assign K7_GTX_REF_CTRL = 1'b1;

   assign kintex_done = 1'b1;

   // Not using Spartan-Kintex connection
   wire kintex_data_in, kintex_data_out;

   assign kintex_data_in = kintex_data_in_p;

`ifndef SIMULATE
   // Drive kintex_data_out with DS buffer to avoid DRC failures
   OBUFDS kintex_dout_ds_dummy(.I(1'b0), .O(kintex_data_out_p), .OB(kintex_data_out_n));
`else
   assign kintex_data_out_p = 1'b1;
   assign kintex_data_out_n = 1'b0;
`endif

   // ----------------------------------
   // Clocking
   // ---------------------------------
   wire sys_clk;
   wire gtrefclk0;

   wire gmii_tx_clk, gmii_rx_clk;
   wire gtx0_tx_out_clk, gtx0_rx_out_clk;
   wire gtx0_tx_usr_clk, gtx0_rx_usr_clk;
   wire tx0_pll_lock, rx0_pll_lock;

   wire gtx1_tx_out_clk, gtx1_rx_out_clk;
   wire gtx1_tx_usr_clk, gtx1_rx_usr_clk;

   // Generate single clock from differential system clk
   ds_clk_buf i_ds_sys_clk (
      .clk_p   (sys_clk_p),
      .clk_n   (sys_clk_n),
      .clk_out (sys_clk)
   );

   // Route 62.5 MHz TXOUTCLK through clock manager to generate 125 MHz clock
   // Ethernet clock managers
   gtx_eth_clks i_gtx_eth_clks_tx (
      .gtx_out_clk (gtx0_tx_out_clk), // From transceiver
      .gtx_usr_clk (gtx0_tx_usr_clk), // Buffered 62.5 MHz
      .gmii_clk    (gmii_tx_clk),     // Buffered 125 MHz
      .pll_lock    (tx0_pll_lock)
   );

   gtx_eth_clks i_gtx_eth_clks_rx (
      .gtx_out_clk (gtx0_rx_out_clk), // From transceiver
      .gtx_usr_clk (gtx0_rx_usr_clk),
      .gmii_clk    (gmii_rx_clk),
      .pll_lock    (rx0_pll_lock)
   );

   // ----------------------------------
   // GTX Instantiation
   // ---------------------------------

   // Instantiate wizard-generated GTX transceiver
   // Configured by gtx_ethernet.tcl and gtx_gen.tcl
   // Refer to qgtx_wrap_pack.vh for port map

   wire [GTX_ETH_WIDTH-1:0] gtx0_rxd, gtx0_txd;
   wire [GTX_CC_WIDTH-1:0]  gtx1_rxd, gtx1_txd;
   wire                     gtx1_txk, gtx1_rxk;

   // Status signals
   wire gt_cpll_locked;
   wire gt_txrx_resetdone;

   wire gt0_rxfsm_resetdone, gt0_txfsm_resetdone;
   wire [2:0] gt0_rxbufstatus;
   wire [1:0] gt0_txbufstatus;
   wire gt1_rxfsm_resetdone, gt1_txfsm_resetdone;
   wire [2:0] gt1_rxbufstatus;
   wire [1:0] gt1_txbufstatus;

   qgtx_wrap #(
      .GT0_WI       (GTX_ETH_WIDTH),
      .GT1_WI       (GTX_CC_WIDTH))
   i_qgtx_wrap (
      // Common Pins
      .drpclk_in               (sys_clk),
      .soft_reset              (1'b0),
      .gtrefclk0_n             (gtrefclk0_n),
      .gtrefclk0_p             (gtrefclk0_p),

`ifndef SIMULATE
      // GTX0 - Ethernet
      .gt0_rxoutclk_out        (gtx0_rx_out_clk),
      .gt0_rxusrclk_in         (gtx0_rx_usr_clk),
      .gt0_rxusrclk2_in        (gtx0_rx_usr_clk),
      .gt0_txoutclk_out        (gtx0_tx_out_clk),
      .gt0_txusrclk_in         (gtx0_tx_usr_clk),
      .gt0_txusrclk2_in        (gtx0_tx_usr_clk),
      .gt0_rxusrrdy_in         (rx0_pll_lock),
      .gt0_rxdata_out          (gtx0_rxd),
      .gt0_txusrrdy_in         (tx0_pll_lock),
      .gt0_txdata_in           (gtx0_txd),
      .gt0_rxn_in              (K7_QSFP1_RX0_N),
      .gt0_rxp_in              (K7_QSFP1_RX0_P),
      .gt0_txn_out             (K7_QSFP1_TX0_N),
      .gt0_txp_out             (K7_QSFP1_TX0_P),
      .gt0_rxfsm_resetdone_out (gt0_rxfsm_resetdone),
      .gt0_txfsm_resetdone_out (gt0_txfsm_resetdone),
      .gt0_rxbufstatus         (gt0_rxbufstatus),
      .gt0_txbufstatus         (gt0_txbufstatus),

      // GTX1 - ChitChat
      .gt1_rxoutclk_out        (gtx1_rx_out_clk),
      .gt1_rxusrclk_in         (gtx1_rx_out_clk),
      .gt1_rxusrclk2_in        (gtx1_rx_out_clk),
      .gt1_txoutclk_out        (gtx1_tx_out_clk),
      .gt1_txusrclk_in         (gtx1_tx_out_clk),
      .gt1_txusrclk2_in        (gtx1_tx_out_clk),
      .gt1_rxusrrdy_in         (gt_cpll_locked),
      .gt1_rxdata_out          (gtx1_rxd),
      .gt1_txusrrdy_in         (gt_cpll_locked),
      .gt1_txdata_in           (gtx1_txd),
      .gt1_rxn_in              (K7_QSFP1_RX1_N),
      .gt1_rxp_in              (K7_QSFP1_RX1_P),
      .gt1_txn_out             (K7_QSFP1_TX1_N),
      .gt1_txp_out             (K7_QSFP1_TX1_P),
      .gt1_rxfsm_resetdone_out (gt1_rxfsm_resetdone),
      .gt1_txfsm_resetdone_out (gt1_txfsm_resetdone),
      .gt1_rxcharisk_out       (gtx1_rxk),
      .gt1_txcharisk_in        (gtx1_txk),
      .gt1_rxbufstatus         (gt1_rxbufstatus),
      .gt1_txbufstatus         (gt1_txbufstatus),
`endif

      .gt_txrx_resetdone       (gt_txrx_resetdone),
      .gt_cpll_locked          (gt_cpll_locked)
   );


   // ----------------------------------
   // GTX Ethernet to Local-Bus bridge
   // ---------------------------------
   wire rx_mon, tx_mon;

   wire lb_valid, lb_rnw, lb_renable;
   wire [LBUS_ADDR_WIDTH-1:0] lb_addr;
   wire [LBUS_DATA_WIDTH-1:0] lb_wdata, lb_rdata;

   eth_gtx_bridge #(
      .IP         (IPADDR),
      .MAC        (MACADDR),
      .JUMBO_DW   (JUMBO_DW))
   i_eth_gtx_bridge (
      .gtx_tx_clk  (gtx0_tx_usr_clk), // Transceiver clock at half rate
      .gmii_tx_clk (gmii_tx_clk),     // Clock for Ethernet fabric - 125 MHz for 1GbE
      .gmii_rx_clk (gmii_rx_clk),
      .gtx_rxd     (gtx0_rxd),
      .gtx_txd     (gtx0_txd),

      // Status signals
      .rx_mon      (rx_mon),
      .tx_mon      (tx_mon),

      // Local bus interface in gmii_tx_clk domain
      .lb_valid    (lb_valid),
      .lb_rnw      (lb_rnw),
      .lb_addr     (lb_addr),
      .lb_wdata    (lb_wdata),
      .lb_renable  (lb_renable),
      .lb_rdata    (lb_rdata)
   );

   wire lb_clk = gmii_tx_clk;

   // ----------------------------------
   // CHITCHAT TX-RX
   // ---------------------------------

   wire tx_transmit_en;

   wire        tx_valid;
   wire [2:0]  tx_location;
   wire [31:0] tx_data0;
   wire [31:0] tx_data1;

   wire [15:0] rx_frame_counter;
   wire [15:0] txrx_latency;

   wire        rx_valid;
   wire [2:0]  ccrx_fault;
   wire [15:0] ccrx_fault_cnt;
   wire        ccrx_los;

   wire [3:0]  rx_protocol_ver;
   wire [2:0]  rx_gateware_type;
   wire [2:0]  rx_location;
   wire [31:0] rx_rev_id;
   wire [31:0] rx_data0;
   wire [31:0] rx_data1;


   // Generate test pattern composed of circular byte shift, interleaved
   // with bad data that should not be sampled by chitchat_txrx_wrap
   reg [127:0] test_data0 = "QF2PRE++CHITCHAT";
   reg [127:0] test_data1 = "COMMS+T+ETHERNET";
   reg [4:0] cycle_cnt = 0;


   always @(posedge sys_clk) begin
      cycle_cnt <= cycle_cnt + 1;

      if (cycle_cnt == 6) begin
         test_data0 <= {test_data0[119:0], test_data0[127:120]};
         test_data1 <= {test_data1[119:0], test_data1[127:120]};
      end
   end

   assign tx_valid = cycle_cnt[4];
   assign tx_data0 = cycle_cnt[4] ? test_data0 : 32'hBADD;
   assign tx_data1 = cycle_cnt[4] ? test_data1 : 32'hBADD;


   chitchat_txrx_wrap #(
      .REV_ID        (32'hdeadbeef)
   ) i_chitchat_wrap (
      // -------------------
      // Data Interface
      // -------------------
      .tx_clk            (sys_clk),

      .tx_transmit_en    (tx_transmit_en),
      .tx_valid          (tx_valid),
      .tx_location       (tx_location),
      .tx_data0          (tx_data0),
      .tx_data1          (tx_data1),

      .rx_clk            (lb_clk),

      .rx_valid          (rx_valid),
      .rx_data0          (rx_data0),
      .rx_data1          (rx_data1),
      .ccrx_frame_drop   (),

      // -------------------
      // LB Interface
      // -------------------
      .lb_clk            (lb_clk),

      .txrx_latency      (txrx_latency),
      .rx_frame_counter  (rx_frame_counter),
      .rx_protocol_ver   (rx_protocol_ver),
      .rx_gateware_type  (rx_gateware_type),
      .rx_location       (rx_location),
      .rx_rev_id         (rx_rev_id),

      .ccrx_fault        (ccrx_fault),
      .ccrx_fault_cnt    (ccrx_fault_cnt),
      .ccrx_los          (ccrx_los),

      // ------------------------------------
      // GTX Interface
      // ------------------------------------
      .gtx_tx_clk        (gtx1_tx_out_clk),
      .gtx_rx_clk        (gtx1_rx_out_clk),

      .gtx_tx_d          (gtx1_txd),
      .gtx_tx_k          (gtx1_txk),
      .gtx_rx_d          (gtx1_rxd),
      .gtx_rx_k          (gtx1_rxk)
   );


   // ----------------------------------
   // Local Bus Register Decoding
   // ---------------------------------
   comms_top_regbank i_comms_regbank
   (
      .lb_clk             (lb_clk),
      .lb_valid           (lb_valid),
      .lb_rnw             (lb_rnw),
      .lb_addr            (lb_addr),
      .lb_wdata           (lb_wdata),
      .lb_renable         (lb_renable),
      .lb_rdata           (lb_rdata),

      .rx_frame_counter_i (rx_frame_counter),
      .txrx_latency_i     (txrx_latency),
      .ccrx_fault_i       (ccrx_fault),
      .ccrx_fault_cnt_i   (ccrx_fault_cnt),
      .ccrx_los_i         (ccrx_los),
      .rx_protocol_ver_i  (rx_protocol_ver),
      .rx_gateware_type_i (rx_gateware_type),
      .rx_location_i      (rx_location),
      .rx_rev_id_i        (rx_rev_id),
      .rx_data0_i         (rx_data0),
      .rx_data1_i         (rx_data1),

      .tx_location_o      (tx_location),
      .tx_transmit_en_o   (tx_transmit_en)
   );

   // ----------------------------------
   // Status LEDs
   // ---------------------------------
   wire lbus_led = rx_frame_counter[15]; // Toggle every 2**15 frames


   // LED[0] GT Initialization done
   // LED[1] Received and decoded packet
   assign LEDS = {gt_txrx_resetdone, lbus_led};

endmodule

