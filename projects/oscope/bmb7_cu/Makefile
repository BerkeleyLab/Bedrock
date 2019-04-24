all: oscope_top.bit

HARDWARE = bmb7_kintex
DSP_FLAVOR = 7
COMMUNICATION = gtx
DAUGHTER = base
XILINX_TOOL := VIVADO

TOP_DIR = ../../..

BUILD_DIR = $(TOP_DIR)/build-tools
DSP_DIR = $(TOP_DIR)/dsp

BOARD_SUPPORT_DIR = $(TOP_DIR)/board_support
FPGA_FAMILY_DIR = $(TOP_DIR)/fpga_family
XILINX_DIR = $(FPGA_FAMILY_DIR)/xilinx
ISERDES_DIR = $(FPGA_FAMILY_DIR)/iserdes
PERIPHERAL_DIR = $(TOP_DIR)/peripheral_drivers
BS_HARDWARE_DIR = $(BOARD_SUPPORT_DIR)/$(HARDWARE)
HOMELESS_DIR = $(TOP_DIR)/homeless

APP_NAME = oscope

VERILOG_DEFINE_FLAGS = ""

SYNTH_OPT += $(VERILOG_DEFINE_FLAGS)

VFLAGS_DEP += -y$(DSP_DIR) -y$(BS_HARDWARE_DIR) -y$(FPGA_FAMILY_DIR) -y$(ISERDES_DIR) -y$(XILINX_DIR) -y$(HOMELESS_DIR) -y. -y$(PERIPHERAL_DIR) -y$(PERIPHERAL_DIR)/idelay_scanner

VFLAGS += $(VERILOG_DEFINE_FLAGS)

CLEAN += *.bit $(APP_NAME)_regmap*.json scalar_$(APP_NAME)_regmap.json
CLEAN_DIRS += _xilinx
CLEAN_DIRS += ./.Xil

vpath %.v $(DSP_DIR)

include $(BUILD_DIR)/top_rules.mk
include $(BS_HARDWARE_DIR)/rules.mk
include $(BOARD_SUPPORT_DIR)/rules.mk

oscope_top.bit: $(AUTOGEN_DIR)/config_romx.v
oscope_top.v: $(AUTOGEN_DIR)/config_romx.v application_top_auto

system_top.xdc: $(APP_NAME)_orig_special.xdc $(APP_NAME)_common.xdc
	cat $^ > $@

$(AUTOGEN_DIR)/config_romx.v: $(BUILD_DIR)/build_rom.py $(APP_NAME)_regmap.json
	$(PYTHON) $< -v $@ -j $(APP_NAME)_regmap.json

scalar_$(APP_NAME)_regmap.json: application_top.v
	$(PYTHON) $(BUILD_DIR)/reverse_json.py > $@

$(APP_NAME)_regmap.json: $(AUTOGEN_DIR)/regmap_application_top.json scalar_$(APP_NAME)_regmap.json static_$(APP_NAME)_regmap.json merge_json.py shorten_names.py
	$(PYTHON) merge_json.py -o $(APP_NAME)_regmap_long.json -i $(filter %.json, $^)
	$(PYTHON) shorten_names.py -o $@ -i $(APP_NAME)_regmap_long.json

include $(BUILD_DIR)/bottom_rules.mk

ifneq (,$(findstring bit,$(MAKECMDGOALS)))
    ifneq (,$(findstring bits,$(MAKECMDGOALS)))
-include $(BITS_:%.bit=$(DEPDIR)/%.bit.d)
    else
-include $(MAKECMDGOALS:%.bit=$(DEPDIR)/%.bit.d)
    endif
endif
