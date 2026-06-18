include ../../../../dir_list.mk
include $(BUILD_DIR)/top_rules.mk
include $(PICORV_DIR)/rules.mk
VIVADO_BASE = $(dir $(shell which vivado))..

vpath %.c $(BOARD_SUPPORT_DIR)/zest_soc/firmware
vpath %.v $(FPGA_FAMILY_DIR)/xilinx $(BOARD_SUPPORT_DIR)/zest_soc $(BOARD_SUPPORT_DIR)/fmc11x $(DSP_DIR) $(BADGER_DIR)/tests/kc705

BLOCK_RAM_SIZE = 16384
SRC_V   = memory_pack.v mpack.v munpack.v picorv32.v pico_pack.v spi_engine.v
SRC_V  += idelays_pack.v freq_count.v freq_gcount.v flag_xdomain.v data_xdomain.v dpram.v phase_diff.v phaset.v
SRC_V  += reg_tech_cdc.v
SRC_V  += zest.v zest_clk_map.v zest_spi_dio_pack.v
SRC_V  += dco_buf.v iserdes_pack.v idelay_wrap.v wfm_pack.v
SRC_V  += $(VIVADO_BASE)/data/verilog/src/glbl.v
# Xilinx primitives that Vivado finds without help:
#  IBUFDS BUFG BUFIO BUFR IDELAYE2 ISERDESE2 ODDR OBUFDS IDELAYCTRL_default
SRC_V  += sfr_pack.v gpio_pack.v

SRCS    = print.c timer.c settings.h
SRCS   += printf.c iserdes.c
SRCS   += $(BOARD_SUPPORT_DIR)/zest_soc/firmware/zest.c $(BOARD_SUPPORT_DIR)/zest_soc/firmware/zest.h zest_test.c

OBJS   = $(subst .c,.o,$(filter %.c, $(SRCS))) startup.o

CFLAGS += -DSIMULATION -I$(BOARD_SUPPORT_DIR)/zest_soc/firmware
VFLAGS += -DSIMULATE -DSIMULATION

TARGET  = zest_test

all: $(TARGET).vcd

$(TARGET).elf: 0x000.lds $(OBJS)
$(TARGET)_tb: $(TARGET)_tb.v $(SRC_V)
	xvlog -nolog -d SIMULATE -d BLOCK_RAM_SIZE=$(BLOCK_RAM_SIZE) $(filter %.v,$^)
	xelab -nolog -L unisims_ver -L secureip $@ glbl -s $@ -timescale 1ns/1ps

$(TARGET).vcd: $(TARGET)_tb $(TARGET)32.hex
	xsim -nolog -R $< -testplusarg vcd

CLEAN += xelab.pb xsim*.jou xsim*.log webtalk*.jou webtalk*.log vivado*.log xvlog.pb zest_test_tb.wdb
CLEAN_DIRS += xsim.dir .Xil _xilinx
include $(BUILD_DIR)/bottom_rules.mk
