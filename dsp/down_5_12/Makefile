include ../../dir_list.mk
include $(BUILD_DIR)/top_rules.mk

vpath %.v ..

all: down_5_12_tb

down_5_12_tb: down_5_12.v reg_delay.v isqrt.v

down_5_12_large.bit: down_5_12.v reg_delay.v isqrt.v blank_a7.ucf
	PART=xc7a100t-fgg484-2 $(SYNTH) down_5_12 $^

down_5_12_small.bit: down_5_12_small.v down_5_12.v reg_delay.v isqrt.v blank_a7.ucf
	PART=xc7a100t-fgg484-2 $(SYNTH) down_5_12_small $^

CLEAN += *.vcd *.bit down_5_12_tb
include $(BUILD_DIR)/bottom_rules.mk
