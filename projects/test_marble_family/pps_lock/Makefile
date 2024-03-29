# Stand-alone version for development

VERILOG = iverilog$(ICARUS_SUFFIX) -Wall -Wno-timescale
VVP = vvp$(ICARUS_SUFFIX)
GTKWAVE = gtkwave
VERILATOR = verilator
VLATOR_LINT_IGNORE = -Wno-PINMISSING -Wno-WIDTH -Wno-PINCONNECTEMPTY
PYTHON = python3

%_tb: %_tb.v
	$(VERILOG) ${VFLAGS_$@} -o $@ $(filter %.v, $^)

%.vcd: %_tb
	$(VVP) -n $< $(VFLAGS) +vcd $(VCD_ARGS) $(VCD_ARGS_$@)

%_view: %.vcd %.gtkw
	$(GTKWAVE) $^

%_check: %_tb
	$(VVP) -N $< $(VFLAGS)

all: pps_lock_tb pll_sim_check pll_xcheck.png

pps_lock_tb: pps_lock.v pps_loop_filter.v

lint: pps_lock.v pps_loop_filter.v
	$(VERILATOR) $(VG_ALL) ${VLATORFLAGS} ${VLATOR_LINT_IGNORE} --lint-only $^

# Build a testbench with Verilator that exercises full PLL functionality
# (scaled by 1000)
Vpps_lock: pll_sim.cpp tt800.c pps_lock.v pps_loop_filter.v
	$(VERILATOR) --trace-fst $(VLATOR_LINT_IGNORE) -DSIMULATE -Gcount_period=125000 -cc --exe $^
	MAKEFLAGS="" make -C obj_dir -f Vpps_lock.mk
	mv obj_dir/$@ $@

pll_sim.vcd: Vpps_lock
	./Vpps_lock +trace

sim_lock.dat: Vpps_lock
	./Vpps_lock +fir_enable

pll_sim_check: sim_lock.dat

pll_freq.png pll_xcheck.png: transient.py lock1.dat sim_lock.dat
	$(PYTHON) $^

clean:
	rm -f *_tb *.vcd Vpps_lock *.png sim_lock.dat
	rm -rf obj_dir
