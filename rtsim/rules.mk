include $(CORDIC_DIR)/rules.mk

VFLAGS_DEP += -y. -I. -y$(DSP_DIR) -I$(DSP_DIR) -y$(CORDIC_DIR) -I$(AUTOGEN_DIR)

cav_mode_auto: cordicg_b22.v
cav_elec_auto: cav_mode_auto
rtsim_auto: prng_auto cav_mech_auto station_auto cav_elec_auto
