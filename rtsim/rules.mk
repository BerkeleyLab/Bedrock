VFLAGS_DEP += -y. -I. -y$(DSP_DIR) -I$(DSP_DIR)
VFLAGS += -I. -y. -y$(DSP_DIR) -I$(DSP_DIR)

VVP_FLAGS += +trace

TEST_BENCH = beam_tb outer_prod_tb a_compress_tb resonator_tb

TGT_ := $(TEST_BENCH)

NO_CHECK =

#CHK_ = $(filter-out $(NO_CHECK), $(TEST_BENCH:%_tb=%_check))
CHK_ += a_comp_check resonator_check

BITS_ :=

PYTHON = python3

a_comp_check: a_compress.py a_compress.dat
	$(PYTHON) a_compress.py -c

resonator_check: resonator_tb resonator_check.m resonator.dat
	$(OCTAVE) resonator_check.m resonator.dat

CLEAN += $(TGT_) $(CHK_) *.bit *.in *.vcd *.dat

CLEAN_DIRS += _xilinx

.PHONY: targets checks bits check_all clean_all
targets: $(TGT_)
checks: $(CHK_)
check_all: $(CHK_)
bits: $(BITS_)
