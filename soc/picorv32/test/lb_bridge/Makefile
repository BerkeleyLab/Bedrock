include ../../../../dir_list.mk
include $(BUILD_DIR)/top_rules.mk
include $(PICORV_DIR)/rules.mk

SRC_V    = memory_pack.v mpack.v munpack.v picorv32.v pico_pack.v lb_bridge_tb.v lb_bridge.v lb_merge.v lb_reading.v
BLOCK_RAM_SIZE = 128
TARGET   = lb_bridge

all: $(TARGET)_check

$(TARGET).elf: 0x000.lds
$(TARGET)_tb: $(SRC_V)
$(TARGET)_check $(TARGET).vcd: $(TARGET)32.hex

include $(BUILD_DIR)/bottom_rules.mk
