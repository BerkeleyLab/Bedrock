include ../../../dir_list.mk

all: oscope_top.bit

HARDWARE = bmb7_kintex
DSP_FLAVOR = 7
COMMUNICATION = gtx
DAUGHTER = base
XILINX_TOOL := VIVADO

XILINX_DIR = $(FPGA_FAMILY_DIR)/xilinx
ISERDES_DIR = $(FPGA_FAMILY_DIR)/iserdes
BS_HARDWARE_DIR = $(BOARD_SUPPORT_DIR)/$(HARDWARE)
OSCOPE_COMMON_DIR=../common

APP_NAME = oscope

VERILOG_DEFINE_FLAGS = ""

SYNTH_OPT += $(VERILOG_DEFINE_FLAGS)

include $(BUILD_DIR)/top_rules.mk
include $(OSCOPE_COMMON_DIR)/rules.mk

VFLAGS_DEP += -y$(DSP_DIR) -y$(BS_HARDWARE_DIR) -y$(FPGA_FAMILY_DIR) -y$(ISERDES_DIR) -y$(XILINX_DIR) -y$(SERIAL_IO_DIR) -y. -y$(PERIPH_DRIVERS_DIR) -y$(PERIPH_DRIVERS_DIR)/idelay_scanner -y$(OSCOPE_COMMON_DIR) -y$(BOARD_SUPPORT_DIR)/zest

VFLAGS += $(VERILOG_DEFINE_FLAGS)

VLATOR_LINT_IGNORE += -Wno-TIMESCALEMOD

CLEAN += *.bit $(APP_NAME)_regmap*.json scalar_$(APP_NAME)_regmap.json
CLEAN_DIRS += _xilinx
CLEAN_DIRS += ./.Xil
CLEAN_DIRS += ./obj_dir

vpath %.v $(DSP_DIR)

include $(BS_HARDWARE_DIR)/rules.mk
include $(BOARD_SUPPORT_DIR)/rules.mk

NEWAD_DIRS += $(OSCOPE_COMMON_DIR)

$(AUTOGEN_DIR)/moving_average.v: $(DSP_DIR)/moving_average/moving_average.py
	$(PYTHON) $(DSP_DIR)/moving_average/moving_average.py > $(AUTOGEN_DIR)/moving_average.v
	exit

oscope_top.bit: $(AUTOGEN_DIR)/config_romx.v

oscope_top.sv: $(AUTOGEN_DIR)/config_romx.v application_top_auto $(AUTOGEN_DIR)/moving_average.v

Voscope_top_CLIB := $(BADGER_DIR)/tests
Voscope_top_tb: oscope_top.sv Voscope_top_tb.cpp $(BADGER_DIR)/tests/udp_model.c

# Run UDP simulation, use leep CLI to read out register list and compare against golden reference
Voscope_top_leep: Voscope_top_tb $(APP_NAME)_regmap.json
	@echo "----- Oscope leep list self-test -----"
	timeout 20 ./$< &
	PYTHONPATH=$(PROJECTS_DIR)/common/ $(PYTHON) -m leep.cli leep://localhost:3010 list > leep_list.txt
	awk -F'"' '/ {/{print $$2}' $(APP_NAME)_regmap.json | cmp leep_list.txt -

Voscope_top_live: Voscope_top_tb $(APP_NAME)_regmap.json
	@echo "----- Oscope build rom live test -----"
	timeout 20 ./$< &
	PYTHONPATH=$(PROJECTS_DIR)/common/ $(PYTHON) $(BUILD_DIR)/build_rom.py --live -a localhost -p 3010

system_top.xdc: $(APP_NAME)_orig_special.xdc $(APP_NAME)_common.xdc

$(AUTOGEN_DIR)/config_romx.v: $(BUILD_DIR)/build_rom.py $(APP_NAME)_regmap.json
	$(PYTHON) $< -v $@ -j $(APP_NAME)_regmap.json

scalar_$(APP_NAME)_regmap.json: $(OSCOPE_COMMON_DIR)/application_top.sv
	$(PYTHON) $(BUILD_DIR)/reverse_json.py $< > $@

$(AUTOGEN_DIR)/%_auto.vh: $(OSCOPE_COMMON_DIR)/%.sv
	mkdir -p $(AUTOGEN_DIR); $(PYTHON) $(BUILD_DIR)/newad.py -o $@ $(NEWAD_ARGS) $(NEWAD_ARGS_$*)

$(AUTOGEN_DIR)/addr_map_%.vh: $(OSCOPE_COMMON_DIR)/%.sv
	mkdir -p $(AUTOGEN_DIR); $(PYTHON) $(BUILD_DIR)/newad.py -a $@ $(NEWAD_ARGS) $(NEWAD_ARGS_$*)

$(AUTOGEN_DIR)/regmap_application_top.json: $(OSCOPE_COMMON_DIR)/application_top.sv
	mkdir -p $(AUTOGEN_DIR); $(PYTHON) $(BUILD_DIR)/newad.py -l -r $@ $(NEWAD_ARGS) $(NEWAD_ARGS_$*)

$(APP_NAME)_regmap.json: $(AUTOGEN_DIR)/regmap_application_top.json scalar_$(APP_NAME)_regmap.json $(OSCOPE_COMMON_DIR)/static_$(APP_NAME)_regmap.json $(OSCOPE_COMMON_DIR)/merge_json.py $(OSCOPE_COMMON_DIR)/shorten_names.py
	$(PYTHON) $(OSCOPE_COMMON_DIR)/merge_json.py -o $(APP_NAME)_regmap_long.json -i $(filter %.json, $^)
	$(PYTHON) $(OSCOPE_COMMON_DIR)/shorten_names.py -o $@ -i $(APP_NAME)_regmap_long.json

include $(BUILD_DIR)/bottom_rules.mk

ifneq (,$(findstring bit,$(MAKECMDGOALS)))
    ifneq (,$(findstring bits,$(MAKECMDGOALS)))
-include $(BITS_:%.bit=$(DEPDIR)/%.bit.d)
    else
-include $(MAKECMDGOALS:%.bit=$(DEPDIR)/%.bit.d)
    endif
endif
ifneq (,$(findstring _tb,$(MAKECMDGOALS)))
    -include $(MAKECMDGOALS:%_tb=$(DEPDIR)/%_tb.d)
endif
