# Try some of these:
# make clean system.vcd
# make clean system_view
# make clean system_synth.bit

include ../../../../dir_list.mk
include $(BUILD_DIR)/top_rules.mk
include $(PICORV_DIR)/rules.mk

BOOTLOADER_SERIAL = /dev/ttyUSB1
BOOTLOADER_BAUDRATE = 115200

COMMON_V  = picorv32.v system.v uart_pack.v uart_rx.v uart_tx.v mpack.v munpack.v pico_pack.v
COMMON_V += memory_pack.v memory2_pack.v
COMMON_V += stream_fifo.v shortfifo.v uart_fifo_pack.v uart_stream.v
COMMON_V += sfr_pack.v gpio_pack.v gpioz_pack.v
COMMON_V += pb_debouncer.v
SIM_V     = system_tb.v $(COMMON_V)
SYNTH_V   = top.v xilinx7/xilinx7_clocks.v $(COMMON_V)

TARGET    = system
SRCS      = system.c print.c timer.c test.c common.c
OBJS      = $(subst .c,.o,$(SRCS)) startup_irq.o bootloader.o

#size of the blockRam [bytes]
BLOCK_RAM_SIZE = 16384
CFLAGS   += -DGIT_VERSION=\"$(GIT_VERSION)\" -DBOOTLOADER_BAUDRATE=$(BOOTLOADER_BAUDRATE)
CFLAGS   += -ffunction-sections
VFLAGS   += -DMEMORY_PACK_FAST

all: $(TARGET)_synth.bit

$(TARGET)_synth.bit: $(TARGET)_synth.tcl top.xdc $(SYNTH_V) system32.hex
$(TARGET).elf: $(OBJS) 0x0e0.lds

$(TARGET)_tb: $(COMMON_V) $(SIM_V)
$(TARGET).vcd: $(TARGET)32.hex

# Only add the SIMULATION flag if target is simulation
$(TARGET)_tb: VFLAGS += -DSIMULATE
$(TARGET).vcd: CFLAGS += -DSIMULATION


.PRECIOUS: $(TARGET).vcd

CLEAN += $(TARGET)_synth.v xvhdl.log xvhdl.pb xvlog.log xelab.log xvlog.pb usage_statistics_webtalk.*
CLEAN += xelab.pb xsim*.jou xsim*.log webtalk*.jou webtalk*.log vivado.log
CLEAN += $(TARGET)_synth.bit
CLEAN_DIRS += xsim.dir .Xil

include $(BUILD_DIR)/bottom_rules.mk
