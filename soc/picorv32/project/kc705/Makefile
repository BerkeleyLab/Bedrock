include ../../../../dir_list.mk
include $(BUILD_DIR)/top_rules.mk
include $(PICORV_DIR)/rules.mk

#size of the blockRam [bytes]
BLOCK_RAM_SIZE = 8192
BOOTLOADER_SERIAL = /dev/ttyUSB1
BOOTLOADER_BAUDRATE = 115200
TARGET     = system

# Define Verilog sources here
COMMON_V  = picorv32.v system.v uart_pack.v uart_rx.v uart_tx.v mpack.v munpack.v pico_pack.v
COMMON_V += memory_pack.v memory2_pack.v
COMMON_V += pb_debouncer.v
COMMON_V += sfr_pack.v gpio_pack.v gpioz_pack.v
COMMON_V += lb_bridge.v lb_merge.v lb_reading.v xadc_mon.v dpram.v
SYNTH_V   = $(COMMON_V) top.v xilinx7_clocks.v
SIM_V     = $(COMMON_V) i2c_slave.v

# Define C sources here
SRCS      =  system.c print.c i2c_soft.c timer.c lcd.c
OBJS      =  $(subst .c,.o,$(SRCS)) startup.o bootloader.o

# Verilog / C flags for compiler, assembler, linker and simulator
# Note: flags for the synthesizer need to be defined in system_synth.tcl
# CFLAGS   += -Os -march=rv32imc
# -ffunction-sections -fdata-sections
CFLAGS += -DBOOTLOADER_BAUDRATE=$(BOOTLOADER_BAUDRATE)

all: $(TARGET)_synth.bit

$(TARGET)_synth.bit: $(TARGET)_synth.tcl top.xdc $(SYNTH_V) system32.hex
$(TARGET).elf: $(OBJS) 0x0e0.lds

$(TARGET)_tb:  $(SIM_V)
$(TARGET).vcd: $(TARGET)32.hex

# Only add the SIMULATION flag if target is simulation
$(TARGET)_tb: VFLAGS += -DSIMULATE
$(TARGET).vcd: CFLAGS += -DSIMULATION

CLEAN += $(TARGET)_synth.v xvhdl.log xvhdl.pb xvlog.log xelab.log xvlog.pb usage_statistics_webtalk.*
CLEAN += xelab.pb xsim*.jou xsim*.log webtalk*.jou webtalk*.log vivado.log
CLEAN += $(TARGET)_synth.bit
CLEAN_DIRS += xsim.dir .Xil

include $(BUILD_DIR)/bottom_rules.mk
