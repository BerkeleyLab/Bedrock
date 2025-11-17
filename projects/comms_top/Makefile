include ../../dir_list.mk

HARDWARE = qf2pre_kintex
COMMUNICATION = gtx

COMMS_TOP_DIR = ./

APP_NAME = comms_top
IP_TCL = gtx_comms_top.tcl
QF2_TOOLS =
QF2_IP = 192.168.1.30
FIB_IP = 192.168.1.173
BIT = $(APP_NAME).bit

all: gen $(APP_NAME).bit

# Set auto-generated dependencies before including top_rules.mk
VERILOG_AUTOGEN +=

VERILOG_DEFINE_FLAGS =
include rules.mk
include $(BUILD_DIR)/top_rules.mk

$(APP_NAME).bit: $(IP_TCL)

hwload:
	ln -sf $(QF2_TOOLS)/qf2_python_latest .; $(PYTHON) -m qf2_python_latest.scripts.program_kintex_7 -t $(QF2_IP) -b $(BIT)

hwtest:
	cd test; ./comms_top_test.py -t $(FIB_IP) -cf comms_test.cf && ./runloop 5 ./comms_top_test.py -cf comms_test.cf

ifneq (,$(findstring bit,$(MAKECMDGOALS)))
    ifneq (,$(findstring bits,$(MAKECMDGOALS)))
-include $(BITS_:%.bit=$(DEPDIR)/%.bit.d)
    else
-include $(MAKECMDGOALS:%.bit=$(DEPDIR)/%.bit.d)
    endif
endif

CLEAN += *.bit test/log.txt
include $(BUILD_DIR)/bottom_rules.mk
