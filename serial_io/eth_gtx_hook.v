`timescale 1ns / 1ns

// ------------------------------------
// eth_gtx_hook.v
// ------------------------------------

module eth_gtx_hook #(
    parameter JUMBO_DW = 14, // Not used, just holdover for compatibility with older eth_gtx_bridge
    parameter GTX_DW   = 20) // Parallel GTX data width; Supported values are 10b and 20b
    (
        input               gtx_tx_clk,  // Transceiver clock at half rate
        input               gmii_tx_clk, // Clock for Ethernet fabric - 125 MHz for 1GbE
        input               gmii_rx_clk,
        input  [GTX_DW-1:0] gtx_rxd,
        output [GTX_DW-1:0] gtx_txd,

        // Auto-Negotiation
        input               an_disable,
        input               rx_err_los,
        output [8:0]        an_status_l, // still in gmii_tx_clk domain
        output [15:0]       lacr_rx,

        input               gmii_tx_en,
        input  [7:0]        gmii_txd,
        output [7:0]        gmii_rxd,
        output              gmii_rx_dv

    );

        wire [9:0] gtx_txd_10;

        // ----------------------------------
        // Data width and rate conversion
        // ---------------------------------

        wire [9:0] gtx_rxd_10;

        generate if (GTX_DW==20) begin: G_GTX_DATA_CONV

            reg  [9:0] gtx_rxd_10_r;
            reg  [9:0] gtx_txd_r;
            wire [9:0] gtp_rxd_l = gtx_rxd[9:0];
            wire [9:0] gtp_rxd_h = gtx_rxd[19:10];
            reg  [19:0] gtx_txd_l;
            reg even=0;

            always @(posedge gmii_tx_clk) begin
                gtx_txd_r <= gtx_txd_10;
            end

            always @(posedge gmii_rx_clk) begin
                even         <= ~even;
                gtx_rxd_10_r <= even ? gtp_rxd_l : gtp_rxd_h;
            end

            always @(posedge gtx_tx_clk) begin
                gtx_txd_l <= {gtx_txd_10, gtx_txd_r};
            end

            assign gtx_txd = gtx_txd_l;
            assign gtx_rxd_10 = gtx_rxd_10_r;

        end else begin

            assign gtx_txd    = gtx_txd_10;
            assign gtx_rxd_10 = gtx_rxd;

        end endgenerate


        // ----------------------------------
        // PCS/PMA and GMII Bridge
        // ---------------------------------


        gmii_link i_gmii_link(
            //GMII to MAC
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
            .rx_err_los   (rx_err_los),
            .an_bypass    (an_disable), // Disable auto-negotiation
            .lacr_rx      (lacr_rx),
            .an_status    (an_status_l)
        );

endmodule
