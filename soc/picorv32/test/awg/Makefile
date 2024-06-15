include ../../../../dir_list.mk
include $(BUILD_DIR)/top_rules.mk
include $(PICORV_DIR)/rules.mk

BLOCK_RAM_SIZE = 512
SRC_V   = memory2_pack.v mpack.v munpack.v picorv32.v pico_pack.v sfr_pack.v
SRC_V  += awg_pack.v flag_xdomain.v dpram.v reg_tech_cdc.v
CFLAGS += -DSIMULATION
OBJS   += startup.o

TARGET  = awg

all: $(TARGET)_check

$(TARGET).elf: 0x000.lds $(OBJS)
$(TARGET)_tb: $(SRC_V)
$(TARGET).vcd $(TARGET)_check: $(TARGET)32.hex

include $(BUILD_DIR)/bottom_rules.mk
