XILINX_TOOL = VIVADO

include ../../../../../dir_list.mk
include $(BUILD_DIR)/top_rules.mk
include $(PICORV_DIR)/rules.mk

MARBLE_DIR=$(PROJECT_DIR)/marble_mini/common
vpath %.c $(MARBLE_DIR)
vpath system.v $(MARBLE_DIR)
vpath spiflash.v $(PICORV_DIR)/test/memio

SRC_V += picorv32.v system.v uart_pack.v uart_rx.v uart_tx.v mpack.v munpack.v
# builds can use memory_pack.v or memory_pack2.v, depending on MEMORY_PACK_FAST
SRC_V += memory2_pack.v pico_pack.v
SRC_V += stream_fifo.v shortfifo.v uart_fifo_pack.v uart_stream.v
SRC_V += sfr_pack.v gpio_pack.v gpioz_pack.v spimemio.v spimemio_pack.v
SRC_V += pb_debouncer.v

OBJS += system.o print.o timer.o test.o startup_irq.o

#size of the blockRam [bytes]
BLOCK_RAM_SIZE = 16384
SYNTH_OPT += -DBLOCK_RAM_SIZE=$(BLOCK_RAM_SIZE)

CFLAGS += -DGIT_VERSION=\"$(GIT_VERSION)\" -I../common
CFLAGS += -DBOOTLOADER_BAUDRATE=$(BOOTLOADER_BAUDRATE)
CFLAGS += -ffunction-sections
