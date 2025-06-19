include ../dir_list.mk

vpath %.v $(RTSIM_DIR) $(DSP_DIR) $(DSP_DIR)/hosted $(BEDROCK_DIR)/localbus $(BADGER_DIR)
vpath %.c ../badger/tests

.PHONY: all
all: targets
include $(BUILD_DIR)/newad_top_rules.mk
RTEFI_CLIENT_LIST = hello.v speed_test.v mem_gateway.v
include $(BADGER_DIR)/rules.mk

NEWAD_ARGS += -y

TEST_BENCH = xy_pi_clip_tb circle_buf_tb cryomodule_tb cryomodule_badger_tb rf_controller_tb

RTEFI_CLIENT_LIST = hello.v speed_test.v mem_gateway.v
include rules.mk

TGT_ := $(TEST_BENCH)

NO_CHECK = cryomodule_badger_check rf_controller_check
CHK_ = $(filter-out $(NO_CHECK), $(TEST_BENCH:%_tb=%_check))
NO_LINT = $(NO_CHECK)
LNT_ = $(filter-out $(NO_LINT), $(TEST_BENCH:%_tb=%_lint))

.PHONY: targets checks bits check_all clean_all
targets: $(TGT_)
checks: $(CHK_)
check_all: $(CHK_)
lint: $(LNT_)
bits: $(BITS_)

_dep/rf_controller_tb.d: rf_controller_tb_auto

cryomodule_in.dat: cryomodule_test_setup.py $(AUTOGEN_DIR)/regmap_cryomodule.json
	$(PYTHON) cryomodule_test_setup.py | sed -e 's/ *#.*//' | grep . > $@

VVP_FLAGS_cryomodule.dat = +pfile=cryomodule_p.dat

cryomodule.out: cryomodule_tb cryomodule_in.dat
cryomodule.dat: cryomodule.out
cryomodule.vcd: cryomodule_in.dat
cryomodule_tb: $(AUTOGEN_DIR)/config_romx.v cryomodule_auto
cryomodule_check: cryomodule.dat
	$(PYTHON) verify_cryomodule.py

$(AUTOGEN_DIR)/config_romx.v:
	mkdir -p $(AUTOGEN_DIR); $(PYTHON) $(BUILD_DIR)/config_crunch.py --OUTPUT=$@

VFLAGS_DEP += -y $(BADGER_DIR)

VFLAGS_cryomodule_badger_tb = -m ./tap-vpi

cryomodule_badger_tb: $(RTEFI_V) $(AUTOGEN_DIR)/config_romx.v cordicg_b22.v cryomodule_auto tap-vpi.vpi

CFLAGS_tap-vpi.o = $(VPI_CFLAGS) -D_POSIX_C_SOURCE=200809L
tap-vpi.vpi: ethernet_model.o tap_alloc.o crc32.o

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
CLEAN += *.o tap-vpi.vpi
CLEAN += cryomodule_in.dat cryomodule_p.dat cryomodule.dat $(RTEFI_CLEAN)
CLEAN_DIRS += _xilinx
include $(BUILD_DIR)/bottom_rules.mk
