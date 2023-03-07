%_tb: %_tb.v %_tb_auto
	$(VERILOG_TB)
 
%_tb_auto: $(AUTOGEN_DIR)/addr_map_%_tb.vh $(AUTOGEN_DIR)/%_tb_auto.vh %_auto
	@echo "."

%_auto: $(AUTOGEN_DIR)/addr_map_%.vh $(AUTOGEN_DIR)/%_auto.vh
	@echo "."

NEWAD_DIRS = .
NEWAD_ARGS = -d $(subst $(SPACE),$(COMMA),$(NEWAD_DIRS)) -i $< -w $(LB_AW)

define NEWAD_O
mkdir -p $(AUTOGEN_DIR); $(PYTHON) $(BUILD_DIR)/newad.py -o $@ $(NEWAD_ARGS) $(NEWAD_ARGS_$*)
endef
define NEWAD_A
mkdir -p $(AUTOGEN_DIR); $(PYTHON) $(BUILD_DIR)/newad.py -a $@ $(NEWAD_ARGS) $(NEWAD_ARGS_$*)
endef
define NEWAD_L
mkdir -p $(AUTOGEN_DIR); $(PYTHON) $(BUILD_DIR)/newad.py -l -r $@ $(NEWAD_ARGS) $(NEWAD_ARGS_$*)
endef
define REV_JSON
$(PYTHON) $(BUILD_DIR)/reverse_json.py $< > $@
endef

$(AUTOGEN_DIR)/%_auto.vh: %.sv
	$(NEWAD_O)
$(AUTOGEN_DIR)/%_auto.vh: %.v
	$(NEWAD_O)

$(AUTOGEN_DIR)/addr_map_%.vh: %.sv
	$(NEWAD_A)
$(AUTOGEN_DIR)/addr_map_%.vh: %.v
	$(NEWAD_A)

$(AUTOGEN_DIR)/regmap_%.json: %.sv
	$(NEWAD_L)
$(AUTOGEN_DIR)/regmap_%.json: %.v
	$(NEWAD_L)

$(AUTOGEN_DIR)/scalar_%_regmap.json: %.sv
	$(REV_JSON)
$(AUTOGEN_DIR)/scalar_%_regmap.json: %.v
	$(REV_JSON)
