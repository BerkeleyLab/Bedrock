include ../../../../dir_list.mk
include $(BUILD_DIR)/top_rules.mk
include $(PICORV_DIR)/rules.mk

BLOCK_RAM_SIZE = 256
SRC_V    = memory_pack.v mpack.v munpack.v picorv32.v pico_pack.v
SRC_V   += uart_pack.v uart_rx.v uart_tx.v
SRC_V   += stream_fifo.v shortfifo.v fifo.v uart_fifo_pack.v uart_stream.v
OBJS     = bootloader.o

TARGET = bootLoad

all: $(TARGET)_check

$(TARGET).elf: 0x0e0.lds $(OBJS)
$(TARGET)_tb: $(SRC_V)
$(TARGET).vcd $(TARGET)_check: $(TARGET)8.hex $(TARGET)32.hex _startup_adr.hex

_startup_adr.hex:
	$(RISCV_TOOLS_PREFIX)objdump -t bootLoad.elf | grep _startup_adr | sed "s/\\s.*$$//"  > _startup_adr.hex

CLEAN += _startup_adr.hex

include $(BUILD_DIR)/bottom_rules.mk
