TARGET = system

include ../common/common.mk

all: $(TARGET)_top.bit

BOOTLOADER_BAUDRATE = 115200
BOOTLOADER_SERIAL = /dev/ttyUSB1
HARDWARE = cmod_a7
SRC_V += system_top.v xilinx7_clocks.v
OBJS += bootloader.o 0x0e0.lds

# TODO vivado does not accepting relative paths in project mode
SYNTH_OPT += -DMEMORY_PACK_FAST

$(TARGET).elf: $(OBJS)
$(TARGET)_top.bit: $(SRC_V) $(TARGET)32.hex

CLEAN += $(TARGET)_top.bit
CLEAN_DIRS += _xilinx .Xil
include $(BUILD_DIR)/bottom_rules.mk
