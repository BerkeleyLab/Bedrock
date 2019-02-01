include $(BADGER_DIR)/rules.mk

VFLAGS_DEP += -y. -I. -y$(RTSIM_DIR) -y$(DSP_DIR) -y$(BADGER_DIR) -y$(CORDIC_DIR)

LB_AW = 15
NEWAD_ARGS += -m -l
NEWAD_DIRS += $(DSP_DIR) $(RTSIM_DIR)

$(AUTOGEN_DIR)/cordicg_b22.v: $(CORDIC_DIR)/cordicgx.py
	mkdir -p $(AUTOGEN_DIR) && $(PYTHON) $< 22 > $@

rf_controller_auto: fdbk_core_auto piezo_control_auto

fdbk_core_auto: $(AUTOGEN_DIR)/cordicg_b22.v
cryomodule_auto: $(AUTOGEN_DIR)/config_romx.v $(AUTOGEN_DIR)/cordicg_b22.v llrf_shell_auto rf_controller_auto fdbk_core_auto station_auto prng_auto cav_mode_auto cav_mech_auto cav_elec_auto lp_notch_auto

cryomodule_badger_auto: $(AUTOGEN_DIR)/cordicg_b22.v cryomodule_auto $(RTEFI_V)

CLEAN += $(RTEFI_CLEAN)
