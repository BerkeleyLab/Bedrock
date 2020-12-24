include ../../dir_list.mk
include $(BUILD_DIR)/top_rules.mk
include $(CORDIC_DIR)/rules.mk

VFLAGS += -I. -y. -y$(CORDIC_DIR) -I$(AUTOGEN_DIR)

%.out: %_tb
	$(VVP) $< +trace > $@

all: parab_tb chirp_driver_tb

checks: spect_test parab_check

parab_tb: parab.v ramps.v

chirp_driver_tb: chirp_driver.v chirp_wrap.v parab.v ramps.v ../multi_sampler.v cordicg_b22.v ../reg_delay.v

spect_test: chirp_driver.out final.py
	$(PYTHON) $(filter %final.py, $^) x

CLEAN += *.out *_tb *.vcd vivado.log cordicg_b22.v
include $(BUILD_DIR)/bottom_rules.mk
