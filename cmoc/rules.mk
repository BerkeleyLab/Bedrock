include $(CORDIC_DIR)/rules.mk
include $(DSP_DIR)/lo_lut/rules.mk

# be lazy about dependencies
VFLAGS += -y. -I. -y$(RTSIM_DIR) -y$(DSP_DIR) -y$(DSP_DIR)/hosted -y$(CORDIC_DIR) -y$(BADGER_DIR) -y_autogen

LB_AW = 15
NEWAD_ARGS += -m -l
NEWAD_DIRS += $(DSP_DIR) $(DSP_DIR)/hosted $(RTSIM_DIR) $(CMOC_DIR)

VERILOG_AUTOGEN += "cordicg_b22.v"

rf_controller_auto: fdbk_core_auto piezo_control_auto lp_notch_auto
rf_controller_tb_auto: rf_controller_auto lo_lut_f40.v lo_lut_f40_05.v

fdbk_core_auto: cordicg_b22.v
cryomodule_auto: _autogen/config_romx.v cordicg_b22.v llrf_shell_auto rf_controller_auto fdbk_core_auto station_auto prng_auto cav_mode_auto cav_mech_auto cav_elec_auto lp_notch_auto lo_lut_f40.v lo_lut_f40_05.v

CLEAN += cordicg_b22.v
