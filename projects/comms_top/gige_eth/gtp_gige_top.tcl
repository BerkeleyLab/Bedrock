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


# proc add_gtcommon {config_file quad_num}

set quad 0
add_gtcommon $GTX_CONFIG_DIR/gtp_ethernet.tcl $quad

# proc add_gtx_protocol {gt_type config_file quad_num gtx_num en8b10b}

set gt_type "GTP"

set quad 0
set gtx 0
set en8b10b 0
add_gt_protocol $gt_type $GTX_CONFIG_DIR/gtp_ethernet.tcl $quad $gtx $en8b10b

# proc add_aux_ip {ipname config_file module_name}
add_aux_ip clk_wiz $GTX_CONFIG_DIR/gtx_eth_clk.tcl gtx_eth_mmcm
