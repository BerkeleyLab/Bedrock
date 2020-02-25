include ../../../../dir_list.mk
include $(BUILD_DIR)/top_rules.mk
include $(PICORV_DIR)/rules.mk

# assume that vivado is on the PATH, this might be needed:
# source /opt/Xilinx/Vivado/2018.2/settings64.sh
VIVADO_BASE = $(dir $(shell which vivado))..
BLOCK_RAM_SIZE     = 2048
SRC_V   = memory2_pack.v mpack.v munpack.v picorv32.v pico_pack.v sfr_pack.v
SRC_V  += fmc11x/iserdes_pack.v fmc11x/idelay_wrap.v fmc11x/dco_buf.v
SRC_V  += flag_xdomain.v dpram.v
SRC_V  += $(VIVADO_BASE)/data/verilog/src/glbl.v
CFLAGS += -DSIMULATION

TARGET  = iserdes_test

all: $(TARGET).vcd

SRCS      = iserdes.c print.c
OBJS      = $(subst .c,.o,$(SRCS)) startup.o

$(TARGET).elf: 0x000.lds startup.o $(OBJS)

$(TARGET).vcd: iserdes_tb
	xsim -nolog -R $< -testplusarg vcd

iserdes_tb: $(SRC_V) iserdes_tb.v $(TARGET)32.hex
	xvlog -nolog -d BLOCK_RAM_SIZE=$(BLOCK_RAM_SIZE) $(filter %.v,$^)
	#xvhdl -nolog $(filter %.vhd,$^)
	xelab -nolog -L unisims_ver -L secureip $@ glbl -s $@ -timescale 1ns/1ps

CLEAN += xvhdl.log xvhdl.pb xvlog.log xelab.log xvlog.pb xelab.pb xsim*.jou xsim*.log webtalk*.jou webtalk*.log
CLEAN_DIRS += xsim.dir .Xil

include $(BUILD_DIR)/bottom_rules.mk
