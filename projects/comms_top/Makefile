include ../../dir_list.mk

HARDWARE = qf2pre_kintex
DSP_FLAVOR = 7
COMMUNICATION = gtx
DAUGHTER = base
XILINX_TOOL := VIVADO

FPGA_FAMILY_GTX_DIR = $(FPGA_FAMILY_DIR)/gtx
BS_HARDWARE_DIR     = $(BOARD_SUPPORT_DIR)/$(HARDWARE)

APP_NAME = comms_top
IP_TCL = gtx_comms_top.tcl

vpath %.v $(BADGER_DIR) $(FPGA_FAMILY_DIR) $(FPGA_FAMILY_GTX_DIR) $(HOMELESS_DIR) $(DSP_DIR)

VFLAGS_DEP += -y$(BS_HARDWARE_DIR) -y$(FPGA_FAMILY_DIR) -y$(BADGER_DIR) -y$(FPGA_FAMILY_GTX_DIR) -y$(HOMELESS_DIR) -y. -I$(HOMELESS_DIR) -I$(BADGER_DIR) -y$(DSP_DIR) -I$(FPGA_FAMILY_GTX_DIR)

VERILOG_DEFINE_FLAGS =
SYNTH_OPT += $(VERILOG_DEFINE_FLAGS)
VFLAGS +=  $(VERILOG_DEFINE_FLAGS)

# Settings for Badger compile
RTEFI_CLIENT_LIST = hello.v speed_test.v mem_gateway.v
include $(BADGER_DIR)/rules.mk

# Set auto-generated dependencies before including top_rules.mk
VERILOG_AUTOGEN += $(RTEFI_V)
include $(BUILD_DIR)/top_rules.mk
include $(BS_HARDWARE_DIR)/rules.mk
include $(BOARD_SUPPORT_DIR)/rules.mk

all: gen $(APP_NAME).bit

gen : $(RTEFI_V)

$(APP_NAME).bit: $(IP_TCL)

ifneq (,$(findstring bit,$(MAKECMDGOALS)))
    ifneq (,$(findstring bits,$(MAKECMDGOALS)))
-include $(BITS_:%.bit=$(DEPDIR)/%.bit.d)
    else
-include $(MAKECMDGOALS:%.bit=$(DEPDIR)/%.bit.d)
    endif
endif

CLEAN_DIRS += ./.Xil _xilinx
CLEAN += $(RTEFI_CLEAN) *.bit
include $(BUILD_DIR)/bottom_rules.mk
