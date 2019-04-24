TOP_DIR = ../../..
include $(TOP_DIR)/dir_list.mk
TARGET = larger_shell_gtx_bmb7_kintex.bit
.PHONY: all
all: $(TARGET)

HARDWARE = bmb7_kintex
DSP_FLAVOR = 7
COMMUNICATION = gtx
DAUGHTER = base
XILINX_TOOL := VIVADO

APP_DIR = $(TOP_DIR)/cmoc
DSP_DIR = $(TOP_DIR)/dsp
BS_HARDWARE_DIR = $(BOARD_SUPPORT_DIR)/$(HARDWARE)

vpath %.v $(APP_DIR) $(RTSIM_DIR) $(DSP_DIR) $(BADGER_DIR)

CLEAN_DIRS += ./.Xil
system_top.xdc: prc.xdc

include $(BUILD_DIR)/top_rules.mk
include $(BS_HARDWARE_DIR)/rules.mk
include $(BOARD_SUPPORT_DIR)/rules.mk
include $(APP_DIR)/rules.mk

SYNTH_OPT += $(VERILOG_DEFINE_FLAGS)

VFLAGS_DEP += -y$(BS_HARDWARE_DIR) -y$(FPGA_FAMILY_DIR) -y$(FPGA_FAMILY_DIR)/xilinx -y$(FPGA_FAMILY_DIR)/pll -y. -y$(APP_DIR) -y$(HOMELESS_DIR)

VFLAGS += $(VERILOG_DEFINE_FLAGS)

CLEAN += $(TARGET) $(AUTOGEN_DIR)/config_romx.v
CLEAN_DIRS += _xilinx

larger_shell_gtx_bmb7_kintex.bit: $(AUTOGEN_DIR)/config_romx.v
$(AUTOGEN_DIR)/config_romx.v:
	mkdir -p $(AUTOGEN_DIR); $(PYTHON) $(BUILD_DIR)/config_crunch.py --HARDWARE=$(HARDWARE) --DSP_FLAVOR=$(DSP_FLAVOR) --OUTPUT=$@

$(DEPDIR)/$(TARGET).d: $(AUTOGEN_DIR)/config_romx.v

larger_shell_gtx_bmb7_kintex.v: cryomodule_auto

include $(BUILD_DIR)/bottom_rules.mk

ifeq (,$(MAKECMDGOALS))
    -include $(TARGET:%.bit=$(DEPDIR)/%.bit.d)
endif
