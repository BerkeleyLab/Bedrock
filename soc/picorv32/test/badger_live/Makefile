include ../../../../dir_list.mk
include $(BUILD_DIR)/top_rules.mk
include $(PICORV_DIR)/rules.mk

vpath %.v $(BADGER_DIR) $(DSP_DIR)
vpath %.c $(BADGER_DIR)/tests $(LIB_DIR)/src
vpath %.py $(BADGER_DIR)
vpath %.csv $(BADGER_DIR)

TARGET  = badger
all: $(TARGET).vcd

#-------------------
# The picorv32soc
#-------------------
MEM_SIZE = 4096
SRC_V  += memory_pack.v mpack.v munpack.v picorv32.v pico_pack.v sfr_pack.v gpio_pack.v
OBJS   += startup.o common.o printf.o
CFLAGS += -DSIMULATION
VFLAGS += -DSIMULATION -m ./tap-vpi -DLINUX_TUN

#-------------------
# The packet badger
#-------------------
# https://www.albinoblacksheep.com/flash/badgers
SRC_V += precog.v test_tx_mac.v
SRC_V += $(RTEFI_V) badger_pack.v
RTEFI_CLIENT_LIST = hello.v speed_test.v mem_gateway.v
include $(BADGER_DIR)/rules.mk

#-------------------
# Ethernet TAP
#-------------------
# VPI module support for live testing
# https://en.wikipedia.org/wiki/TUN/TAP
# On-line test using Icarus and Linux's tun/tap feature
# Setup for a single-user machine is pretty easy: as root do a
#  tunctl -u your_name_here && ifconfig tap0 192.168.7.1 up
# and then you can make tap_start.  In another shell session,
# try to ping 192.168.7.4
# and echo "Watson, come here" | nc -u -w 3 192.168.7.4 7
#
# Welcome to the jungle we've got fun and games ...
CFLAGS_VPI = $(shell iverilog-vpi --cflags) -D_POSIX_C_SOURCE=200809L
tap-vpi.vpi: CC=cc
tap-vpi.vpi: CFLAGS=$(CFLAGS_VPI)
tap-vpi.vpi: ethernet_model.c tap_alloc.o crc32.o
udp-vpi.vpi: udp_model.c
%-vpi.vpi: %-vpi.o
	iverilog-vpi $^

$(TARGET).elf: 0x000.lds $(OBJS)
$(TARGET)_tb: $(SRC_V)
$(TARGET).vcd: $(TARGET)32.hex tap-vpi.vpi

CLEAN += crc32.o tap_alloc.o tap-vpi.vpi tap-vpi.o ethernet_model.o $(OBJS) $(RTEFI_CLEAN)

include $(BUILD_DIR)/bottom_rules.mk

.PRECIOUS: $(TARGET).vcd
