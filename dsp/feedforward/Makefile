PYTHON = python3
VERILOG = iverilog$(ICARUS_SUFFIX) -Wall -Wno-timescale
VVP = vvp$(ICARUS_SUFFIX)
GTKWAVE = gtkwave
CFLAGS = --std=c99 -O2 -Wall -Wextra

%_tb: %_tb.v
	$(VERILOG) ${VFLAGS_$@} -o $@ $(filter %.v, $^)

%.vcd: %_tb
	$(VVP) -n $< $(VFLAGS) +vcd $(VCD_ARGS) $(VCD_ARGS_$@)

%_view: %.vcd %.gtkw
	$(GTKWAVE) $^

%_check: %_tb
	$(VVP) -N $< $(VFLAGS)

demo_%.png: vpoly5.py
	$(PYTHON) $< $@

# Unfortunately no meaningful cross-checks take place here
# Just "make && qiv feelgood.png" to feel good about the functionality.
# Real work ahead is to make this quantitative, with documented scaling,
# actually connecting simple.py (or something similar) to cic_bank_memgen.py.
# That work is unlikely to involve substantive changes to the synthesizable Verilog code.
all: cic_bank.out feelgood.png

ff_driver_tb: ff_driver.v cic_bankx.v a_model.v

ff_driver.out: ff_driver_tb cic_bankx_in.dat ff_plusargs.py pulse_set.json
	$(VVP) -N $< +trace `$(PYTHON) ff_plusargs.py pulse_set.json`

ff_driver.vcd: ff_driver_tb cic_bankx_in.dat ff_plusargs.py pulse_set.json
	$(VVP) -N $< +vcd +trace `$(PYTHON) ff_plusargs.py pulse_set.json`

cic_bankx_in.dat: cic_bank_memgen.py pulse_set.json
	$(PYTHON) $^ > $@

cic_bank: cic_bank.o

cic_bank.out: cic_bank cic_bankx_in.dat
	./cic_bank 2048 8192 1 < $(word 2, $^) > $@

feelgood.png: feelgood.py ff_driver.out pulse_set.json
	$(PYTHON) $^

clean:
	rm -f *.o *.vcd *.out cic_bank cic_bankx_in.dat ff_driver_tb feelgood.png *.pyc
	rm -rf __pycache__
