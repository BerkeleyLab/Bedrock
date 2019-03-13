###############################
# Configuration file for qgtx_wrap instances used in comms_top.v
# Quad GTX 0:
#    GTX0: Ethernet (1.25 Gbps)
#    GTX1: ChitChat (2.5 Gbps)
#    GTX2: -
#    GTX3: -
###############################

set GTX_CONFIG_DIR "../../fpga_family/gtx"

source $GTX_CONFIG_DIR/gtx_gen.tcl

# proc add_protocol {quad_num gtx_num protocol}

add_gtx_protocol 0 0 "Ethernet"
add_gtx_protocol 0 1 "ChitChat"

