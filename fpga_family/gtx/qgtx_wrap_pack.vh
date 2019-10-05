// ------------------------------------
// QGTX_WRAP_PACK.VH
// Helper macros for qgtx_wrap.v
// ------------------------------------

`define GTi_PORTS(GTi, DWI) output               gt``GTi``_rxoutclk_out,\
                            input                gt``GTi``_rxusrclk_in,\
                            input                gt``GTi``_rxusrclk2_in,\
                            output               gt``GTi``_txoutclk_out,\
                            input                gt``GTi``_txusrclk_in,\
                            input                gt``GTi``_txusrclk2_in,\
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
                            input  [(DWI/8)-1:0] gt``GTi``_txcharisk_in,\
                            output               gt``GTi``_rxbyteisaligned,\
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
                       `undef GT0_PLL0\
                       `undef GT1_PLL0\
                       `undef GT2_PLL0\
                       `undef GT3_PLL0\
                       `undef GT0_PLL1\
                       `undef GT1_PLL1\
                       `undef GT2_PLL1\
                       `undef GT3_PLL1\
                       `undef GTCOMMON_EN\
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
                       `endif
