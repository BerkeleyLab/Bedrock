# Digaree is uncoupled from other LBNL infrastructure.
# For orthogonality of testing, please keep that as a functioning option.

# Compatible with  -g 2005-sv
VERILOG = iverilog$(ICARUS_SUFFIX) -Wall -Wno-timescale
VVP = vvp$(ICARUS_SUFFIX) -n
GTKWAVE = gtkwave
# Tested with python2 (2.7.3, 2.7.9, and 2.7.12) and python3 (3.4.2 and 3.5.2)
PYTHON = python3
AWK = awk
SYNTH = xil_syn
SYNTH_VIVADO = sh vivado_batch
# Tested with gcc, clang, and tcc
CFLAGS = -O2 -Wall -Wextra -pedantic -std=c99 -D_DEFAULT_SOURCE
CFLAGS += -Wshadow -Wundef -Wstrict-prototypes -Wredundant-decls
CFLAGS += -I .

# See README.run2
SRF_DATA = ../run2.dat

%_tb: %_tb.v
	$(VERILOG) $(VFLAGS_$@) -o $@ $(filter %.v, $^)

%.out: %_tb
	$(VVP) $< > $@

%.vcd: %_tb
	$(VVP) $< $(VFLAGS) +vcd $(VCD_ARGS)

%_view: %.vcd %.gtkw
	$(GTKWAVE) $^

%.pdf: %.eps
	gs -dEPSCrop -sDEVICE=pdfwrite -sOutputFile=$@ -dNOPAUSE -dBATCH -dAutoRotatePages=/None -c .setpdfwrite -f $<

%.pdf: %.tex
	pdftex $<

all: inverse_check ilookup_check match_mem match_reg accuracy detune_cw detune_pulse_test decay_slope_test

# gnu make magic
.DELETE_ON_ERROR:
.PHONY: inverse_check ilookup_check match accuracy plot

# Get Digaree program-building rules from rules.mk
DIG_DIR = .
include rules.mk

main_tb: sf_main.v ops.vh

VFLAGS_user_mem_tb = -Puser_tb.data_len=$(DATA_LEN) -Puser_tb.consts_len=$(CONSTS_LEN) -Puser_tb.const_aw=$(CONST_AW) -Puser_tb.PMEM=1
user_mem_tb: user_tb.v sf_user_wrap.v sf_user.v sf_main.v ops.vh sf_dpram.v
	$(VERILOG) $(VFLAGS_$@) -o $@ $(filter %.v, $^)

VFLAGS_user_reg_tb = -Puser_tb.data_len=$(DATA_LEN) -Puser_tb.consts_len=$(CONSTS_LEN) -Puser_tb.const_aw=$(CONST_AW) -Puser_tb.PMEM=0
user_reg_tb: user_tb.v sf_user_wrap.v sf_user.v sf_main.v ops.vh sf_dpram.v
	$(VERILOG) $(VFLAGS_$@) -o $@ $(filter %.v, $^)


user_mem.vcd: init2.dat
user_reg.vcd: init2.dat

user_%.out: user_%_tb init2.dat
	$(VVP) $< $(VFLAGS) > $@

user_%.trace: user_%.out ops.vh
	grep " // " ops.vh | grep -v " // terminus" > ops.vh_$$$$ && paste $< ops.vh_$$$$ > $@; rm ops.vh_$$$$

inverse_tb: sf_main.v

# 22-bit version makes 4.0ns, 174 LUTs, 134 FF, 1 DSP48A1
# that's roughly 0.6% of an XC6SLX25
main_s6.bit: sf_main.v blank_s6.ucf
	PART=xc6slx45t-fgg484-3 $(SYNTH) sf_main $^
	mv _xilinx/sf_main.bit $@

# 22-bit version makes 6.0ns, 444 LUTs, 134 FF, 1 MULT18X18
# that's roughly 2.6% of an XC3S1000
main_s3.bit: sf_main.v blank_s3.ucf
	PART=xc3s1000-ft256-5 $(SYNTH) sf_main $^
	mv _xilinx/sf_main.bit $@

# 22-bit version makes 4.0ns, 336 LUTs, 195 FF, 1 DSP48A1
# that's roughly 1.2% of an XC6SLX25
user_s6.bit: sf_user.v sf_main.v ops.vh sf_dpram.v blank_s6.ucf
	PART=xc6slx45t-fgg484-3 $(SYNTH) sf_user $^
	mv _xilinx/sf_user.bit $@

# 22-bit version makes 6.4ns, 656 LUTs, 195 FF, 1 MULT18X18
# that's roughly 4.0% of an XC3S1000
user_s3.bit: sf_user.v sf_main.v ops.vh sf_dpram.v blank_s3.ucf
	PART=xc3s1000-ft256-5 $(SYNTH) sf_user $^
	mv _xilinx/sf_user.bit $@

# 22-bit version makes 3.4ns, 313 LUTs, 183 FF, 1 DSP48E1
# that's roughly 0.5% of an XC7A100T
user_a7.bit: sf_user.v sf_main.v ops.vh sf_dpram.v blank_x7.ucf
	PART=xc7a100t-fgg484-2 $(SYNTH) sf_user $^
	mv _xilinx/sf_user.bit $@

# 22-bit version makes 2.6ns, 262 LUTs, 275 FF, 1 DSP48E1
# When configured with 24-bit multiplier,
# 24-bit version makes 4.2 ns, 260 LUTs, 295 FF, 2 DSP48E1
# could get down to 2.8 ns with an extra pipeline stage in the multiplier
user_k7.bit: sf_user.tcl sf_user.v sf_main.v ops.vh sf_dpram.v sf_user.xdc
	$(SYNTH_VIVADO) sf_user
	mv vivado_project/sf_user.runs/impl_1/sf_user.bit $@

.PHONY: bits
bits: main_s6.bit main_s3.bit user_s6.bit user_s3.bit

# init.dat will be read by both Verilog (user_tb.v) and C (sim1.c),
# so it has to be kept very simple.
init.dat: initgen$(STYLE).py
	$(PYTHON) $< > $@

init2.dat: init_xindex.py init.dat ops.vh
	$(PYTHON) $< > $@

sim1.h: paramh.py user_tb.v
	$(PYTHON) $^ $@

sim1.o: ops.h sim1.h

sim1: sim1.o

sim1.trace: sim1 init.dat
	./sim1 < init.dat > sim1.dat_$$$$ && grep -v "^static " < ops.h > ops.h_$$$$ && paste -d " " sim1.dat_$$$$ ops.h_$$$$ > $@; rm sim1.dat_$$$$ ops.h_$$$$

sim1.results: sim1.trace
	$(AWK) '/ int /||/ ZZZ /{print $$6,$$3}' $< | sort > $@

user_%.results: proc_usertrace.py user_%.trace
	$(PYTHON) $^ | sort > $@

tuning_dsp4.pdf: computer.pdf cgen_srf.py

inverse.dat: sim1
	./sim1 invcheck | $(AWK) '/plot/{$$1=""; print $$0}' > $@

# To see things graphically, use "plot" option of invcheck.py
inverse_check: invcheck.py inverse.dat
	$(PYTHON) $<

ilookup_check: ilookup_check.sh inverse.dat inverse.out
	sh $<

match_%: sim1.results user_%.results
	cmp $^
	@echo PASS

match_mem:
match_reg:

accuracy: accuracy.py sim1.trace init.dat
	$(PYTHON) $<

init_run2.dat: pfloat.py
	$(PYTHON) $<

test.dat: sim1 $(SRF_DATA) init_run2.dat
	./sim1 $(SRF_DATA) < init_run2.dat | $(AWK) '/_ab/{print $$2, $$3}' > $@

plot: pfloat.py $(SRF_DATA) test.dat
	$(PYTHON) $^

# pulse.dat and iq_sys2_rfs2_0.dat obtained from SRF cavities in pulsed and CW
# mode, respectively
detune_pulse: detune_coeff_calc.py fitter_dat/pulse.dat
	$(PYTHON) $< -v -m pulse -f $(filter %.dat, $^)

detune_cw: detune_coeff_calc.py fitter_dat/iq_sys2_rfs2_0.dat
	$(PYTHON) $< -v -m cw -f $(filter %.dat, $^)

detune_pulse_test: fitter_test.py fitter_dat/pulse.dat fitter_test_pulse.gold
	$(PYTHON) $< -f $(filter %.dat, $^) > fitter_test.out
	cmp fitter_test.out $(word 3, $^)
	@echo "PASS"

decay_slope_test: find_decay_slope.py fitter_dat/pulse.dat find_decay_slope.gold
	$(PYTHON) $< -f $(filter %.dat, $^) > find_decay_slope.out
	cmp find_decay_slope.out $(word 3, $^)
	@echo "PASS"

clean:
	rm -f *_tb *.vcd *.bit *.out *.trace *.results ops.h ops.vh *.o sim1 init*.dat *.pdf *.log *.pyc sim1.h inverse.dat test.dat *.png *.out
	rm -rf _xilinx vivado_project __pycache__
	sh check_clean
