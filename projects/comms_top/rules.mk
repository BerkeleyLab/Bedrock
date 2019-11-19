DAUGHTER = base
XILINX_TOOL := VIVADO

FPGA_FAMILY_GTX_DIR = $(FPGA_FAMILY_DIR)/mgt
BS_HARDWARE_DIR     = $(BOARD_SUPPORT_DIR)/$(HARDWARE)
CHITCHAT_DIR        = $(SERIAL_IO_DIR)/chitchat

vpath %.v $(BADGER_DIR) $(FPGA_FAMILY_DIR) $(FPGA_FAMILY_GTX_DIR) $(SERIAL_IO_DIR) $(DSP_DIR) $(CHITCHAT_DIR) $(HOMELESS_DIR)

VFLAGS_DEP += -y$(BS_HARDWARE_DIR) -y$(FPGA_FAMILY_DIR) -y$(BADGER_DIR) -y$(FPGA_FAMILY_GTX_DIR) -y$(SERIAL_IO_DIR) -y. -I$(SERIAL_IO_DIR) -I$(BADGER_DIR) -y$(DSP_DIR) -I$(FPGA_FAMILY_GTX_DIR) -y$(CHITCHAT_DIR) -I$(CHITCHAT_DIR) -y$(HOMELESS_DIR) -I$(COMMS_TOP_DIR)

SYNTH_OPT += $(VERILOG_DEFINE_FLAGS)
VFLAGS +=  $(VERILOG_DEFINE_FLAGS)

include $(BS_HARDWARE_DIR)/rules.mk
include $(BOARD_SUPPORT_DIR)/rules.mk

# Settings for Badger compile
RTEFI_CLIENT_LIST = hello.v speed_test.v mem_gateway.v
include $(BADGER_DIR)/rules.mk

# Set auto-generated dependencies before including top_rules.mk
VERILOG_AUTOGEN += $(RTEFI_V)

gen : $(RTEFI_V)

CLEAN_DIRS += ./.Xil _xilinx
CLEAN += $(RTEFI_CLEAN)
