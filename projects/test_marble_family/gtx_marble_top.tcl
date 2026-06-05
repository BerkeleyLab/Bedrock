###############################
# Configuration file for qgt_wrap instances used in marble_top.v
# Quad GTX 1:
#    GTX0: -
#    GTX1: -
#    GTX2: -
#    GTX3: Ethernet (2.5 Gbps)
#
# Aux IP:
#    Ethernet MMCM
#
###############################

set MGT_CONFIG_DIR "../../fpga_family/mgt"
source $MGT_CONFIG_DIR/mgt_gen.tcl

set gt_type "GTX"
set quad 1
set endrp 0
set pll_type "CPLL"
set en8b10b 0
set gtx 3
add_gt_protocol $gt_type $MGT_CONFIG_DIR/gtx_ethernet_2_50.tcl $quad $gtx $en8b10b $endrp $pll_type

# proc add_aux_ip {ipname config_file module_name}
set ::env(DOUBLEBIT) 1
add_aux_ip clk_wiz $MGT_CONFIG_DIR/mgt_eth_clk.tcl mgt_eth_mmcm
