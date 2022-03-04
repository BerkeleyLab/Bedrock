DIG_DIR ?= $(DSP_DIR)/digaree

VFLAGS_DEP += -y$(DIG_DIR) -I$(DIG_DIR)
VFLAGS += -I$(DIG_DIR)

# Enable this stanza for SRF cavity detune and quench finding
STYLE = _srf
DATA_LEN = 6
CONSTS_LEN = 8
CONST_AW = 3

# Enable this stanza for RF distortion correction
# STYLE = _ip3
# DATA_LEN = 8
# CONSTS_LEN = 4
# CONST_AW = 2

ops.h: $(DIG_DIR)/cgen$(STYLE).py $(DIG_DIR)/cgen_lib.py
	$(PYTHON) $< > $@

ops.vh: $(DIG_DIR)/sched.py ops.h
	$(PYTHON) $^ > $@

CLEAN += ops.h ops.vh
