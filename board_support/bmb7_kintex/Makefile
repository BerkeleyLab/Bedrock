UNISIM_PATH = $(HOME)/hack/verilog/unisims_lrd
VERILOG = iverilog$(ICARUS_SUFFIX) -Wall -Wno-timescale

%_tb: %_tb.v
	$(VERILOG) -DSIMULATE ${VFLAGS_$@} -o $@ $(filter %.v, $^) $(filter %.vhd, $^)

all: bmb7_tb

bmb7_tb: bmb7.v k7_s6.v application_top.v

VFLAGS_bmb7_tb = -y ../../common-hdl -y ../../peripheral-drivers -y ../../fpga-family/gtx -y ../../fpga-family/pll -y $(UNISIM_PATH)

clean:
	rm -f bmb7_tb
