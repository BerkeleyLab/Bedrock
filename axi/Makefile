# Makefile AXI-related tools
include ../dir_list.mk
include $(BUILD_DIR)/top_rules.mk

.PHONY: all
all: axi_host_check axi_lb_check axi_lb_cdc_check

axi_host_tb: axi_host_tb.v axi_host.v axi_dummy.v axi_delay.v
	$(VERILOG_TB)

axi_lb_tb: axi_lb_tb.v axi_lb.v axi_host.v axi_delay.v $(LOCALBUS_DIR)/lb_dummy.v $(LOCALBUS_DIR)/lb_delay.v
	$(VERILOG_TB)

#VFLAGS_axi_lb_cdc_tb=-DCHATTER_AXI_LB_CDC
axi_lb_cdc_tb: axi_lb_cdc_tb.v axi_lb_cdc.v axi_host.v axi_delay.v $(DSP_DIR)/fifo_2c.v $(DSP_DIR)/dpram.v $(LOCALBUS_DIR)/lb_dummy.v $(LOCALBUS_DIR)/lb_delay.v
	$(VERILOG_TB)

CLEAN+=axi_lb_cdc_tb axi_lb_tb axi_host_tb
CLEAN+=axi_lb_cdc.vcd axi_lb.vcd axi_host.vcd

include $(BUILD_DIR)/bottom_rules.mk
