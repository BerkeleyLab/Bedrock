include ../../dir_list.mk
I2CBRIDGE_DIR = $(PERIPH_DRIVERS_DIR)/i2cbridge

%_tb: %_tb.v
	$(VERILOG) $(VFLAGS_$@) -o $@ $(filter %.v, $^)
%_check: %_tb
	$(VVP) $< $(VVP_FLAGS)

# =====
# Possibly common setup / configuration
include $(BUILD_DIR)/top_rules.mk

# Local overrides of default variables
VERILOG += -Wno-timescale
# VERILOG += -g2005-sv
# Configuration not covered (yet?) by Bedrock's top_rules.mk
VCD_ARGS = $(VCD_ARGS_$@)

# XXX consider converting this to something more compatible with Bedrock's VIVADO_SYNTH.
VIVADOEXEC = vivado
SYNTH_VIVADO = $(VIVADOEXEC) -mode batch -source

# =====
# Attention!!!!
vpath %.v $(BADGER_DIR)/tests $(HOMELESS_DIR) $(DSP_DIR) $(SERIAL_IO_DIR) $(I2CBRIDGE_DIR) $(PERIPH_DRIVERS_DIR) $(BOARD_SUPPORT_DIR)/marblemini
vpath %.c $(BADGER_DIR)/tests
vpath %.xdc $(BOARD_SUPPORT_DIR)/marblemini

# This must go in front of include $(BADGER_DIR)/rules.mk
all: lb_marble_slave_tb marble_base_tb no_multiple_drivers_check

# Packet Badger synthesizable code
RTEFI_CLIENT_LIST = hello.v speed_test.v mem_gateway.v spi_flash.v
RTEFI_EXTRA_V = spi_flash_engine.v
include $(BADGER_DIR)/rules.mk

I2CBRIDGE_V = i2c_chunk.v i2c_prog.v i2c_bit.v i2c_analyze.v dpram.v

# =====
# auto-generated files
scalar_marble_regmap.json: lb_marble_slave.v
	$(PYTHON) $(BUILD_DIR)/reverse_json.py $< > $@
marble_regmap.json: static_regmap.json scalar_marble_regmap.json
	$(PYTHON) $(BUILD_DIR)/merge_json.py -o $@ -i $(filter %.json, $^)
config_romx.v: marble_regmap.json $(filter-out config_romx.v, $(MARBLE_SYNTH_SOURCE))
	$(PYTHON) $(BUILD_DIR)/build_rom.py -v $@ -j $< -d "Marble Testing"

# =====
# VPI module support for live testing
# https://en.wikipedia.org/wiki/TUN/TAP
CFLAGS_udp-vpi.o = $(VPI_CFLAGS) -D_POSIX_C_SOURCE=200809L
CFLAGS_udp_model.o = $(VPI_CFLAGS)
udp-vpi.vpi: udp_model.o

# =====
# subset that is interesting to test live on network
LB_MARBLE_SLAVE_V = lb_marble_slave.v dpram.v freq_count.v config_romx.v $(I2CBRIDGE_V) ad5662.v
lb_marble_slave_tb: $(LB_MARBLE_SLAVE_V) mem_gateway.v reg_delay.v client_sub.v i2c_slave_model.v
VFLAGS_lb_marble_slave_tb = -DUSE_I2CBRIDGE -m ./udp-vpi
net_slave_run: lb_marble_slave_tb udp-vpi.vpi
	$(VVP) $< +udp_port=8030 +vcd

# =====
# Actual regression test of the above; tricky!
# Depends on UDP port 8030 not being tied up.
# It would be nice to have a "quiet" option to udp-vpi.
net_slave_check: lb_marble_slave_tb udp-vpi.vpi
	$(VVP) $< +udp_port=8030 2>/dev/null & sleep 1 && $(PYTHON) testcase.py --sim --ramtest --stop --rlen=34

# =====
# syntax-check only, no actual test bench code
MARBLE_BASE_V = marble_base.v $(RTEFI_V) activity.v base_rx_mac.v spi_gate.v mac_compat_dpram.v ctrace.v $(LB_MARBLE_SLAVE_V)
marble_base_tb: $(MARBLE_BASE_V)
VFLAGS_marble_base_tb = -DUSE_I2CBRIDGE -DMMC_CTRACE

.PHONY: no_multiple_drivers_check
no_multiple_drivers_check: marble_base_tb
	$(AWK) '$$NF=="drivers" && $$(NF-1)>1 {print $$0; code=1}BEGIN{code=0}END{exit(code)}' $<
	@echo PASS

# =====
# constraint
pin_map_fmc.csv: pin_map_fmc.py
	$(PYTHON) $< > $@
marble1.xdc: $(BADGER_DIR)/tests/meta-xdc.py Marble.xdc pin_map.csv pin_map_fmc.csv
	$(PYTHON) $^ > $@

# =====
# bitfile
MARBLE_SYNTH_SOURCE = marble1.v marble/gmii_clock_handle.v kc705/xilinx7_clocks.v gmii_to_rgmii.v $(MARBLE_BASE_V) marble1.xdc
marble1.d: $(MARBLE_SYNTH_SOURCE)
	echo $^ | tr ' ' '\n' > $@
marble1.bit: marble1.tcl marble1.d $(MARBLE_SYNTH_SOURCE)
	$(SYNTH_VIVADO) $<
	mv _xilinx/marble1.runs/impl_1/marble1.bit $@

clean:
	rm -f $(RTEFI_CLEAN) *_tb *.d *.o *.vpi *.vcd *.pyc i2cbridge/*.pyc
	rm -f pin_map_fmc.csv marble1.xdc marble1.bit vivado* datasheet.txt
	rm -f scalar_marble_regmap.json marble_regmap.json config_romx.v
	rm -rf _xilinx .Xil
