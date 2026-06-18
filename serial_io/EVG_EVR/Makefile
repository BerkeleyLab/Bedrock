include ../../dir_list.mk

# This override goes _before_ top_rules.mk, to simplify builds in a
# directory like this that does not use newad.
%_tb: %_tb.v
	$(VERILOG) $(VG_ALL) $(V_TB) $(VFLAGS) -o $@ $(filter %v, $^)

include $(BUILD_DIR)/top_rules.mk

vpath %.v $(DSP_DIR)

all: NMEAtest_check tinyEVR_check evrSROC_check evr_ts_cdc_check

tinyEVR_tb: tinyEVR.v

evrSROC_tb: evrSROC.v reg_tech_cdc.v

evr_ts_cdc_tb: evr_ts_cdc.v tinyEVR.v

NMEAtest: NMEAtest.o NMEA.o

NMEAtest_check: NMEAtest
	./NMEAtest \
        '$$GPRMC,064951.000,A,2307.1256,N,12016.4438,E,0.03,165.48,260406,3.05,W,A*2C' \
        '$$GPRMC,064951.123,A,2307.1256,N,12016.4438,E,0.03,165.48,260406,3.05,W,A*2C' \
        '$$GPRMC,220516,A,5133.82,N,00042.24,W,173.8,231.8,130604,004.2,W*79' \
        '$$GPRMC,225446,A,4916.45,N,12311.12,W,000.5,054.7,191104,020.3,E*61' \
        '$$GPRMC,010455.000,A,3754.7666,N,12201.4667,W,0.01,0.00,220420,,,D*7C'\
        '$$GPGSV,1,1,00*79'

# cocotb testbench for evr_gt_wrapper.v and timing_core.v
DUT      = evr_wrapper
TOPLEVEL = $(DUT)
MODULE   = test_$(DUT)
VERILOG_SOURCES += $(DUT).v
VERILOG_SOURCES += evr_gt_wrapper.v
VERILOG_SOURCES += timing_core.v
VERILOG_SOURCES += $(DSP_DIR)/freq_count.v $(DSP_DIR)/freq_gcount.v
VERILOG_SOURCES += tinyEVR.v evr_ts_cdc.v evrSROC.v
VERILOG_SOURCES += $(DSP_DIR)/data_xdomain.v $(DSP_DIR)/flag_xdomain.v $(DSP_DIR)/reg_tech_cdc.v

export PARAM_FCNT_WIDTH := 8
export PARAM_GT_TYPE    := \"GT_SIM\"

include cocotb_inc.mk

CLEAN += NMEAtest NMEAtest.o NMEA.o tinyEVR_tb evrSROC_tb evr_ts_cdc_tb

include $(BUILD_DIR)/bottom_rules.mk
