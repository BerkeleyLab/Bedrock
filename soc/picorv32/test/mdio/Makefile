include ../../../../dir_list.mk
include $(BUILD_DIR)/top_rules.mk
include $(PICORV_DIR)/rules.mk

MEM_SIZE = 4096

SRC_V  = memory_pack.v mpack.v munpack.v picorv32.v pico_pack.v
SRC_V += sfr_pack.v gpio_pack.v gpioz_pack.v
SRC_V += mdio_slave.v
#OBJS   = $(COMMON_DIR)/startup.o $(LIB_DIR)/src/timer.o $(LIB_DIR)/src/mdio.o $(LIB_DIR)/src/print.o
OBJS   = startup.o timer.o mdio.o print.o mdio_soft.o

# CFLAGS   += -ffunction-sections

TARGET = mdio

all: $(TARGET)_check

$(TARGET).elf: 0x000.lds $(OBJS)
$(TARGET)_tb: $(SRC_V)
$(TARGET).vcd $(TARGET)_check: $(TARGET)32.hex

include $(BUILD_DIR)/bottom_rules.mk
