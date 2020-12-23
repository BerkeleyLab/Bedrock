XILINX_TOOL = VIVADO

include ../../../../../dir_list.mk
include $(BUILD_DIR)/top_rules.mk
include $(PICORV_DIR)/rules.mk

KC705_DIR=$(PROJECT_DIR)/kc705/common
vpath %.c $(KC705_DIR)
vpath system.v $(KC705_DIR)

SRC_V += picorv32.v system.v uart_pack.v uart_rx.v uart_tx.v mpack.v munpack.v
SRC_V += memory_pack.v memory2_pack.v pico_pack.v
SRC_V += pb_debouncer.v sfr_pack.v gpio_pack.v gpioz_pack.v

OBJS =  system.o print.o i2c_soft.o timer.o lcd.o startup.o

#size of the blockRam [bytes]
BLOCK_RAM_SIZE = 8192
SYNTH_OPT += -DBLOCK_RAM_SIZE=$(BLOCK_RAM_SIZE)

CFLAGS += -DBOOTLOADER_BAUDRATE=$(BOOTLOADER_BAUDRATE) -I../common
CFLAGS += -ffunction-sections
