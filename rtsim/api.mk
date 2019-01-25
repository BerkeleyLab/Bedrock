VFLAGS_DEP += -y. -I. -y$(DSP_DIR) -I$(DSP_DIR) -y$(CORDIC_DIR) -I$(AUTOGEN_DIR)

$(AUTOGEN_DIR)/cordicg_b22.v: $(CORDIC_DIR)/cordicgx.py
	mkdir -p $(AUTOGEN_DIR) && $(PYTHON) $< 22 > $@

cav_mode_auto: $(AUTOGEN_DIR)/cordicg_b22.v
cav_elec_auto: cav_mode_auto
rtsim_auto: prng_auto cav_mech_auto station_auto cav_elec_auto
