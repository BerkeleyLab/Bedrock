TARGET = system

all: $(TARGET)_top.bit

include ../common/common.mk

BOOTLOADER_BAUDRATE = 115200
BOOTLOADER_SERIAL = /dev/ttyUSB1
HARDWARE = cmod_a7
SRC_V += system_top.v xilinx7_clocks.v
OBJS += bootloader.o 0x0e0.lds

# TODO vivado does not accepting relative paths in project mode
SYNTH_OPT += -DMEMORY_PACK_FAST

$(TARGET).elf: $(OBJS)
# TODO workaround `project_proc.tcl.patch` required for vivado to find top-level
$(TARGET)_top.bit: $(SRC_V) $(TARGET)32.hex

CLEAN += $(TARGET)_top.bit
include $(BUILD_DIR)/bottom_rules.mk
