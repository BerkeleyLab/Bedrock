PART = xc7k160tffg676-2
FPGA_FAMILY = 7series

VFLAGS_DEP += -y. -I. -y$(DSP_DIR)
VFLAGS += -I. -y.

TEST_BENCH = jxj_gate_tb

jxj_gate_tb: $(DSP_DIR)/shortfifo.v

TGT_ := $(TEST_BENCH)

NO_CHECK =
CHK_ = $(filter-out $(NO_CHECK), $(TEST_BENCH:%_tb=%_check))
NO_LINT = $(NO_CHECK)
LNT_ = $(filter-out $(NO_LINT), $(TEST_BENCH:%_tb=%_lint))

.PHONY: targets checks bits check_all clean_all
targets: $(TGT_)
checks: $(CHK_)
check_all: $(CHK_)
lint: $(LNT_)

CLEAN += *_tb *.vcd *.out
CLEAN_DIR += _autogen
