set cfg_dict {
   CONFIG.PRIMITIVE                  {PLL}
   CONFIG.PRIM_IN_FREQ               {62.500}
   CONFIG.CLKOUT1_USED               {true}
   CONFIG.CLKOUT2_USED               {true}
   CONFIG.CLKOUT3_USED               {true}
   CONFIG.PRIMARY_PORT               {clk_in}
   CONFIG.CLK_OUT1_PORT              {mgt_clk}
   CONFIG.CLK_OUT2_PORT              {gmii_clk}
   CONFIG.CLK_OUT3_PORT              {gmii_clk90}
   CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {62.5}
   CONFIG.CLKOUT1_REQUESTED_PHASE    {90.0}
   CONFIG.CLKOUT2_REQUESTED_OUT_FREQ {125.0}
   CONFIG.CLKOUT3_REQUESTED_OUT_FREQ {125.0}
   CONFIG.CLKOUT3_REQUESTED_PHASE    {90.0}
   CONFIG.MMCM_DIVCLK_DIVIDE         {1}
   CONFIG.OVERRIDE_MMCM              {true}
   CONFIG.MMCM_COMPENSATION          {BUF_IN}
   CONFIG.NUM_OUT_CLKS               {3}
}
