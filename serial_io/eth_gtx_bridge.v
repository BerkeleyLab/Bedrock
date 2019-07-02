`timescale 1ns / 1ns

// ------------------------------------
// eth_gtx_bridge.v
//
// Wrapper around rtefi_blob and gmii_link with a TX/RX path width conversion for GTX compatibility
// ------------------------------------

module eth_gtx_bridge #(
   parameter IP       = {8'd192, 8'd168, 8'd7, 8'd4},
   parameter MAC      = 48'h112233445566,
   parameter JUMBO_DW = 14)
(
   input         gtx_tx_clk,  // Transceiver clock at half rate
   input         gmii_tx_clk, // Clock for Ethernet fabric - 125 MHz for 1GbE
   input         gmii_rx_clk,
   input  [19:0] gtx_rxd,
   output [19:0] gtx_txd,

   // Status signals
   output        rx_mon,
   output        tx_mon,

   // Ethernet configuration (shift) interface
   input         cfg_enable_rx,
   input         cfg_clk,
   input         cfg_valid,
   input         cfg_mem_sel, // 0 - MAC/IP; 1 - UDP Ports
   input  [7:0]  cfg_wdata,

   // Local Bus interface
   output        lb_valid,
   output        lb_rnw,
   output [23:0] lb_addr,
   output [31:0] lb_wdata,
   output        lb_renable,
   input  [31:0] lb_rdata
);
   wire [7:0] gmii_rxd, gmii_txd;
   wire [9:0] gtx_txd_10;
   reg  [9:0] gtx_rxd_10;
   wire gmii_tx_en, gmii_rx_er, gmii_rx_dv;

   // ----------------------------------
   // Data width and rate conversion
   // ---------------------------------

   reg  [9:0] gtx_txd_r;
   wire [9:0] gtp_rxd_l = gtx_rxd[9:0];
   wire [9:0] gtp_rxd_h = gtx_rxd[19:10];
   reg  [19:0] gtx_txd_l;
   reg even=0;

   always @(posedge gmii_tx_clk) begin
       gtx_txd_r <= gtx_txd_10;
   end

   always @(posedge gmii_rx_clk) begin
       even       <= ~even;
       gtx_rxd_10 <= even ? gtp_rxd_l : gtp_rxd_h;
   end

   always @(posedge gtx_tx_clk) begin
       gtx_txd_l <= {gtx_txd_10, gtx_txd_r};
   end

   assign gtx_txd = gtx_txd_l;

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
   localparam MACIP_MEM_SZ = 10; // Bytes
   localparam UDP_MEM_SZ = 16;
   localparam SEL_MACIP = 0, SEL_UDP = 1;

   reg [3:0] cfg_mem_ptr=0;
   reg       prev_mem_sel=0;
   wire switch_mem;

   assign switch_mem = (cfg_mem_sel != prev_mem_sel) ? 1'b1 : 1'b0;

   always @(posedge cfg_clk) begin
      if (cfg_valid) begin
         if (switch_mem) begin
            prev_mem_sel <= cfg_mem_sel;
            cfg_mem_ptr <= 1;
         end else begin
            if (cfg_mem_ptr == (cfg_mem_sel==SEL_MACIP ? MACIP_MEM_SZ : UDP_MEM_SZ) - 1)
               cfg_mem_ptr <= 0;
            else
               cfg_mem_ptr <= cfg_mem_ptr + 1;
         end
      end
   end

   wire [3:0] cfg_addr = switch_mem ? 3'b0 : cfg_mem_ptr;
   wire cfg_ipmac = (cfg_mem_sel == SEL_MACIP) ? 1'b1 : 1'b0;
   wire cfg_udp   = (cfg_mem_sel == SEL_UDP)   ? 1'b1 : 1'b0;

   rtefi_blob #(.ip(IP), .mac(MAC), .mac_aw(2)) badger(
      // GMII Input (Rx)
      .rx_clk              (gmii_rx_clk),
      .rxd                 (gmii_rxd),
      .rx_dv               (gmii_rx_dv),
      .rx_er               (1'b0),
      // GMII Output (Tx)
      .tx_clk              (gmii_tx_clk),
      .txd                 (gmii_txd),
      .tx_en               (gmii_tx_en),
      // Configuration
      .enable_rx           (cfg_enable_rx),
      .config_clk          (cfg_clk),
      .config_a            (cfg_addr),
      .config_d            (cfg_wdata),
      .config_s            (cfg_ipmac),
      .config_p            (cfg_udp),
      // TX MAC Host interface
      .host_clk            (1'b0),
      .host_waddr          (3'b0),
      .host_write          (1'b0),
      .host_wdata          (16'b0),
      .tx_mac_done         (),
      // Debug ports
      .ibadge_stb          (),
      .ibadge_data         (),
      .obadge_stb          (),
      .obadge_data         (),
      .xdomain_fault       (),
      // Pass-through to user modules
      .p2_nomangle         (1'b0),
      .p3_addr             (lb_addr),
      .p3_control_strobe   (lb_valid),
      .p3_control_rd       (lb_rnw),
      .p3_control_rd_valid (lb_renable),
      .p3_data_out         (lb_wdata),
      .p3_data_in          (lb_rdata),
      .rx_mon              (rx_mon),
      .tx_mon              (tx_mon)
   );

endmodule
