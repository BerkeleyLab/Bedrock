include ../../dir_list.mk

%_tb: %_tb.v
	$(VERILOG) $(VFLAGS_$@) -o $@ $(filter %.v, $^)
%_check: %_tb
	$(VVP) $< $(VVP_FLAGS)

# =====
# Possibly common setup / configuration
include $(BUILD_DIR)/top_rules.mk

# Local overrides of default variables
VERILOG += -Wno-timescale

vpath %.v $(SERIAL_IO_DIR)

# =====
# gets us $(FREQ_DEMO_V)
include freq_demo_rules.mk

all: b2decimal_check dec_forward_check freq_demo_tb

# =====
# Parallel binary to decimal ASCII
b2decimal_tb: b2decimal.v
dec_forward_tb: dec_forward.v b2decimal.v

# =====
# freq_demo subsystem
freq_demo_tb: $(FREQ_DEMO_V)

clean:
	rm -f *_tb *.d *.o *.vcd *.pyc
