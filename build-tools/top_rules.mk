# Build flags for all targets
GCC_FLAGS = -Wstrict-prototypes -Wpointer-arith -Wcast-align -Wcast-qual \
	-Wshadow -Waggregate-return -Wmissing-prototypes -Wnested-externs \
	-Wall -W -Wno-unused -Winline -Wwrite-strings -Wundef -pedantic
CF_ALL = -Wall -O2 -W -fPIC -g -std=c99 -D_GNU_SOURCE $(GCC_FLAGS) ${CFLAGS_$@}
LF_ALL = -lm ${LDFLAGS_$@}

ICARUS_SUFFIX =
VERILOG_VPI = iverilog-vpi$(ICARUS_SUFFIX)
VERILOG = iverilog$(ICARUS_SUFFIX) -Wall
VG_ALL = -DSIMULATE
V_TB = -Wno-timescale
VFLAGS = ${VFLAGS_$@} -y$(AUTOGEN_DIR) -I$(AUTOGEN_DIR)
VVP_FLAGS = ${VVP_FLAGS_$@}
VVP = vvp$(ICARUS_SUFFIX) -N
VERILATOR = verilator -Wall -Wno-fatal
GTKWAVE = gtkwave
VPIEXT = vpi
PYTHON = python3
AWK = awk
VPI_CFLAGS := $(shell $(VERILOG_VPI) --cflags)
VPI_LDFLAGS := $(shell $(VERILOG_VPI) --ldflags)
DEPDIR = _dep
IPX_DIR = _ipx
AUTOGEN_DIR = _autogen

# Build tools
#CC = $(BUILD_DIR)/ccd-gcc
CC = gcc
INST = $(BUILD_DIR)/install
COMP = $(CC) $(CF_ALL) $(CF_TGT) -o $@ -c $<
LINK = $(CC) $(LF_ALL) $(LF_TGT) -o $@ $^ $(LL_TGT)
COMPLINK = $(CC) $(CF_ALL) $(CF_TGT) $(LF_ALL) $(LF_TGT) -o $@ $< $(LL_TGT)
ARCH = ar rcs $@ $^
VERILOG_COMP = $(VERILOG) $(VG_ALL) $(VPI_TGT) ${VFLAGS} $(VFLAGS_DEP) -o $@ $^
VERILOG_TB = $(VERILOG) $(VG_ALL) $(V_TB) ${VFLAGS} $(VFLAGS_DEP) -o $@ $(filter %v, $^)
VERILOG_TB_VPI = $(VERILOG) $(VG_ALL) $(VPI_TGT) ${VFLAGS} $(VFLAGS_DEP) -o $@ $(filter %.v, $^)
VERILOG_SIM = cd `dirname $@` && $(VVP) `basename $<` $(VVP_FLAGS)
VERILOG_VIEW = $(GTKWAVE) $(GTKW_OPT) $^
VERILOG_CHECK = $(VVP) $< $(VVP_FLAGS) | $(AWK) -f $(filter %.awk, $^)
VERILOG_RUN = $(VVP) $@
#VPI_LINK = $(VERILOG_VPI) --name=$(basename $@) $^ $(LL_TGT) $(LF_ALL) $(VPI_LDFLAGS)
VPI_LINK = $(CXX) -std=gnu99 -o $@ $^ $(LL_TGT) $(LF_ALL) $(VPI_LDFLAGS)
MAKEDEP = $(VERILOG) $(V_TB) $(VG_ALL) ${VFLAGS} $(VFLAGS_DEP) -o /dev/null -M$@.$$$$ $<

VLATORFLAGS = $(subst -y,-y ,${VFLAGS}) $(subst -y,-y ,${VFLAGS_DEP}) -y . -I.
VLATOR_LINT_IGNORE = -Wno-PINMISSING -Wno-WIDTH -Wno-REDEFMACRO -Wno-PINCONNECTEMPTY
VERILATOR_LINT = $(VERILATOR) $(VG_ALL) ${VLATORFLAGS} ${VLATOR_LINT_IGNORE} --lint-only $(filter %.v, $^)

FMC_MAP = awk -F\" 'NR==FNR{a[$$2]=$$4;next}$$4 in a{printf "NET %-15s LOC = %-4s | IOSTANDARD = %10s; \# %s\n",$$2,a[$$4],$$6,$$4}'
XDC_MAP = awk -F"[ \"\t]+" 'NR==FNR{gsub(/]/,"",$$8);a[$$8]=$$4;next}($$3 in a){printf "set_property -dict \"PACKAGE_PIN %-4s IOSTANDARD %s\" [get_ports %s]\n",a[$$3], $$4, $$2}'
ISE_SYNTH = bash $(BUILD_DIR)/xil_syn
VIVADO_CMD = vivado -mode batch -nojou -nolog
VIVADO_SYNTH = $(VIVADO_CMD) -source $(BUILD_DIR)/vivado_tcl/project_proc.tcl $(BUILD_DIR)/vivado_tcl/vivado_project.tcl -tclargs
VIVADO_REMOTE_SYNTH = $(VIVADO_SYNTH)
SYNTH_OPT = -DMEM_SIZE=16384
PLANAHEAD_SYNTH = planAhead -mode batch -nojou -nolog -source $(BUILD_DIR)/vivado_tcl/project_proc.tcl $(BUILD_DIR)/vivado_tcl/planahead_project.tcl -tclargs
VIVADO_FLASH = $(VIVADO_CMD) -source $(BUILD_DIR)/vivado_tcl/vivado_flash.tcl -tclargs
VIVADO_CREATE_IP = $(VIVADO_CMD) -source $(BUILD_DIR)/vivado_tcl/lbl_ip.tcl $(BUILD_DIR)/vivado_tcl/create_ip.tcl -tclargs
OCTAVE_SILENT = $(OCTAVE) -q $<
PS2PDF = ps2pdf -dEPSCrop $< $@
CHECK = $(VVP) $< | awk -f $(filter %.awk, $^)
BIT2RBF = bit2rbf $@ < $<
GIT_VERSION = $(shell git describe --abbrev=4 --dirty --always --tags)

# General directory-independent implicit rules

%.o: %.c
	$(COMP)

%: %.o
	$(LINK)

%: %.c
	$(COMPLINK)

%.a: %.o
	$(ARCH)

%_tb: %_tb.v %_tb_auto
	$(VERILOG_TB)

%_tb_auto: $(AUTOGEN_DIR)/addr_map_%_tb.vh $(AUTOGEN_DIR)/%_tb_auto.vh %_auto
	@echo .

%_auto: $(AUTOGEN_DIR)/addr_map_%.vh $(AUTOGEN_DIR)/%_auto.vh
	@echo .

%_live: %_tb.v
	$(VERILOG_TB)

%_tb_vpi: %_tb.v
	$(VERILOG_TB_VPI)

%: %.v
	$(VERILOG_COMP)

%.vpi: %.o
	$(VPI_LINK)

%.vcd: %_tb
	$(VERILOG_SIM) +vcd $(VCD_ARGS)

%_view: %.vcd %.gtkw
	$(VERILOG_VIEW)

%_check: %_tb $(BUILD_DIR)/testcode.awk
	$(VERILOG_CHECK)

%_lint: %.v %_auto
	$(VERILATOR_LINT)

%: %.m
	$(OCTAVE_SILENT)

%.pdf: %.eps
	$(PS2PDF)

%.rbf: %.bit
	$(BIT2RBF)

%.v: %.vpx
	$(PYTHON) $(BUILD_DIR)/third.py $< > $@

%.dot: %.vpx
	$(PYTHON) $(BUILD_DIR)/third.py -dot $< > $@

%.dat: %_tb
	$(VVP) $< $(VVP_FLAGS) > $@

ifeq ($(XILINX_TOOL), VIVADO)
%_$(DAUGHTER).xdc: $(BOARD_SUPPORT_DIR)/$(HARDWARE)/%.xdc  $(BOARD_SUPPORT_DIR)/$(DAUGHTER)/fmc.map
	$(XDC_MAP) $^ > $@

%_$(DAUGHTER1).xdc: $(BOARD_SUPPORT_DIR)/$(HARDWARE)/%.xdc  $(BOARD_SUPPORT_DIR)/$(DAUGHTER1)/fmc.map
	$(XDC_MAP) $^ > $@
# vivado synth
%.bit: system_top.xdc %.v
	$(VIVADO_SYNTH) $(HARDWARE) $* "$(SYNTH_OPT)" $^

# Uncomment below for remote synth
#%.bit: VIVADO_SOURCE_ARGS=$(shell $(PYTHON) $(BUILD_DIR)/exec_remote.py $^)
#%.bit: $(BUILD_DIR)/vivado_tcl/project_proc.tcl $(BUILD_DIR)/vivado_tcl/vivado_project.tcl system_top.xdc %.v
#if test $(REMOTE_SYNTH) = 1 ; then mkdir _temp; echo $^ | xargs -J % cp % _temp; tar -zcf - _temp/* | ssh fpga "rm -rf _temp; tar -zxf - && source /home/vkvytla/software/Vivado/2015.3/settings64.sh && cd _temp ; $(VIVADO_REMOTE_SYNTH) $(HARDWARE) $* system_top.xdc $(VIVADO_SOURCE_ARGS)" ; rm -rf _temp && scp fpga":"~/_temp/*.bit .; else $(VIVADO_SYNTH) $(HARDWARE) $* $^; fi

%.mcs: %.bit
	$(VIVADO_FLASH) $< $@ spix4

%_bpi.mcs: %.bit
	$(VIVADO_FLASH) $< $@ bpix16

else ifeq ($(XILINX_TOOL), PLANAHEAD)
%.bit: %.ucf %.vhd
	$(PLANAHEAD_SYNTH) $(HARDWARE) $* $^
%.mcs: %.bit
	promgen -w -spi -p mcs -o $@ -s 16384 -u 0 $<
else
# ISE synth
# $PART is defined at $(BS_HARDWARE_DIR)/rules.mk
%.bit: %.v system_top.ucf
	CLOCK_PIN=$(CLOCK_PIN) PART=$(PART) $(ISE_SYNTH) $* $(SYNTH_OPT) $^ && mv _xilinx/$@ $@

%.mcs: %.bit
	promgen -w -spi -p mcs -o $@ -s 16384 -u 0 $<
endif

UNISIM_CRAP = 'BUFGCE|IOBUF|BUFG|IBUFDS_GTE2|ICAPE2|IOBUF|STARTUPE2|MMCME2_BASE'

# Auto-generated verilog entities shall be set by globally appending to this variable
$(DEPDIR)/%.bit.d: %.v $(VERILOG_AUTOGEN)
	set -e; mkdir -p $(DEPDIR); $(MAKEDEP) && ( printf "$*.bit $@: "; sort -u $@.$$$$ | grep -Ee $(UNISIM_CRAP) -v | tr '\n' ' '; printf "\n" ) > $@ && rm -f $@.$$$$

$(DEPDIR)/%_tb.d: %_tb.v $(VERILOG_AUTOGEN)
	set -e; mkdir -p $(DEPDIR); $(MAKEDEP) && ( printf "$*_tb $@: "; sort -u $@.$$$$ | tr '\n' ' '; printf "\n" ) > $@ && rm -f $@.$$$$

LB_AW = 10
EMPTY :=
SPACE := $(EMPTY) $(EMPTY)
COMMA := ,
NEWAD_DIRS = .
NEWAD_ARGS = -d $(subst $(SPACE),$(COMMA),$(NEWAD_DIRS)) -i $< -w $(LB_AW)
$(AUTOGEN_DIR)/%_auto.vh: %.v
	mkdir -p $(AUTOGEN_DIR); $(PYTHON) $(BUILD_DIR)/newad.py -o $@ $(NEWAD_ARGS) $(NEWAD_ARGS_$*)

$(AUTOGEN_DIR)/addr_map_%.vh: %.v
	mkdir -p $(AUTOGEN_DIR); $(PYTHON) $(BUILD_DIR)/newad.py -a $@ $(NEWAD_ARGS) $(NEWAD_ARGS_$*)

$(AUTOGEN_DIR)/regmap_%.json: %.v
	mkdir -p $(AUTOGEN_DIR); $(PYTHON) $(BUILD_DIR)/newad.py -l -r $@ $(NEWAD_ARGS) $(NEWAD_ARGS_$*)

# http://www.graphviz.org/content/dot-language
# apt-get install graphviz
%.ps:   %.dot
	dot -Tps $< -o $@

%_support.vh: $(BS_HARDWARE_DIR)/%_support.in
	perl $(BUILD_DIR)/regmap_proc.pl $< > $@
