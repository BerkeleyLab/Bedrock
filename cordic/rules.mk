cordicg_b%.v: $(CORDIC_DIR)/cordicgx.py
	$(PYTHON) $< $* > $@
