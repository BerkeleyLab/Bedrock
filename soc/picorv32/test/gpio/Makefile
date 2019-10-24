include ../../../../dir_list.mk
include $(BUILD_DIR)/top_rules.mk
include $(PICORV_DIR)/rules.mk

TARGET  = gpio
BLOCK_RAM_SIZE = 512
CFLAGS += -DSIMULATION
SRC_V += memory2_pack.v mpack.v munpack.v picorv32.v pico_pack.v
SRC_V += gpio_pack.v sfr_pack.v

all: $(TARGET)_check

$(TARGET).vcd $(TARGET)_check: $(TARGET)32.hex
$(TARGET).elf: $(COMMON_DIR)/0x000.lds startup.o
$(TARGET)_tb: $(SRC_V)

CLEAN += startup.o

include $(BUILD_DIR)/bottom_rules.mk
