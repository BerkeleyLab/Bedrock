`timescale 1ns / 1ns

// ------------------------------------
// eth_gtx_bridge.v
//
// DEPRECATED (but still used in projects/comms_top!)
// Wrapper around rtefi_blob and eth_gtx_hook with a TX/RX path width conversion for GTX compatibility
// Note that this module "just" instantiates two others:
// eth_gtx_hook and rtefi_blob.
// If you keep them separate, that gives you a valuable opportunity
// to put your simulated design on a test network.
// Look in the badger/tests directory for examples and tools to support
// this technique, using GMII ports of rtefi_blob.
// Similar capabilities don't exist for the 20-bit ports coming out of this
// module, that is meant for attachment to the Xilinx GTX/GTP interface.
// ------------------------------------

module eth_gtx_bridge #(
   parameter IP       = {8'd192, 8'd168, 8'd7, 8'd4},
   parameter MAC      = 48'h112233445566,
   parameter JUMBO_DW = 14,  // Not used, just holdover for compatibility with older eth_gtx_bridge
   parameter GTX_DW   = 20,  // Parallel GTX data width; Supported values are 10b and 20b
   parameter DOUBLEBIT = 0)  // Experimental
(
   input               gtx_tx_clk,  // Transceiver clock, sometimes at half rate
   input               gmii_tx_clk, // Clock for Ethernet fabric - 125 MHz for 1GbE
   input               gmii_rx_clk,
   input  [GTX_DW-1:0] gtx_rxd,
   output [GTX_DW-1:0] gtx_txd,

   input               an_disable,
   output [8:0]        an_status, // cfg_clk domain

   // Status signals
   output              rx_mon,
   output              tx_mon,

   // Ethernet configuration interface
   input               cfg_clk,
   input               cfg_enable_rx,
   input               cfg_valid,
   input  [4:0]        cfg_addr, // cfg_addr[4] = {0 - MAC/IP, 1 - UDP Ports}
   input  [7:0]        cfg_wdata,
   // Dummy ports used to trigger newad address space generation
   (* external *)
   input  [7:0]        cfg_reg, // external
   (* external *)
   output [4:0]        cfg_reg_addr, // external

   // Local Bus interface
   output              lb_valid,
   output              lb_rnw,
   output [23:0]       lb_addr,
   output [31:0]       lb_wdata,
   output              lb_renable,
   input  [31:0]       lb_rdata
);

   reg  [8:0] an_status_x_cfg_clk;
   wire [8:0] an_status_l;
   wire [7:0] gmii_rxd, gmii_txd;
   wire gmii_tx_en, gmii_rx_dv;

   eth_gtx_hook #(.JUMBO_DW(14), .GTX_DW(GTX_DW), .DOUBLEBIT(DOUBLEBIT)) hook(
       .gtx_tx_clk   (gtx_tx_clk),
       .gmii_tx_clk  (gmii_tx_clk),
       .gmii_rx_clk  (gmii_rx_clk),
       .gtx_rxd      (gtx_rxd),
       .gtx_txd      (gtx_txd),

       .an_disable   (an_disable),
       .rx_err_los   (1'b0),
       .an_status_l  (an_status_l),

       .gmii_rxd     (gmii_rxd),
       .gmii_rx_dv   (gmii_rx_dv),
       .gmii_txd     (gmii_txd),
       .gmii_tx_en   (gmii_tx_en)
       );

   // Cross quasi-static an_status to cfg_clk so it can be read out by Host
   always @(posedge cfg_clk) an_status_x_cfg_clk <= an_status_l;
   assign an_status = an_status_x_cfg_clk;

   // ----------------------------------
   // Ethernet MAC
   // ---------------------------------
   localparam SEL_MACIP = 0, SEL_UDP = 1;

   wire cfg_ipmac = (cfg_addr[4]==SEL_MACIP) & cfg_valid;
   wire cfg_udp   = (cfg_addr[4]==SEL_UDP) & cfg_valid;

   rtefi_blob #(.ip(IP), .mac(MAC), .mac_aw(2), .p3_enable_bursts(1)) badger(
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
      .config_a            (cfg_addr[3:0]),
      .config_d            (cfg_wdata),
      .config_s            (cfg_ipmac),
      .config_p            (cfg_udp),

      // MAC Host interface
      .host_rdata          (16'h0),
      .buf_start_addr      (2'h0),
      .tx_mac_start        (1'h0),
      .rx_mac_hbank        (1'h0),
      .rx_mac_accept       (1'h0),

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
