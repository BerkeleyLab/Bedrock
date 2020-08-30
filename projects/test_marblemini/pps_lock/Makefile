# Stand-alone version for development

VERILOG = iverilog$(ICARUS_SUFFIX) -Wall -Wno-timescale
VVP = vvp$(ICARUS_SUFFIX)
GTKWAVE = gtkwave
VERILATOR = verilator
VLATOR_LINT_IGNORE = -Wno-PINMISSING -Wno-WIDTH -Wno-REDEFMACRO -Wno-PINCONNECTEMPTY

%_tb: %_tb.v
	$(VERILOG) ${VFLAGS_$@} -o $@ $(filter %.v, $^)

%.vcd: %_tb
	$(VVP) -n $< $(VFLAGS) +vcd $(VCD_ARGS) $(VCD_ARGS_$@)

%_view: %.vcd %.gtkw
	$(GTKWAVE) $^

%_check: %_tb
	$(VVP) -N $< $(VFLAGS)

# XXX to-do: make a real regression test
all: pps_lock_tb

pps_lock_tb: pps_lock.v pps_loop_filter.v

lint: pps_lock.v pps_loop_filter.v
	$(VERILATOR) $(VG_ALL) ${VLATORFLAGS} ${VLATOR_LINT_IGNORE} --lint-only $^

clean:
	rm -f *_tb *.vcd
