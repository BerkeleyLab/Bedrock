// ------------------------------------
// QGT_WRAP_PACK.VH
// Helper macros for qgt_wrap.v
// ------------------------------------

`define GTi_PORTS(GTi, DWI) `ifdef GT_TYPE__GTX\
                            input                gt``GTi``_refclk0,\
                            input                gt``GTi``_refclk1,\
                            `endif\
                            output               gt``GTi``_rxoutclk_out,\
                            input                gt``GTi``_rxusrclk_in,\
                            output               gt``GTi``_txoutclk_out,\
                            input                gt``GTi``_txusrclk_in,\
                            input                gt``GTi``_rxusrrdy_in,\
                            output [DWI-1:0]     gt``GTi``_rxdata_out,\
                            input                gt``GTi``_txusrrdy_in,\
                            input  [DWI-1:0]     gt``GTi``_txdata_in,\
                            input                gt``GTi``_rxn_in,\
                            input                gt``GTi``_rxp_in,\
                            output               gt``GTi``_txn_out,\
                            output               gt``GTi``_txp_out,\
                            output               gt``GTi``_rxfsm_resetdone_out,\
                            output               gt``GTi``_txfsm_resetdone_out,\
                            `ifdef GT``GTi``_8B10B_EN\
                            output [(DWI/8)-1:0] gt``GTi``_rxcharisk_out,\
                            output [(DWI/8)-1:0] gt``GTi``_rxchariscomma_out,\
                            input  [(DWI/8)-1:0] gt``GTi``_txcharisk_in,\
                            output [(DWI/8)-1:0] gt``GTi``_rxdisperr_out,\
                            output [(DWI/8)-1:0] gt``GTi``_rxnotintable_out,\
                            output               gt``GTi``_rxbyteisaligned,\
                            `endif\
                            `ifdef GT``GTi``_DRP_EN\
                            input                gt``GTi``_drpclk_in,\
                            input  [(DWI-13):0]  gt``GTi``_drpaddr_in,\
                            input  [(DWI-14):0]  gt``GTi``_drpdi_in,\
                            output [(DWI-14):0]  gt``GTi``_drpdo_out,\
                            input                gt``GTi``_drpen_in,\
                            output               gt``GTi``_drprdy_out,\
                            input                gt``GTi``_drpwe_in,\
                            `endif\
                            output [2:0]         gt``GTi``_rxbufstatus,\
                            output [1:0]         gt``GTi``_txbufstatus,

`define Q_REDEFINE(Qi) `undef GT0_ENABLE\
                       `undef GT1_ENABLE\
                       `undef GT2_ENABLE\
                       `undef GT3_ENABLE\
                       `undef GT0_8B10B_EN\
                       `undef GT1_8B10B_EN\
                       `undef GT2_8B10B_EN\
                       `undef GT3_8B10B_EN\
                       `undef GT0_DRP_EN\
                       `undef GT1_DRP_EN\
                       `undef GT2_DRP_EN\
                       `undef GT3_DRP_EN\
                       `undef GT0_PLL0\
                       `undef GT1_PLL0\
                       `undef GT2_PLL0\
                       `undef GT3_PLL0\
                       `undef GT0_PLL1\
                       `undef GT1_PLL1\
                       `undef GT2_PLL1\
                       `undef GT3_PLL1\
                       `undef GTCOMMON_EN\
                       `undef PLL0_RECLK0\
                       `undef PLL0_RECLK1\
                       `undef PLL1_RECLK0\
                       `undef PLL1_RECLK1\
                       `ifdef Q``Qi``_GT0_ENABLE `define GT0_ENABLE\
                       `endif\
                       `ifdef Q``Qi``_GT1_ENABLE `define GT1_ENABLE\
                       `endif\
                       `ifdef Q``Qi``_GT2_ENABLE `define GT2_ENABLE\
                       `endif\
                       `ifdef Q``Qi``_GT3_ENABLE `define GT3_ENABLE\
                       `endif\
                       `ifdef Q``Qi``_GT0_8B10B_EN `define GT0_8B10B_EN\
                       `endif\
                       `ifdef Q``Qi``_GT1_8B10B_EN `define GT1_8B10B_EN\
                       `endif\
                       `ifdef Q``Qi``_GT2_8B10B_EN `define GT2_8B10B_EN\
                       `endif\
                       `ifdef Q``Qi``_GT3_8B10B_EN `define GT3_8B10B_EN\
                       `endif\
                       `ifdef Q``Qi``_GT0_DRP_EN `define GT0_DRP_EN\
                       `endif\
                       `ifdef Q``Qi``_GT1_DRP_EN `define GT1_DRP_EN\
                       `endif\
                       `ifdef Q``Qi``_GT2_DRP_EN `define GT2_DRP_EN\
                       `endif\
                       `ifdef Q``Qi``_GT3_DRP_EN `define GT3_DRP_EN\
                       `endif\
                       `ifdef Q``Qi``_GT0_PLL0 `define GT0_PLL0\
                       `endif\
                       `ifdef Q``Qi``_GT1_PLL0 `define GT1_PLL0\
                       `endif\
                       `ifdef Q``Qi``_GT2_PLL0 `define GT2_PLL0\
                       `endif\
                       `ifdef Q``Qi``_GT3_PLL0 `define GT3_PLL0\
                       `endif\
                       `ifdef Q``Qi``_GT0_PLL1 `define GT0_PLL1\
                       `endif\
                       `ifdef Q``Qi``_GT1_PLL1 `define GT1_PLL1\
                       `endif\
                       `ifdef Q``Qi``_GT2_PLL1 `define GT2_PLL1\
                       `endif\
                       `ifdef Q``Qi``_GT3_PLL1 `define GT3_PLL1\
                       `endif\
                       `ifdef Q``Qi``_GTCOMMON_ENABLE `define GTCOMMON_EN\
                       `endif\
                       `ifdef Q``Qi``_PLL0_REFCLK0 `define PLL0_REFCLK0\
                       `endif\
                       `ifdef Q``Qi``_PLL0_REFCLK1 `define PLL0_REFCLK1\
                       `endif\
                       `ifdef Q``Qi``_PLL1_REFCLK0 `define PLL1_REFCLK0\
                       `endif\
                       `ifdef Q``Qi``_PLL1_REFCLK1 `define PLL1_REFCLK1\
                       `endif
