TARGET = system

all: $(TARGET).vcd

include ../common/common.mk

# max. baudrate is F_CLK / 8
BOOTLOADER_BAUDRATE = 10416666
VFLAGS += -DMEMORY_PACK_FAST -DBOOTLOADER_BAUDRATE=$(BOOTLOADER_BAUDRATE)
CFLAGS += -DSIMULATION
SRC_V += system_tb.v sram_model.v
OBJS += 0x000.lds

$(TARGET).vcd: $(TARGET)32.hex
$(TARGET).elf: $(OBJS)
$(TARGET)_tb: $(SRC_V)

include $(BUILD_DIR)/bottom_rules.mk
