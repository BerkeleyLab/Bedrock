// ------------------------------------
// mgt_eth_clks.v
//
// Low-level wrapper for clock management module and clock buffers for GbE
// ------------------------------------

module mgt_eth_clks #(
   parameter USR_CLK_BUF = 0, // 0 - BUFG; 1 - BUFH
   parameter GMII_CLK_BUF = 0
) (
   input  reset,
   input  mgt_out_clk,
   output mgt_usr_clk,
   output gmii_clk,
   output gmii_clk90,
   output pll_lock
);

`ifndef SIMULATE

   wire mgt_out_clk_buf;
   wire mgt_usr_clk_l, gmii_clk_l, gmii_clk90_l;

   /* -- This is being included automatically by the Transceiver Wizard
   // Buffer for input clock (required for Kintex7, not required for Virtex7)
   BUFG i_mgt_out_clk_buf (
      .I (mgt_out_clk),
      .O (mgt_out_clk_buf)
   );
   */

   // Instantiate wizard-generated clock management module
   // Configured by mgt_eth_clk.tcl
   mgt_eth_mmcm i_mgt_eth_mmcm (
      .clk_in     (mgt_out_clk),
      .reset      (reset),
      .mgt_clk    (mgt_usr_clk_l),
      .gmii_clk   (gmii_clk_l),
      .gmii_clk90 (gmii_clk90_l),
      .locked     (pll_lock)
   );

   // Buffer clock management outputs
   generate
   if(USR_CLK_BUF == 0) begin
      BUFG i_mgt_usr_clk_buf (.I (mgt_usr_clk_l), .O (mgt_usr_clk));
   end else begin
      BUFH i_mgt_usr_clk_buf (.I (mgt_usr_clk_l), .O (mgt_usr_clk));
   end

   if(GMII_CLK_BUF == 0) begin
      BUFG i_gmii_clk_buf (.I (gmii_clk_l), .O (gmii_clk));
      BUFG i_gmii_clk90_buf (.I (gmii_clk90_l), .O (gmii_clk90));
   end else begin
      BUFH i_gmii_clk_buf (.I (gmii_clk_l), .O (gmii_clk));
      BUFH i_gmii_clk90_buf (.I (gmii_clk90_l), .O (gmii_clk90));
   end
   endgenerate

`else
   localparam CLK_PER_125 = 8;  // 8ns/125MHz
   localparam CLK_PER_625 = 16; // 16ns/62.5MHz

   reg mgt_usr_clk_l=0, gmii_clk_l=0;

   initial forever #(CLK_PER_125/2) gmii_clk_l    <= ~gmii_clk_l;
   initial forever #(CLK_PER_625/2) mgt_usr_clk_l <= ~mgt_usr_clk_l;

   assign pll_lock    = 1;
   assign gmii_clk    = gmii_clk_l;
   assign gmii_clk90  = gmii_clk_l;
   assign mgt_usr_clk = mgt_usr_clk_l;
`endif

endmodule
