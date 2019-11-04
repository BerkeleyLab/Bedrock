include ../../dir_list.mk

# =====
# These overrides go _before_ top_rules.mk
%_check: %_tb
	$(VVP) $< $(VCD_ARGS_$@)
%_tb: %_tb.v
	$(VERILOG) $(VFLAGS_$@) -o $@ $(filter %.v, $^)

include $(BUILD_DIR)/top_rules.mk

all: ds1822_check

ds1822_tb: ds1822_driver.v ds1822.v ds1822_state.v

CLEAN += ds1822_tb

include $(BUILD_DIR)/bottom_rules.mk

