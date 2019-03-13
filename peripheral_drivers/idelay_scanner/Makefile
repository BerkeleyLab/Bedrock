VERILOG = iverilog$(ICARUS_SUFFIX) -DSIMULATE -Wall -Wno-timescale
VVP = vvp$(ICARUS_SUFFIX) -n
GTKWAVE = gtkwave
AWK = awk
TESTCODE = testcode.awk
VVP_FLAGS = $(VVP_FLAGS_$@)
DSP_DIR = ../../dsp

%_tb: %_tb.v
	$(VERILOG) ${VFLAGS_$@} -o $@ $(filter %.v, $^)

%.out: %_tb
	$(VVP) $< $(VVP_FLAGS) > $@

%.vcd: %_tb
	$(VVP) $< $(VVP_FLAGS) +vcd

%_check: %_tb $(TESTCODE)
	$(VVP) $< $(VVP_FLAGS) | $(AWK) -f $(filter %.awk, $^)

%_view: %.vcd %.sav
	$(GTKWAVE) $^

all: idelay_scanner_check scanner_shell_tb

idelay_scanner_tb: idelay_scanner.v $(DSP_DIR)/dpram.v decider.v

scanner_shell_tb: scanner_shell.v idelay_scanner.v $(DSP_DIR)/dpram.v decider.v $(DSP_DIR)/tt800.v $(DSP_DIR)/reg_delay.v

clean:
	rm -f *_tb *.vcd *.bit *.out *.log
	rm -rf _xilinx vivado_project
