###############################
# Configuration file for qgt_wrap instances used in comms_top.v
# Quad GTX 0:
#    GTX0: Ethernet (1.25 Gbps)
#    GTX1: ChitChat (2.5 Gbps)
#    GTX2: -
#    GTX3: -
#
# Aux IP:
#    Ethernet MMCM
#
###############################

set MGT_CONFIG_DIR "../../fpga_family/mgt"
source $MGT_CONFIG_DIR/mgt_gen.tcl

# proc add_gtcommon {config_file quad_num}

# proc add_gt_protocol {config_file quad_num gt_num en8b10b pll_type}

set gt_type "GTX"

set quad 0
set gt 0
set en8b10b 0
set endrp 0
set pll_type "CPLL"
add_gt_protocol $gt_type $MGT_CONFIG_DIR/gtx_ethernet.tcl $quad $gt $en8b10b $endrp $pll_type

set quad 0
set gt 1
set en8b10b 1
set endrp 0
set pll_type "CPLL"
add_gt_protocol $gt_type $MGT_CONFIG_DIR/gtx_chitchat.tcl $quad $gt $en8b10b $endrp $pll_type

# proc add_aux_ip {ipname config_file module_name}
add_aux_ip clk_wiz $MGT_CONFIG_DIR/mgt_eth_clk.tcl mgt_eth_mmcm
