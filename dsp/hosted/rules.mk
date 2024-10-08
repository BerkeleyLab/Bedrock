
# Interaction between newad and auto-dependency generation is confusing.
# . and $(DSP_DIR) are different when building out-of-tree
VFLAGS_DEP += -I. -y . -y$(DSP_DIR) -y$(CORDIC_DIR)
VFLAGS += -I. -y . -y$(DSP_DIR) -y$(CORDIC_DIR) -I$(AUTOGEN_DIR)

TEST_BENCH = lp_tb lp_2notch_tb lp_notch_tb phs_avg_tb mp_proc_tb etrig_bridge_tb

TGT_ := $(TEST_BENCH)

NO_CHECK = lp_check
CHK_ += non_iq_interleaved_piloop_pycheck lp_notch_check lp_2notch_check

.PHONY: targets checks bits check_all clean_all
targets: $(TGT_)
checks: $(CHK_)
check_all: $(CHK_)
lint: $(LNT_)
bits: $(BITS_)

%_pycheck: %_tb tb_pycheck.py
	$(VVP) $< +trace
	$(PYTHON) $(word 2, $^) -f $*

lp_notch_check: lp_notch_test.py lp_tb lp_notch_tb
	$(PYTHON) $<

lp_2notch_check: lp_2notch_test.py lp_tb lp_2notch_tb
	$(PYTHON) $<

CLEAN += $(TGT_) $(CHK_) *_tb *.pyc *.bit *.in *.vcd
CLEAN += lp_out.dat notch_test.dat non_iq_interleaved_piloop.out
