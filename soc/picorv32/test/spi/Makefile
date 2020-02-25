include ../../../../dir_list.mk
include $(BUILD_DIR)/top_rules.mk
include $(PICORV_DIR)/rules.mk

BLOCK_RAM_SIZE = 512
TARGET   = spi_test

SRC_V    =  memory_pack.v mpack.v munpack.v  picorv32.v pico_pack.v
SRC_V    += spi_pack.v sfr_pack.v spi_engine.v spi_slave.v
SRC_V    += stream_fifo.v shortfifo.v
OBJS     += startup.o

all: $(TARGET)_check

$(TARGET).elf: 0x000.lds $(OBJS)
$(TARGET)_tb: $(SRC_V)
$(TARGET).vcd $(TARGET)_check: $(TARGET)32.hex

include $(BUILD_DIR)/bottom_rules.mk
