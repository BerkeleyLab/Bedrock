VFLAGS_DEP += -y. -I. -y$(DSP_DIR) -I$(DSP_DIR) -y$(CORDIC_DIR)
VFLAGS += -I. -y. -y$(DSP_DIR) -I$(DSP_DIR) -y$(CORDIC_DIR) -I$(AUTOGEN_DIR)

VVP_FLAGS += +trace

TEST_BENCH = beam_tb outer_prod_tb resonator_tb a_compress_tb cav_mode_tb cav_elec_tb rtsim_tb

TGT_ := $(TEST_BENCH)

NO_CHECK =

#CHK_ = $(filter-out $(NO_CHECK), $(TEST_BENCH:%_tb=%_check))
CHK_ += a_comp_check resonator_check cav_mode_check

BITS_ :=

VFLAGS_cav_mode_tb += -DLB_DECODE_cav_mode
VFLAGS_cav_elec_tb += -DLB_DECODE_cav_elec

%_s6.bit: %.v $(DEPDIR)/%.bit.d blank_s6.ucf
	arch=s6 $(ISE_SYNTH) $* $(SYNTH_OPT) $^ && mv _xilinx/$@ $@

%_a7.bit: %.v $(DEPDIR)/%.bit.d blank_a7.ucf
	arch=a7 $(ISE_SYNTH) $* $(SYNTH_OPT) $^ && mv _xilinx/$@ $@

$(AUTOGEN_DIR)/cordicg_b22.v: $(CORDIC_DIR)/cordicgx.py
	mkdir -p $(AUTOGEN_DIR) && $(PYTHON) $< 22 > $@

-include $(RTSIM_DIR)/api.mk

rtsim_in.dat: param.py rtsim_auto $(AUTOGEN_DIR)/regmap_rtsim.json
	$(PYTHON) $< $(AUTOGEN_DIR)/regmap_rtsim.json | sed -e 's/ *#.*//' | grep . > $@

rtsim.vcd: rtsim_in.dat

rtsim.dat: rtsim_tb rtsim_in.dat
	$(VVP) $< +pfile=$@
	$(PYTHON) rtsim_test.py

# XXX why does this break builds?
# .PHONY: rtsim_auto

a_comp_check: a_compress.py a_compress.dat
	$(PYTHON) $< -c

resonator_check: resonator_check.py resonator.dat
	$(PYTHON) $<

cav_mode_check: cav_mode_check.py cav_mode.dat
	$(PYTHON) $<

LB_AW = 14 # Set the Local Bus Address Width for test benches

CLEAN += $(TGT_) $(CHK_) *.bit *.in *.vcd *.dat *.png

CLEAN_DIRS += _xilinx

.PHONY: targets checks bits check_all clean_all
targets: $(TGT_)
checks: $(CHK_)
check_all: $(CHK_)
bits: $(BITS_)
