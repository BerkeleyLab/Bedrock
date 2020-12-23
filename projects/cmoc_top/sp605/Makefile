TOP_DIR = ../../..
include $(TOP_DIR)/dir_list.mk

TARGET = larger_shell_gmii_sp605.bit
.PHONY: all
all: $(TARGET)

HARDWARE = sp605
DSP_FLAVOR = 7
COMMUNICATION = gmii
#COMMUNICATION = mgt
DAUGHTER = base
FPGA_FAMILY = spartan6
RTEFI_CLIENT_LIST = hello.v speed_test.v mem_gateway.v

APP_DIR = $(TOP_DIR)/cmoc
BS_HARDWARE_DIR = $(BOARD_SUPPORT_DIR)/$(HARDWARE)

ifneq (,$(findstring mgt,$(COMMUNICATION)))
ETHER_GENV += s6_gtp_params.vh
# hard-coded dependency need to be auto-resolved by MAKEDEP later
larger_shell_mgt_sp605.bit: s6_gtp_params.vh $(AUTOGEN_DIR)/config_romx.v

#mgt_base.ucf: larger_extra.ucf
endif

vpath %.v $(APP_DIR) $(RTSIM_DIR) $(DSP_DIR) $(BADGER_DIR)

include $(BUILD_DIR)/top_rules.mk
include $(BS_HARDWARE_DIR)/rules.mk
include $(FPGA_FAMILY_DIR)/$(FPGA_FAMILY)/rules.mk
include $(BS_HARDWARE_DIR)/rules.mk
include $(BOARD_SUPPORT_DIR)/rules.mk
include $(APP_DIR)/rules.mk
include _dep/larger_shell_gmii_sp605.bit.d

system_top.ucf: larger_extra.ucf

$(DEPDIR)/$(TARGET).d: $(AUTOGEN_DIR)/config_romx.v
larger_shell_gmii_sp605.v: cryomodule_badger_auto

SYNTH_OPT += $(VERILOG_DEFINE_FLAGS)

VFLAGS_DEP += -y$(BS_HARDWARE_DIR) -y$(FPGA_FAMILY_DIR)/$(FPGA_FAMILY) -y$(FPGA_FAMILY_DIR)/pll -y. -y$(APP_DIR)

VFLAGS += $(VERILOG_DEFINE_FLAGS)

CLEAN += $(TARGET)
CLEAN_DIRS += _xilinx

$(AUTOGEN_DIR)/config_romx.v:
	mkdir -p $(AUTOGEN_DIR); $(PYTHON) $(BUILD_DIR)/config_crunch.py --HARDWARE=$(HARDWARE) --DSP_FLAVOR=$(DSP_FLAVOR) --OUTPUT=$@

include $(BUILD_DIR)/bottom_rules.mk

ifeq (,$(MAKECMDGOALS))
    -include $(TARGET:%.bit=$(DEPDIR)/%.bit.d)
endif
