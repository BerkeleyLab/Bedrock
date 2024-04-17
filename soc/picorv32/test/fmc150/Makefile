include ../../../../dir_list.mk
include $(BUILD_DIR)/top_rules.mk
include $(PICORV_DIR)/rules.mk
vpath %.c $(BOARD_SUPPORT_DIR)/fmc150/firmware
vpath %.v $(FPGA_FAMILY_DIR)/xilinx $(BOARD_SUPPORT_DIR)/fmc150 $(DSP_DIR)

BLOCK_RAM_SIZE = 1024
SRC_V   = memory_pack.v mpack.v munpack.v picorv32.v pico_pack.v
SRC_V  += idelays_pack.v ads62.v freq_count.v freq_gcount.v
SRC_V  += BUFG.v IBUFDS.v IDDR.v IDELAYE2.v IDELAYCTRL.v
SRC_V  += sfr_pack.v gpio_pack.v
OBJS   = startup.o timer.o

CFLAGS += -DSIMULATION -I$(BOARD_SUPPORT_DIR)/fmc150/firmware
VFLAGS += -DSIMULATE

TARGET  = fmc150

all: $(TARGET)_check

$(TARGET).elf: 0x000.lds $(OBJS)
$(TARGET)_tb: $(SRC_V)
$(TARGET).vcd $(TARGET)_check: $(TARGET)32.hex

include $(BUILD_DIR)/bottom_rules.mk
