include ../../../../dir_list.mk
include $(BUILD_DIR)/top_rules.mk
include $(PICORV_DIR)/rules.mk

vpath %.v $(PERIPH_DRIVERS_DIR)/ds1822

BLOCK_RAM_SIZE = 2048

SRC_V  = memory_pack.v mpack.v munpack.v picorv32.v pico_pack.v
SRC_V += sfr_pack.v gpio_pack.v gpioz_pack.v debug_console.v
OBJS   = startup.o onewire_soft.o print.o

# CFLAGS   += -ffunction-sections

TARGET = onewire

all: $(TARGET)_check

$(TARGET).elf: 0x000.lds $(OBJS)
$(TARGET)_tb: $(SRC_V) ds1822.v ds1822_state.v
$(TARGET).vcd $(TARGET)_check: $(TARGET)32.hex

include $(BUILD_DIR)/bottom_rules.mk
