# Stand-alone version for development

# i2c_slave_model.v copied from i2c_opencores_20180813.tar.gz
# We use it for simulation only, not synthesis, and it's 2-clause BSD

VERILOG = iverilog$(ICARUS_SUFFIX) -Wall -Wno-timescale
VVP = vvp$(ICARUS_SUFFIX) -N
GTKWAVE = gtkwave
SYNTH = xil_syn
PYTHON = python3

include i2cbridge_rules.mk

# Only used to pick up dpram.v from LBNL's bedrock
# Could just say DSP_DIR = ../.. , except in case of out-of-tree builds
BEDROCK_DIR := $(dir $(lastword $(MAKEFILE_LIST)))../..
DSP_DIR = $(BEDROCK_DIR)/dsp
vpath %.v $(DSP_DIR)

%_tb: %_tb.v
	$(VERILOG) ${VFLAGS_$@} -o $@ $(filter %.v, $^)

%.out: %_tb
	$(VVP) $< > $@

%.vcd: %_tb
	$(VVP) $< $(VFLAGS) +vcd $(VCD_ARGS) $(VCD_ARGS_$@)

%_view: %.vcd %.gtkw
	$(GTKWAVE) $^

%_check: %_tb
	$(VVP) $< $(VFLAGS)

%.dat: %_tb
	$(VVP) $< > $@

%.pdf: %.eps
	SOURCE_DATE_EPOCH=`stat -c %Y $<` gs -dEPSCrop -sDEVICE=pdfwrite -sOutputFile=$@ -dNOPAUSE -dBATCH -dAutoRotatePages=/None -c .setpdfwrite -f $<

%trace.vcd: %trace.dat
	$(PYTHON) c2vcd.py $< > $@

all: i2c_bit_tb i2c_prog_check i2c_analyze_tb i2c_chunk_check

i2c_bit_tb: i2c_bit.v i2c_slave_model.v

i2c_prog_tb: i2c_prog.v i2c_bit.v i2c_slave_model.v

i2c_analyze_tb: i2c_analyze.v

atrace.dat: i2c_analyze_tb
	$(VVP) $< +dfile=$@

init.in: ramtest.py
	$(PYTHON) $< > $@

i2c_chunk_tb: $(I2CBRIDGE_V) i2c_slave_model.v

i2c_chunk.vcd: init.in

i2c_chunk_check: init.in

a2trace.dat: i2c_chunk_tb init.in
	$(VVP) $< +dfile=$@

i2c_chunk.bit: $(I2CBRIDGE_V) blank_s6.ucf
	PART=xc6slx45t-fgg484-2 $(SYNTH) i2c_chunk $^
	mv _xilinx/i2c_chunk.bit .

# Count lines of Verilog code, not counting testbenches
loc: i2c_bit.v i2c_prog.v i2c_analyze.v i2c_chunk.v
	sed -e 's,//.*,,' $^ | grep -c .

# Might succeed if you have GhostScript 9.20 as found on Debian Stretch
repro_pdf: blocks.pdf
	sha256sum -c < pdfsums

blocks.svg: blocks.eps
	inkscape --export-plain-svg $@ $<

DEMO_PY=demo_assem.py

demo_assem.in: $(DEMO_PY)
	$(PYTHON) $< > $@

map.vh: $(DEMO_PY)
	$(PYTHON) $< v > $@

map.h: $(DEMO_PY)
	$(PYTHON) $< c > $@

map.json: $(DEMO_PY)
	$(PYTHON) $< j > $@

clean:
	rm -f *_tb *.vcd *.dat *.bit *.pdf *.pyc init.in
	rm -rf _xilinx __pycache__
	rm -rf map.vh map.h map.json demo_assem.in

