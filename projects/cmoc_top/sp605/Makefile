all: targets

HARDWARE = sp605
DSP_FLAVOR = 7
COMMUNICATION = gmii
#COMMUNICATION = mgt
DAUGHTER = base
FPGA_FAMILY = spartan6

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

ifneq (,$(findstring mgt,$(COMMUNICATION)))
ETHER_GENV += s6_gtp_params.vh
# hard-coded dependency need to be auto-resolved by MAKEDEP later
larger_shell_mgt_sp605.bit: s6_gtp_params.vh

#mgt_base.ucf: larger_extra.ucf
endif


vpath %.v $(APP_DIR) $(RTSIM_DIR) $(DSP_DIR) $(BADGER_DIR)

include $(BUILD_DIR)/top_rules.mk
include $(BS_HARDWARE_DIR)/rules.mk
include $(FPGA_FAMILY_DIR)/$(FPGA_FAMILY)/rules.mk
include $(BS_HARDWARE_DIR)/rules.mk
include $(BOARD_SUPPORT_DIR)/rules.mk
include $(APP_DIR)/api.mk

system_top.ucf: larger_extra.ucf

larger_shell_gmii_sp605.bit: $(AUTOGEN_DIR)/config_romx.v
larger_shell_gmii_sp605.v: cryomodule_badger_auto

VERILOG_DEFINE_FLAGS = ""

SYNTH_OPT += $(VERILOG_DEFINE_FLAGS)

VFLAGS_DEP += -y$(BS_HARDWARE_DIR) -y$(FPGA_FAMILY_DIR)/$(FPGA_FAMILY) -y$(FPGA_FAMILY_DIR)/pll -y. -y$(APP_DIR)

VFLAGS += $(VERILOG_DEFINE_FLAGS)

CLEAN += *.bit
CLEAN_DIRS += _xilinx

ifneq (,$(findstring bit,$(MAKECMDGOALS)))
    ifneq (,$(findstring bits,$(MAKECMDGOALS)))
	-include $(BITS_:%.bit=$(DEPDIR)/%.bit.d)
    else
	-include $(MAKECMDGOALS:%.bit=$(DEPDIR)/%.bit.d)
    endif
endif
