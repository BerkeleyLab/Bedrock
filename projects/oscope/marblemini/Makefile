include ../../../dir_list.mk

include $(BUILD_DIR)/top_rules.mk

zest_connector.csv: remap_gen.py
	$(PYTHON) remap_gen.py > $@

# TODO: Remove the relative path digilent pmod dependency
top.xdc: $(BOARD_SUPPORT_DIR)/marblemini/Marble.xdc $(BOARD_SUPPORT_DIR)/marblemini/pin_map.csv ../../test_marblemini/digilent_led_pmod.csv zest_connector.csv
	$(PYTHON) $(BADGER_DIR)/tests/meta-xdc.py $^ > $@

clean:
	rm -rf top.xdc zest_connector.csv
