s6_gtp_params.vh:
	$(PERL) $(BUILD_DIR)/ucf2par $(FPGA_FAMILY_DIR)/$(FPGA_FAMILY)/s6gtp.ucf > $@

CLEAN += s6_gtp_params.vh
