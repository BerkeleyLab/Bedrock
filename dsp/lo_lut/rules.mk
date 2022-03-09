VFLAGS_DEP += -y$(DSP_DIR)/lo_lut -I$(DSP_DIR)/lo_lut
VFLAGS += -I$(DSP_DIR)/lo_lut

lo_lut_f40.v: $(DSP_DIR)/lo_lut/lo_lut_gen.py
	$(PYTHON) $< -a 131071.0 -p 14/33 -s 0.0 -b 18 -t "f40"

lo_lut_f40_05.v: $(DSP_DIR)/lo_lut/lo_lut_gen.py
	$(PYTHON) $< -a 131071.0 -p 14/33 -s 0.5 -r 7/66 -b 18 -t "f40_05"

CLEAN += lo_lut_*.v sin_lut_*.vh cos_lut_*.vh
