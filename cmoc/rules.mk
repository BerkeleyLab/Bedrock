VFLAGS_DEP += -y. -I. -y$(RTSIM_DIR)
VFLAGS += -I. -y. -y$(CORDIC_DIR) -y$(DSP_DIR) -y$(RTSIM_DIR) -I$(AUTOGEN_DIR) -y$(AUTOGEN_DIR)
NEWAD_DIRS += $(DSP_DIR),$(RTSIM_DIR)

TEST_BENCH = xy_pi_clip_tb fdbk_core_tb tgen_tb cryomodule_tb

TGT_ := $(TEST_BENCH)

NO_CHECK =
CHK_ = $(filter-out $(NO_CHECK), $(TEST_BENCH:%_tb=%_check))

LB_AW = 13

vpath %.v $(RTSIM_DIR)
vpath %.vh $(RTSIM_DIR)

.PHONY: targets checks bits check_all clean_all
targets: $(TGT_)
checks: $(CHK_)
check_all: $(CHK_)
bits: $(BITS_)

$(AUTOGEN_DIR)/cordicg_b22.v: $(CORDIC_DIR)/cordicgx.py
	mkdir -p $(AUTOGEN_DIR) && $(PYTHON) $< 22 > $@

rf_controller_auto: fdbk_core_auto piezo_control_auto

fdbk_core_auto: $(AUTOGEN_DIR)/cordicg_b22.v
fdbk_core.vcd: $(AUTOGEN_DIR)/regmap_fdbk_core_tb.json
fdbk_core.vcd: fdbk_core_tb fdbk_core_test.py
	$(PYTHON) fdbk_core_test.py
fdbk_core_check: fdbk_core.vcd
	echo DONE

cryomodule_auto: $(AUTOGEN_DIR)/config_romx.v $(AUTOGEN_DIR)/cordicg_b22.v fdbk_core_auto station_auto prng_auto cav_mode_auto cav_mech_auto cav_elec_auto

CLEAN += $(TGT_) $(CHK_) *.bit *.in *.vcd
CLEAN += fdbk_core*.dat lim_step_file_in.dat setmp_step_file_in.dat

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
