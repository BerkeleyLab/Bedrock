###############################
# Configuration file for qgt_wrap instances used in gige_top.v
# Quad GTP 0:
#    GTP0: Ethernet (1.25 Gbps)
#
# Aux IP:
#    Ethernet MMCM
#
###############################

if { [info exists ::env(DOUBLEBIT)] } {
    set doublebit $::env(DOUBLEBIT)
} else {
    set doublebit 0
}

puts "INFO: Building Transceivers with DOUBLEBIT = $doublebit"

set MGT_CONFIG_DIR "../../../fpga_family/mgt"
source $MGT_CONFIG_DIR/mgt_gen.tcl

# proc add_gtcommon {config_file quad_num pll0_refclk pll1_refclk}
set quad 0
set pll0_refclk "REFCLK0"
set pll1_refclk "REFCLK0"

# proc add_gt_protocol {gt_type config_file quad_num gt_num en8b10b pll_type}
set gt_type "GTP"
set gt 0
set en8b10b 0
set endrp 0
set pll_type "PLL0"

if { $doublebit == 1 } {
    add_gtcommon $MGT_CONFIG_DIR/gtp_common_2_50.tcl $quad $pll0_refclk $pll1_refclk
    add_gt_protocol $gt_type $MGT_CONFIG_DIR/gtp_ethernet_2_50.tcl $quad $gt $en8b10b $endrp $pll_type
} else {
    add_gtcommon $MGT_CONFIG_DIR/gtp_common_1_25.tcl $quad $pll0_refclk $pll1_refclk
    add_gt_protocol $gt_type $MGT_CONFIG_DIR/gtp_ethernet.tcl $quad $gt $en8b10b $endrp $pll_type
}

add_aux_ip clk_wiz $MGT_CONFIG_DIR/mgt_eth_clk.tcl mgt_eth_mmcm
add_aux_ip clk_wiz gtp_sys_clk_mmcm.tcl gtp_sys_clk_mmcm
