VFLAGS_DEP += -y. -I. -y$(DSP_DIR) -I$(DSP_DIR) -y$(CORDIC_DIR)
VFLAGS += -I. -y. -y$(DSP_DIR) -I$(DSP_DIR) -y$(CORDIC_DIR) -I$(AUTOGEN_DIR)

VVP_FLAGS += +trace

TEST_BENCH = beam_tb outer_prod_tb resonator_tb a_compress_tb cav_mode_tb

TGT_ := $(TEST_BENCH)

NO_CHECK =

#CHK_ = $(filter-out $(NO_CHECK), $(TEST_BENCH:%_tb=%_check))
CHK_ += a_comp_check resonator_check cav_mode_check

BITS_ :=

VFLAGS_cav_mode_tb += -DLB_DECODE_cav_mode

PART=xc6slx45t-fgg484-3

%.bit: %.v $(DEPDIR)/%.bit.d blank_s6.ucf
	CLOCK_PIN=$(CLOCK_PIN) PART=$(PART) $(ISE_SYNTH) $* $(SYNTH_OPT) $^ && mv _xilinx/$@ $@

cordicg_b22.v: $(CORDIC_DIR)/cordicgx.py
	$(PYTHON) $< 22 > cordicg_b22.v

cav_mode_tb: cordicg_b22.v

a_comp_check: a_compress.py a_compress.dat
	$(PYTHON) a_compress.py -c

resonator_check: resonator_tb resonator_check.m resonator.dat
	$(OCTAVE) resonator_check.m resonator.dat

cav_mode_check: cav_check1.m cav_mode.dat
	$(OCTAVE) $<

$(AUTOGEN_DIR)/%_auto.vh: %.v
	mkdir -p $(AUTOGEN_DIR); $(PYTHON) $(BUILD_DIR)/newad.py -i $< -o $@ -w 14

$(AUTOGEN_DIR)/addr_map_%.vh: %.v
	mkdir -p $(AUTOGEN_DIR); $(PYTHON) $(BUILD_DIR)/newad.py -i $< -a $@ -w 14

$(AUTOGEN_DIR)/regmap_%.json: %.v
	mkdir -p $(AUTOGEN_DIR); $(PYTHON) $(BUILD_DIR)/newad.py -i $< -r $@ -w 14

CLEAN += $(TGT_) $(CHK_) *.bit *.in *.vcd *.dat cordicg_b22.v

CLEAN_DIRS += _xilinx

.PHONY: targets checks bits check_all clean_all
targets: $(TGT_)
checks: $(CHK_)
check_all: $(CHK_)
bits: $(BITS_)
