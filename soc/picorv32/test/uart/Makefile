include ../../../../dir_list.mk
include $(BUILD_DIR)/top_rules.mk
include $(PICORV_DIR)/rules.mk

SRC_V  = uart_tx.v uart_rx.v frame_gen.v frame_check.v
SRC_V += stream_fifo.v shortfifo.v fifo.v

TARGET = uart

all: $(TARGET)_check

$(TARGET)_tb: $(SRC_V)

include $(BUILD_DIR)/bottom_rules.mk
