CURR_DIR     := $(dir $(lastword $(MAKEFILE_LIST)))
TOPLEVEL_LANG = verilog

SIM ?= icarus
WAVES ?= 0

COCOTB_HDL_TIMEUNIT = 1ns
COCOTB_HDL_TIMEPRECISION = 1ps

ifeq ($(SIM), icarus)
	COMPILE_ARGS += -Wall -Wno-timescale
	COMPILE_ARGS += $(foreach v,$(filter PARAM_%,$(.VARIABLES)),-P $(TOPLEVEL).$(subst PARAM_,,$(v))=$($(v)))
else ifeq ($(SIM), verilator)
	COMPILE_ARGS += --timing
	COMPILE_ARGS += $(foreach v,$(filter PARAM_%,$(.VARIABLES)),-G$(subst PARAM_,,$(v))=$($(v)))
# to avoid warning on 1-bit signal in counter
	EXTRA_ARGS += -Wno-width
# to avoid warning on unconnected output pins
	EXTRA_ARGS += -Wno-pinmissing
	ifeq ($(WAVES), 1)
		EXTRA_ARGS += --trace --trace-fst --trace-structs
	endif
endif

# https://github.com/cocotb/cocotb/issues/2279
# Check if testing failed message exists in results.xml.
.PHONY: check_results
check_results: sim
	$(call check_for_results_file)
	$(PYTHON_BIN) $(CURR_DIR)check_results.py -i results.xml

include $(shell cocotb-config --makefiles)/Makefile.sim

clean::
	rm -f results.xml
	rm -rf __pycache__
