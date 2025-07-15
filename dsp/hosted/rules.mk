include $(CORDIC_DIR)/rules.mk

# Interaction between newad and auto-dependency generation is confusing.
# . and $(DSP_DIR) are different when building out-of-tree
VFLAGS_DEP += -I. -y . -y$(DSP_DIR) -y$(CORDIC_DIR)
VFLAGS += -I. -y . -y$(DSP_DIR) -y$(CORDIC_DIR) -I$(AUTOGEN_DIR)

TEST_BENCH = lp_tb lp_2notch_tb lp_notch_tb phs_avg_tb mp_proc_tb etrig_bridge_tb fdbk_core_tb

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

_dep/fdbk_core_tb.d: fdbk_core_tb_auto
fdbk_core_tb: cordicg_b22.v

# No magic to generate fdbk_core.vcd, because running fdbk_core_tb
# depends on in_file.  A plethora of such files are created by fdbk_core_test.py,
# which then runs fdbk_core_tb for each case.
# fdbk_core.vcd: $(AUTOGEN_DIR)/regmap_fdbk_core_tb.json

.PRECIOUS: fdbk_core_plot.pdf
fdbk_core_plot.pdf: fdbk_core_tb fdbk_core_test.py $(AUTOGEN_DIR)/regmap_fdbk_core_tb.json
	$(PYTHON) fdbk_core_test.py $@
fdbk_core_check: fdbk_core_plot.pdf
	@echo DONE

CLEAN += $(TGT_) $(CHK_) *_tb *.pyc *.bit *.in *.vcd
CLEAN += lp_out.dat notch_test.dat non_iq_interleaved_piloop.out
CLEAN += fdbk_core_plot.pdf fdbk_core*.dat cordicg_b*.v lim_step_file_in.dat setmp_step_file_in.dat
