TOP_DIR = ../../..
include $(TOP_DIR)/dir_list.mk
.PHONY: all
all: $(TARGET)

XILINX_TOOL := VIVADO
APP_NAME = cmoc

HARDWARE = marblemini

APP_DIR = $(TOP_DIR)/cmoc
DSP_DIR = $(TOP_DIR)/dsp
OSCOPE_COMMON_DIR = $(TOP_DIR)/projects/oscope/common
BS_HARDWARE_DIR = $(BOARD_SUPPORT_DIR)/$(HARDWARE)

vpath %.v $(APP_DIR) $(RTSIM_DIR) $(DSP_DIR) $(DSP_DIR)/hosted $(BADGER_DIR)

CLEAN_DIRS += ./.Xil

include $(BUILD_DIR)/newad_top_rules.mk
include $(BS_HARDWARE_DIR)/rules.mk
include $(APP_DIR)/rules.mk

SYNTH_OPT += $(VERILOG_DEFINE_FLAGS)

VFLAGS_DEP += -y$(BS_HARDWARE_DIR) -y$(BOARD_SUPPORT_DIR)/marblemini -y$(FPGA_FAMILY_DIR) -y$(FPGA_FAMILY_DIR) -y$(FPGA_FAMILY_DIR)/xilinx -y$(FPGA_FAMILY_DIR)/pll -y. -y$(APP_DIR) -y$(HOMELESS_DIR) -y$(HOMELESS_DIR)/freq_demo -y$(BADGER_DIR) -y$(BADGER_DIR)/tests -y$(BADGER_DIR)/tests/kc705 -y$(SERIAL_IO_DIR) -y../../test_marble_family -I../../test_marble_family -y../../test_marble_family/pps_lock -y$(PERIPH_DRIVERS_DIR) -y$(PERIPH_DRIVERS_DIR)/i2cbridge -y../bmb7_cu

VFLAGS += $(VERILOG_DEFINE_FLAGS)

system_top.xdc: $(BOARD_SUPPORT_DIR)/$(HARDWARE)/Marble.xdc $(BOARD_SUPPORT_DIR)/$(HARDWARE)/pin_map.csv $(HARDWARE)_top.csv
	@echo "Building for $(HARDWARE); Use make HARDWARE=marble(mini) otherwise"
	$(PYTHON) $(BADGER_DIR)/tests/meta-xdc.py $^ > $@

CLEAN += $(TARGET) $(AUTOGEN_DIR)/config_romx.v *~ system_top.xdc cmoc_top.bin cmoc_top.prm cmoc_top.bit $(APP_NAME)_regmap_long.json $(APP_NAME)_regmap.json marble_features*.vh $(RTEFI_CLEAN)
CLEAN += *.log *.jou
CLEAN_DIRS += _xilinx

cmoc_top.bit: $(AUTOGEN_DIR)/config_romx.v
cmoc_top.v: marble_features_defs.vh marble_features_params.vh $(AUTOGEN_DIR)/config_romx.v rtefi_blob.v construct_tx_table.v cryomodule_auto

download: cmoc_top.bit
	openocd -f $(BOARD_SUPPORT_DIR)/$(HARDWARE)/marble.cfg -c "transport select jtag; init; xc7_program xc7.tap; pld load 0 $^; exit"

$(AUTOGEN_DIR)/config_romx.v: $(BUILD_DIR)/build_rom.py $(APP_NAME)_regmap.json
	$(PYTHON) $< -v $@ -j $(APP_NAME)_regmap.json

$(DEPDIR)/$(TARGET).d: $(AUTOGEN_DIR)/config_romx.v

$(APP_NAME)_regmap.json: $(AUTOGEN_DIR)/regmap_cryomodule.json $(OSCOPE_COMMON_DIR)/merge_json.py $(OSCOPE_COMMON_DIR)/shorten_names.py
	$(PYTHON) $(OSCOPE_COMMON_DIR)/merge_json.py -o $(APP_NAME)_regmap_long.json -i $(filter %.json, $^)
	$(PYTHON) $(OSCOPE_COMMON_DIR)/shorten_names.py -o $@ -i $(APP_NAME)_regmap_long.json

# actual file output is marble_features_(defs/params).vh
marble_features_defs.vh marble_features_params.vh: $(BUILD_DIR)/gen_features.py marble_features.yaml
	$(PYTHON) $< -i $(filter %.yaml, $^) -c $(HARDWARE) --split

include $(BUILD_DIR)/bottom_rules.mk

ifneq (,$(findstring bit,$(MAKECMDGOALS)))
    ifneq (,$(findstring bits,$(MAKECMDGOALS)))
include $(BITS_:%.bit=$(DEPDIR)/%.bit.d)
    else
include $(MAKECMDGOALS:%.bit=$(DEPDIR)/%.bit.d)
    endif
endif
