include ../dir_list.mk
include $(BUILD_DIR)/top_rules.mk

BASE_V = jit_rad_gateway_demo.v jit_rad_gateway.v dpram.v flag_xdomain.v reg_tech_cdc.v
BADGER_V = $(BASE_V) mem_gateway.v reg_delay.v
QF2_V = $(BASE_V) jxj_gate.v shortfifo.v

vpath %.v $(DSP_DIR) $(BADGER_DIR) $(BOARD_SUPPORT_DIR)/bmb7_kintex
vpath %.c $(BADGER_DIR)/tests

all: jit_rad_gateway_demo_badger jit_rad_gateway_demo_qf2 jit_rad_gateway_demo_cdc.txt Vjit_rad_gateway_demo jit_rad_gateway_check
all: tgen_tb

jit_rad_gateway_demo_badger: $(BADGER_V)
	$(VERILOG) $(V_TB) -o $@ $^

jit_rad_gateway_demo_qf2: $(QF2_V)
	$(VERILOG) $(V_TB) -DQF2 -o $@ $^

jit_rad_gateway_tb: $(QF2_V)
VFLAGS_jit_rad_gateway_tb = -DQF2

# jit_rad_gateway_demo_yosys.json: $(BADGER_V)
jit_rad_gateway_demo_yosys.json: $(QF2_V)
YOSYS_JSON_OPTION += -DQF2

VLATOR_LINT_IGNORE = -Wno-PINMISSING -Wno-WIDTH -Wno-UNUSEDSIGNAL -Wno-TIMESCALEMOD

Vjit_rad_gateway_demo: $(BADGER_V) xfer_sim.cpp udp_model.c
	rm -f udp_model.o  # can't leave C version around for C++ to find
	$(VERILATOR) --trace $(VLATOR_LINT_IGNORE) -cc --exe $^
	MAKEFLAGS="" make -C obj_dir -f Vjit_rad_gateway_demo.mk USER_CPPFLAGS="-I $(BADGER_DIR)/tests"
	mv obj_dir/$@ $@

live: Vjit_rad_gateway_demo
	./Vjit_rad_gateway_demo +udp_port=3010 +trace
# see README.md for suggestions for what to do with "make live"

tgen_tb: tgen.v dpram.v

clean:
	rm -f jit_rad_gateway_demo_badger jit_rad_gateway_demo_qf2 *_tb
	rm -f jit_rad_gateway_demo_cdc.txt jit_rad_gateway_demo_yosys.json
	rm -f Vjit_rad_gateway_demo xfer_demo.vcd jit_rad_gateway_tb *.vcd
	rm -rf obj_dir
