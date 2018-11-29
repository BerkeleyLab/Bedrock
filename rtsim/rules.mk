VFLAGS_DEP += -y. -I. -y$(DSP_DIR) -I$(DSP_DIR) -y$(CORDIC_DIR)
VFLAGS += -I. -y. -y$(DSP_DIR) -I$(DSP_DIR) -y$(CORDIC_DIR) -I$(AUTOGEN_DIR)

VVP_FLAGS += +trace

TEST_BENCH = beam_tb outer_prod_tb resonator_tb a_compress_tb cav4_mode_tb

TGT_ := $(TEST_BENCH)

NO_CHECK =

#CHK_ = $(filter-out $(NO_CHECK), $(TEST_BENCH:%_tb=%_check))
CHK_ += a_comp_check resonator_check cav4_mode_check

BITS_ :=

PYTHON = python3

VFLAGS_cav4_mode_tb += -DLB_DECODE_cav4_mode

cordicg_b22.v: $(CORDIC_DIR)/cordicgx.py
	$(PYTHON) $< 22 > cordicg_b22.v

cav4_mode_tb: cordicg_b22.v

a_comp_check: a_compress.py a_compress.dat
	$(PYTHON) a_compress.py -c

resonator_check: resonator_tb resonator_check.m resonator.dat
	$(OCTAVE) resonator_check.m resonator.dat

cav4_mode_check: cav4_check1.m cav4_mode.dat
	$(OCTAVE) $<

CLEAN += $(TGT_) $(CHK_) *.bit *.in *.vcd *.dat cordicg_b22.v

CLEAN_DIRS += _xilinx

.PHONY: targets checks bits check_all clean_all
targets: $(TGT_)
checks: $(CHK_)
check_all: $(CHK_)
bits: $(BITS_)
