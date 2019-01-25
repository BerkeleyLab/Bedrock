BUILD_DIR = ../build-tools
DSP_DIR = ../dsp
CORDIC_DIR = ../cordic
RTSIM_DIR = ../rtsim
BADGER_DIR = ../badger/
CMOC_DIR = ./

vpath %.v $(RTSIM_DIR) $(DSP_DIR) $(BADGER_DIR)

.PHONY: all
all: targets
include $(BUILD_DIR)/top_rules.mk
include rules.mk
