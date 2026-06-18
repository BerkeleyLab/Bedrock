# Makefile for wctrace demo

THIS_DIR := $(realpath $(dir $(abspath $(lastword $(MAKEFILE_LIST)))))
include $(THIS_DIR)/../../dir_list.mk
include $(BUILD_DIR)/top_rules.mk

TESTS_DIR=$(BADGER_DIR)/tests
WCTRACE_SOURCES=wctrace.v $(DSP_DIR)/dpram.v
WCTRACE_TOP_SOURCES=wctrace_top.v $(BADGER_DIR)/mem_gateway.v $(DSP_DIR)/reg_delay.v
WCTRACE_LIVE_SOURCES=wctrace_live.cpp $(TESTS_DIR)/udp_model.c config_romx.v
INC_DIRS=$(TESTS_DIR)

all: wctrace_w2_check wctrace_w1_check wctrace_w0_check wctrace_n_check wctrace_live

VFLAGS_wctrace_w2_tb=-DTEST_WIDE2 -DWCTRACE_DEBUG
VFLAGS_wctrace_w1_tb=-DTEST_WIDE1 -DWCTRACE_DEBUG
VFLAGS_wctrace_w0_tb=-DTEST_WIDE0 -DWCTRACE_DEBUG
VFLAGS_wctrace_n_tb=-DTEST_NORMAL -DWCTRACE_DEBUG

.PHONY: wctrace_w2_check
wctrace_w2_check: wctrace_w2_tb
	$(VERILOG_CHECK)

.PHONY: wctrace_w1_check
wctrace_w1_check: wctrace_w1_tb
	$(VERILOG_CHECK)

.PHONY: wctrace_w0_check
wctrace_w0_check: wctrace_w0_tb
	$(VERILOG_CHECK)

.PHONY: wctrace_n_check
wctrace_n_check: wctrace_n_tb
	$(VERILOG_CHECK)

.PHONY: wctrace_w2_tb
wctrace_w2_tb: wctrace_tb.v $(WCTRACE_SOURCES)
	$(VERILOG_TB)

.PHONY: wctrace_w1_tb
wctrace_w1_tb: wctrace_tb.v $(WCTRACE_SOURCES)
	$(VERILOG_TB)

.PHONY: wctrace_w0_tb
wctrace_w0_tb: wctrace_tb.v $(WCTRACE_SOURCES)
	$(VERILOG_TB)

.PHONY: wctrace_n_tb
wctrace_n_tb: wctrace_tb.v $(WCTRACE_SOURCES)
	$(VERILOG_TB)

config_romx.v: wctrace_top_regmap.json
	$(PYTHON) -m leep.build_rom --placeholder_rev -v $@ -j $< -d "wctrace live demo"

VC_INCLUDES = $(foreach var,$(INC_DIRS),-CFLAGS -I$(var))

wctrace_live: $(WCTRACE_TOP_SOURCES) $(WCTRACE_LIVE_SOURCES) $(WCTRACE_SOURCES)
	$(VERILATOR) --trace $(VLATOR_LINT_IGNORE) -Wno-UNUSEDSIGNAL $(VC_INCLUDES) -cc --exe $^
	MAKEFLAGS="" make -C obj_dir -f Vwctrace_top.mk
	mv obj_dir/Vwctrace_top $@

CLEAN += wctrace_w2_tb wctrace_w1_tb wctrace_w0_tb wctrace_n_tb
CLEAN += wctrace_live config_romx.v
CLEAN_DIRS += obj_dir

include $(BUILD_DIR)/bottom_rules.mk
