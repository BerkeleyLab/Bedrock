GATEWARE_DIR   = $(PICORV_DIR)/gateware
LIB_DIR        = $(PICORV_DIR)/firmware
PROJECT_DIR    = $(PICORV_DIR)/project
TEST_DIR       = $(PICORV_DIR)/test
COMMON_DIR     = $(PICORV_DIR)/common
LDLIBS         = -lgcc
INC_DIR        = -I$(LIB_DIR)/inc -I./ -I$(COMMON_DIR)

vpath %.v $(GATEWARE_DIR) $(DSP_DIR) $(FPGA_FAMILY_DIR)/xilinx
vpath %.S $(COMMON_DIR)
vpath %.lds $(COMMON_DIR)
vpath %.c $(LIB_DIR)/src

RISCV_TOOLS_PREFIX = riscv64-unknown-elf-
CC      = $(RISCV_TOOLS_PREFIX)gcc
AR      = $(RISCV_TOOLS_PREFIX)ar
VFLAGS  = -Wall -Wno-timescale -DBLOCK_RAM_SIZE=$(BLOCK_RAM_SIZE)
CCSPECS = -specs=picolibc.specs
CLFLAGS = -march=rv32imc -mabi=ilp32 -ffreestanding -DBLOCK_RAM_SIZE=$(BLOCK_RAM_SIZE) -nostartfiles $(CCSPECS)
CFLAGS  = -std=c99 -Os -Wall -Wextra -Wundef -Wstrict-prototypes $(CLFLAGS)
LDFLAGS = $(CLFLAGS) -Wl,--strip-debug,--print-memory-usage,-Bstatic,-Map,$*.map,--defsym,BLOCK_RAM_SIZE=$(BLOCK_RAM_SIZE),--gc-sections,--no-relax -T$(filter %.lds, $^)
# --no-relax is a workaround for https://github.com/riscvarchive/riscv-binutils-gdb/issues/144
# --verbose=3,-M for verbose linker output / debugging

%.lst: %.elf
	$(RISCV_TOOLS_PREFIX)objdump -d $< > $@

%.bin: %.elf
	$(RISCV_TOOLS_PREFIX)objcopy -O binary $< $@

%8.hex: %.elf
	$(RISCV_TOOLS_PREFIX)objcopy $< -O verilog $@

%32.hex: %8.hex
	$(PYTHON) $(COMMON_DIR)/hex8tohex32.py $< > $@

# for vivado in project mode, hex-files need to end with .dat
%32.dat: %32.hex
	cp $< $@

%_load: %32.hex
	$(PYTHON) $(COMMON_DIR)/boot_load.py $< $(BOOTLOADER_SERIAL) --baud_rate $(BOOTLOADER_BAUDRATE)

# All testbenches use $stop, eliminating the old `awk` dependency
%_check: %_tb
	$(VERILOG_SIM)

%.o: %.c
	$(CC) $(INC_DIR) $(CFLAGS) -o $@ -c $<

%.o: %.S
	$(CC) $(INC_DIR) $(CFLAGS) -o $@ -c $<

%.elf: %.o
	$(CC) $(LDFLAGS) -o $@ $(filter %.o, $^) $(LDLIBS)
	chmod -x $@

%_synth.bit: %.v
	$(VIVADO_CMD) -source $(filter %.tcl, $^) -tclargs $(basename $@) $(BLOCK_RAM_SIZE) $(filter %.v, $^)

# No serial number is provided in this rule, so it's only useful when
# a single FTDI device is plugged into your workstation
%_config: %.bit
	xc3sprog -c jtaghs1_fast $<

CLEAN += $(TARGET).vcd $(TARGET)_tb $(TARGET).map $(TARGET).lst  $(TARGET).elf pico.trace
CLEAN += $(TARGET)8.hex $(TARGET)32.hex $(TARGET)32.dat $(TARGET).o $(OBJS)
