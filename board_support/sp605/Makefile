ether_mc_sp605.bit: ether_mc_sp605.v $(ETH_MC_DEPS) $(FPGA_DIR)/sp60x_clocks.v config_romx_sp605.v sp605_gmii_base.ucf
	PART=xc6slx45t-fgg484-3  $(SYNTH) ether_mc $^
	mv _xilinx/ether_mc.bit $@

ether_fllrf_sp605.bit: ether_fllrf_sp605.v $(BUILD_v_fllrf) $(FPGA_DIR)/sp60x_clocks.v config_romx_sp605.v sp605_gmii_base.ucf
	PART=xc6slx45t-fgg484-3  $(SYNTH) ether_fllrf $^
	mv _xilinx/ether_fllrf.bit $@

ether_mgt_sp605_tb: ether_gtp_sp605_tb.v $(S6GTP_SUPPORT) BUFG.v IBUFDS.v $(S6GTP_XILINX_SIM_MODULE)

## mgt support on Spartan 6
ether_mgt_sp605.bit: ether_mgt_sp605.v $(S6GTP_SUPPORT) $(FPGA_DIR)/sp60x_clocks.v config_romx_sp605.v sp605_mgt_base.ucf $(ETH_MGT_DEPS)
	PART=xc6slx45t-fgg484-3  $(SYNTH) ether_mgt $^
	mv _xilinx/ether_mgt.bit $@

ether_both_sp605.bit: ether_both_sp605.v $(S6GTP_SUPPORT) $(ETH_MC_DEPS) $(FPGA_DIR)/sp60x_clocks.v config_romx_sp605.v  $(COMMON_HDL_DIR)/data_xdomain.v $(COMMON_HDL_DIR)/flag_xdomain.v sp605_mgt_gmii_base.ucf $(ETH_MGT_DEPS) $(TXU)
	PART=xc6slx45t-fgg484-3  $(SYNTH) ether_both_sp605 $^
	mv _xilinx/ether_both_sp605.bit $@

ether_fmc_mgt_sp605.bit: ether_fmc_mgt_sp605.v ether_fmc_mgt.vh $(S6GTP_SUPPORT) $(ETH_MC_DEPS) $(FPGA_DIR)/sp60x_clocks.v config_romx_sp605.v sp605_mgt_fmc.ucf $(FMC_SUPPORT) $(DDR_SUPPORT)
	PART=xc6slx45t-fgg484-3  $(SYNTH) ether_fmc_mgt $^
	mv _xilinx/ether_fmc_mgt.bit $@

ether_fmc_mc_sp605.bit: ether_fmc_mc_sp605.v ether_fmc_mc.vh $(FPGA_DIR)/sp60x_clocks.v config_romx_sp605.v sp605_gmii_fmc.ucf $(FMC_SUPPORT) $(DDR_SUPPORT)
	PART=xc6slx45t-fgg484-3  $(SYNTH) ether_fmc_mc $^
	mv _xilinx/ether_fmc_mc.bit $@
