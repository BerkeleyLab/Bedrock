include ../dir_list.mk

include $(BUILD_DIR)/top_rules.mk

all: ad5662_check ad9653_tb ad9653_lint spi_mon_check spi_master_check

ad5662_tb: ad5662.v

ad9653_lint: ad9653.v
	$(VERILOG) -tnull -DSIMULATE $^ -y $(FPGA_FAMILY_DIR)/iserdes -y $(FPGA_FAMILY_DIR)/xilinx

spi_master_tb: spi_master.v

spi_mon_tb: spi_mon.v spi_master.v $(DSP_DIR)/dpram.v

spi_mon.dat: spi_mon_prog.py
	$(PYTHON) $< > $@

spi_mon.vcd: spi_mon.dat

spi_mon_check: spi_mon.dat

CLEAN += ad5662_tb ad9653_tb spi_master_tb spi_mon_tb spi_mon.dat *.vcd

include $(BUILD_DIR)/bottom_rules.mk
