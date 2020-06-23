XILINX_TOOL = VIVADO

include ../../../../../dir_list.mk
include $(BUILD_DIR)/top_rules.mk
include $(PICORV_DIR)/rules.mk

TARGET = system_top

BOOTLOADER_SERIAL = /dev/ttyUSB1
BOOTLOADER_BAUDRATE = 921600
BLOCK_RAM_SIZE = 4096

SRC_V += memory2_pack.v mpack.v munpack.v picorv32.v pico_pack.v
SRC_V += uart_pack.v uart_rx.v uart_tx.v sram_pack.v sram2_pack.v
SRC_V += $(TARGET).v ../system.v xilinx7_clocks.v

OBJS += $(TARGET).o startup_irq.o bootloader.o print.o timer.o
CFLAGS += -DBOOTLOADER_BAUDRATE=$(BOOTLOADER_BAUDRATE) -I..

SYNTH_OPT = -DBLOCK_RAM_SIZE=$(BLOCK_RAM_SIZE) -DMEMORY_PACK_FAST
HARDWARE = cmod_a7

all: $(TARGET).bit

$(TARGET).elf: $(OBJS) 0x0e0.lds

# need to apply `project_proc.tcl.patch` for synthesis to find top-level
$(TARGET).bit: $(SRC_V) $(TARGET)32.hex

CLEAN += $(TARGET).bit
CLEAN_DIRS += .ipynb_checkpoints _xilinx .Xil

include $(BUILD_DIR)/bottom_rules.mk
