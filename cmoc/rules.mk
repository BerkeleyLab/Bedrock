TEST_BENCH = xy_pi_clip_tb fdbk_core_tb tgen_tb circle_buf_tb cryomodule_tb cryomodule_badger_tb

include $(CMOC_DIR)/api.mk

TGT_ := $(TEST_BENCH)

NO_CHECK = tgen_check cryomodule_badger_check
CHK_ = $(filter-out $(NO_CHECK), $(TEST_BENCH:%_tb=%_check))

.PHONY: targets checks bits check_all clean_all
targets: $(TGT_)
checks: $(CHK_)
check_all: $(CHK_)
bits: $(BITS_)

fdbk_core.vcd: $(AUTOGEN_DIR)/regmap_fdbk_core_tb.json
fdbk_core.vcd: fdbk_core_tb fdbk_core_test.py
	$(PYTHON) fdbk_core_test.py
fdbk_core_check: fdbk_core.vcd
	echo DONE

cryomodule_in.dat: cryomodule_test_setup.py $(AUTOGEN_DIR)/regmap_cryomodule.json
	$(PYTHON) cryomodule_test_setup.py | sed -e 's/ *#.*//' | grep . > $@

VVP_FLAGS_cryomodule.dat = +pfile=cryomodule_p.dat

cryomodule.out: cryomodule_tb cryomodule_in.dat
cryomodule.dat: cryomodule.out
cryomodule.vcd: cryomodule_in.dat
cryomodule_check: cryomodule.dat
	$(PYTHON) verify_cryomodule.py


CLEAN += $(TGT_) $(CHK_) *.bit *.in *.vcd
CLEAN += fdbk_core*.dat lim_step_file_in.dat setmp_step_file_in.dat cryomodule_in.dat cryomodule_p.dat cryomodule.dat config_romx.v $(RTEFI_CLEAN)

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
