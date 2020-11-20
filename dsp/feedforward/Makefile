include ../../dir_list.mk
include $(BUILD_DIR)/top_rules.mk

CIC_BANK_MEM_SZ = 2048
CIC_BANK_LEN = 8192
CIC_BANK_SHIFT = 1

all: cic_bank.out feelgood.png ff_pulser_check

ff_driver_tb: ff_driver.v cic_bankx.v a_model.v

ff_driver.out: ff_driver_tb ff_plusargs.py pulse_set.json
	$(VVP) -N $< +trace `$(PYTHON) ff_plusargs.py pulse_set.json`

VVP_FLAGS_ff_driver.vcd = +trace `$(PYTHON) ff_plusargs.py pulse_set.json`

ff_pulser_tb: ff_pulser.v $(DSP_DIR)/reg_delay.v

cic_bankx_in.dat: cic_bank_memgen.py pulse_set.json
	$(PYTHON) $^ > $@

cic_bank: cic_bank.o

cic_bank.out: cic_bank cic_bankx_in.dat
	./cic_bank $(CIC_BANK_MEM_SZ) $(CIC_BANK_LEN) $(CIC_BANK_SHIFT) < $(word 2, $^) > $@

feelgood.png: feelgood.py ff_driver.out pulse_set.json
	$(PYTHON) $^

# done
CLEAN += *.o *.vcd *.out cic_bank cic_bankx_in.dat ff_driver_tb feelgood.png
include $(BUILD_DIR)/bottom_rules.mk
