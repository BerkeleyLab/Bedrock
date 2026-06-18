include ../../dir_list.mk
include $(BUILD_DIR)/top_rules.mk

vpath %.v $(SERIAL_IO_DIR) $(DSP_DIR)

TGT_ := chitchat_tb chitchat_txrx_wrap_tb
CHK_ = $(TGT_:%_tb=%_check)

all: targets

.PHONY: checks
targets: $(TGT_)
checks: $(CHK_)

SRCS = chitchat_tx.v chitchat_rx.v chitchat_pack.vh crc16.v shortfifo.v data_xdomain.v flag_xdomain.v reg_tech_cdc.v

chitchat_tb: $(SRCS) ../gtx_noise.v ../dec_8b10b.v
chitchat_txrx_wrap_tb: chitchat_txrx_wrap.v $(SRCS)

CLEAN += chitchat_tb chitchat_txrx_wrap_tb
CLEAN_DIR += _autogen

include $(BUILD_DIR)/bottom_rules.mk
