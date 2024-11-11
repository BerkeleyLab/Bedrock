include ../../../dir_list.mk

HARDWARE = ac701
COMMUNICATION = gtp

COMMS_TOP_DIR = ../

APP_NAME = gige_top
IP_TCL = gtp_gige_top.tcl
SFP_IP = 192.168.1.179
BITFILE = $(APP_NAME).bit

# Set auto-generated dependencies before including top_rules.mk
VERILOG_AUTOGEN +=

VERILOG_DEFINE_FLAGS =
include $(COMMS_TOP_DIR)/rules.mk
include $(BUILD_DIR)/top_rules.mk

all: gen $(APP_NAME).bit

$(APP_NAME).bit: $(IP_TCL)

hwload_ac701:
	xc3sprog -c jtaghs1_fast $(SERIAL_NUM_OPT) $(BITFILE)

hwtest_ac701:
	ping -c2 $(SFP_IP) &&  cd ../test && python3 comms_top_test.py -t $(SFP_IP) -cf mem_test.cf

ifneq (,$(findstring bit,$(MAKECMDGOALS)))
    ifneq (,$(findstring bits,$(MAKECMDGOALS)))
-include $(BITS_:%.bit=$(DEPDIR)/%.bit.d)
    else
-include $(MAKECMDGOALS:%.bit=$(DEPDIR)/%.bit.d)
    endif
endif

CLEAN += *.bit ../test/*.dat
include $(BUILD_DIR)/bottom_rules.mk
