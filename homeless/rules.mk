VFLAGS_DEP += -I. -y . -y$(DSP_DIR)
VFLAGS += -I. -y . -y$(DSP_DIR)

TEST_BENCH = activity_tb ctrace_tb fake_dpram_tb multi_counter_tb

TGT_ := $(TEST_BENCH)
CHK_ =  multi_counter_check

targets: $(TGT_)
checks: $(CHK_)

CLEAN += $(TGT_)
