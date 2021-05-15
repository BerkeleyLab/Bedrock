include ../dir_list.mk

# Override the more complex newad-supporting rule in $(BUILD_DIR)/top_rules.mk
%_tb: %_tb.v
	$(VERILOG) $(VFLAGS_$@) -o $@ $(filter %.v, $^)

# Override the testcode.awk-based rule in $(BUILD_DIR)/top_rules.mk
%_check: %_tb
	$(VVP) $< $(VCD_ARGS_$@)

include $(BUILD_DIR)/top_rules.mk

all: ad5662_check ad9653_tb spi_mon_check spi_master_check

ad5662_tb: ad5662.v

spi_master_tb: spi_master.v

spi_mon_tb: spi_mon.v spi_master.v $(DSP_DIR)/dpram.v

spi_mon.dat: spi_mon_prog.py
	$(PYTHON) $< > $@

spi_mon.vcd: spi_mon.dat

spi_mon_check: spi_mon.dat

CLEAN += ad5662_tb spi_master_tb spi_mon_tb spi_mon.dat

include $(BUILD_DIR)/bottom_rules.mk
