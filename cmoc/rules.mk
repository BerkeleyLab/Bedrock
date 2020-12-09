include $(CORDIC_DIR)/rules.mk
include $(DSP_DIR)/lo_lut/rules.mk

VFLAGS_DEP += -y. -I. -y$(RTSIM_DIR) -y$(DSP_DIR) -y$(CORDIC_DIR)

LB_AW = 15
NEWAD_ARGS += -m -l
NEWAD_DIRS += $(DSP_DIR) $(RTSIM_DIR)

VERILOG_AUTOGEN += "cordicg_b22.v "

rf_controller_auto: fdbk_core_auto piezo_control_auto lp_notch_auto

fdbk_core_auto: cordicg_b22.v
cryomodule_auto: cordicg_b22.v llrf_shell_auto rf_controller_auto fdbk_core_auto station_auto prng_auto cav_mode_auto cav_mech_auto cav_elec_auto lp_notch_auto lo_lut_f40.v lo_lut_f40_05.v

cryomodule_badger_auto: cordicg_b22.v cryomodule_auto

CLEAN += cordicg_b22.v
