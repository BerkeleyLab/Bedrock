all: targets

#HARDWARE = qf2pre_kintex
HARDWARE = bmb7_kintex
DSP_FLAVOR = 7
XILINX_TOOL := VIVADO
include ../../dir_list.mk


vpath %.v $(APP_DIR)

CLEAN_DIRS += ./.Xil
system_top.xdc: larger_extra.xdc

include $(BUILD_DIR)/top_rules.mk
include $(BS_HARDWARE_DIR)/rules.mk
include $(BOARD_SUPPORT_DIR)/rules.mk
include $(ETHER_SUPPORT_DIR)/rules.mk
include $(APP_DIR)/rules.mk

IP_TCL = ./ip/clk_wiz_0.tcl ./ip/gtwizard_1.tcl
IP_TCL = ${FPGA_FAMILY_DIR}/gtx/gtx_eth_clk.tcl ${FPGA_FAMILY_DIR}/gtx/gtx_ethernet.tcl
VERILOG_DEFINE_FLAGS = ""

SYNTH_OPT += $(VERILOG_DEFINE_FLAGS)

VFLAGS_DEP += -y$(BS_HARDWARE_DIR) -y$(FPGA_FAMILY_DIR)/$(FPGA_FAMILY) -y$(ETHER_TOP_DIR) -y$(FPGA_FAMILY_DIR)/pll -y.

VFLAGS +=  $(VERILOG_DEFINE_FLAGS)

$(BITS_): $(IP_TCL)
