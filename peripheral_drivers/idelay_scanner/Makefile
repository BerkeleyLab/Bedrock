include ../../dir_list.mk

# Override the more complex newad-supporting rule in $(BUILD_DIR)/top_rules.mk
%_tb: %_tb.v
	$(VERILOG) $(V_TB) $(VFLAGS_$@) -o $@ $(filter %.v, $^)

# Override the testcode.awk-based rule in $(BUILD_DIR)/top_rules.mk
%_check: %_tb
	$(VVP) $< $(VCD_ARGS_$@)

include $(BUILD_DIR)/top_rules.mk

all: idelay_scanner_check scanner_shell_tb

idelay_scanner_tb: idelay_scanner.v $(DSP_DIR)/dpram.v decider.v

scanner_shell_tb: scanner_shell.v idelay_scanner.v $(DSP_DIR)/dpram.v decider.v $(DSP_DIR)/tt800.v $(DSP_DIR)/reg_delay.v

CLEAN += idelay_scanner_tb scanner_shell_tb

include $(BUILD_DIR)/bottom_rules.mk
