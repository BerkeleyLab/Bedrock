TOP_DIR = ../../..
APP_DIR = $(TOP_DIR)/cmoc
BADGER_DIR = $(TOP_DIR)/badger
BUILD_DIR = $(TOP_DIR)/build-tools

vpath %.v $(APP_DIR)

include $(BUILD_DIR)/top_rules.mk
include $(APP_DIR)/api.mk

# TODO: Complete butchering of makefile. Should be fixed
cryomodule_dummy.v:
	cd $(APP_DIR) && make cryomodule_EXPAND.v && cd - && cp $(APP_DIR)/cryomodule_EXPAND.v .

bit: cryomodule_dummy.v
	$(PYTHON) cryomodule_top.py --cpu-type=picorv32

sim: cryomodule_dummy.v
	$(PYTHON) cryomodule_top.py --sim-only --cpu-type=picorv32

sim_trace: cryomodule_dummy.v
	$(PYTHON) cryomodule_top.py --sim-only --trace

CLEAN += *.bit
CLEAN_DIRS += soc_*
