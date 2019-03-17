# Stand-alone version for development

VERILOG = iverilog$(ICARUS_SUFFIX) -Wall -Wno-timescale
VVP = vvp$(ICARUS_SUFFIX) -n
GTKWAVE = gtkwave
AWK = awk
SYNTH = xil_syn

%_tb: %_tb.v
	$(VERILOG) ${VFLAGS_$@} -o $@ $(filter %.v, $^)

%.out: %_tb
	$(VVP) $< > $@

%.vcd: %_tb
	$(VVP) $< $(VFLAGS) +vcd $(VCD_ARGS) $(VCD_ARGS_$@)

%_view: %.vcd %.sav
	$(GTKWAVE) $^

%_check: %_tb testcode.awk
	$(VVP) $< $(VFLAGS) | $(AWK) -f $(filter %.awk, $^)

%.dat: %_tb
	vvp $< > $@

all: llspi_tb

COMMON_HDL = ../../../dsp
PERIPH_HDL = ../../../peripheral_drivers

llspi_tb: llspi.v $(PERIPH_HDL)/spi_eater.v $(COMMON_HDL)/shortfifo.v $(PERIPH_HDL)/ad9653_sim.v $(PERIPH_HDL)/ad7794_sim.v

llspi_in.dat: llspi_in.py
	python $< > $@

llspi.vcd llspi_check: llspi_in.dat

# synthesis check, not meant to be useful on hardware
llspi.bit: llspi.v $(PERIPH_HDL)/spi_eater.v $(COMMON_HDL)/shortfifo.v
	arch=s6 $(SYNTH) llspi $^
	mv _xilinx/$@ .

clean:
	rm -f *_tb *.vcd llspi_in.dat *.bit
	rm -rf _xilinx
