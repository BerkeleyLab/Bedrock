// ------------------------------------
// chitchat_txrx_wrap.v
//
// Wrapper module containing Chitchat TX and RX instances connected together
// and clock-domain crossers on all interfaces, which can be optionally disabled.
//
// ------------------------------------


module chitchat_txrx_wrap #(
   parameter REV_ID = 0,
   parameter TX_GATEWARE_TYPE = 0,
   parameter RX_GATEWARE_TYPE = 0,
   parameter TX_TO_GTX_CDC = 1, // Selectively enable/disable CDC
   parameter GTX_TO_RX_CDC = 1,
   parameter GTX_TO_LB_CDC = 1
) (
   // -------------------
   // Data Interface
   // -------------------
   input         tx_clk,

   input         tx_transmit_en,
   input  [2:0]  tx_location,
   input         tx_valid0, // Input data will be latched on tx_valid{0,1} and
                            // sent when tx_send_x_tgtx=1. If tx_valid rate is higher
                            // than tx_send_x_tgtx, data will be lost.
   input         tx_valid1,
   input  [31:0] tx_data0,
   input  [31:0] tx_data1,
   input         tx_extra_data_valid,
   input  [127:0] tx_extra_data,

   input         rx_clk,

   output        rx_valid,
   output [31:0] rx_data0,
   output [31:0] rx_data1,
   output        rx_extra_data_valid,
   output [127:0] rx_extra_data,
   output        ccrx_frame_drop, // Debug output

   // -------------------
   // LB Interface
   // -------------------
   input         lb_clk,

   output [15:0] txrx_latency,
   output [15:0] rx_frame_counter,
   output [3:0]  rx_protocol_ver,
   output [2:0]  rx_gateware_type,
   output [2:0]  rx_location,
   output [31:0] rx_rev_id,

   output [2:0]  ccrx_fault,
   output [15:0] ccrx_fault_cnt,
   output        ccrx_los,

   // ------------------------------------
   // GTX Interface
   // ------------------------------------
   input         gtx_tx_clk,
   input         gtx_rx_clk,

   output [15:0] gtx_tx_d,
   output [1:0]  gtx_tx_k,
   input  [15:0] gtx_rx_d,
   input  [1:0]  gtx_rx_k
);

   // TX CDC signals
   wire [31:0]           tx_data0_x_tgtx, tx_data1_x_tgtx;
   wire [127:0]          tx_extra_data_x_tgtx;
   wire                  tx_valid0_x_tgtx, tx_valid1_x_tgtx, tx_extra_data_valid_x_tgtx;
   wire                  tx_send_x_tgtx;
   reg                   tx_transmit_en_tgtx = 0;
   reg  [2:0]            tx_location_tgtx;
   wire [15:0]           rx_frame_counter_x_tgtx;
   wire [15:0]           tx_local_frame_counter_x_tgtx;
   reg  [15:0]           txrx_latency_x_tgtx, txrx_latency_r_lb;
   wire                  rx_valid_x_tgtx;


   // RX CDC signals
   localparam RX_PACK_WI = 32*2 + 1 + 128;
   wire [RX_PACK_WI-1:0] rx_pack, rx_pack_x_rgtx;
   wire [31:0]           rx_data0_x_rgtx, rx_data1_x_rgtx;
   wire [127:0]          rx_extra_data_rx, rx_extra_data_x_rgtx;
   wire                  rx_valid_x_rgtx, rx_valid_l_rx, rx_extra_data_valid_x_rgtx, rx_extra_data_valid_rx;
   wire                  ccrx_frame_drop_x_rgtx;
   reg                   ccrx_los_r_lb;
   reg  [15:0]           ccrx_fault_cnt_r_lb;
   reg  [3:0]            rx_protocol_ver_r_lb;
   reg  [2:0]            rx_gateware_type_r_lb;
   reg  [31:0]           rx_rev_id_r_lb;
   reg  [2:0]            rx_location_r_lb;
   wire                  ccrx_los_l_rgtx;
   wire [15:0]           ccrx_fault_cnt_l_rgtx;
   wire [3:0]            rx_protocol_ver_l_rgtx;
   wire [2:0]            rx_gateware_type_l_rgtx;
   wire [31:0]           rx_rev_id_l_rgtx;
   wire [2:0]            rx_location_l_rgtx;
   wire [15:0]           rx_lback_frame_counter_x_rgtx, rx_lback_frame_counter_x_tgtx;

   // LB CDC signals
   localparam LB_PACK_WI = 16 + 3;
   wire [LB_PACK_WI-1:0] lb_pack, lb_pack_x_rgtx;
   wire [15:0]           rx_frame_counter_x_rgtx;
   wire [2:0]            ccrx_fault_x_rgtx;


   // ----------------------
   // TX CDC
   // ----------------------
   generate if (TX_TO_GTX_CDC) begin : G_TX_CDC
      // This synchronizer serves the dual purpose of latching to input
      // data on tx_valid
      data_xdomain # (.size(32)) i_tx0_sync (
         .clk_in   (tx_clk),
         .gate_in  (tx_valid0),
         .data_in  (tx_data0),
         .clk_out  (gtx_tx_clk),
         .gate_out (tx_valid0_x_tgtx), // Unused
         .data_out (tx_data0_x_tgtx)
      );

      data_xdomain # (.size(32)) i_tx1_sync (
         .clk_in   (tx_clk),
         .gate_in  (tx_valid1),
         .data_in  (tx_data1),
         .clk_out  (gtx_tx_clk),
         .gate_out (tx_valid1_x_tgtx), // Unused
         .data_out (tx_data1_x_tgtx)
      );

      data_xdomain # (.size(128)) i_xtx_sync (
         .clk_in   (tx_clk),
         .gate_in  (tx_extra_data_valid),
         .data_in  (tx_extra_data),
         .clk_out  (gtx_tx_clk),
         .gate_out (tx_extra_data_valid_x_tgtx), // Unused
         .data_out (tx_extra_data_x_tgtx)
      );

      // Synchronize rx_frame_counter for loopback latency calc
      data_xdomain # (.size(16*2)) i_tx_latency_sync (
         .clk_in   (gtx_rx_clk),
         .gate_in  (rx_valid_x_rgtx),
         .data_in  ({rx_frame_counter_x_rgtx, rx_lback_frame_counter_x_rgtx}),
         .clk_out  (gtx_tx_clk),
         .gate_out (rx_valid_x_tgtx),
         .data_out ({rx_frame_counter_x_tgtx, rx_lback_frame_counter_x_tgtx})
      );
   end else begin
      reg [31:0] tx_data0_r, tx_data1_r;
      reg [127:0] tx_extra_data_r;
      // Latch input data on tx_valid{0,1}
      always @(tx_clk) if (tx_valid0) tx_data0_r <= tx_data0;
      always @(tx_clk) if (tx_valid1) tx_data1_r <= tx_data1;
      always @(tx_clk) if (tx_extra_data_valid) tx_extra_data_r <= tx_extra_data;

      assign {tx_data1_x_tgtx, tx_data0_x_tgtx} = {tx_data1_r, tx_data0_r};

      assign {rx_frame_counter_x_tgtx, rx_lback_frame_counter_x_tgtx} = {rx_frame_counter_x_rgtx, rx_lback_frame_counter_x_rgtx};
   end endgenerate

   // Quasi-static signals; Just register in destination clk domain
   always @(posedge gtx_tx_clk) begin
      tx_location_tgtx    <= tx_location;
      tx_transmit_en_tgtx <= tx_transmit_en;
   end

   chitchat_tx #(
      .REV_ID           (REV_ID),
      .TX_GATEWARE_TYPE (TX_GATEWARE_TYPE)
   ) i_chitchat_tx (
      .clk                       (gtx_tx_clk),
      .tx_transmit_en            (tx_transmit_en_tgtx),
      .tx_send                   (tx_send_x_tgtx), // Testing only (not useful w/ CDC)
      .tx_location               (tx_location_tgtx),
      .tx_data0                  (tx_data0_x_tgtx),
      .tx_data1                  (tx_data1_x_tgtx),
      .tx_extra_data             (tx_extra_data_x_tgtx),
      .tx_loopback_frame_counter (rx_frame_counter_x_tgtx),
      .local_frame_counter       (tx_local_frame_counter_x_tgtx),
      .gtx_d                     (gtx_tx_d),
      .gtx_k                     (gtx_tx_k)
   );

   // Compute loopback latency
   always @(posedge gtx_tx_clk) begin
      if (rx_valid_x_tgtx)
         txrx_latency_x_tgtx <= tx_local_frame_counter_x_tgtx - rx_lback_frame_counter_x_tgtx;
   end

   chitchat_rx #(
      .RX_GATEWARE_TYPE (RX_GATEWARE_TYPE)
   ) i_chitchat_rx (
      .clk                       (gtx_rx_clk),
      .gtx_d                     (gtx_rx_d),
      .gtx_k                     (gtx_rx_k),
      .ccrx_fault                (ccrx_fault_x_rgtx),
      .ccrx_fault_cnt            (ccrx_fault_cnt_l_rgtx),
      .ccrx_los                  (ccrx_los_l_rgtx),
      .ccrx_frame_drop           (ccrx_frame_drop_x_rgtx),
      .rx_valid                  (rx_valid_x_rgtx),
      .rx_protocol_ver           (rx_protocol_ver_l_rgtx),
      .rx_gateware_type          (rx_gateware_type_l_rgtx),
      .rx_location               (rx_location_l_rgtx),
      .rx_rev_id                 (rx_rev_id_l_rgtx),
      .rx_data0                  (rx_data0_x_rgtx),
      .rx_data1                  (rx_data1_x_rgtx),
      .rx_extra_data_valid       (rx_extra_data_valid_x_rgtx),
      .rx_extra_data             (rx_extra_data_x_rgtx),
      .rx_frame_counter          (rx_frame_counter_x_rgtx),
      .rx_loopback_frame_counter (rx_lback_frame_counter_x_rgtx)
   );

   // ----------------------
   // RX CDC
   // ----------------------
   assign rx_pack_x_rgtx = {rx_data1_x_rgtx, rx_data0_x_rgtx, ccrx_frame_drop_x_rgtx};

   generate if (GTX_TO_RX_CDC) begin : G_RX_CDC
      data_xdomain # (.size(RX_PACK_WI)) i_rx_sync (
         .clk_in   (gtx_rx_clk),
         .gate_in  (rx_valid_x_rgtx | ccrx_frame_drop_x_rgtx),
         .data_in  (rx_pack_x_rgtx),
         .clk_out  (rx_clk),
         .gate_out (rx_valid_l_rx),
         .data_out (rx_pack)
      );

      data_xdomain # (128) i_xrx_sync (
         .clk_in   (gtx_rx_clk),
         .gate_in  (rx_extra_data_valid_x_rgtx | ccrx_frame_drop_x_rgtx),
         .data_in  (rx_extra_data_x_rgtx),
         .clk_out  (rx_clk),
         .gate_out (rx_extra_data_valid_rx),
         .data_out (rx_extra_data_rx)
      );

   end else begin
      assign rx_valid_l_rx    = rx_valid_x_rgtx;
      assign rx_pack          = rx_pack_x_rgtx;
      assign rx_extra_data_valid_rx = rx_extra_data_valid_x_rgtx;
      assign rx_extra_data_rx = rx_extra_data_x_rgtx;
      assign ccrx_frame_drop = ccrx_frame_drop_x_rgtx;
   end endgenerate

   assign rx_valid        = rx_valid_l_rx & ~rx_pack[0]; // Demux valid/frame_drop
   assign rx_extra_data_valid = rx_extra_data_valid_rx & ~rx_pack[0]; // Demux valid/frame_drop
   assign ccrx_frame_drop = rx_valid_l_rx & rx_pack[0];

   assign {rx_data1, rx_data0} = rx_pack[RX_PACK_WI-1:1];
   assign rx_extra_data = rx_extra_data_rx;

   // ----------------------
   // LB CDC
   // ----------------------
   assign lb_pack_x_rgtx = {rx_frame_counter_x_rgtx, ccrx_fault_x_rgtx};

   generate if (GTX_TO_LB_CDC) begin : G_LB_CDC
     data_xdomain # (.size(LB_PACK_WI)) i_lb_sync (
         .clk_in   (gtx_rx_clk),
         .gate_in  (rx_valid_x_rgtx | ccrx_frame_drop_x_rgtx),
         .data_in  (lb_pack_x_rgtx),
         .clk_out  (lb_clk),
         .gate_out (), // Unused
         .data_out (lb_pack)
      );
   end else begin
      assign lb_pack = lb_pack_x_rgtx;
   end endgenerate

   assign {rx_frame_counter, ccrx_fault} = lb_pack;

   // Quasi-static signals; Just register in destination clk domain
   always @(posedge lb_clk) begin
      ccrx_los_r_lb         <= ccrx_los_l_rgtx;
      ccrx_fault_cnt_r_lb   <= ccrx_fault_cnt_l_rgtx;
      rx_protocol_ver_r_lb  <= rx_protocol_ver_l_rgtx;
      rx_gateware_type_r_lb <= rx_gateware_type_l_rgtx;
      rx_rev_id_r_lb        <= rx_rev_id_l_rgtx;
      rx_location_r_lb      <= rx_location_l_rgtx;
      txrx_latency_r_lb     <= txrx_latency_x_tgtx; // Expected to go to steady state
   end

   // ----------------------
   // Drive output pins
   // ----------------------
   assign ccrx_los         = ccrx_los_r_lb;
   assign ccrx_fault_cnt   = ccrx_fault_cnt_r_lb;
   assign rx_protocol_ver  = rx_protocol_ver_r_lb;
   assign rx_gateware_type = rx_gateware_type_r_lb;
   assign rx_rev_id        = rx_rev_id_r_lb;
   assign rx_location      = rx_location_r_lb;
   assign txrx_latency     = txrx_latency_r_lb;

endmodule
