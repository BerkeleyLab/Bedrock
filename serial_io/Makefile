include ../dir_list.mk

# This override goes _before_ top_rules.mk, to simplify builds in a
# directory like this that does not use newad.
%_tb: %_tb.v
	$(VERILOG) $(VG_ALL) $(V_TB) $(VFLAGS) -o $@ $(filter %v, $^)

include $(BUILD_DIR)/top_rules.mk

vpath %.v $(SERIAL_IO_DIR) $(DSP_DIR)

TGT_ := dec_8b10b_tb patt_gen_tb gmii_link_tb
CHK_ = $(TGT_:%_tb=%_check)

all: targets gmii_to_rgmii_lint

.PHONY: checks
targets: $(TGT_)
checks: $(CHK_)

SRCS = patt_gen.v data_xdomain.v flag_xdomain.v reg_tech_cdc.v multi_sampler.v
patt_gen_tb : $(SRCS)

dec_8b10b_tb: dec_8b10b.v
VVP_FLAGS_dec_8b10b_check = +init_file=self_sim.dat +init_disp=1
# self_sim.dat was hand-transcribed from gmii_link_view

SRCS = gmii_link.v ep_tx_pcs.v ep_rx_pcs.v ep_sync_detect.v enc_8b10b.v dec_8b10b.v negotiate.v shortfifo.v
gmii_link_tb: $(SRCS)

# Special case; only minimally tie in to top_rules.mk
gmii_to_rgmii_lint: gmii_to_rgmii.v
	$(VERILATOR) --lint-only -Wno-TIMESCALEMOD -Wno-UNUSED $< -y $(FPGA_FAMILY_DIR)/xilinx

CLEAN += patt_gen_tb gmii_link_tb dec_8b10b_tb *.vcd
CLEAN_DIR += _autogen

include $(BUILD_DIR)/bottom_rules.mk
