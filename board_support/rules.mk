system_top.ucf: $(BOARD_SUPPORT_DIR)/$(HARDWARE)/base.ucf $(BOARD_SUPPORT_DIR)/$(HARDWARE)/$(COMMUNICATION).ucf
	cat $^ > $@
system_top.xdc: $(BOARD_SUPPORT_DIR)/$(HARDWARE)/base.xdc $(BOARD_SUPPORT_DIR)/$(HARDWARE)/$(COMMUNICATION).xdc
	cat $^ > $@

%_$(DAUGHTER).ucf: %.ucf  $(BOARD_SUPPORT_DIR)/$(DAUGHTER)/fmc.map
	$(FMC_MAP) $^ > $@
%_$(DAUGHTER1).ucf: %.ucf  $(BOARD_SUPPORT_DIR)/$(DAUGHTER1)/fmc.map
	$(FMC_MAP) $^ > $@

%_$(DAUGHTER).xdc: %.xdc  $(BOARD_SUPPORT_DIR)/$(DAUGHTER)/fmc.map
	$(XDC_MAP) $^ > $@
%_$(DAUGHTER1).xdc: %.xdc  $(BOARD_SUPPORT_DIR)/$(DAUGHTER1)/fmc.map
	$(XDC_MAP) $^ > $@

ifeq ($(XILINX_TOOL), VIVADO)
    CLEAN += system_top.xdc
else
    CLEAN += system_top.ucf
endif
