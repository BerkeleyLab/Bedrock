XILINX_TOOL = VIVADO

include ../../../../../dir_list.mk
include $(BUILD_DIR)/top_rules.mk
include $(PICORV_DIR)/rules.mk

COM_DIR=$(PICORV_DIR)/project/cmod_a7/common
vpath %.c $(COM_DIR)
vpath system.v $(COM_DIR)
vpath sram_model.v $(PICORV_DIR)/test/sram

SRC_V += picorv32.v system.v uart_pack.v uart_rx.v uart_tx.v mpack.v munpack.v
SRC_V += memory_pack.v memory2_pack.v pico_pack.v
SRC_V += stream_fifo.v shortfifo.v uart_fifo_pack.v uart_stream.v
SRC_V += sfr_pack.v gpio_pack.v gpioz_pack.v
SRC_V += pb_debouncer.v sram_pack.v sram2_pack.v

OBJS += system.o print.o timer.o test.o common.o startup_irq.o

#size of the blockRam [bytes]
BLOCK_RAM_SIZE = 16384
SYNTH_OPT += -DBLOCK_RAM_SIZE=$(BLOCK_RAM_SIZE)

CFLAGS += -DGIT_VERSION=\"$(GIT_VERSION)\" -I../common
CFLAGS += -DBOOTLOADER_BAUDRATE=$(BOOTLOADER_BAUDRATE)
CFLAGS += -ffunction-sections

CLEAN += $(TARGET).bit
CLEAN_DIRS += _xilinx .Xil
