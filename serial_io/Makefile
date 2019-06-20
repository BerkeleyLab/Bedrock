include ../dir_list.mk
include $(BUILD_DIR)/top_rules.mk

vpath %.v $(SERIAL_IO_DIR) $(DSP_DIR)

TGT_ := patt_gen_tb
CHK_ = $(TGT_:%_tb=%_check)

.PHONY: checks
targets: $(TGT_)
checks: $(CHK_)

SRCS = patt_gen.v data_xdomain.v flag_xdomain.v multi_sampler.v

patt_gen_tb : $(SRCS)

CLEAN += patt_gen_tb
CLEAN_DIR += _autogen

include $(BUILD_DIR)/bottom_rules.mk
