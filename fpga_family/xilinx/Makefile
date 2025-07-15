
include ../../dir_list.mk
include $(BUILD_DIR)/top_rules.mk

all: xadc_tempvoltmon_check

# XADC Temperature and Voltage monitor
xadc_tempvoltmon_tb: xadc_tempvoltmon.v fake_xadc.v

CLEAN+=xadc_tempvoltmon_tb

include $(BUILD_DIR)/bottom_rules.mk
