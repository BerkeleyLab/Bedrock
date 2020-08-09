TARGET = system

include ../common/common.mk

all: $(TARGET)_top.bit

BOOTLOADER_BAUDRATE = 115200
BOOTLOADER_SERIAL = /dev/ttyUSB1
HARDWARE = marblemini
SYNTH_OPT += -DMEMORY_PACK_FAST
SRC_V += system_top.v xilinx7_clocks.v
OBJS += bootloader.o 0x0e0.lds

vpath Marble.xdc $(BOARD_SUPPORT_DIR)/marblemini

$(TARGET).elf: $(OBJS)
$(TARGET)_top.bit: $(SRC_V) $(TARGET)32.dat

system_top.xdc: $(BADGER_DIR)/tests/meta-xdc.py Marble.xdc pin_map.csv
	$(PYTHON) $^ > $@

flash_gateware: $(TARGET)_top.bin
	$(eval OCD_OPS = jtagspi_program $^ 0x0; fpga_program;)
	$(OCD_CMD)

CLEAN += $(TARGET)_top.bit $(TARGET)_top.bin $(TARGET)_top.prm system_top.xdc
CLEAN_DIRS += _xilinx .Xil
include $(BUILD_DIR)/bottom_rules.mk
