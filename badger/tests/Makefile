# Plea to future developers:  this is a single coherent code base;
# don't split it up into excessive directories, makefiles, and/or repositories!
# That will only make everything less direct and less comprehensible.
# As evidence I point you to the three 2018-era gitlab.lbl.gov repositories
# and five directories required to accomplish the tasks in scope here.
# Down that path lies madness!  Confusion is the enemy!

# =====
BUILD_DIR = .
BADGER_DIR = ..
HOMELESS_DIR = local
SERIAL_IO_DIR = local
# Hope this only does something when part of Bedrock
-include ../../dir_list.mk

# =====
# These overrides go _before_ top_rules.mk
%_check: %.out %.gold
	cmp $^
	@echo "PASS"
%_check: %_tb
	$(VVP) $< $(VCD_ARGS_$@)
%_tb: %_tb.v
	$(VERILOG) $(VFLAGS_$@) -o $@ $(filter %.v, $^)
%-vpi.vpi: %-vpi.o
	$(VERILOG_VPI) $^

# =====
# Possibly common setup / configuration
include $(BUILD_DIR)/top_rules.mk

# Local overrides of default variables
VERILOG += -Wno-timescale -DSIMULATE

# We're 99% integrated into bedrock's verilator workflow
VLATOR_LINT_IGNORE += -Wno-UNUSED -Wno-DECLFILENAME

# Configuration not covered (yet?) by Bedrock's top_rules.mk
VCD_ARGS = $(VCD_ARGS_$@)
VVP_FLAGS = ${VVP_FLAGS_$@} ${VCD_ARGS_$@}
XCIRCUIT = xcircuit
# XXX consider converting this to something more compatible with Bedrock's VIVADO_SYNTH.
VIVADOEXEC = vivado
SYNTH_VIVADO = $(VIVADOEXEC) -mode batch -source
# apt-get install xvfb
# Normally OK to blank out XVFB if you don't have xvfb-run and don't mind pop-ups.
# Plus, it's only used in one maintainer-mode target below.
XVFB = xvfb-run -a -s "-screen 0 1440x900x24"

# used for size and speed measurements, not actual hardware
%.bit: %.v
	arch=s6 $(ISE_SYNTH) $(notdir $(basename $<)) $^
	mv _xilinx/$@ $@

# =====
# Attention!!!!
vpath %.v $(DSP_DIR) $(HOMELESS_DIR) $(SERIAL_IO_DIR)
vpath %.eps ..

all: crc_selfcheck_check derive_check crc8e_guts_check udp_port_cam_check
all: scanner_check hack_icmp_cksum_check rtefi_pipe_check hw_test_tb
all: hello_check speed_test_check mem_gateway_check spi_flash_check
all: Vrtefi_blob Vhw_test Vmem_gateway_check Vcluster udprtx
all: test_tx_check precog_check mac_subset_check
all: sp605_gmii_test_tb kc705_gmii_test_tb ac701_rgmii_test_tb badge_trace_tb
all: rtefi_live lb_timing_demo.vcd cluster_run_check
# all: lb_timing_demo.pdf

# Packet Badger synthesizable code
RTEFI_CLIENT_LIST = hello.v speed_test.v mem_gateway.v spi_flash.v
RTEFI_EXTRA_V = spi_flash_engine.v
include ../rules.mk

# =====
# CRC32 code verification
# These foo3.dat files are not currently used by the main test benches,
# but generate them anyway so we can cross-check our various CRC implementations
%3.dat: packetgen.py
	$(PYTHON) $< $* > $@
crc_selfcheck_check: crc_selfcheck udp3.dat arp3.dat icmp3.dat udp4.dat
	./$< $(word 2, $^)
	./$< $(word 3, $^)
	./$< $(word 4, $^)
	./$< $(word 5, $^)

crc_selfcheck: crc_selfcheck.o crc32.o

derive_tb: crc_genguts.vh

crc_genguts.vh: crc_derive
	./$< 16 0x1021 32 > $@

crc8e_guts.vh: crc_derive
	./$< -lsb 32 0x04C11DB7 8 > $@

# New feature compared to PSPEPS: no include file (or path) needed!
# crc8e_guts.v is pre-filled in.  The following steps give its derivation
# and cross-check, but non-developers don't have to hassle with it.
# It's true that crc8e_guts.v is a non-source file that's checked into
# version control, but the alternatives have proven worse.
crc8e_guts_y.v: crc8e_guts_x.v crc8e_guts.vh
	$(VERILOG) -E -o $@ $<

crc8e_guts_check: crc8e_guts_y.v crc8e_guts.v
	cmp $^
	@echo "PASS"

# =====
# pcap2v for using pcap files; not part of the main testing path,
# and therefore not part of the default build.
# apt-get install libpcap-dev
pcap2v: crc32.o
CFLAGS_pcap2v = -D_DEFAULT_SOURCE
LDLIBS_pcap2v = -l pcap

# =====
# VPI module support for live testing
# https://en.wikipedia.org/wiki/TUN/TAP
CFLAGS_tap-vpi.o = $(VPI_CFLAGS) -D_POSIX_C_SOURCE=200809L
tap-vpi.vpi: ethernet_model.o tap_alloc.o crc32.o
CFLAGS_udp-vpi.o = $(VPI_CFLAGS) -D_POSIX_C_SOURCE=200809L
udp-vpi.vpi: udp_model.c

# =====
# Components
hack_icmp_cksum_tb: hack_icmp_cksum.v
udp_port_cam_tb: udp_port_cam.v
badge_trace_tb: badge_trace.v

# =====
xfer1: xfer1.readable
	tr ' ' '\n' < $< > $@

# =====
# Tangent for client testing
hello_tb: hello.v client_sub.v reg_delay.v udp-vpi.vpi
VFLAGS_hello_tb = -m ./udp-vpi
hello.vcd: udp-vpi.vpi xfer1
hello_run: hello_tb udp-vpi.vpi
	$(VVP) $< +udp_port=3010 +vcd
hello.out: hello_tb udp-vpi.vpi xfer1
	$(VVP) $< +log +packet_file=$(filter %xfer1, $^) > $@

# =====
# Another tangent for another client
speed_test_tb: speed_test.v client_sub.v reg_delay.v udp-vpi.vpi
VFLAGS_speed_test_tb = -m ./udp-vpi
speed_test.vcd: udp-vpi.vpi xfer1
speed_test_run: speed_test_tb udp-vpi.vpi
	$(VVP) $< +udp_port=3000 +vcd
speed_test.out: speed_test_tb udp-vpi.vpi xfer1
	$(VVP) $< +log +packet_file=$(filter %xfer1, $^) > $@

# =====
# Another tangent for another client
LB_DEMO_V = lb_demo_slave.v freq_count.v freq_gcount.v fake_config_romx.v reg_tech_cdc.v dpram.v multi_counter.v
# LB_DEMO_V += badge_trace.v
mem_gateway_tb: mem_gateway.v client_sub.v reg_delay.v $(LB_DEMO_V) udp-vpi.vpi
VFLAGS_mem_gateway_tb = -m ./udp-vpi
mem_gateway.vcd: udp-vpi.vpi xfer1
mem_gateway_run: mem_gateway_tb udp-vpi.vpi
	$(VVP) $< +udp_port=3000 +vcd
mem_gateway.out: mem_gateway_tb udp-vpi.vpi xfer1
	$(VVP) $< +log +packet_file=$(filter %xfer1, $^) > $@

# ====
# WIP client supporting SPI Flash
spi_flash_tb: spiflash.v client_sub.v spi_flash.v spi_flash_engine.v reg_delay.v udp-vpi.vpi
VFLAGS_spi_flash_tb = -m ./udp-vpi
spi_flash.vcd: udp-vpi.vpi spi_flash_pack lorem_ipsum.hex
lorem_ipsum.hex: hexdump.py lorem_ipsum.txt
	$(PYTHON) $^ > $@
VCD_ARGS_spi_flash.vcd = +packet_file=$(filter %spi_flash_pack, $^) +data_len=265 +firmware=$(filter %lorem_ipsum.hex, $^)
spi_flash.out: spi_flash_tb udp-vpi.vpi spi_flash_pack lorem_ipsum.hex
	$(VVP) $< +log $(VCD_ARGS_spi_flash.vcd) > $@
spi_flash.grab: spi_flash_check.sh udp-vpi.vpi spi_flash_tb lorem_ipsum.hex spi_test.py
	bash $< $(filter %spi_test.py, $^)
spi_flash_check: spi_flash.grab lorem_ipsum.txt
	cmp $^
	@echo "PASS"

# =====
# scanner off-line test
scanner_tb: offline.v scanner.v ones_chksum.v udp_port_cam.v reg_tech_cdc.v crc8e_guts.v
stests.dat: packetgen.py
	$(PYTHON) $< > $@
scanner.vcd: stests.dat
scanner_check: stests.dat
VCD_ARGS_scanner.vcd = +packet_file=stests.dat
VCD_ARGS_scanner_check = +packet_file=stests.dat

# =====
# assembled pipeline
rtefi_pipe_tb: $(RTEFI_V) fake_config_romx.v offline.v mac_compat_dpram.v
rtefi_pipe.out: rtefi_pipe_tb udp4.dat
	$(VVP) $< +trace +packet_file=$(filter %udp4.dat, $^) > $@
rtefi_pipe.vcd: udp4.dat
VCD_ARGS_rtefi_pipe.vcd = +packet_file=$(filter %udp4.dat, $^)

# =====
# unified version of assembled pipeline and test peripherals,
# configured for on-line (tap) testing

HW_TEST_V = hw_test.v $(RTEFI_V) mac_compat_dpram.v activity.v base_rx_mac.v packet_categorize.v data_xdomain.v flag_xdomain.v $(LB_DEMO_V) spi_gate.v
hw_test_tb: $(HW_TEST_V) tap-vpi.vpi
VFLAGS_hw_test_tb = -m ./tap-vpi
hw_test.vcd: tap-vpi.vpi
.PRECIOUS: hw_test.vcd  # work-around; better if vvp could exit with success
hw_test_start: hw_test_tb tap-vpi.vpi
	$(VVP) $<

# =====
# check of basic CDC-correctness
hw_test_yosys.json: hw_test_skin.v $(HW_TEST_V)
# exercise with make hw_test_cdc.txt

# =====
# experimental bitfiles, not for hardware
# summarizes fabric footprints based on XST synthesizing for Spartan-6
bits: scanner.bit construct.bit xformer.bit ethernet_crc_add.bit udp_port_cam_wrap.bit rtefi_blob.bit
	cd _xilinx && for f in $(basename $^); do echo $$f; grep "Slice LUT" $${f}_map.mrp; done
scanner.bit: ones_chksum.v udp_port_cam.v crc8e_guts.v reg_tech_cdc.v
construct.bit: ones_chksum.v construct_tx_table.v
xformer.bit: hack_icmp_cksum.v reg_delay.v
ethernet_crc_add.bit: crc8e_guts.v
udp_port_cam_wrap.bit: udp_port_cam.v
rtefi_blob.bit: $(RTEFI_V)

# =====
# Make a bitfile for an SP605 with Xilinx XST
# first just a syntax check (sp605_gmii_test.v is empty)
SYNTH_SOURCE_SP605 = gmii_hw_test.v $(HW_TEST_V) sp605/gmii_clock_handle.v sp605/spartan6_clocks.v
sp605_gmii_test_tb: $(SYNTH_SOURCE_SP605) sp605/ODDR2.v
sp605_gmii_test.bit: $(SYNTH_SOURCE_SP605) sp605/sp605_gmii.ucf
	PART=xc6slx45t-fgg484-3 $(ISE_SYNTH) $(notdir $(basename $<)) $^
	mv _xilinx/gmii_hw_test.bit $@
sp605_gmii_test_iobs: sp605_gmii_test.bit
	grep -E "LOCATED|Direction" _xilinx/sp605_gmii_test_pad.txt | $(AWK) -F "|" '/GMII/{if (1) print $$3, $$6, $$12, $$14, $$15}' | sort

# =====
# Make a bitfile for a KC705 with Xilinx Vivado
# first just a syntax check (kc705_gmii_test.v is empty)
SYNTH_SOURCE_KC705 = gmii_hw_test.v $(HW_TEST_V) kc705/gmii_clock_handle.v $(FPGA_FAMILY_DIR)/xilinx/xilinx7_clocks.v
kc705_gmii_test_tb: $(SYNTH_SOURCE_KC705) kc705/ODDR.v kc705/BUFG.v kc705/IBUFGDS.v kc705/MMCME2_BASE.v
kc705_gmii_test.d: $(SYNTH_SOURCE_KC705) kc705/kc705_gmii.xdc
	echo $^ | tr ' ' '\n' > $@
kc705_gmii_test.bit: kc705_gmii_test.tcl kc705_gmii_test.d badger.tcl $(SYNTH_SOURCE_KC705) kc705/kc705_gmii.xdc
	$(SYNTH_VIVADO) $<
	mv _xilinx/kc705_gmii_test.runs/impl_1/gmii_hw_test.bit $@

# =====
# Make bitfiles for AC701 with both Xilinx XST and Xilinx Vivado
# first just a syntax check (ac701_rgmii_test.v is empty)
SYNTH_SOURCE_AC701 = rgmii_hw_test.v $(SYNTH_SOURCE_KC705) gmii_to_rgmii.v
ac701_rgmii_test_tb: $(SYNTH_SOURCE_AC701) kc705/ODDR.v kc705/BUFG.v kc705/IBUFGDS.v kc705/MMCME2_BASE.v $(patsubst %, $(FPGA_FAMILY_DIR)/xilinx/%.v, BUFIO BUFR IBUF IDDR OBUF)
ac701_rgmii_test.bit: $(SYNTH_SOURCE_AC701) ac701/ac701_rgmii.ucf
	PART=xc7a200t-fbg676-2 $(ISE_SYNTH) $(notdir $(basename $<)) $^
	mv _xilinx/rgmii_hw_test.bit $@
ac701_rgmii_test.d: $(SYNTH_SOURCE_AC701) ac701/ac701_rgmii.xdc
	echo $^ | tr ' ' '\n' > $@
ac701_rgmii_vtest.bit: ac701_rgmii_test.tcl ac701_rgmii_test.d badger.tcl $(SYNTH_SOURCE_AC701) ac701/ac701_rgmii.xdc
	$(SYNTH_VIVADO) $<
	mv _xilinx/ac701_rgmii_test.runs/impl_1/rgmii_hw_test.bit $@

# =====
SYNTH_SOURCE_MARBLEM = rgmii_hw_test.v gmii_to_rgmii.v $(HW_TEST_V) marble/gmii_clock_handle.v $(FPGA_FAMILY_DIR)/xilinx/xilinx7_clocks.v
marblem_rgmii_test.d: $(SYNTH_SOURCE_MARBLEM) marble/marblem_rgmii.xdc
	echo $^ | tr ' ' '\n' > $@
marblem_rgmii_vtest.bit: marblem_rgmii_test.tcl marblem_rgmii_test.d badger.tcl $(SYNTH_SOURCE_MARBLEM) marble/marblem_rgmii.xdc
	$(SYNTH_VIVADO) $<
	mv _xilinx/marblem_rgmii_test.runs/impl_1/rgmii_hw_test.bit $@

# =====
# On-line test using Icarus and Linux's tun/tap feature
rtefi_live: rtefi_pipe_tb.v $(RTEFI_V) fake_config_romx.v mac_compat_dpram.v tap-vpi.vpi
	$(VERILOG) -m ./tap-vpi -DLINUX_TUN -o $@ $(filter %.v, $^)

# Setup for a single-user machine is pretty easy: as root do a
#  tunctl -u your_name_here && ifconfig tap0 192.168.7.1 up
# and then you can make tap_start.  In another shell session,
# try to ping 192.168.7.4
# and echo "Watson, come here" | nc -u -w 3 192.168.7.4 7
tap_start: rtefi_live tap-vpi.vpi
	$(VVP) $< +vcd

# =====
# Verilator
# My first ever attempt!  Probably full of bogosities, but it does work.
# References for adding -CFLAGS -Wno-logical-op to the verilator command line:
# https://github.com/verilator/verilator/issues/3334
# https://gcc.gnu.org/bugzilla/show_bug.cgi?id=69602
Vrtefi_blob: $(RTEFI_V) rtefi_sim.cpp ethernet_model.c tap_alloc.c crc32.c
	rm -f ethernet_model.o tap_alloc.o crc32.o  # can't leave C version around for C++ to find
	$(VERILATOR) --trace $(VLATOR_LINT_IGNORE) -CFLAGS -Wno-logical-op -cc --exe $^
	MAKEFLAGS="" make -C obj_dir -f Vrtefi_blob.mk
	mv obj_dir/$@ $@

# =====
# Verilator, slightly larger scope
Vhw_test: $(HW_TEST_V) hw_test_sim.cpp ethernet_model.c tap_alloc.c crc32.c crc8e_guts.vh crc_genguts.vh
	rm -f ethernet_model.o tap_alloc.o crc32.o  # can't leave C version around for C++ to find
	$(VERILATOR) --trace $(VLATOR_LINT_IGNORE) -CFLAGS -Wno-logical-op -cc --exe $(filter-out crc8e_guts.vh crc_genguts.vh, $^)
	MAKEFLAGS="" make -C obj_dir -f Vhw_test.mk
	mv obj_dir/$@ $@
# TFTP server demo:
# in terminal 1: make Vhw_test && ./Vhw_test
# in terminal 2: python3 badger_lb_io.py --ip 192.168.7.4 get_rxn
# in terminal 3: curl -s tftp://192.168.7.4/testing123
# The curl command should print "ABC".  This the virtual contents of every file requested.
# See tftp_test.sh

# =====
Vmem_gateway_wrap: mem_gateway_wrap.v mem_gateway.v reg_delay.v $(LB_DEMO_V) mem_gateway_sim.cpp udp_model.c
	rm -f udp_model.o  # can't leave C version around for C++ to find
	$(VERILATOR) --trace $(VLATOR_LINT_IGNORE) -cc --exe $^
	MAKEFLAGS="" make -C obj_dir -f Vmem_gateway_wrap.mk
	mv obj_dir/$@ $@
Vmem_gateway_check: Vmem_gateway_wrap Vmg_check.sh badger_lb_io.py
	bash $(word 2,$^) $(word 3,$^)

# ===== ROM generator
# Normally we leave fake_config_romx.v static, even though it's machine-generated.
# That's why it's considered "fake":  the embedded gitid is not correct.
# Enable these rules -- that depend on tools in bedrock! -- if you need to update it.
# That shouldn't happen very often.
ifdef FAKE_CONFIG_MAINT
BEDROCK_BUILD_TOOLS=../../build-tools
LB_DEMO_FLWR=lb_demo_slave.v
LB_STATIC_JSON=static_regmap.json
LB_SCALAR_JSON=scalar_lb_demo_map.json
LB_DEMO_JSON=lb_demo_map.json

$(LB_SCALAR_JSON): $(LB_DEMO_FLWR)
	$(PYTHON) $(BEDROCK_BUILD_TOOLS)/reverse_json.py $^ > $@

$(LB_DEMO_JSON): $(LB_STATIC_JSON) $(LB_SCALAR_JSON)
	$(PYTHON) $(BEDROCK_BUILD_TOOLS)/merge_json.py -o $@ -i $^

fake_config_romx.v: $(LB_DEMO_JSON)
	$(PYTHON) $(BEDROCK_BUILD_TOOLS)/build_rom.py --mod_prefix fake_ -j $^ -v $@

CLEAN += $(LB_DEMO_JSON)
CLEAN += $(LB_SCALAR_JSON)
endif

# =====
# WIP
Vcluster: cluster_wrap.sv mem_gateway_wrap.v mem_gateway.v reg_delay.v $(LB_DEMO_V) cluster_sim.cpp udp_model.c
	rm -f udp_model.o  # can't leave C version around for C++ to find
	$(VERILATOR) --trace $(VLATOR_LINT_IGNORE) -cc --exe $^
	MAKEFLAGS="" make -C obj_dir -f Vcluster_wrap.mk USER_CPPFLAGS="-DVL_DEBUG"
	mv obj_dir/Vcluster_wrap $@
cluster_run.out: cluster_run.sh Vcluster
	bash $<

# =====
# Simple syntax check
rtefi_blob_tb: $(RTEFI_V)

# =====
# Experimental, bitrotted
rtefi_blob_synth.v: $(RTEFI_V)
hw_test_synth.v: $(HW_TEST_V)
YOSYS_SHARE = /usr/share/yosys
SYNTH_SOURCE_AC701X = rgmii_hw_test.v hw_test_synth.v kc705/gmii_clock_handle.v $(FPGA_FAMILY_DIR)/xilinx/xilinx7_clocks.v gmii_to_rgmii.v
ac701_rgmii_testx_tb: $(SYNTH_SOURCE_AC701X) kc705/ODDR.v kc705/IBUFGDS.v kc705/MMCME2_BASE.v $(YOSYS_SHARE)/xilinx/cells_sim.v
# ac701_rgmii_testx_tb won't work until I have a viable RAMB18E1
ac701_rgmii_testx.d: $(SYNTH_SOURCE_AC701X) ac701/ac701_rgmii.xdc
	echo $^ | tr ' ' '\n' > $@
ac701_rgmii_vtestx.bit: ac701_rgmii_testx.tcl ac701_rgmii_testx.d badger.tcl $(SYNTH_SOURCE_AC701X) ac701/ac701_rgmii.xdc
	$(SYNTH_VIVADO) $<
	mv _xilinx/ac701_rgmii_testx.runs/impl_1/rgmii_hw_test.bit $@

# =====
# More experimental rules relating to a possible future MAC
host_mem: host_mem_gen
	./host_mem_gen
test_tx_tb: test_tx_mac.v
test_tx.vcd: host_mem
test_tx.out: test_tx_tb host_mem
	$(VVP) $<
precog_tb: precog.v
mac_subset_tb: mac_subset.v test_tx_mac.v precog.v mac_compat_dpram.v reg_tech_cdc.v
host_cmds.dat: host_cmds_gen mac_subset.gold
	./host_cmds_gen $(filter %mac_subset.gold, $^)
mac_subset.vcd: host_cmds.dat
mac_subset.out: mac_subset_tb host_cmds.dat
	$(VVP) $<
retrigger.dat: packetgen.py packet2txmac.py
	$(PYTHON) $< flip | $(PYTHON) $(word 2, $^) > $@
selfmac_in.dat: packetgen.py retrigger.dat
	$(PYTHON) $< lb $(word 2, $^) > $@
selfmac.vcd: rtefi_pipe_tb selfmac_in.dat
	$(VVP) $< +vcd $(VCD_ARGS_$@)
	mv rtefi_pipe.vcd $@  # horrible
VCD_ARGS_selfmac.vcd = +packet_file=$(filter %selfmac_in.dat, $^)
# Can also make tap_start or make Vhw_test && ./Vhw_test and
# python3 packetgen.py flip | python3 badger_lb_io.py --ip=192.168.7.4 arb
# or python3 badger_lb_io.py --ip=192.168.7.4 emit
# Result is at least visible to tcpdump -i tap0
# and nc -u -l -p 3011
# Should make packetgen.py smarter about the dest MAC created in that case.

# =====
# If you've kept your .gtkw files up to date, this target should do nothing.
# Still learning how window managers affect [sst_width].
# rtefi_sim.gtkw and hw_test.gtkw are oddball, being only useful interactively.
# The tail command gets rid of the non-reproducible GTKWave header.
gtkw_refresh:
	for f in *.gtkw; do if test $$f != rtefi_sim.gtkw && test $$f != hw_test.gtkw; then $(XVFB) make $${f%.gtkw}_view GTKW_OPT="-r gtkwave_nosplash.rc -S resave.tcl"; tail -n +9 $$f > temp_$$$$.gtkw && mv temp_$$$$.gtkw $$f; fi; done

# Documentation from Du
lb_timing_demo.pdf: lb_timing_demo.vcd lb_timing_demo.gtkw
	$(XVFB) $(GTKWAVE) -r gtkwave_nosplash.rc -S gtkw_print.tcl $^

# =====
# Other, weirder, maintenance stuff
spellme:
	cat *.v ../*.v | $(PERL) -ne 's/\/\/(.*)/print $$1,"\n"/e' > $@
	# rmccmt -c *.c *.cpp >> $@
# Lines Of Code, synthesizable only, not counting test framework or the
# big machine-generated instruction table in construct_tx_table.v
loc: rtefi_preblob.v $(filter-out rtefi_blob.v construct_tx_table.v, $(RTEFI_V))
	sed -e 's,[ \t]*//.*,,' $^ | grep -c .
locc:
	rmccmt *.c *.cpp | tr -d ' \t' | grep -c .
.PHONY: spellme loc locc

CLEAN += *_tb *.o *.vpi *.vcd *.d *.out *_synth.v *.svg crc_genguts.vh crc_derive crc_selfcheck
CLEAN += crc8e_guts.vh spellme* crc8e_guts_y.v rtefi_live Vrtefi_blob Vmem_gateway_wrap Vhw_test Vcluster
CLEAN += stests.dat *3.dat pcap2v host_mem_gen host_mem test_tx.out mac_subset.out host_cmds_gen
CLEAN += host_cmds.dat retrigger.dat selfmac_in.dat xfer1 lorem_ipsum.hex spi_flash.grab udprtx
CLEAN += cluster_run.out hw_test_cdc.txt hw_test_yosys.json
CLEAN += $(RTEFI_CLEAN)
CLEAN += *.html *.pdf *.log *.bit
CLEAN_DIRS += obj_dir _xilinx .Xil
# Actual "clean" rule in bottom_rules.mk
include $(BUILD_DIR)/bottom_rules.mk
