// ------------------------------------
// gtx_eth_clks.v
//
// Low-level wrapper for clock management module and clock buffers for GbE
// ------------------------------------

module gtx_eth_clks (
   input  gtx_out_clk,
   input  reset,
   output gtx_usr_clk,
   output gmii_clk,
   output pll_lock
);

`ifndef SIMULATE

   wire gtx_out_clk_buf;
   wire gtx_usr_clk_l, gmii_clk_l;

   /* -- This is being included automatically by the Transceiver Wizard
   // Buffer for input clock (required for Kintex7, not required for Virtex7)
   BUFG i_gtx_out_clk_buf (
      .I (gtx_out_clk),
      .O (gtx_out_clk_buf)
   );
   */

   // Instantiate wizard-generated clock management module
   // Configured by gtx_ethernet_clk.tcl
   gtx_eth_mmcm i_gtx_eth_mmcm (
      .clk_in   (gtx_out_clk),
      .reset    (reset),
      .gtx_clk  (gtx_usr_clk_l),
      .gmii_clk (gmii_clk_l),
      .locked   (pll_lock)
   );

   // Buffer clock management outputs
   BUFG i_gtx_usr_clk_buf (
      .I (gtx_usr_clk_l),
      .O (gtx_usr_clk)
   );

   BUFG i_gmii_clk_buf (
      .I (gmii_clk_l),
      .O (gmii_clk)
   );

`else
   localparam CLK_PER_125 = 8;  // 8ns/125MHz
   localparam CLK_PER_625 = 16; // 16ns/62.5MHz

   reg gtx_usr_clk_l=0, gmii_clk_l=0;

   initial forever #(CLK_PER_125/2) gmii_clk_l    <= ~gmii_clk_l;
   initial forever #(CLK_PER_625/2) gtx_usr_clk_l <= ~gtx_usr_clk_l;

   assign pll_lock    = 1;
   assign gmii_clk    = gmii_clk_l;
   assign gtx_usr_clk = gtx_usr_clk_l;
`endif

endmodule
