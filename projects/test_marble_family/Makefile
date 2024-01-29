include ../../dir_list.mk
I2CBRIDGE_DIR = $(PERIPH_DRIVERS_DIR)/i2cbridge
include $(I2CBRIDGE_DIR)/i2cbridge_rules.mk
# Unisims not provided
UNISIMS_DIR = broken

# It seems like the variable VERILOG_TB from $(BUILD_DIR)/top_rules.mk is intended to be
# used for this exact recipe.  But other local additions to variables like "VERILOG" cause
# its expansion to now include multiple copies of the same flag/arg so it looks a little
# funny at the command line (doesn't seem to cause trouble).  This should be cleaned up.
# For now, redundantly inserting another "-DSIMULATE" here.
#$(VERILOG_TB)
%_tb: %_tb.v
	$(VERILOG) $(VFLAGS_$@) -DSIMULATE -o $@ $(filter %.v, $^)
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
VLATOR_LINT_IGNORE += -Wno-UNUSED -Wno-DECLFILENAME
YOSYS = yosys

# XXX consider converting this to something more compatible with Bedrock's VIVADO_SYNTH.
VIVADOEXEC = vivado
SYNTH_VIVADO = $(VIVADOEXEC) -mode batch -source

# =====
# Attention!!!!
vpath %.v $(BADGER_DIR)/tests $(HOMELESS_DIR) $(DSP_DIR) $(SERIAL_IO_DIR) $(I2CBRIDGE_DIR) $(PERIPH_DRIVERS_DIR) $(BOARD_SUPPORT_DIR)/marblemini $(HOMELESS_DIR)/freq_demo ./pps_lock ../../fpga_family/ds_clk_buf.v
vpath %.c $(BADGER_DIR)/tests $(BUILD_DIR)

# =====
# gets us $(FREQ_DEMO_V)
include $(HOMELESS_DIR)/freq_demo/freq_demo_rules.mk

# This must go in front of include $(BADGER_DIR)/rules.mk
all: lb_marble_slave_tb marble_base_tb no_multiple_drivers_check marble_base_lint

# =====
# gps_test, too simple to need testing ... right
gps_test_tb: gps_test.v simpleuart.v dpram.v

# Packet Badger synthesizable code
RTEFI_CLIENT_LIST = hello.v speed_test.v mem_gateway.v spi_flash.v
RTEFI_EXTRA_V = spi_flash_engine.v
include $(BADGER_DIR)/rules.mk

# =====
# auto-generated files
scalar_marble_regmap.json: lb_marble_slave.v
	$(PYTHON) $(BUILD_DIR)/reverse_json.py $< > $@
marble_regmap.json: static_regmap.json scalar_marble_regmap.json
	$(PYTHON) $(BUILD_DIR)/merge_json.py -o $@ -i $(filter %.json, $^)
config_romx.v: marble_regmap.json $(filter-out config_romx.v, $(MARBLE_SYNTH_SOURCE))
	$(PYTHON) $(BUILD_DIR)/build_rom.py --placeholder_rev -v $@ -j $< -d "Marble Testing"

# gen_features.py rules (note the use of PHONY targets)
# actual file outputs are marble_features_params.vh and marble_features_defs.vh
marble1_features: $(BUILD_DIR)/gen_features.py marble_features.yaml
	$(PYTHON) $< -i $(filter %.yaml, $^) -c marble_mini --split

marble2_features: $(BUILD_DIR)/gen_features.py marble_features.yaml
	$(PYTHON) $< -i $(filter %.yaml, $^) -c marble_v2 --split
.PHONY: marble1_features marble2_features

# ====
# tmds_test, requires access to unisims (or unisims_lrd)
tmds_test_tb: tmds_test.v
VFLAGS_tmds_test_tb = -y $(UNISIMS_DIR)

# =====
# VPI module support for live testing
# https://en.wikipedia.org/wiki/TUN/TAP
CFLAGS_udp-vpi.o = $(VPI_CFLAGS) -D_POSIX_C_SOURCE=200809L
CFLAGS_udp_model.o = $(VPI_CFLAGS)
udp-vpi.vpi: udp_model.o

# =====
# MMC mailbox self-checking testbench
mmc_mailbox_tb: mmc_mailbox.v $(HOMELESS_DIR)/fake_dpram.v $(DSP_DIR)/dpram.v $(BADGER_DIR)/tests/spi_gate.v $(PERIPH_DRIVERS_DIR)/spi_master.v

# =====
# subset that is interesting to test live on network
AD5662_V = ad5662_lock.v pps_lock.v pps_loop_filter.v ad5662.v
LB_MARBLE_SLAVE_V = lb_marble_slave.v dpram.v freq_count.v multi_counter.v config_romx.v $(I2CBRIDGE_V) $(AD5662_V) \
										gps_test.v simpleuart.v fake_dpram.v xadc_tempmon.v dna.v
lb_marble_slave_tb: $(LB_MARBLE_SLAVE_V) mem_gateway.v reg_delay.v client_sub.v i2c_slave_model.v udp-vpi.vpi
VFLAGS_lb_marble_slave_tb = -m ./udp-vpi
net_slave_run: lb_marble_slave_tb udp-vpi.vpi
	$(VVP) $< +udp_port=8030 +vcd

# =====
# Actual regression test of the above; tricky!
# Depends on UDP port 8030 not being tied up.
# It would be nice to have a "quiet" option to udp-vpi.
net_slave_check: lb_marble_slave_tb udp-vpi.vpi read_trx.dat
	$(VVP) $< +udp_port=8030 2>/dev/null & sleep 1 && $(PYTHON) testcase.py -a localhost -p 0 --sim --ramtest --stop --rlen=34

# syntax-check only, no actual test bench code
MARBLE_BASE_V = marble_base.v packet_categorize.v data_xdomain.v flag_xdomain.v $(RTEFI_V) activity.v base_rx_mac.v spi_gate.v mac_compat_dpram.v ctrace.v $(LB_MARBLE_SLAVE_V) $(FREQ_DEMO_V) mmc_mailbox.v

marble_base_tb: $(MARBLE_BASE_V)
VFLAGS_marble_base_tb =

.PHONY: no_multiple_drivers_check
no_multiple_drivers_check: marble_base_tb
	$(AWK) '$$NF=="drivers" && $$(NF-1)>1 {print $$0; code=1}BEGIN{code=0}END{exit(code)}' $<
	@echo "PASS"

marble_base_lint: $(MARBLE_BASE_V)
	$(VERILATOR) --lint-only -DSIMULATE $(VLATOR_LINT_IGNORE) $^

# You'd better have a verilator in the v5 series!
marble_top_lint: marble_top.v marble2_features $(MARBLE_BASE_V) $(FPGA_FAMILY_DIR)/ds_clk_buf.v $(SERIAL_IO_DIR)/gmii_to_rgmii.v
	$(VERILATOR) --lint-only --timing $(VLATOR_LINT_IGNORE) -DSIMULATE -y $(FPGA_FAMILY_DIR)/xilinx $(filter-out marble2_features, $^)

marble_base_yosys.json: marble_base_shell.v $(MARBLE_BASE_V) $(BUILD_DIR)/cdc_snitch_proc.ys
	$(YOSYS) --version
	$(YOSYS) -q -p "read_verilog -DBUGGY_FORLOOP $(filter %.v, $^); script $(filter %_proc.ys, $^); write_json $@"
# (I don't think yosys for-loop is actually buggy, just tediously slow, and in this case unnecessary)
marble_base_cdc.txt: $(BUILD_DIR)/cdc_snitch.py marble_base_yosys.json
	$(PYTHON) $^ -o $@

# =====
# constraint
pin_map_fmc.csv: pin_map_fmc.py
	$(PYTHON) $< > $@
marble1.xdc: $(BADGER_DIR)/tests/meta-xdc.py $(patsubst %,$(BOARD_SUPPORT_DIR)/marblemini/%, Marble.xdc pin_map.csv) pin_map_fmc.csv marble_mini_top.csv
	$(PYTHON) $^ > $@

marble2.xdc: $(BADGER_DIR)/tests/meta-xdc.py $(patsubst %,$(BOARD_SUPPORT_DIR)/marble/%, Marble.xdc pin_map.csv) pin_map_fmc.csv marble_top.csv
	$(PYTHON) $^ | sed -e '/FMC._.[AK]_/s/IOSTANDARD LVCMOS25/IOSTANDARD LVCMOS25 PULLTYPE PULLUP/' > $@

# =====
# Initialization file for i2cbridge
read_trx.dat: read_trx.py
	$(PYTHON) $< > $@

# Build a testbench with Verilator that can be put on the (simulated) network as 192.168.7.4
# marble_base.v is over in board_support/marblemini, but most of the infrastructure,
# including lb_marble_slave.v, is here.
Vmarble_base: $(MARBLE_BASE_V) marble_base_sim.cpp ethernet_model.c tap_alloc.c crc32.c
	rm -f ethernet_model.o tap_alloc.o crc32.o  # can't leave C version around for C++ to find
	$(VERILATOR) --trace-fst $(VLATOR_LINT_IGNORE) -DSIMULATE -cc --exe $^
	MAKEFLAGS="" make -C obj_dir -f Vmarble_base.mk USER_CPPFLAGS="-I $(BADGER_DIR)/tests"
	mv obj_dir/$@ $@
# Recipe:
#  make Vmarble_base read_trx.dat && ./Vmarble_base +trace
#  ping -c 2 192.168.7.4; python3 lbus_access.py -a 192.168.7.4 -t 3 mem 2097200:8; python3 lbus_access.py -a 192.168.7.4 -t 3 reg 327686=1
#  gtkwave marble_base_sim.vcd marble_base_sim.gtkw

# =====
# bitfile
MARBLE_SYNTH_SOURCE = marble_top.v tmds_test.v marble/gmii_clock_handle.v $(FPGA_FAMILY_DIR)/xilinx/xilinx7_clocks.v gmii_to_rgmii.v $(MARBLE_BASE_V) read_trx.dat ../../fpga_family/ds_clk_buf.v
# MARBLE_SYNTH_SOURCE += scrap_dev.v
marble1.d: $(MARBLE_SYNTH_SOURCE) marble1.xdc
	echo $^ | tr ' ' '\n' > $@

marble1.bit: marble.tcl marble1.d marble1_features bit_stamp_mod
	$(SYNTH_VIVADO) $< -tclargs $(filter %.d, $^) marble1 $(BUILD_DIR)/vivado_tcl/swap_gitid.tcl
	G=marble1.$$(git rev-parse --short=8 --verify HEAD); if git diff | grep -q .; then echo "modified code; not coercing bitfile header timestamp"; mv $$G.x.bit $$G.bit; else ./bit_stamp_mod -s $$(git log -1 --pretty=%ct) $$G.bit < $$G.x.bit && rm $$G.x.bit && sha256sum $$G.bit; fi

marble2.d: $(MARBLE_SYNTH_SOURCE) marble2.xdc
	echo $^ | tr ' ' '\n' > $@

marble2.bit: marble.tcl marble2.d marble2_features bit_stamp_mod
	$(SYNTH_VIVADO) $< -tclargs $(filter %.d, $^) marble2 $(BUILD_DIR)/vivado_tcl/swap_gitid.tcl
	G=marble2.$$(git describe --always --abbrev=8 --dirty); if test $${G%-dirty} != $${G}; then echo "modified code; not coercing bitfile header timestamp"; mv $$G.x.bit $$G.bit; else ./bit_stamp_mod -s $$(git log -1 --pretty=%ct) $$G.bit < $$G.x.bit && rm $$G.x.bit && sha256sum $$G.bit; fi

# =====
# bitfile loading and testing; bitfile specified by doing 'make BIT=marble1.bit marble1_hwload'

# Default IP address set from microcontroller
RGMII_IP = 192.168.19.31
BIT = marble1.bit

# add the Marble serial number
marble1_hwload:
	openocd -f serial.cfg -f marble.cfg -c "transport select jtag; init; xc7_program xc7.tap; pld load 0 ${BIT}; exit"

marble1_hwtest: udprtx
	ping -c 2 ${RGMII_IP}
	test $$(PYTHONPATH=../common $(PYTHON) -m leep.cli leep://${RGMII_IP}:803 gitid) = $$(git rev-parse HEAD) && echo "gitid OK"
	./udprtx ${RGMII_IP} 100000 8  # should take under 3 seconds
	$(PYTHON) testcase.py -a ${RGMII_IP} --trx --marble 0


# =====
# Marble bitfile loading and testing; bitfile specified by doing 'make BIT=marble2.bit marble2_hwload'

# Default IP address set from microcontroller
SERIAL = ""
MARBLE_IP = 192.168.19.${SERIAL}
BIT2 = marble2.bit
# Stored in the Zest board installed on mohs CI test stand; here, we just check that we can read it
ZEST_SN = "LBNL DIGITIZER V1.0 SN  024"

marble2_hwload:
	@echo "Using Marble with serial number ${SERIAL}"
	openocd -c "adapter driver ftdi; ftdi_serial 0000${SERIAL};" -f marble.cfg -c "transport select jtag; init; xc7_program xc7.tap; pld load 0 ${BIT2}; exit"

marble2_hwtest: udprtx
	ping -c 2 ${MARBLE_IP}
	test $$(PYTHONPATH=../common $(PYTHON) -m leep.cli leep://${MARBLE_IP}:803 gitid) = $$(git rev-parse HEAD) && echo "gitid OK"
	./udprtx ${MARBLE_IP} 100000 8  # should take under 3 seconds
	$(PYTHON) testcase.py -a ${MARBLE_IP} --trx --si570
	sn="$$($(PYTHON) zest_sn.py -a ${MARBLE_IP} -p 803)" && echo "$$sn" && test "$$sn" = ${ZEST_SN}

clean:
	rm -f $(RTEFI_CLEAN) *_tb *.d *.o *.vpi *.vcd *.pyc i2cbridge/*.pyc
	rm -f pin_map_fmc.csv marble*.xdc marble*.bit marble*.vh marble*.json vivado*
	rm -f scalar_marble_regmap.json marble_regmap.json config_romx.v
	rm -f read_trx.dat Vmarble_base bit_stamp_mod udprtx marble_base_cdc.txt
	rm -rf _xilinx .Xil obj_dir __pycache__
