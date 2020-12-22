include ../dir_list.mk

# Override the more complex newad-supporting rule in $(BUILD_DIR)/top_rules.mk
%_tb: %_tb.v
	$(VERILOG) $(VFLAGS_$@) -o $@ $(filter %.v, $^)

# Override the testcode.awk-based rule in $(BUILD_DIR)/top_rules.mk
%_check: %_tb
	$(VVP) $< $(VCD_ARGS_$@)

include $(BUILD_DIR)/top_rules.mk

all: ad5662_check ad9653_tb

ad5662_tb: ad5662.v

spi_master_tb: spi_master.v strobe_gen.v

CLEAN += ad5662_tb spi_master_tb

include $(BUILD_DIR)/bottom_rules.mk
