VFLAGS_DEP += -y. -I.
VFLAGS += -I. -y. -y$(CORDIC_DIR) -I$(AUTOGEN_DIR)

TEST_BENCH = data_xdomain_tb upconv_tb half_filt_tb vectormul_tb tt800_tb rot_dds_tb mon_12_tb lp_tb lp_notch_tb

TGT_ := $(TEST_BENCH)

NO_CHECK = piloop2_check banyan_mem_check pplimit_check cavity_check ctrace_check lp_check
CHK_ = $(filter-out $(NO_CHECK), $(TEST_BENCH:%_tb=%_check))

BITS_ := bandpass3.bit
PYTHON = python3

.PHONY: targets checks bits check_all clean_all
targets: $(TGT_)
checks: $(CHK_)
check_all: $(CHK_)
bits: $(BITS_)

$(AUTOGEN_DIR)/cordicg_b22.v: $(CORDIC_DIR)/cordicgx.py
	mkdir -p $(AUTOGEN_DIR) && $(PYTHON) $< 22 > $@

rot_dds_auto: $(AUTOGEN_DIR)/cordicg_b22.v

mon_12_auto: $(AUTOGEN_DIR)/cordicg_b22.v

VFLAGS_rx_buffer_tb = -DTARGET_s3

bandpass3.dat: bandpass3_tb cset3.m
	$(VVP) $< `$(OCTAVE) -q cset3.m` > $@

bandpass3_check: bpp3.m bandpass3.dat
	$(OCTAVE) -q $(notdir $<)

bandpass3.bit: bandpass3.v
	$(SYNTH) bandpass3 $^
	mv _xilinx/bandpass3.bit $@

timestamp.bit: timestamp.v reg_delay.v
	$(SYNTH) timestamp $^
	mv _xilinx/timestamp.bit $@

half_filt_check: half_filt.py half_filt.dat
	$(PYTHON) half_filt.py -c

lp_notch_check: lp_notch_test.py lp_tb lp_notch_tb
	$(PYTHON) $<

# scattershot approach
# limited to den>=12
mon_12_check: mon_12_tb $(BUILD_DIR)/testcode.awk
	$(VVP) $< +amp=20000 +den=16  +phs=3.14 | $(AWK) -f $(filter %.awk, $^)
	$(VVP) $< +amp=32763 +den=128 +phs=-0.2 | $(AWK) -f $(filter %.awk, $^)
	$(VVP) $< +amp=99999 +den=28  +phs=1.57 | $(AWK) -f $(filter %.awk, $^)
	$(VVP) $< +amp=200   +den=12  +phs=0.70 | $(AWK) -f $(filter %.awk, $^)

banyan_crosscheck: banyan_tb banyan_ch_find.py
	$(VVP) banyan_tb +trace +squelch | $(PYTHON) banyan_ch_find.py

tt800_ref.dat: tt800_ref
	./tt800_ref > $@

tt800_check: tt800_tb tt800.dat tt800_ref.dat
	cmp tt800.dat tt800_ref.dat

ctrace_test1.out: ctrace_tb
	$(VVP) $< +dfile=$@

# maybe generally useful, here used for testing ctrace
%.vcd: %.out
	$(PYTHON) c2vcd.py $< > $@


CLEAN += $(TGT_) $(CHK_) *.bit *.in *.vcd bandpass3.dat half_filt.dat piloop2.dat pdetect.dat tt800_ref tt800.dat tt800_ref.dat tt800_ref.d ctrace_test1.out lp_out.dat notch_test.dat
CLEAN_DIRS += _xilinx

ifneq (,$(findstring bit,$(MAKECMDGOALS)))
    ifneq (,$(findstring bits,$(MAKECMDGOALS)))
	-include $(BITS_:%.bit=$(DEPDIR)/%.bit.d)
    else
	-include $(MAKECMDGOALS:%.bit=$(DEPDIR)/%.bit.d)
    endif
endif
ifneq (,$(findstring _tb,$(MAKECMDGOALS)))
    -include $(MAKECMDGOALS:%_tb=$(DEPDIR)/%_tb.d)
endif
ifneq (,$(findstring _view,$(MAKECMDGOALS)))
    -include $(MAKECMDGOALS:%_tb=$(DEPDIR)/%_tb.d)
endif
ifneq (,$(findstring _check,$(MAKECMDGOALS)))
    -include $(MAKECMDGOALS:%_tb=$(DEPDIR)/%_tb.d)
endif
ifeq (,$(MAKECMDGOALS))
    -include $(TEST_BENCH:%_tb=$(DEPDIR)/%_tb.d)
endif
