TARGET = system

include ../common/common.mk

all: $(TARGET)_top.bit

BOOTLOADER_BAUDRATE = 115200
BOOTLOADER_SERIAL = /dev/ttyUSB1
HARDWARE = cmod_a7
SYNTH_OPT += -DMEMORY_PACK_FAST
SRC_V += system_top.v xilinx7_clocks.v
OBJS += bootloader.o 0x0e0.lds

# -----------------
#  openOCD config
# -----------------
# Needs the latest development version of openOCD
# SPI proxy bitstreams from https://github.com/quartiq/bscan_spi_bitstreams
BS_BIT = $(HOME)/.openocd/bscan_spi_bitstreams/bscan_spi_xc7a35t.bit
OCD_CMD = openocd -f digilent_cmod_a7.cfg -c "init; jtagspi_init 0 $(BS_BIT); $(OCD_OPS) exit;"

$(TARGET).elf: $(OBJS)
$(TARGET)_top.bit: $(SRC_V) $(TARGET)32.dat

flash_gateware: $(TARGET)_top.bin
	$(eval OCD_OPS = jtagspi_program $^ 0x0; fpga_program;)
	$(OCD_CMD)

CLEAN += $(TARGET)_top.bit
CLEAN_DIRS += _xilinx .Xil
include $(BUILD_DIR)/bottom_rules.mk
