`timescale 1ns / 1ns

// ------------------------------------
// eth_gtx_bridge.v
//
// Wrapper around rtefi_blob and gmii_link with a TX/RX path width conversion for GTX compatibility
// ------------------------------------

module eth_gtx_bridge #(
   parameter IP       = {8'd192, 8'd168, 8'd7, 8'd4};
   parameter MAC      = 48'h112233445566;
   parameter JUMBO_DW = 14)
(
   input         gtx_tx_clk,  // Transceiver clock at half rate
   input         gmii_tx_clk, // Clock for Ethernet fabric - 125 MHz for 1GbE 
   input         gmii_rx_clk,
   input  [19:0] gtx_rxd,
   output [19:0] gtx_txd,

   // Local Bus interface
   output        lb_valid,
   output        lb_rnw,
   output [23:0] lb_addr, // TODO: Something special about lb_addr[17]?
   output [31:0] lb_wdata,
   output        lb_rvalid,
   input  [31:0] lb_rdata
);
   wire [7:0] gmii_rxd, gmii_txd;
   wire [9:0] gtx_txd_10, gtx_rxd_10;
   wire gmii_tx_en, gmii_rx_er, gmii_rx_dv;

   // ----------------------------------
   // Data width and rate conversion
   // ---------------------------------

   reg  [9:0] gtx_txd_r;
   wire [9:0] gtp_rxd_l = gtx_rxd[9:0];
   wire [9:0] gtp_rxd_h = gtx_rxd[19:10];
   reg even=0;

   // decode incoming data @ gtp_tx_clk
   always @(posedge gmii_tx_clk) begin
       gtx_txd_r <= gtx_txd_10;
   end
   
   always @(posedge gmii_rx_clk) begin
       even       <= ~even;
       gtx_rxd_10 <= even ? gtp_rxd_l : gtp_rxd_h;
   end
   
   // encode outgoing data @ gmii_tx_clk
   always @(posedge gtx_tx_clk) begin
       gtx_txd <= {gtx_txd_10, gtx_txd_r};
   end

   // ----------------------------------
   // PCS/PMA and GMII Bridge
   // ---------------------------------

   wire [5:0] link_leds;
   wire [15:0] lacr_rx;
   wire [1:0] an_state_mon;

   gmii_link i_gmii_link(
        // GMII to MAC
   	.RX_CLK       (gmii_rx_clk),
   	.RXD          (gmii_rxd),
   	.RX_DV        (gmii_rx_dv),
        // MAC to GMII
   	.GTX_CLK      (gmii_tx_clk),
   	.TXD          (gmii_txd),
   	.TX_EN        (gmii_tx_en),
   	.TX_ER        (1'b0),
        // To Transceiver
   	.txdata       (gtx_txd_10), 
        .rxdata       (gtx_rxd_10),
   	.rx_err_los   (1'b0),
   	.an_bypass    (1'b1),     // Disable auto-negotiation
   	.lacr_rx      (lacr_rx),
   	.an_state_mon (an_state_mon),
   	.leds         (link_leds) // TODO: Connect this to actual LEDs
   );

   // ----------------------------------
   // Ethernet MAC
   // ---------------------------------

   rtefi_blob #(.ip(IP), .mac(MAC)) badger(
      // GMII Input (Rx)
      .rx_clk              (gmii_rx_clk),
      .rxd                 (gmii_rxd),
      .rx_dv               (gmii_rx_dv),
      .rx_er               (gmii_rx_er),
      // GMII Output (Tx)
      .tx_clk              (gmii_tx_clk),
      .txd                 (gmii_txd),
      .tx_en               (gmii_tx_en),
      // Configuration
      .enable_rx           (1'b1),
      .config_clk          (gmii_tx_clk), 
      .config_a            (4'd0), 
      .config_d            (8'd0),
      .config_s            (1'b0), 
      .config_p            (1'b0),
   
      // Pass-through to user modules
      .p2_nomangle         (1'b0),
      .p3_addr             (lb_addr),
      .p3_control_strobe   (lb_valid),
      .p3_control_rd       (lb_rnw),
      .p3_control_rd_valid (lb_rvalid),
      .p3_data_out         (lb_wdata),
      .p3_data_in          (lb_rdata)
   );

endmodule
