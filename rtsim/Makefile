BUILD_DIR = ../build-tools
CORDIC_DIR = ../cordic
DSP_DIR = ../dsp

.PHONY: all
all: targets

include $(BUILD_DIR)/top_rules.mk

ifneq (clean,$(MAKECMDGOALS))
	-include $(DEPDIR)/resonator.bit.d
endif

include rules.mk
