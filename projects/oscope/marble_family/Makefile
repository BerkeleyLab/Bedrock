HARDWARE = marble
DSP_FLAVOR = 7
COMMUNICATION = gtx
DAUGHTER = base
XILINX_TOOL := VIVADO


include ../../../dir_list.mk
OSCOPE_COMMON_DIR = ../common
MARBLE_FAMILY_DIR = ../../test_marble_family

APP_NAME = oscope

vpath %.v $(DSP_DIR)

include $(BUILD_DIR)/newad_top_rules.mk
include $(OSCOPE_COMMON_DIR)/rules.mk


VFLAGS_DEP += -y$(DSP_DIR) -y$(BOARD_SUPPORT_DIR)/marblemini -y$(BOARD_SUPPORT_DIR)/zest -y$(FPGA_FAMILY_DIR) -y$(FPGA_FAMILY_DIR)/xilinx -y$(FPGA_FAMILY_DIR)/iserdes -y$(SERIAL_IO_DIR) -y. -y$(PERIPH_DRIVERS_DIR) -y$(PERIPH_DRIVERS_DIR)/idelay_scanner -y$(OSCOPE_COMMON_DIR) -y$(HOMELESS_DIR) -y$(BADGER_DIR) -y$(BADGER_DIR)/tests -y$(BADGER_DIR)/tests/kc705 -y$(MARBLE_FAMILY_DIR) -y$(MARBLE_FAMILY_DIR)/pps_lock -y$(PERIPH_DRIVERS_DIR)/i2cbridge -y$(HOMELESS_DIR)/freq_demo -DSIMULATE

LB_AW = 23
NEWAD_DIRS += $(OSCOPE_COMMON_DIR)
NEWAD_ARGS += -b8388608 -y
RTEFI_CLIENT_LIST = hello.v speed_test.v mem_gateway.v spi_flash.v
RTEFI_EXTRA_V = spi_flash_engine.v
include $(BADGER_DIR)/rules.mk

$(AUTOGEN_DIR)/moving_average.v: $(DSP_DIR)/moving_average/moving_average.py
	$(PYTHON) $(DSP_DIR)/moving_average/moving_average.py | grep -v '(* top' > $@

oscope_features: $(BUILD_DIR)/gen_features.py oscope_features.yaml
	$(PYTHON) $< -i $(filter %.yaml, $^) -c marble_v2 --split

# gen_features.py rules; note the use of dummy targets, actual file outputs are:
# oscope_features_params.vh and oscope_features_defs.vh
oscope_marble1_features: $(BUILD_DIR)/gen_features.py oscope_features.yaml
	$(PYTHON) $< -i $(filter %.yaml, $^) -c marble_mini --split
	touch $@

oscope_marble2_features: $(BUILD_DIR)/gen_features.py oscope_features.yaml
	$(PYTHON) $< -i $(filter %.yaml, $^) -c marble_v2 --split
	touch $@

zest_connector.csv: remap_gen.py
	$(PYTHON) remap_gen.py -p $(BEDROCK_DIR) > $@

system_top.xdc: $(BOARD_SUPPORT_DIR)/$(HARDWARE)/Marble.xdc $(BOARD_SUPPORT_DIR)/$(HARDWARE)/pin_map.csv zest_connector.csv oscope_rules.csv
	$(PYTHON) $(BADGER_DIR)/tests/meta-xdc.py $^ > $@

oscope_top.sv: $(AUTOGEN_DIR)/config_romx.v $(RTEFI_V) $(AUTOGEN_DIR)/application_top_auto.vh $(AUTOGEN_DIR)/addr_map_application_top.vh $(AUTOGEN_DIR)/moving_average.v oscope_marble2_features

oscope_top.bit: $(AUTOGEN_DIR)/config_romx.v

# =====
# Process code base with sv2v, verilator, yosys, and cdc_snitch
# Experimental and still somewhat messy
# Exposes weaknessess in our tools' handling of inout ports; see
#   https://github.com/zachjs/sv2v/issues/295
#   https://github.com/YosysHQ/yosys/issues/4708
#   https://github.com/verilator/verilator/issues/2844
UPPER_SV = oscope_top.sv $(OSCOPE_COMMON_DIR)/application_top.sv $(BOARD_SUPPORT_DIR)/zest/zest_cfg_if.sv $(BOARD_SUPPORT_DIR)/zest/zest_if.sv $(BOARD_SUPPORT_DIR)/zest/zest_wrap.sv $(OSCOPE_COMMON_DIR)/digitizer_config.sv
oscope_prep.v: $(AUTOGEN_DIR)/application_top_auto.vh $(AUTOGEN_DIR)/addr_map_application_top.vh oscope_marble2_features
	$(SV2V) -DSIMULATE -DVERILATOR -I $(AUTOGEN_DIR) $(UPPER_SV) > $@
	wc -l $@
oscope_pure_v.d: oscope_prep.v $(AUTOGEN_DIR)/config_romx.v $(RTEFI_V) $(AUTOGEN_DIR)/moving_average.v
	$(VERILOG) -Wno-timescale -o /dev/null $< -y$(AUTOGEN_DIR) $(VFLAGS_DEP) -M$@.$$$$ && sort -u < $@.$$$$ | tr '\n' ' ' | sed -e 's/^/oscope_pure_v_check oscope_prep_yosys.json: /' -e 's/ $$//' > $@ && rm $@.$$$$
# make this dependency file first, explicitly, if you are doing sv2v/cdc_snitch work
dep: oscope_pure_v.d
-include oscope_pure_v.d
.PHONY: oscope_pure_v_check dep
# dependencies from oscope_pure_v.d
# sv2v tends to make a lot of VARHIDDEN
# I don't like the 33 x UNDRIVEN
VLATOR_LINT_IGNORE += -Wno-UNUSED -Wno-VARHIDDEN -Wno-DECLFILENAME -Wno-CASEINCOMPLETE
VLATORFLAGS += -DSIMULATE
oscope_pure_v_check:
	$(VERILATOR_LINT)
# exercise with make dep && make oscope_pure_v_check
# or make dep && make oscope_prep_lint
# same result, but different dependency list management
#
YOSYS_JSON_OPTION += -DSIMULATE
# most dependencies from oscope_pure_v.d
oscope_prep_yosys.json: $(FPGA_FAMILY_DIR)/xilinx/IBUFGDS.v
# exercise with make dep && make oscope_prep_cdc.txt
# =====

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
	openocd -f $(MARBLE_FAMILY_DIR)/marble.cfg -c "transport select jtag; init; xc7_program xc7.tap; pld load 0 oscope_top.bit; exit"


include $(BUILD_DIR)/bottom_rules.mk
CLEAN += *.bit *.bin *.prm $(APP_NAME)_regmap*.json scalar_$(APP_NAME)_regmap.json *_features*.json *_features*.vh oscope_marble*_features
CLEAN += system_top.xdc zest_connector.csv $(RTEFI_CLEAN) foo.gtkw foo.vcd
CLEAN += oscope_prep.v oscope_prep_yosys.json oscope_prep_cdc.txt oscope_pure_v.d
CLEAN_DIRS +=  _xilinx .Xil

ifneq (,$(findstring bit,$(MAKECMDGOALS)))
    ifneq (,$(findstring bits,$(MAKECMDGOALS)))
-include $(BITS_:%.bit=$(DEPDIR)/%.bit.d)
    else
-include $(MAKECMDGOALS:%.bit=$(DEPDIR)/%.bit.d)
    endif
endif
