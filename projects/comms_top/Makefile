HARDWARE = qf2pre_kintex
DSP_FLAVOR = 7
COMMUNICATION = gtx
DAUGHTER = base
XILINX_TOOL := VIVADO

TOP_DIR = ../..

BUILD_DIR = $(TOP_DIR)/build-tools
DSP_DIR   = $(TOP_DIR)/dsp

BOARD_SUPPORT_DIR   = $(TOP_DIR)/board_support
FPGA_FAMILY_DIR     = $(TOP_DIR)/fpga_family
FPGA_FAMILY_GTX_DIR = $(FPGA_FAMILY_DIR)/gtx
PERIPHERAL_DIR      = $(TOP_DIR)/peripheral_drivers
BS_HARDWARE_DIR     = $(BOARD_SUPPORT_DIR)/$(HARDWARE)
BADGER_DIR          = $(TOP_DIR)/badger
HOMELESS_DIR        = $(TOP_DIR)/homeless

APP_NAME = comms_top

vpath %.v $(BADGER_DIR) $(FPGA_FAMILY_DIR) $(FPGA_FAMILY_GTX_DIR) $(HOMELESS_DIR) $(DSP_DIR)

CLEAN_DIRS += ./.Xil $(RTEFI_V)
#system_top.xdc: larger_extra.xdc

include $(BUILD_DIR)/top_rules.mk
include $(BS_HARDWARE_DIR)/rules.mk
include $(BOARD_SUPPORT_DIR)/rules.mk
include $(BADGER_DIR)/rules.mk

IP_TCL = gtx_comms_top.tcl

VERILOG_DEFINE_FLAGS =-DGT0_ENABLE -DGT1_ENABLE

SYNTH_OPT += $(VERILOG_DEFINE_FLAGS)

VFLAGS_DEP += -y$(BS_HARDWARE_DIR) -y$(FPGA_FAMILY_DIR) -y$(BADGER_DIR) -y$(FPGA_FAMILY_GTX_DIR) -y$(HOMELESS_DIR) -y. -I$(HOMELESS_DIR) -I$(BADGER_DIR) -y$(DSP_DIR)

VFLAGS +=  $(VERILOG_DEFINE_FLAGS)

#$(BITS_): $(IP_TCL)

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
