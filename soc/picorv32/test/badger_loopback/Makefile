include ../../../../dir_list.mk
include $(BUILD_DIR)/top_rules.mk
include $(PICORV_DIR)/rules.mk

vpath %.v $(BADGER_DIR) $(DSP_DIR)
vpath %.c $(BADGER_DIR)/tests $(LIB_DIR)/src
vpath %.py $(BADGER_DIR)
vpath %.csv $(BADGER_DIR)

TARGET  = badger_lb
all: $(TARGET).vcd

#-------------------
# The picorv32soc
#-------------------
BLOCK_RAM_SIZE = 4096
SRC_V  += memory_pack.v mpack.v munpack.v picorv32.v pico_pack.v sfr_pack.v gpio_pack.v
OBJS   += startup.o print.o badger.o common.o

#-------------------
# The packet badger
#-------------------
# https://www.albinoblacksheep.com/flash/badgers
SRC_V += precog.v test_tx_mac.v
SRC_V += $(RTEFI_V) badger_pack.v
RTEFI_CLIENT_LIST = hello.v speed_test.v mem_gateway.v
CFLAGS += -ffunction-sections -fdata-sections

include $(BADGER_DIR)/rules.mk

$(TARGET).elf: 0x000.lds $(OBJS)
$(TARGET)_tb: $(SRC_V)
$(TARGET).vcd: $(TARGET)32.hex

CLEAN += $(OBJS) $(RTEFI_CLEAN)

include $(BUILD_DIR)/bottom_rules.mk

.PRECIOUS: $(TARGET).vcd
