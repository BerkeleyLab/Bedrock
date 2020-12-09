TOP_DIR = ../../..
include $(TOP_DIR)/dir_list.mk
.PHONY: all
all: $(TARGET)

HARDWARE = marblemini
DSP_FLAVOR = 7
XILINX_TOOL := VIVADO

APP_NAME = cmoc

APP_DIR = $(TOP_DIR)/cmoc
DSP_DIR = $(TOP_DIR)/dsp
OSCOPE_COMMON_DIR = $(TOP_DIR)/projects/oscope/common
BS_HARDWARE_DIR = $(BOARD_SUPPORT_DIR)/$(HARDWARE)

vpath %.v $(APP_DIR) $(RTSIM_DIR) $(DSP_DIR) $(BADGER_DIR)

CLEAN_DIRS += ./.Xil

include $(BUILD_DIR)/top_rules.mk
include $(BS_HARDWARE_DIR)/rules.mk
include $(APP_DIR)/rules.mk

SYNTH_OPT += $(VERILOG_DEFINE_FLAGS)

VFLAGS_DEP += -y$(BS_HARDWARE_DIR) -y$(BOARD_SUPPORT_DIR)/marblemini -y$(FPGA_FAMILY_DIR) -y$(FPGA_FAMILY_DIR) -y$(FPGA_FAMILY_DIR)/xilinx -y$(FPGA_FAMILY_DIR)/pll -y. -y$(APP_DIR) -y$(HOMELESS_DIR) -y$(HOMELESS_DIR)/freq_demo -y$(BADGER_DIR) -y$(BADGER_DIR)/tests -y$(BADGER_DIR)/tests/kc705 -y$(SERIAL_IO_DIR) -y../../test_marble_family/ -y$(PERIPH_DRIVERS_DIR) -y$(PERIPH_DRIVERS_DIR)/i2cbridge -y../bmb7_cu

VFLAGS += $(VERILOG_DEFINE_FLAGS)

system_top.xdc: $(BOARD_SUPPORT_DIR)/$(HARDWARE)/Marble.xdc $(BOARD_SUPPORT_DIR)/$(HARDWARE)/pin_map.csv digilent_led_pmod.csv oscope_rules.csv
	echo "Building for $(HARDWARE); Use make HARDWARE=marble otherwise"
	$(PYTHON) $(BADGER_DIR)/tests/meta-xdc.py $^ > $@

CLEAN += $(TARGET) $(AUTOGEN_DIR)/config_romx.v *~ system_top.xdc cmoc_top.bin cmoc_top.prm cmoc_top.bit $(APP_NAME)_regmap_long.json $(APP_NAME)_regmap.json $(RTEFI_CLEAN)
CLEAN_DIRS += _xilinx

cmoc_top.bit: $(AUTOGEN_DIR)/config_romx.v
cmoc_top.v: $(AUTOGEN_DIR)/config_romx.v rtefi_blob.v construct_tx_table.v cryomodule_auto

download: cmoc_top.bit
	openocd -f $(BOARD_SUPPORT_DIR)/$(HARDWARE)/marble.cfg -c "transport select jtag; init; xc7_program xc7.tap; pld load 0 $^; exit"

$(AUTOGEN_DIR)/config_romx.v: $(BUILD_DIR)/build_rom.py $(APP_NAME)_regmap.json
	$(PYTHON) $< -v $@ -j $(APP_NAME)_regmap.json

$(DEPDIR)/$(TARGET).d: $(AUTOGEN_DIR)/config_romx.v

$(APP_NAME)_regmap.json: $(AUTOGEN_DIR)/regmap_cryomodule.json $(OSCOPE_COMMON_DIR)/merge_json.py $(OSCOPE_COMMON_DIR)/shorten_names.py
	$(PYTHON) $(OSCOPE_COMMON_DIR)/merge_json.py -o $(APP_NAME)_regmap_long.json -i $(filter %.json, $^)
	$(PYTHON) $(OSCOPE_COMMON_DIR)/shorten_names.py -o $@ -i $(APP_NAME)_regmap_long.json

include $(BUILD_DIR)/bottom_rules.mk

ifneq (,$(findstring bit,$(MAKECMDGOALS)))
    ifneq (,$(findstring bits,$(MAKECMDGOALS)))
include $(BITS_:%.bit=$(DEPDIR)/%.bit.d)
    else
include $(MAKECMDGOALS:%.bit=$(DEPDIR)/%.bit.d)
    endif
endif
