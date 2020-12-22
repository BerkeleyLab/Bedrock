include ../../../../dir_list.mk
include $(BUILD_DIR)/top_rules.mk
include $(PICORV_DIR)/rules.mk
vpath system.v ..

# builds can use memory_pack.v or memory_pack2.v, depending on MEMORY_PACK_FAST
SRC_V += memory2_pack.v mpack.v munpack.v picorv32.v pico_pack.v
SRC_V += uart_pack.v uart_rx.v uart_tx.v sram_pack.v sram2_pack.v
SRC_V += system.v sfr_pack.v gpio_pack.v gpioz_pack.v

TARGET = sram
BLOCK_RAM_SIZE = 512
VFLAGS += -DMEMORY_PACK_FAST
SRC_V += sram_model.v
OBJS += startup.o

all: $(TARGET).vcd

$(TARGET).elf: 0x000.lds $(OBJS)
$(TARGET)_tb: $(SRC_V)
$(TARGET).vcd: $(TARGET)32.hex

include $(BUILD_DIR)/bottom_rules.mk
