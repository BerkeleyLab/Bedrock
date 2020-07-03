include ../../../../dir_list.mk
include $(BUILD_DIR)/top_rules.mk
include $(PICORV_DIR)/rules.mk

BLOCK_RAM_SIZE = 4096

SRC_V  = memory_pack.v mpack.v munpack.v picorv32.v pico_pack.v
SRC_V += sfr_pack.v gpio_pack.v gpioz_pack.v I2C_model.v
OBJS   = startup.o timer.o i2c_soft.o print.o

# CFLAGS   += -ffunction-sections

TARGET = i2c

all: $(TARGET)_check

$(TARGET).elf: 0x000.lds $(OBJS)
$(TARGET)_tb: $(SRC_V)
$(TARGET).vcd $(TARGET)_check: $(TARGET)32.hex

include $(BUILD_DIR)/bottom_rules.mk
