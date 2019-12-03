include ../../dir_list.mk

HARDWARE = qf2pre_kintex
DSP_FLAVOR = 7
COMMUNICATION = gtx
DAUGHTER = base
XILINX_TOOL := VIVADO

FPGA_FAMILY_GTX_DIR = $(FPGA_FAMILY_DIR)/gtx
BS_HARDWARE_DIR     = $(BOARD_SUPPORT_DIR)/$(HARDWARE)
CHITCHAT_DIR        = $(SERIAL_IO_DIR)/chitchat

APP_NAME = comms_top
IP_TCL = gtx_comms_top.tcl

vpath %.v $(BADGER_DIR) $(FPGA_FAMILY_DIR) $(FPGA_FAMILY_GTX_DIR) $(SERIAL_IO_DIR) $(DSP_DIR) $(CHITCHAT_DIR) $(HOMELESS_DIR)

VFLAGS_DEP += -y$(BS_HARDWARE_DIR) -y$(FPGA_FAMILY_DIR) -y$(BADGER_DIR) -y$(FPGA_FAMILY_GTX_DIR) -y$(SERIAL_IO_DIR) -y. -I$(SERIAL_IO_DIR) -I$(BADGER_DIR) -y$(DSP_DIR) -I$(FPGA_FAMILY_GTX_DIR) -y$(CHITCHAT_DIR) -I$(CHITCHAT_DIR) -y$(HOMELESS_DIR)

VERILOG_DEFINE_FLAGS =
SYNTH_OPT += $(VERILOG_DEFINE_FLAGS)
VFLAGS +=  $(VERILOG_DEFINE_FLAGS)

# Settings for Badger compile
RTEFI_CLIENT_LIST = hello.v speed_test.v mem_gateway.v
include $(BADGER_DIR)/rules.mk

# Set auto-generated dependencies before including top_rules.mk
VERILOG_AUTOGEN += $(RTEFI_V)
include $(BUILD_DIR)/top_rules.mk
include $(BS_HARDWARE_DIR)/rules.mk
include $(BOARD_SUPPORT_DIR)/rules.mk

all: gen $(APP_NAME).bit

gen : $(RTEFI_V)

comms_features.vh: $(BUILD_DIR)/gen_features.py comms_features.yaml
	$(PYTHON) $< -i $(filter %.yaml, $^)

$(APP_NAME).bit: $(IP_TCL) comms_features.vh

# TODO: Add target capable of loading bitfile (requires QF2 tools)

hwtest:
	cd test; ./comms_top_test.py -cf comms_test.cf && ./runloop 30 ./comms_top_test.py -cf comms_test.cf > log.txt

ifneq (,$(findstring bit,$(MAKECMDGOALS)))
    ifneq (,$(findstring bits,$(MAKECMDGOALS)))
-include $(BITS_:%.bit=$(DEPDIR)/%.bit.d)
    else
-include $(MAKECMDGOALS:%.bit=$(DEPDIR)/%.bit.d)
    endif
endif

CLEAN_DIRS += ./.Xil _xilinx
CLEAN += $(RTEFI_CLEAN) *.bit test/log.txt
include $(BUILD_DIR)/bottom_rules.mk
