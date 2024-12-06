include $(CORDIC_DIR)/rules.mk

# Interaction between newad and auto-dependency generation is confusing.
# . and $(DSP_DIR) are different when building out-of-tree
VFLAGS_DEP += -I. -y . -y$(DSP_DIR) -y$(CORDIC_DIR)
VFLAGS += -I. -y . -y$(DSP_DIR) -y$(CORDIC_DIR) -I$(AUTOGEN_DIR)

TEST_BENCH = data_xdomain_tb upconv_tb half_filt_tb complex_mul_tb tt800_tb rot_dds_tb mon_12_tb xy_pi_clip_tb iq_chain4_tb cordic_mux_tb timestamp_tb afterburner_tb ssb_out_tb banyan_tb banyan_mem_tb biquad_tb iirFilter_tb circle_buf_tb cic_multichannel_tb cic_wave_recorder_tb circle_buf_serial_tb iq_deinterleaver_tb serializer_multichannel_tb complex_freq_tb iq_trace_tb second_if_out_tb cpxmul_fullspeed_tb dpram_tb host_averager_tb cic_simple_us_tb phase_diff_tb phaset_tb complex_mul_flat_tb fwashout_tb lpass1_tb slew_xarray_tb isqrt_tb freq_count_tb

TGT_ := $(TEST_BENCH)

NO_CHECK = piloop2_check cavity_check banyan_mem_check
CHK_ = $(filter-out $(NO_CHECK), $(TEST_BENCH:%_tb=%_check))
CHK_ += multiply_accumulate_pycheck
NO_LINT = $(NO_CHECK) mon_12_lint biquad_lint
LNT_ = $(filter-out $(NO_LINT), $(TEST_BENCH:%_tb=%_lint))

BITS_ := bandpass3.bit

VERILOG_AUTOGEN += " "

.PHONY: targets checks bits check_all clean_all
targets: $(TGT_)
checks: $(CHK_)
check_all: $(CHK_)
lint: $(LNT_)
bits: $(BITS_)

%_pycheck: %_tb tb_pycheck.py
	$(VVP) $< +trace
	$(PYTHON) $(word 2, $^) -f $*

rot_dds_tb: cordicg_b22.v ph_acc.v

mon_12_tb: cordicg_b22.v

ssb_out_tb: cordicg_b22.v

cordic_mux_tb: cordicg_b22.v

VFLAGS_rx_buffer_tb = -DTARGET_s3

timestamp.bit: timestamp.v reg_delay.v
	$(SYNTH) timestamp $^
	mv _xilinx/timestamp.bit $@

half_filt_check: half_filt.py half_filt.dat
	$(PYTHON) $< -c

iq_modulator.dat: iq_modulator_tb
	$(VVP) $< +trace

# scattershot approach
# limited to den>=12
mon_12_check: mon_12_tb
	$(VVP) $< +amp=20000 +den=16  +phs=3.14
	$(VVP) $< +amp=32763 +den=128 +phs=-0.2
	$(VVP) $< +amp=99999 +den=28  +phs=1.57
	$(VVP) $< +amp=200   +den=12  +phs=0.70

tt800_ref.dat: tt800_ref
	./tt800_ref > $@

tt800_check: tt800_tb tt800.dat tt800_ref.dat
	cmp tt800.dat tt800_ref.dat

biquad_tb: saturateMath.v
iirFilter_tb: saturateMath.v

banyan_check: banyan_tb banyan_ch_find.py
	$(VERILOG_CHECK)
	$(VVP) banyan_tb +trace +squelch | $(PYTHON) $(filter %banyan_ch_find.py, $^)

include $(DSP_DIR)/lo_lut/rules.mk

# SSB Drivers
SSB_TEST_PY = ssb_drive_test.py

second_if_out_tb: cordicg_b22.v lo_lut_f40.v lo_lut_f40_05.v

second_if_out_check: second_if_out_tb $(SSB_TEST_PY)
	$(VVP) $< +trace +if_lo=0 && $(PYTHON) $(word 2, $^) second_if_out.dat 145
	$(VVP) $< +trace +if_lo=1 && $(PYTHON) $(word 2, $^) second_if_out.dat 60

ssb_out_check: ssb_out_tb $(SSB_TEST_PY)
	$(VVP) $< +trace && $(PYTHON) $(word 2, $^) ssb_out.dat SSB_OUT
	$(VVP) $< +trace +single && $(PYTHON) $(word 2, $^) ssb_out.dat SSB_OUT SINGLE

# 1st order low/high pass filters
FTEST_PY = filter_test.py
fwashout_check: $(FTEST_PY) fwashout_tb
	$(PYTHON) $^
lpass1_check: $(FTEST_PY) lpass1_tb
	$(PYTHON) $^

CLEAN += $(TGT_) $(CHK_) *_tb *.pyc *.bit *.in *.vcd *.lxt *~
CLEAN += half_filt.dat pdetect.dat tt800_ref tt800.dat tt800_ref.dat tt800_ref.d
CLEAN += cordicg_b22.v second_if_out.dat ssb_*.dat multiply_accumulate.out
CLEAN += fwashout.dat lpass1.dat iq_modulator.dat

CLEAN_DIRS += tt800_ref.dSYM
CLEAN_DIRS += _xilinx __pycache__

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
