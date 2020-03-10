BUILD_DIR = .
CORDIC_DIR = .
# In Bedrock, BUILD_DIR and CORDIC_DIR get overridden in ../dir_list.mk
-include ../dir_list.mk
include $(BUILD_DIR)/top_rules.mk

all: cordic_ptor_check cordic_rtop_check cordic_bias_check cordic_slve_check

# Resource exported to projects that use us
include rules.mk

# CORDIC configuration for regression tests
# DPW == Data Path Width
DPW = 22
NSTG = 20

CORDIC_BASE_V = cordicg_b$(DPW).v cstageg.v addsubg.v
cordicg_tb: $(CORDIC_BASE_V)
VFLAGS_cordicg_tb = -DDPW=$(DPW) -pnstg=$(NSTG)

cordic_ptor.dat: cordicg_tb
	$(VVP) $< +op=0 > $@

cordic_rtop.dat: cordicg_tb
	$(VVP) $< +op=1 > $@

cordic_bias.dat: cordicg_tb
	$(VVP) $< +rmix=1 > $@

cordic_slve.dat: cordicg_tb
	$(VVP) $< +op=3 > $@

cordic_ptor_check: cordic_check.py cordic_ptor.dat
	@echo
	@echo "Check of x,y,theta->x,y"
	$(PYTHON) $< $(word 2, $^)

cordic_rtop_check: cordic_check.py cordic_rtop.dat
	@echo
	@echo "Check of x,y,theta->r,theta"
	$(PYTHON) $< $(word 2, $^)

cordic_bias_check: cordic_check.py cordic_bias.dat
	@echo
	@echo "Check of downconversion bias"
	$(PYTHON) $< bias $(word 2, $^)

cordic_slve_check: cordic_check.py cordic_slve.dat
	@echo
	@echo "Check of slave mode"
	$(PYTHON) $< $(word 2, $^)


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

perf.dat: perf_run.sh
	sh $< $(NEST_MAKE) > $@

perf.png: perf_plot.py perf.dat
	$(PYTHON) $<

CLEAN += cordicg_b[1-9]*.v cordicg_tb cordic_*.dat cordic_*.bit perf.png
CLEAN_DIRS += _xilinx
include $(BUILD_DIR)/bottom_rules.mk
