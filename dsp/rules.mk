VFLAGS_DEP += -y. -I. -y$(DSP_DIR) -y$(CORDIC_DIR)
VFLAGS += -I. -y. -y$(CORDIC_DIR) -I$(AUTOGEN_DIR)

TEST_BENCH = data_xdomain_tb upconv_tb half_filt_tb vectormul_tb tt800_tb rot_dds_tb mon_12_tb lp_tb lp_notch_tb xy_pi_clip_tb mp_proc_tb iq_chain4_tb cordic_mux_tb timestamp_tb afterburner_tb ssb_out_tb

TGT_ := $(TEST_BENCH)

NO_CHECK = piloop2_check cavity_check lp_check
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

ssb_out_auto: $(AUTOGEN_DIR)/cordicg_b22.v

cordic_mux_auto: $(AUTOGEN_DIR)/cordicg_b22.v

fdbk_core_auto: $(AUTOGEN_DIR)/cordicg_b22.v

rf_controller_auto: lp_notch_auto fdbk_core_auto piezo_control_auto

fdbk_core.vcd: $(AUTOGEN_DIR)/regmap_fdbk_core_tb.json
fdbk_core.vcd: fdbk_core_tb fdbk_core_test.py
	$(PYTHON) fdbk_core_test.py
fdbk_core_check: fdbk_core.vcd
	echo DONE

VFLAGS_rx_buffer_tb = -DTARGET_s3

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

tt800_ref.dat: tt800_ref
	./tt800_ref > $@

tt800_check: tt800_tb tt800.dat tt800_ref.dat
	cmp tt800.dat tt800_ref.dat

CLEAN += $(TGT_) $(CHK_) *.bit *.in *.vcd half_filt.dat pdetect.dat tt800_ref tt800.dat tt800_ref.dat tt800_ref.d lp_out.dat notch_test.dat
CLEAN += fdbk_core*.dat lim_step_file_in.dat setmp_step_file_in.dat

CLEAN_DIRS += tt800_ref.dSYM
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
