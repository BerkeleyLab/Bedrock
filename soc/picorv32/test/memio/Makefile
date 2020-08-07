include ../../../../dir_list.mk
include $(BUILD_DIR)/top_rules.mk
include $(PICORV_DIR)/rules.mk
vpath system.v ..

SRC_V += memory2_pack.v mpack.v munpack.v picorv32.v pico_pack.v
SRC_V += spiflash.v spimemio.v spimemio_pack.v system.v

TARGET = memio
BLOCK_RAM_SIZE = 512
VFLAGS += -DMEMORY_PACK_FAST
VCD_ARGS += +firmware=flashdata8.hex
OBJS += startup.o

all: $(TARGET).vcd

$(TARGET).elf: 0x000.lds $(OBJS)
$(TARGET)_tb: $(SRC_V)
$(TARGET).vcd: $(TARGET)32.hex flashdata32.hex

CLEAN += flashdata32.hex sram.vcd

include $(BUILD_DIR)/bottom_rules.mk
