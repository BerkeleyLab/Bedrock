AWK = gawk
VERILOG = iverilog$(ICARUS_SUFFIX) -Wall -Wno-timescale
VVP = vvp$(ICARUS_SUFFIX) -n
SYNTH = xil_syn  # not supplied here
PYTHON = python3
DPW = 22
NSTG = 20
# data path width

cordicg_b$(DPW).v: $(CORDIC_DIR)/cordicgx.py
	$(PYTHON) $< $(DPW) > $@
