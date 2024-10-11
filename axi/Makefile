# Makefile AXI-related tools
include ../dir_list.mk
include $(BUILD_DIR)/top_rules.mk

.PHONY: all
all: axi_host_check axi_host_pipelined_check axi_lb_check axi_lb_cdc_check axi_channel_xdomain_check axi_cdc_check lb_test_host_check

axi_host_tb: axi_host_tb.v axi_host.v axi_dummy.v axi_delay.v
	$(VERILOG_TB)

axi_host_pipelined_tb: axi_host_pipelined_tb.v axi_host_pipelined.v axi_dummy.v
	$(VERILOG_TB)

#axi_cdc_tb: axi_cdc_tb.v axi_cdc.v axi_host.v $(DSP_DIR)/data_xdomain.v $(DSP_DIR)/flag_xdomain.v $(DSP_DIR)/reg_tech_cdc.v axi_dummy.v
axi_cdc_tb: axi_cdc_tb.v axi_cdc.v axi_channel_xdomain.v axi_host_pipelined.v axi_dummy.v $(DSP_DIR)/fifo_2c.v $(DSP_DIR)/dpram.v
	$(VERILOG_TB)

axi_lb_tb: axi_lb_tb.v axi_lb.v axi_host.v axi_delay.v $(LOCALBUS_DIR)/lb_dummy.v $(LOCALBUS_DIR)/lb_delay.v
	$(VERILOG_TB)

#VFLAGS_axi_lb_cdc_tb=-DCHATTER_AXI_LB_CDC
axi_lb_cdc_tb: axi_lb_cdc_tb.v axi_lb_cdc.v axi_host.v axi_delay.v $(DSP_DIR)/fifo_2c.v $(DSP_DIR)/dpram.v $(LOCALBUS_DIR)/lb_dummy.v $(LOCALBUS_DIR)/lb_delay.v
	$(VERILOG_TB)

lb_test_host_tb: lb_test_host_tb.v lb_test_host.v lb_cdc.v $(DSP_DIR)/fifo_2c.v $(DSP_DIR)/dpram.v $(LOCALBUS_DIR)/lb_dummy.v
	$(VERILOG_TB)

axi_channel_xdomain_tb: axi_channel_xdomain_tb.v axi_channel_xdomain.v channel_consumer.v channel_producer.v $(DSP_DIR)/fifo_2c.v $(DSP_DIR)/dpram.v

# TODO - FIXME (this comes from bedrock/badger/tests/Makefile; modify it to drive lb_client_tb)
# =====
xfer1: $(BADGER_DIR)/tests/xfer1.readable
	tr ' ' '\n' < $< > $@

# =====
# VPI module support for live testing
# https://en.wikipedia.org/wiki/TUN/TAP
CFLAGS_tap-vpi.o = $(VPI_CFLAGS) -D_POSIX_C_SOURCE=200809L
tap-vpi.vpi: $(BADGER_DIR)/tests/ethernet_model.o $(BADGER_DIR)/tests/tap_alloc.o $(BADGER_DIR)/tests/crc32.o
# TODO KEEF - dammit... the CFLAGS_udp-vpi.o expansion fails here because it actually should be CFLAGS_$(BADGER_DIR)/tests/udp-vpi.vpi
#CFLAGS_udp-vpi.o = $(VPI_CFLAGS) -D_POSIX_C_SOURCE=200809L
#$(BADGER_DIR)/tests/udp-vpi.vpi: $(BADGER_DIR)/tests/udp_model.c

#VPI_DEP=$(BADGER_DIR)/tests/udp-vpi
VPI_DEP=
# =====
# Another tangent for another client
#$(BADGER_DIR)/tests/udp-vpi.vpi
lb_client_tb: lb_client.v $(LOCALBUS_DIR)/lb_dummy.v lb_test_host.v lb_cdc.v $(DSP_DIR)/fifo_2c.v $(DSP_DIR)/dpram.v $(BADGER_DIR)/tests/client_sub.v $(VPI_DEP)
#VFLAGS_lb_client_tb = -m $(VPI_DEP)
VFLAGS_lb_client_tb = -DCLIENT_SUB_NO_UDP
lb_client.vcd: lass_pkt_in $(VPI_DEP)
lb_client_run: lb_client_tb $(VPI_DEP)
	$(VVP) $< +udp_port=3000 +vcd
lb_client.out: lb_client_tb $(VPI_DEP) lass_pkt_in
	$(VVP) $< +log +vcd +packet_file=lass_pkt_in > $@


CLEAN+=axi_lb_cdc_tb axi_lb_tb axi_host_tb axi_host_pipelined_tb axi_cdc_tb axi_channel_xdomain_tb lb_test_host_tb
CLEAN+=axi_lb_cdc.vcd axi_lb.vcd axi_host.vcd axi_host_pipelined.vcd axi_cdc.vcd axi_channel_xdomain.vcd lb_test_host.vcd

include $(BUILD_DIR)/bottom_rules.mk
