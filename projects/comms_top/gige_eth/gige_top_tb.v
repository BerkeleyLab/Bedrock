`timescale 1ns / 1ns

module gige_top_tb;

   localparam SIM_TIME = 1e6;

   localparam SYS_CLK_PER = 5;
   localparam REFCLK0_PER = 8;
   localparam REFCLK1_PER = 8;

   reg sys_clk_p=0, refclk0_p=0, refclk1_p=0;
   wire sys_clk_n, refclk0_n, refclk1_n;

   initial forever begin sys_clk_p <= ~sys_clk_p; #(SYS_CLK_PER/2); end
   initial forever begin refclk0_p <= ~refclk0_p; #(REFCLK0_PER/2); end
   initial forever begin refclk1_p <= ~refclk1_p; #(REFCLK0_PER/2); end

   assign sys_clk_n = ~sys_clk_p;
   assign refclk0_n = ~refclk0_p;
   assign refclk1_n = ~refclk1_p;

   wire sfp_txp, sfp_txn;

   defparam i_dut.i_q0_gtx_wrap.i_gtx0.inst.EXAMPLE_SIM_GTRESET_SPEEDUP = "TRUE";
   defparam i_dut.i_q0_gtx_wrap.i_gtx0.inst.EXAMPLE_SIMULATION = 1;

   gige_top i_dut
   (
      .SYS_CLK_P (sys_clk_p),
      .SYS_CLK_N (sys_clk_n),
      .MGTREFCLK0_P (refclk0_p),
      .MGTREFCLK0_N (refclk0_n),
      .MGTREFCLK1_P (refclk1_p),
      .MGTREFCLK1_N (refclk1_n),
      .MGTREFCLK0_SEL1 (),
      .MGTREFCLK0_SEL0 (),
      .SFP_RXP (sfp_txp),
      .SFP_RXN (sfp_txn),
      .SFP_TXP (sfp_txp),
      .SFP_TXN (sfp_txn),
      .LED()
   );

endmodule
