include ../dir_list.mk

# This override goes _before_ top_rules.mk, to simplify builds in a
# directory like this that does not use newad.
%_tb: %_tb.v
	$(VERILOG) $(VG_ALL) $(V_TB) $(VFLAGS) -o $@ $(filter %v, $^)

include $(BUILD_DIR)/top_rules.mk

VFLAGS = -I. -y. -y$(DSP_DIR)

vpath %.v $(DSP_DIR)

TGT_ := ctrace_tb
CHK_ = $(TGT_:%_tb=%_check)

.PHONY: checks
targets: $(TGT_)
checks: $(CHK_)

CLEAN += $(TGT_)

include $(BUILD_DIR)/bottom_rules.mk
