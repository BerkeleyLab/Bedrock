HARDWARE = marble
DSP_FLAVOR = 7
COMMUNICATION = gtx
DAUGHTER = base
XILINX_TOOL := VIVADO


include ../../../dir_list.mk
OSCOPE_COMMON_DIR=../common

APP_NAME = oscope

vpath %.v $(DSP_DIR)

include $(BUILD_DIR)/top_rules.mk
include $(OSCOPE_COMMON_DIR)/rules.mk


VFLAGS_DEP += -y$(DSP_DIR) -y$(BOARD_SUPPORT_DIR)/marblemini -y$(BOARD_SUPPORT_DIR)/zest -y$(FPGA_FAMILY_DIR) -y$(FPGA_FAMILY_DIR)/xilinx -y$(FPGA_FAMILY_DIR)/iserdes -y$(ISERDES_DIR) -y$(XILINX_DIR) -y$(SERIAL_IO_DIR) -y. -y$(PERIPH_DRIVERS_DIR) -y$(PERIPH_DRIVERS_DIR)/idelay_scanner -y$(OSCOPE_COMMON_DIR) -y$(HOMELESS_DIR) -y$(BADGER_DIR) -y$(BADGER_DIR)/tests -y$(BADGER_DIR)/tests/kc705 -y../../test_marble_family/ -y$(PERIPH_DRIVERS_DIR)/i2cbridge -y$(HOMELESS_DIR)/freq_demo -DSIMULATE

LB_AW = 23
NEWAD_DIRS += $(OSCOPE_COMMON_DIR)
NEWAD_ARGS += -b8388608
RTEFI_CLIENT_LIST = hello.v speed_test.v mem_gateway.v spi_flash.v
RTEFI_EXTRA_V = spi_flash_engine.v
VLATOR_LINT_IGNORE += -Wno-TIMESCALEMOD
include $(BADGER_DIR)/rules.mk

$(AUTOGEN_DIR)/moving_average.v: $(DSP_DIR)/moving_average/moving_average.py
	$(PYTHON) $(DSP_DIR)/moving_average/moving_average.py > $(AUTOGEN_DIR)/moving_average.v

zest_connector.csv: remap_gen.py
	$(PYTHON) remap_gen.py -p $(BEDROCK_DIR) > $@

# TODO: Remove the relative path digilent pmod dependency
system_top.xdc: $(BOARD_SUPPORT_DIR)/$(HARDWARE)/Marble.xdc $(BOARD_SUPPORT_DIR)/$(HARDWARE)/pin_map.csv digilent_led_pmod.csv zest_connector.csv oscope_rules.csv
	$(PYTHON) $(BADGER_DIR)/tests/meta-xdc.py $^ > $@

oscope_top.bit: $(AUTOGEN_DIR)/config_romx.v
oscope_top.sv: $(AUTOGEN_DIR)/config_romx.v $(RTEFI_V) application_top_auto $(AUTOGEN_DIR)/moving_average.v

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

download:
	openocd -f ../../test_marble_family/marble.cfg -c "transport select jtag; init; xc7_program xc7.tap; pld load 0 oscope_top.bit; exit"

include $(BUILD_DIR)/bottom_rules.mk
CLEAN += *.bit *.bin *.prm $(APP_NAME)_regmap*.json scalar_$(APP_NAME)_regmap.json
CLEAN += top.xdc zest_connector.csv $(RTEFI_CLEAN)
CLEAN_DIRS +=  _xilinx .Xil

ifneq (,$(findstring bit,$(MAKECMDGOALS)))
    ifneq (,$(findstring bits,$(MAKECMDGOALS)))
-include $(BITS_:%.bit=$(DEPDIR)/%.bit.d)
    else
-include $(MAKECMDGOALS:%.bit=$(DEPDIR)/%.bit.d)
    endif
endif
