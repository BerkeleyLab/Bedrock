PART = xc7a100t-fgg484-2
FPGA_FAMILY = 7series

# =====
# constraint
marble1.xdc: $(BADGER_DIR)/tests/meta-xdc.py pin_map.csv
	$(PYTHON) $< < $(word 2, $^) > $@

# Packet Badger synthesizable code
RTEFI_CLIENT_LIST = hello.v speed_test.v mem_gateway.v spi_flash.v
RTEFI_EXTRA_V = spi_flash_engine.v
include $(BADGER_DIR)/rules.mk
