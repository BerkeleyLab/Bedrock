# Plea to future developers:  this is a single coherent code base;
# don't split it up into excessive directories, makefiles, and/or repositories!
# That will only make everything less direct and less comprehensible.
# As evidence I point you to the three 2018-era gitlab.lbl.gov repositories
# and five directories required to accomplish the tasks in scope here.
# Down that path lies madness!  Confusion is the enemy!

# =====
include ../../dir_list.mk


# These go _before_ top_rules.mk
%_check: %.out %.gold
	cmp $^
	@echo PASS
%_check: %_tb
	$(VVP) $< $(VCD_ARGS_$@)
%_tb: %_tb.v
	$(VERILOG) $(VFLAGS_$@) -o $@ $(filter %.v, $^)
%-vpi.vpi: %-vpi.o
	$(VERILOG_VPI) $^
%_view: %.vcd %.gtkw
	$(GTKWAVE) $(GTKW_OPT) $^

# =====
# Possibly common setup / configuration
include $(BUILD_DIR)/top_rules.mk

# Local overrides of default rules
VERILOG += -Wno-timescale -DSIMULATE

CFLAGS_VPI := $(shell $(VERILOG_VPI) --cflags)
VVP = vvp$(ICARUS_SUFFIX) -N
VCD_ARGS = $(VCD_ARGS_$@)
VERILATOR = verilator
PERL = perl
# apt-get install xvfb
# normally OK to blank out XVFB if you don't have xvfb-run and don't mind pop-ups
XVFB = xvfb-run -a -s "-screen 0 1440x900x24"

# used for size and speed measurements, not actual hardware
%.bit: %.v
	arch=s6 $(ISE_SYNTH) $(notdir $(basename $<)) $^
	mv _xilinx/$@ $@

# =====
# Attention!!!!
vpath %.v $(BADGER_DIR) $(DSP_DIR) $(HOMELESS_DIR)

all: crc_selfcheck_check derive_check crc8e_guts_check udp_port_cam_check scanner_check hack_icmp_cksum_check rtefi_pipe_check sp605_gmii_test_tb kc705_gmii_test_tb ac701_rgmii_test_tb hello_check speed_test_check mem_gateway_check badge_trace_tb lb_timing_demo_tb

# Packet Badger synthesizable code
RTEFI_CLIENT_LIST = hello.v speed_test.v mem_gateway.v
include $(BADGER_DIR)/rules.mk

# =====
# CRC32 code verification
# These foo3.dat files are not currently used by the main test benches,
# but generate them anyway so we can cross-check our various CRC implementations
%3.dat: packetgen.py
	$(PYTHON) $< $(@:3.dat=) > $@
crc_selfcheck_check: crc_selfcheck udp3.dat arp3.dat icmp3.dat udp4.dat
	./$< $(word 2, $^)
	./$< $(word 3, $^)
	./$< $(word 4, $^)
	./$< $(word 5, $^)

crc_selfcheck: crc_selfcheck.o crc32.o

derive_tb: crc_genguts.vh

crc_genguts.vh: crc_derive
	./$^ 16 0x1021 32 > $@

crc8e_guts.vh: crc_derive
	./$^ -lsb 32 0x04C11DB7 8 > $@

# New feature compared to PSPEPS: no include file (or path) needed!
# crc8e_guts.v is pre-filled in.  The following steps give its derivation
# and cross-check, but non-developers don't have to hassle with it.
# It's true that crc8e_guts.v is a non-source file that's checked into
# version control, but the alternatives have proven worse.
crc8e_guts_y.v: crc8e_guts_x.v crc8e_guts.vh
	$(VERILOG) -E -o $@ $<

crc8e_guts_check: crc8e_guts_y.v crc8e_guts.v
	cmp $^
	@echo PASS

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
CFLAGS_tap-vpi.o = $(CFLAGS_VPI) -D_POSIX_C_SOURCE=200809L
tap-vpi.vpi: ethernet_model.c tap_alloc.o crc32.o
CFLAGS_udp-vpi.o = $(CFLAGS_VPI) -D_POSIX_C_SOURCE=200809L
udp-vpi.vpi: udp_model.c

# =====
# Components
hack_icmp_cksum_tb: hack_icmp_cksum.v
udp_port_cam_tb: udp_port_cam.v
badge_trace_tb: badge_trace.v

# =====
# Tangent for client testing
hello_tb: hello.v client_sub.v reg_delay.v
VFLAGS_hello_tb = -m ./udp-vpi
hello.vcd: udp-vpi.vpi
hello_run: hello_tb udp-vpi.vpi
	$(VVP) $< +udp_port=3010 +vcd
hello.out: hello_tb udp-vpi.vpi xfer1
	$(VVP) $< +log +packet_file=$(filter %xfer1, $^) > $@

# =====
# Another tangent for another client
speed_test_tb: speed_test.v client_sub.v reg_delay.v
VFLAGS_speed_test_tb = -m ./udp-vpi
speed_test.vcd: udp-vpi.vpi
speed_test_run: speed_test_tb udp-vpi.vpi
	$(VVP) $< +udp_port=3000 +vcd
speed_test.out: speed_test_tb udp-vpi.vpi xfer1
	$(VVP) $< +log +packet_file=$(filter %xfer1, $^) > $@

# =====
# Another tangent for another client
LB_DEMO_V = lb_demo_slave.v freq_count2.v
# LB_DEMO_V += badge_trace.v
mem_gateway_tb: mem_gateway.v client_sub.v reg_delay.v $(LB_DEMO_V) lb_gateway.v
VFLAGS_mem_gateway_tb = -m ./udp-vpi
mem_gateway.vcd: udp-vpi.vpi
mem_gateway_run: mem_gateway_tb udp-vpi.vpi
	$(VVP) $< +udp_port=3000 +vcd
mem_gateway.out: mem_gateway_tb udp-vpi.vpi xfer1
	$(VVP) $< +log +packet_file=$(filter %xfer1, $^) > $@

# ====
# WIP client
spi_flash_tb: client_sub.v spi_flash.v spi_flash_engine.v reg_delay.v
VFLAGS_spi_flash_tb = -m ./udp-vpi
spi_flash.vcd: udp-vpi.vpi spi_flash_pack
VCD_ARGS_spi_flash.vcd = +packet_file=$(filter %spi_flash_pack, $^) +data_len=14
spi_flash.out: spi_flash_tb udp-vpi.vpi spi_flash_pack
	$(VVP) $< +log +packet_file=spi_flash_pack > $@

# =====
# scanner off-line test
scanner_tb: offline.v scanner.v ones_chksum.v udp_port_cam.v crc8e_guts.v
stests.dat: packetgen.py
	$(PYTHON) $< > $@
scanner.vcd: stests.dat
scanner_check: stests.dat
VCD_ARGS_scanner.vcd = +packet_file=stests.dat
VCD_ARGS_scanner_check = +packet_file=stests.dat

# =====
# assembled pipeline
rtefi_pipe_tb: $(RTEFI_V) fake_config_romx.v offline.v
rtefi_pipe.out: rtefi_pipe_tb udp4.dat
	$(VVP) $< +trace +packet_file=$(filter %udp4.dat, $^) > $@
rtefi_pipe.vcd: udp4.dat
VCD_ARGS_rtefi_pipe.vcd = +packet_file=$(filter %udp4.dat, $^)

# =====
# experimental bitfiles, not for hardware
bits: scanner.bit construct.bit xformer.bit ethernet_crc_add.bit udp_port_cam_wrap.bit rtefi_blob.bit
	(cd _xilinx && for f in $(basename $^); do echo $$f; grep "Slice LUT" $${f}_map.mrp; done)
scanner.bit: ones_chksum.v udp_port_cam.v crc8e_guts.v
construct.bit: ones_chksum.v construct_tx_table.v
xformer.bit: hack_icmp_cksum.v reg_delay.v
ethernet_crc_add.bit: crc8e_guts.v
udp_port_cam_wrap.bit: udp_port_cam.v
rtefi_blob.bit: $(RTEFI_V)

# =====
# Make a bitfile for an SP605 with Xilinx XST
# first just a syntax check (sp605_gmii_test.v is empty)
SYNTH_SOURCE_EXTRA = hw_test.v spi_gate.v $(LB_DEMO_V) activity.v
SYNTH_SOURCE_SP605 = gmii_hw_test.v $(RTEFI_V) $(SYNTH_SOURCE_EXTRA) sp605/gmii_clock_handle.v sp605/spartan6_clocks.v
sp605_gmii_test_tb: $(SYNTH_SOURCE_SP605) sp605/ODDR2.v
sp605_gmii_test.bit: $(SYNTH_SOURCE_SP605) sp605/sp605_gmii.ucf
	PART=xc6slx45t-fgg484-3 $(ISE_SYNTH) $(notdir $(basename $<)) $^
	mv _xilinx/gmii_hw_test.bit $@
sp605_gmii_test_iobs: sp605_gmii_test.bit
	grep -E "LOCATED|Direction" _xilinx/sp605_gmii_test_pad.txt | $(AWK) -F "|" '/GMII/{if (1) print $$3, $$6, $$12, $$14, $$15}' | sort

# =====
# Make a bitfile for a KC705 with Xilinx Vivado
# first just a syntax check (kc705_gmii_test.v is empty)
SYNTH_SOURCE_KC705 = gmii_hw_test.v $(RTEFI_V) $(SYNTH_SOURCE_EXTRA) kc705/gmii_clock_handle.v kc705/xilinx7_clocks.v
kc705_gmii_test_tb: $(SYNTH_SOURCE_KC705) kc705/ODDR.v kc705/BUFG.v kc705/IBUFGDS.v kc705/MMCME2_BASE.v
kc705_gmii_test.d: $(SYNTH_SOURCE_KC705) kc705/kc705_gmii.xdc
	echo $^ | tr ' ' '\n' > $@
kc705_gmii_test.bit: kc705_gmii_test.tcl kc705_gmii_test.d $(SYNTH_SOURCE_KC705) kc705/kc705_gmii.xdc
	$(SYNTH_VIVADO) $<
	mv _xilinx/kc705_gmii_test.runs/impl_1/gmii_hw_test.bit $@

# =====
# Make bitfiles for AC701 with both Xilinx XST and Xilinx Vivado
# first just a syntax check (ac701_rgmii_test.v is empty)
SYNTH_SOURCE_AC701 = rgmii_hw_test.v $(SYNTH_SOURCE_KC705) gmii_to_rgmii.v
ac701_rgmii_test_tb: $(SYNTH_SOURCE_AC701) kc705/ODDR.v kc705/BUFG.v kc705/IBUFGDS.v kc705/MMCME2_BASE.v
ac701_rgmii_test.bit: $(SYNTH_SOURCE_AC701) ac701/ac701_rgmii.ucf
	PART=xc7a200t-fbg676-2 $(ISE_SYNTH) $(notdir $(basename $<)) $^
	mv _xilinx/rgmii_hw_test.bit $@
ac701_rgmii_test.d: $(SYNTH_SOURCE_AC701) ac701/ac701_rgmii.xdc
	echo $^ | tr ' ' '\n' > $@
ac701_rgmii_vtest.bit: ac701_rgmii_test.tcl ac701_rgmii_test.d $(SYNTH_SOURCE_AC701) ac701/ac701_rgmii.xdc
	$(SYNTH_VIVADO) $<
	mv _xilinx/ac701_rgmii_test.runs/impl_1/rgmii_hw_test.bit $@

# =====
# On-line test using Icarus and Linux's tun/tap feature
rtefi_live: rtefi_pipe_tb.v $(RTEFI_V)
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
Vrtefi_blob: $(RTEFI_V) rtefi_sim.cpp ethernet_model.c tap_alloc.c crc32.c
	rm -f ethernet_model.o tap_alloc.o crc32.o  # can't leave C version around for C++ to find
	$(VERILATOR) --trace -Wno-PINMISSING -Wno-WIDTH -cc --exe $^
	make -C obj_dir -f Vrtefi_blob.mk
	mv obj_dir/$@ $@

# =====
# Simple syntax check
rtefi_blob_tb: $(RTEFI_V)

# =====
# Experimental
rtefi_blob_synth.v: $(RTEFI_V)
hw_test_synth.v: $(SYNTH_SOURCE_EXTRA) $(RTEFI_V)
SYNTH_SOURCE_AC701X = rgmii_hw_test.v hw_test_synth.v kc705/gmii_clock_handle.v kc705/xilinx7_clocks.v gmii_to_rgmii.v
ac701_rgmii_testx_tb: $(SYNTH_SOURCE_AC701X) kc705/ODDR.v kc705/IBUFGDS.v kc705/MMCME2_BASE.v $(HOME)/share/yosys/xilinx/cells_sim.v
# ac701_rgmii_testx_tb won't work until I have a viable RAMB18E1
ac701_rgmii_testx.d: $(SYNTH_SOURCE_AC701X) ac701/ac701_rgmii.xdc
	echo $^ | tr ' ' '\n' > $@
ac701_rgmii_vtestx.bit: ac701_rgmii_testx.tcl ac701_rgmii_testx.d $(SYNTH_SOURCE_AC701X) ac701/ac701_rgmii.xdc
	$(SYNTH_VIVADO) $<
	mv _xilinx/ac701_rgmii_testx.runs/impl_1/rgmii_hw_test.bit $@

# =====
# If you've kept your .gtkw files up to date, this target should do nothing.
# Still learning how window managers affect [sst_width].
# rtefi_sim.gtkw is an oddball.
gtkw_refresh:
	for f in *.gtkw; do if test $$f != rtefi_sim.gtkw; then $(XVFB) make $${f%.gtkw}_view GTKW_OPT="-r gtkwave_nosplash.rc -S resave.tcl"; tail -n +9 $$f > temp_$$$$.gtkw && mv temp_$$$$.gtkw $$f; fi; done

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

CLEAN += *_tb *.o *.vpi *.vcd *.d *.out *_synth.v crc_genguts.vh crc_derive crc_selfcheck crc8e_guts.vh spellme* crc8e_guts_y.v rtefi_live Vrtefi_blob stests.dat *3.dat pcap2v $(RTEFI_CLEAN)
CLEAN_DIRS += obj_dir _xilinx
# Actual "clean" rule in bottom_rules.mk
include $(BUILD_DIR)/bottom_rules.mk
