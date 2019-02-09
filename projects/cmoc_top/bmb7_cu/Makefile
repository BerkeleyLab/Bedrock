all: targets

HARDWARE = bmb7_kintex
DSP_FLAVOR = 7
COMMUNICATION = gtx
DAUGHTER = base
XILINX_TOOL := VIVADO

TOP_DIR = ../../..
APP_DIR = $(TOP_DIR)/cmoc
BUILD_DIR = $(TOP_DIR)/build-tools
DSP_DIR = $(TOP_DIR)/dsp
RTSIM_DIR = $(TOP_DIR)/rtsim
CORDIC_DIR = $(TOP_DIR)/cordic
BOARD_SUPPORT_DIR = $(TOP_DIR)/board_support
FPGA_FAMILY_DIR = $(TOP_DIR)/fpga_family
BADGER_DIR = $(TOP_DIR)/badger
BS_HARDWARE_DIR = $(BOARD_SUPPORT_DIR)/$(HARDWARE)

vpath %.v $(APP_DIR) $(RTSIM_DIR) $(DSP_DIR) $(BADGER_DIR)

CLEAN_DIRS += ./.Xil
system_top.xdc: prc.xdc

include $(BUILD_DIR)/top_rules.mk
include $(BS_HARDWARE_DIR)/rules.mk
include $(BOARD_SUPPORT_DIR)/rules.mk
include $(APP_DIR)/api.mk

VERILOG_DEFINE_FLAGS = ""

SYNTH_OPT += $(VERILOG_DEFINE_FLAGS)

VFLAGS_DEP += -y$(BS_HARDWARE_DIR) -y$(FPGA_FAMILY_DIR) -y$(FPGA_FAMILY_DIR)/$(FPGA_FAMILY) -y$(FPGA_FAMILY_DIR)/pll -y. -y$(APP_DIR)

VFLAGS += $(VERILOG_DEFINE_FLAGS)

CLEAN += *.bit
CLEAN_DIRS += _xilinx

larger_shell_gtx_bmb7_kintex.bit: $(AUTOGEN_DIR)/config_romx.v
larger_shell_gtx_bmb7_kintex.v: cryomodule_auto

ifneq (,$(findstring bit,$(MAKECMDGOALS)))
    ifneq (,$(findstring bits,$(MAKECMDGOALS)))
-include $(BITS_:%.bit=$(DEPDIR)/%.bit.d)
    else
-include $(MAKECMDGOALS:%.bit=$(DEPDIR)/%.bit.d)
    endif
endif
