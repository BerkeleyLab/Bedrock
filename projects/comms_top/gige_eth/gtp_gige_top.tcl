###############################
# Configuration file for qgtx_wrap instances used in gige_top.v
# Quad GTP 0:
#    GTP0: Ethernet (1.25 Gbps)
#
# Aux IP:
#    Ethernet MMCM
#
###############################

set GTX_CONFIG_DIR "../../../fpga_family/gtx"
source $GTX_CONFIG_DIR/gtx_gen.tcl


# proc add_gtcommon {config_file quad_num pll0_refclk pll1_refclk}

set quad 0
set pll0_refclk "REFCLK0"
set pll1_refclk "REFCLK0"
add_gtcommon $GTX_CONFIG_DIR/gtp_common_1_25.tcl $quad $pll0_refclk $pll1_refclk

# proc add_gtx_protocol {gt_type config_file quad_num gtx_num en8b10b pll_type}

set gt_type "GTP"

set quad 0
set gtx 0
set en8b10b 0
set pll_type "PLL0"
add_gt_protocol $gt_type $GTX_CONFIG_DIR/gtp_ethernet.tcl $quad $gtx $en8b10b $pll_type

# proc add_aux_ip {ipname config_file module_name}
add_aux_ip clk_wiz $GTX_CONFIG_DIR/gtx_eth_clk.tcl gtx_eth_mmcm

add_aux_ip clk_wiz gtp_sys_clk_mmcm.tcl gtp_sys_clk_mmcm
