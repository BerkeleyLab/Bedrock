include ../../../../dir_list.mk
include $(BUILD_DIR)/top_rules.mk
include $(PICORV_DIR)/rules.mk

BLOCK_RAM_SIZE = 128
SRC_V  = mpack.v munpack.v

TARGET = mpack

all: $(TARGET)_check

$(TARGET)_tb: $(SRC_V)

include $(BUILD_DIR)/bottom_rules.mk
