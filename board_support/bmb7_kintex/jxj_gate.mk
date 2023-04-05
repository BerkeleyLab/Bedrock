# Stand-alone version for development

VERILOG = iverilog$(ICARUS_SUFFIX) -Wall -Wno-timescale
VVP = vvp$(ICARUS_SUFFIX) -n
GTKWAVE = gtkwave
AWK = awk
SYNTH = xil_syn
COMMON_HDL_DIR = submodules/common-hdl

%_tb: %_tb.v
	$(VERILOG) ${VFLAGS_$@} -o $@ $(filter %.v, $^) $(filter %.vhd, $^)

%.out: %_tb
	$(VVP) $< > $@

%.vcd: %_tb
	$(VVP) $< $(VFLAGS) +vcd $(VCD_ARGS) $(VCD_ARGS_$@)

%_view: %.vcd %.gtkw
	$(GTKWAVE) $^

%_check: %_tb
	$(VVP) $< $(VFLAGS)

%.dat: %_tb
	vvp $< > $@

all: jxj_gate_tb

jxj_gate_tb: jxj_gate.v $(patsubst %,$(COMMON_HDL_DIR)/%.v, shortfifo tx_8b9b oversampled_rx_8b9b)

A = +packet_file=test1.dat +data_len=24
VCD_ARGS_jxj_gate.vcd = $(A)

test1.out: jxj_gate_tb test1.dat
	$(VVP) $< $(A) > $@

clean:
	rm -f *_tb *.vcd *.bit test1.out
	rm -rf _xilinx ivl_vhdl_work
