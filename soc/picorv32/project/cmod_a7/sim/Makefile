TARGET = system

all: $(TARGET).vcd

include ../common/common.mk

# max. baudrate is F_CLK / 8
BOOTLOADER_BAUDRATE = 8522727
VFLAGS += -DBOOTLOADER_BAUDRATE=$(BOOTLOADER_BAUDRATE)
#  -DMEMORY_PACK_FAST
# virtual SPI flash contents
VCD_ARGS += +firmware=$(PICORV_DIR)/test/memio/flashdata8.hex
CFLAGS += -DSIMULATION
SRC_V += system_tb.v sram_model.v spiflash.v
OBJS += 0x000.lds

$(TARGET).vcd: $(TARGET)32.hex
$(TARGET).elf: $(OBJS)
$(TARGET)_tb: $(SRC_V)

include $(BUILD_DIR)/bottom_rules.mk

.PRECIOUS: $(TARGET).vcd
