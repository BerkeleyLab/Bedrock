include ../dir_list.mk

vpath %.v $(RTSIM_DIR) $(DSP_DIR) $(DSP_DIR)/hosted $(BADGER_DIR)

.PHONY: all
all: targets
NO_DEFAULT_TB_RULE := 1
include $(BUILD_DIR)/top_rules.mk
include $(BUILD_DIR)/newad_rules.mk
RTEFI_CLIENT_LIST = hello.v speed_test.v mem_gateway.v
include $(BADGER_DIR)/rules.mk

TEST_BENCH = xy_pi_clip_tb fdbk_core_tb tgen_tb circle_buf_tb cryomodule_tb cryomodule_badger_tb rf_controller_tb

RTEFI_CLIENT_LIST = hello.v speed_test.v mem_gateway.v
include rules.mk

TGT_ := $(TEST_BENCH)

NO_CHECK = tgen_check cryomodule_badger_check rf_controller_check
CHK_ = $(filter-out $(NO_CHECK), $(TEST_BENCH:%_tb=%_check))
NO_LINT = $(NO_CHECK)
LNT_ = $(filter-out $(NO_LINT), $(TEST_BENCH:%_tb=%_lint))

.PHONY: targets checks bits check_all clean_all
targets: $(TGT_)
checks: $(CHK_)
check_all: $(CHK_)
lint: $(LNT_)
bits: $(BITS_)

_dep/fdbk_core_tb.d: fdbk_core_tb_auto
_dep/rf_controller_tb.d: rf_controller_tb_auto


fdbk_core.vcd: $(AUTOGEN_DIR)/regmap_fdbk_core_tb.json
fdbk_core.vcd: fdbk_core_tb fdbk_core_test.py
	$(PYTHON) fdbk_core_test.py
fdbk_core_check: fdbk_core.vcd
	@ echo DONE

cryomodule_in.dat: cryomodule_test_setup.py $(AUTOGEN_DIR)/regmap_cryomodule.json
	$(PYTHON) cryomodule_test_setup.py | sed -e 's/ *#.*//' | grep . > $@

VVP_FLAGS_cryomodule.dat = +pfile=cryomodule_p.dat

cryomodule.out: cryomodule_tb cryomodule_in.dat
cryomodule.dat: cryomodule.out
cryomodule.vcd: cryomodule_in.dat
cryomodule_tb: $(AUTOGEN_DIR)/config_romx.v $(AUTOGEN_DIR)/cryomodule_auto.vh
cryomodule_check: cryomodule.dat
	$(PYTHON) verify_cryomodule.py

$(AUTOGEN_DIR)/config_romx.v:
	mkdir -p $(AUTOGEN_DIR); $(PYTHON) $(BUILD_DIR)/config_crunch.py --OUTPUT=$@

VFLAGS_DEP += -y $(BADGER_DIR) -Wno-macro-redefinition

cryomodule_badger_tb.v: $(RTEFI_V) $(AUTOGEN_DIR)/config_romx.v cordicg_b22.v cryomodule_auto

CLEAN += $(RTEFI_CLEAN)

ifneq (,$(findstring bit,$(MAKECMDGOALS)))
    ifneq (,$(findstring bits,$(MAKECMDGOALS)))
	include $(BITS_:%.bit=$(DEPDIR)/%.bit.d)
    else
	include $(MAKECMDGOALS:%.bit=$(DEPDIR)/%.bit.d)
    endif
endif

# ifneq (,$(findstring _tb,$(MAKECMDGOALS)))
#     include $(MAKECMDGOALS:%_tb=$(DEPDIR)/%_tb.d)
# endif
# ifneq (,$(findstring _view,$(MAKECMDGOALS)))
#     include $(MAKECMDGOALS:%_tb=$(DEPDIR)/%_tb.d)
# endif
# ifneq (,$(findstring _check,$(MAKECMDGOALS)))
#     include $(MAKECMDGOALS:%_tb=$(DEPDIR)/%_tb.d)
# endif
# ifeq (,$(MAKECMDGOALS))
#     include $(TEST_BENCH:%_tb=$(DEPDIR)/%_tb.d)
# endif

CLEAN += $(TGT_) $(CHK_) *.bit *.in *.vcd
CLEAN += fdbk_core*.dat lim_step_file_in.dat setmp_step_file_in.dat cryomodule_in.dat cryomodule_p.dat cryomodule.dat $(RTEFI_CLEAN)
CLEAN_DIRS += _xilinx
include $(BUILD_DIR)/bottom_rules.mk
