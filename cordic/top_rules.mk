# Very simple for stand-alone testing.
# In Bedrock context, should be ignored in favor of $(BUILD_DIR)/top_rules.mk
AWK = gawk
VERILOG = iverilog$(ICARUS_SUFFIX) -Wall -Wno-timescale
VVP = vvp$(ICARUS_SUFFIX) -n
SYNTH = xil_syn  # not supplied here
PYTHON = python3

%_tb: %_tb.v
	$(VERILOG) $(VFLAGS_$@) -o $@ $(filter %.v, $^)
