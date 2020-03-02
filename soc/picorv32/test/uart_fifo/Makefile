include ../../../../dir_list.mk
include $(BUILD_DIR)/top_rules.mk
include $(PICORV_DIR)/rules.mk

BLOCK_RAM_SIZE = 1024

SRC_V  = uart_tx.v uart_rx.v stream_fifo.v shortfifo.v
SRC_V += memory2_pack.v mpack.v munpack.v picorv32.v pico_pack.v
SRC_V += uart_pack.v uart_fifo_pack.v uart_stream.v

TARGET = uart

all: $(TARGET)_check

OBJS = startup.o common.o

$(TARGET).elf: 0x000.lds $(OBJS)
$(TARGET)_tb: $(SRC_V)
$(TARGET).vcd $(TARGET)_check: $(TARGET)32.hex

include $(BUILD_DIR)/bottom_rules.mk
