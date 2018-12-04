AWK = mawk
VERILOG = iverilog$(ICARUS_SUFFIX) -Wall -Wno-timescale
VVP = vvp$(ICARUS_SUFFIX) -n
SYNTH = xil_syn  # not supplied here
PYTHON = python3
DPW = 22
NSTG = 20
# data path width

%_tb: %_tb.v
	$(VERILOG) $(VFLAGS_$@) -o $@ $(filter %.v, $^)

all: cordic0_test cordic1_test cordic2_test cordic3_test

cordicg_b$(DPW).v: cordicgx.py
	$(PYTHON) $< $(DPW) > $@

CORDIC_BASE_V = cordicg_b$(DPW).v cstageg.v addsubg.v
cordicg_tb: $(CORDIC_BASE_V)
VFLAGS_cordicg_tb = -DDPW=$(DPW) -pnstg=$(NSTG)

cordic0.dat: cordicg_tb
	$(VVP) $< +op=0 > $@

cordic1.dat: cordicg_tb
	$(VVP) $< +op=1 > $@

cordic2.dat: cordicg_tb
	$(VVP) $< +rmix=1 > $@

cordic3.dat: cordicg_tb
	$(VVP) $< +op=3 > $@

cordic0_test: cordic_test.awk cordic0.dat
	@echo
	@echo "Check of x,y,theta->x,y"
	$(AWK) -f $^

cordic1_test: cordic_test.awk cordic1.dat
	@echo
	@echo "Check of x,y,theta->r,theta"
	$(AWK) -f $^

cordic2_test: cordic2_test.awk cordic2.dat
	@echo
	@echo "Check of downconversion bias"
	$(AWK) -f $^

cordic3_test: cordic_test.awk cordic3.dat
	@echo
	@echo "Check of slave mode"
	$(AWK) -f $^


# synthesis targets
# not intended for hardware, just used to measure speed and resources
# see README for results
cordic_s3.bit: cordic_wrap.v $(CORDIC_BASE_V) blank_s3.ucf
	PART=xc3s1000-ft256-5 $(SYNTH) cordic_wrap $^
	mv _xilinx/cordic_wrap.bit $@

cordic_s6.bit: cordic_wrap.v $(CORDIC_BASE_V) blank_s6.ucf
	PART=xc6slx45t-fgg484-3 $(SYNTH) cordic_wrap $^
	mv _xilinx/cordic_wrap.bit $@

cordic_a7.bit: cordic_wrap.v $(CORDIC_BASE_V) blank_a7.ucf
	PART=xc7a100t-fgg484-2 $(SYNTH) cordic_wrap $^
	mv _xilinx/cordic_wrap.bit $@

cordic_k7.bit: cordic_wrap.v $(CORDIC_BASE_V) blank_k7.ucf
	PART=xc7k70t-fbg484-1 $(SYNTH) cordic_wrap $^
	mv _xilinx/cordic_wrap.bit $@

perf.dat:
	sh perf_run.sh > $@

perf.png: perf_plot.py perf.dat
	$(PYTHON) $<

clean:
	rm -rf _xilinx
	rm -f cordicg_b[1-9]*.v cordicg_tb cordic?.dat cordic_*.bit perf.png
