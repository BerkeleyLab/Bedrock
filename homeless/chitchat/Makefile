include ../../dir_list.mk
include $(BUILD_DIR)/top_rules.mk

vpath %.v $(HOMELESS_DIR) $(DSP_DIR) ./

TGT_ := chitchat_tb chitchat_txrx_wrap_tb
CHK_ = $(TGT_:%_tb=%_check)

.PHONY: checks
targets: $(TGT_)
checks: $(CHK_)

SRCS = chitchat_txrx_wrap.v chitchat_tx.v chitchat_rx.v crc16.v shortfifo.v data_xdomain.v flag_xdomain.v

chitchat_tb: $(SRCS)
chitchat_txrx_wrap_tb: $(SRCS)

CLEAN += chitchat_tb chitchat_txrx_wrap_tb
CLEAN_DIR += _autogen

include $(BUILD_DIR)/bottom_rules.mk
