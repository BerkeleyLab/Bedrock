include ../../dir_list.mk

HARDWARE = qf2pre_kintex
COMMUNICATION = gtx

APP_NAME = comms_top
IP_TCL = gtx_comms_top.tcl
QF2_TOOLS =
QF2_IP = 192.168.1.30
FIB_IP = 192.168.1.173
BIT = $(APP_NAME).bit

# Set auto-generated dependencies before including top_rules.mk
VERILOG_AUTOGEN += comms_features.vh

VERILOG_DEFINE_FLAGS =
include rules.mk
include $(BUILD_DIR)/top_rules.mk

all: gen $(APP_NAME).bit

comms_features.vh: $(BUILD_DIR)/gen_features.py comms_features.yaml
	$(PYTHON) $< -i $(filter %.yaml, $^)

$(APP_NAME).bit: $(IP_TCL)


hwload:
	ln -s $(QF2_TOOLS)/qf2_python .; python -m qf2_python.scripts.program_kintex_7 -t $(QF2_IP) -b $(BIT)

hwtest:
	cd test; ./comms_top_test.py -t $(FIB_IP) -cf comms_test.cf && ./runloop 5 ./comms_top_test.py -cf comms_test.cf > log.txt

ifneq (,$(findstring bit,$(MAKECMDGOALS)))
    ifneq (,$(findstring bits,$(MAKECMDGOALS)))
-include $(BITS_:%.bit=$(DEPDIR)/%.bit.d)
    else
-include $(MAKECMDGOALS:%.bit=$(DEPDIR)/%.bit.d)
    endif
endif

CLEAN += *.bit test/log.txt comms_features.json comms_features.vh
include $(BUILD_DIR)/bottom_rules.mk
