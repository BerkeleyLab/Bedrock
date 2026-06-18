TARGET = badger_lwip
all: $(TARGET)_sim

include ../../../../dir_list.mk
include $(BUILD_DIR)/top_rules.mk
include $(PICORV_DIR)/rules.mk
include $(BADGER_DIR)/rules.mk

vpath %.v $(BADGER_DIR) $(DSP_DIR)
vpath %.c $(BADGER_DIR)/tests $(LIB_DIR)/src
vpath %.py $(BADGER_DIR)
vpath %.csv $(BADGER_DIR)

#-------------------
# Picorv32soc
#-------------------
BLOCK_RAM_SIZE = 128000
SRC_V  += $(TARGET)_tb.v memory_pack.v mpack.v munpack.v picorv32.v pico_pack.v sfr_pack.v gpio_pack.v

#-------------------
# Packet badger
#-------------------
# https://www.albinoblacksheep.com/flash/badgers
SRC_V += badger_pack.v
SRC_V += $(RTEFI_V) precog.v test_tx_mac.v

#-------------------
# Firmware + lwip
#-------------------
# to setup the tap interface:
#   sudo tunctl -u $USER
#   sudo ip addr add dev tap0 192.168.7.1/24
#   sudo ip link set dev tap0 up
LWIPDIR=$(BEDROCK_DIR)../lwip/src
LWIP_APPS=$(LWIPDIR)/../contrib/apps
include $(LWIPDIR)/Filelists.mk
# All lwip related object files
LWIP_C=$(COREFILES) $(CORE4FILES) $(NETIFFILES) $(HTTPFILES) $(LWIPDIR)/api/err.c liblwip/badgerif.c
LWIP_O=$(LWIP_C:.c=.o)
OBJS   += $(TARGET).o startup.o print.o printf.o badger.o $(LWIP_O)
CFLAGS += -DSIMULATION -I./liblwip -I$(LWIPDIR)/include -I$(LWIPDIR)/include/ipv4
CFLAGS += -I$(LWIP_APPS) -ffunction-sections -fdata-sections
# Turns out we really need the stdlib this time ... however we have our own startup code
CFLAGS := $(filter-out -nostdlib,$(CFLAGS)) -nostartfiles
# master debug switch, customize lwipopts.h for finer control
CFLAGS += -DLWIP_DEBUG

#-------------------
# Verilator
#-------------------
# builds an hardware emulator for running / debugging lwip
# -DETHERNET_MODEL_DEBUG
V$(TARGET): $(SRC_V) $(TARGET)_sim.cpp ethernet_model.c tap_alloc.c crc32.c
	$(VERILATOR) --trace -cc --exe --top-module $(TARGET)_tb \
	           -Wno-PINMISSING -Wno-WIDTH -Wno-CASEINCOMPLETE \
	           -DBLOCK_RAM_SIZE=$(BLOCK_RAM_SIZE) \
	           -CFLAGS "-I$(BADGER_DIR)/tests" \
	           $^
	MAKEFLAGS="" make -C obj_dir -f V$(TARGET)_tb.mk
	mv obj_dir/$@_tb $@

#-------------------
# Explicit targets
#-------------------
# picorv linker options
$(TARGET).elf: 0x000.lds $(OBJS)

# Run emulator without .vcd tracing
$(TARGET)_sim: V$(TARGET) $(TARGET)32.hex
	./$<

# Run emulator and generate (a huge!) .vcd trace file
$(TARGET).vcd: V$(TARGET) $(TARGET)32.hex
	./$< +trace

CLEAN += crc32.o tap_alloc.o tap-vpi.vpi tap-vpi.o ethernet_model.o $(OBJS) $(RTEFI_CLEAN) V$(TARGET)
CLEAN_DIRS += obj_dir

include $(BUILD_DIR)/bottom_rules.mk
.PRECIOUS: $(TARGET).vcd
