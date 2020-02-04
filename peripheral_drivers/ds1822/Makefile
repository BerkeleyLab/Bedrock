include ../../dir_list.mk

# Override the more complex newad-supporting rule in $(BUILD_DIR)/top_rules.mk
%_tb: %_tb.v
	$(VERILOG) $(VFLAGS_$@) -o $@ $(filter %.v, $^)

# Override the testcode.awk-based rule in $(BUILD_DIR)/top_rules.mk
%_check: %_tb
	$(VVP) $< $(VCD_ARGS_$@)

include $(BUILD_DIR)/top_rules.mk

all: ds1822_check

ds1822_tb: ds1822_driver.v ds1822.v ds1822_state.v

CLEAN += ds1822_tb

include $(BUILD_DIR)/bottom_rules.mk
