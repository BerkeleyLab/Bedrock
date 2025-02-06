`timescale 1ns / 1ns

// ------------------------------------
// eth_gtx_hook.v
// ------------------------------------
// Converts between an internal/virtual GMII Ethernet port (8-bit, 125 MHz)
// and the user pins of an on-chip serdes
//   GTX_DW = 10                :  125 MHz serdes clk for Spartan-6 LXT
//   GTX_DW = 20  DOUBLEBIT = 0 :  62.5 MHz serdes clk for Xilinx 7-series
//   GTX_DW = 20  DOUBLEBIT = 1 :  125 MHz serdes clk for Xilinx 7-series (experimental)

module eth_gtx_hook #(
    parameter JUMBO_DW = 14,  // Not used, just holdover for compatibility with older eth_gtx_bridge
    parameter EVENINIT = 0,
    parameter ENC_DISPINIT=1'b0,
    parameter GTX_DW   = 20,  // Parallel GTX data width; Supported values are 10b and 20b
    parameter DOUBLEBIT = 0,  // Experimental
    parameter CTRACE_AW = 14  // Diagnostic
  ) (
        input               gtx_tx_clk,  // Transceiver clock, sometimes at half rate
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

`ifdef FIBER_TRACE
        // ctrace CSRs
        ,input              ctrace_start,
        output              ctrace_running,
        output [CTRACE_AW-1:0] ctrace_pc_mon,
        // ctrace readout in lb_clk domain
        input               lb_clk,
        input  [CTRACE_AW-1:0] lb_addr,
        output [31:0]       lb_out
`endif
    );

        wire [9:0] gtx_txd_10;  // driven by i_gmii_link
        wire [9:0] gtx_rxd_10;  // input to i_gmii_link

        // ----------------------------------
        // Data width and rate conversion
        // ---------------------------------

        generate if ((GTX_DW==20) && DOUBLEBIT) begin: G_GTX_DOUBLEBIT_CONV

            // gmii and gtx clocks are considered the same in this stanza
            // One could also write this bit rearrangement with a generate loop,
            // but I don't mind being explicit about it.
            assign gtx_txd = {
               gtx_txd_10[9], gtx_txd_10[9], gtx_txd_10[8], gtx_txd_10[8],
               gtx_txd_10[7], gtx_txd_10[7], gtx_txd_10[6], gtx_txd_10[6],
               gtx_txd_10[5], gtx_txd_10[5], gtx_txd_10[4], gtx_txd_10[4],
               gtx_txd_10[3], gtx_txd_10[3], gtx_txd_10[2], gtx_txd_10[2],
               gtx_txd_10[1], gtx_txd_10[1], gtx_txd_10[0], gtx_txd_10[0]};
            assign gtx_rxd_10 = {
               gtx_rxd[19], gtx_rxd[17],
               gtx_rxd[15], gtx_rxd[13],
               gtx_rxd[11], gtx_rxd[9],
               gtx_rxd[7],  gtx_rxd[5],
               gtx_rxd[3],  gtx_rxd[1]};
            wire confused =  // XXX how to read out this status bit in hardware?
               (gtx_rxd[19]^gtx_rxd[18]) | (gtx_rxd[17]^gtx_rxd[16]) |
               (gtx_rxd[15]^gtx_rxd[14]) | (gtx_rxd[13]^gtx_rxd[12]) |
               (gtx_rxd[11]^gtx_rxd[10]) | (gtx_rxd[9]^gtx_rxd[8]) |
               (gtx_rxd[7]^gtx_rxd[6]) | (gtx_rxd[5]^gtx_rxd[4]) |
               (gtx_rxd[3]^gtx_rxd[2]) | (gtx_rxd[1]^gtx_rxd[0]);

        end else if (GTX_DW==20) begin: G_GTX_DATA_CONV

            // gtx clock is half the gmii clock rate in this stanza
            reg  [9:0] gtx_rxd_10_r=0;
            reg  [9:0] gtx_txd_r=0;
            wire [9:0] gtx_rxd_l = gtx_rxd[9:0];
            wire [9:0] gtx_rxd_h = gtx_rxd[19:10];
            reg  [19:0] gtx_txd_l=0;
            reg even=EVENINIT;

            always @(posedge gmii_tx_clk) begin
                gtx_txd_r <= gtx_txd_10;
            end

            always @(posedge gmii_rx_clk) begin
                even         <= ~even;
                // This next line would be a CDC, except Vivado "knows" that
                // gmii_rx_clk and gtx_rx_clk are "related clocks".
                // Note that gtx_rx_clk is only implicit in this module:
                // it's the clock domain of the gtx_rxd input port.
                gtx_rxd_10_r <= even ? gtx_rxd_l : gtx_rxd_h;
            end

            always @(posedge gtx_tx_clk) begin
                // This next line would be a CDC, except Vivado "knows" that
                // gtx_tx_clk and gmii_tx_clk are "related clocks".
                gtx_txd_l <= {gtx_txd_10, gtx_txd_r};
            end

            assign gtx_txd = gtx_txd_l;
            assign gtx_rxd_10 = gtx_rxd_10_r;

        end else begin

            // gmii and gtx clocks are considered the same in this stanza
            assign gtx_txd    = gtx_txd_10;
            assign gtx_rxd_10 = gtx_rxd;

        end endgenerate


        // ----------------------------------
        // PCS/PMA and GMII Bridge
        // ---------------------------------


        gmii_link #(.ENC_DISPINIT(ENC_DISPINIT), .CTRACE_AW(CTRACE_AW)) i_gmii_link(
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
            .rx_err_los   (rx_err_los),
            .an_bypass    (an_disable), // Disable auto-negotiation
            .lacr_rx      (lacr_rx),
            .an_status    (an_status_l)
`ifdef FIBER_TRACE
            // ctrace CSRs
            ,.ctrace_start(ctrace_start), // input
            .ctrace_running(ctrace_running), // output
            .ctrace_pc_mon(ctrace_pc_mon), // output [CTRACE_AW-1:0]
            // ctrace readout in lb_clk domain
            .lb_clk(lb_clk), // input
            .lb_addr(lb_addr), // input [CTRACE_AW-1:0]
            .lb_out(lb_out) // output [31:0]
`endif
        );

endmodule
