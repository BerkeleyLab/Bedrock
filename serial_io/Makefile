include ../dir_list.mk

# =====
# This override goes _before_ top_rules.mk, in a directory like this where
# testbenches $stop() when they fail.  Hope this becomes the default someday.
%_check: %_tb
	$(VVP) $< $(VCD_ARGS_$@)
# This override goes _before_ top_rules.mk, to simplify builds in a
# directory like this that does not use newad.
%_tb: %_tb.v
	$(VERILOG) $(VG_ALL) $(V_TB) $(VFLAGS) -o $@ $(filter %v, $^)

include $(BUILD_DIR)/top_rules.mk

vpath %.v $(SERIAL_IO_DIR) $(DSP_DIR)

TGT_ := patt_gen_tb gmii_link_tb
CHK_ = $(TGT_:%_tb=%_check)

.PHONY: checks
targets: $(TGT_)
checks: $(CHK_)

SRCS = patt_gen.v data_xdomain.v flag_xdomain.v multi_sampler.v
patt_gen_tb : $(SRCS)

SRCS = gmii_link.v ep_tx_pcs.v ep_rx_pcs.v ep_sync_detect.v enc_8b10b.v dec_8b10b.v negotiate.v shortfifo.v
gmii_link_tb: $(SRCS)

CLEAN += patt_gen_tb gmii_link_tb
CLEAN_DIR += _autogen

include $(BUILD_DIR)/bottom_rules.mk
