BUILD_DIR = ../../build-tools
CORDIC_DIR = ../../cordic
DSP_DIR = ../../dsp

include $(BUILD_DIR)/top_rules.mk
include $(BUILD_DIR)/newad_top_rules.mk
include $(CORDIC_DIR)/rules.mk
TEST_BENCH  = duc_tb zest_dac_interp_tb
CHECKS      = duc_check

vpath %.v $(DSP_DIR)
VFLAGS_DEP += -y$(DSP_DIR) -y$(CORDIC_DIR) -y.
VFLAGS += $(VFLAGS_DEP)

.PHONY: all clean
all: $(TEST_BENCH) $(CHECKS)

# validate and demonstrate duc.v, that's similar to bedrock's second_if_out.v
duc.dat: duc_tb
	$(VVP) $< +trace
duc_check: duc_test.py duc.dat
	$(PYTHON) $^

CLEAN += $(TEST_BENCH)
CLEAN += $(TEST_BENCH:%_tb=%.vcd)
CLEAN += *.dat

include $(BUILD_DIR)/bottom_rules.mk
