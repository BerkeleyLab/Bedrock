#!/bin/sh
# Mostly covers the test stage of bedrock gitlab CI, plus flake8.
# Collected and cleaned up from scattered .gitlab* .yml files.
# Running this script is possibly easier than fussing with Docker,
# and definitely gives more test coverage than typing "make" in whatever
# directory you're developing in.  Measured execution time is about
# three minutes on decent hardware (Ryzen 5 PRO 5650GE).

# Can be run as an unprivileged user on a pretty basic Debian Bookworm
# system, or other recent-enough Linux distributions.
# apt-get install -y build-essential git iverilog tcl flake8
# apt-get install -y python3-yaml python3-scipy python3-matplotlib
# apt-get install -y verilator yosys
# On older systems, including Debian Bullseye and Ubuntu 22.04 LTS,
# you'll have to instead build verilator v4.220 or later and yosys 0.23
# or later from source, since the distribution's published versions are
# too old and buggy.

# An enhanced set of tests can be selected with "$1" = "more".
# The additional setup on Debian Bullseye or Bookworm isn't so bad:
# apt-get install -y gcc-riscv64-unknown-elf picolibc-riscv64-unknown-elf
# pip3 install nmigen==0.2

# Suggest (but don't mandate) running with flags set:
# sh -ex selftest.sh
# or for more complete tests:
# sh -ex selftest.sh more

# XXX could/should we do a git clean -fdx between steps?

# Print some system status and tool versions
# When run with -e, will cause early failure if something is missing
uname -s -r
gcc --version
python3 --version
iverilog -V
verilator --version
yosys -V
echo 'puts "tclsh [info patchlevel]"' | tclsh
flake8 --version
if [ "$1" = "more" ]; then
python3 -c 'import nmigen; print("nmigen found", nmigen.__version__)'
riscv64-unknown-elf-gcc --version
fi

# Don't want any graphics coming out of this by accident
unset DISPLAY

# The following tests are listed in the (alphabetical) order that they
# appear on a gitlab pipeline status page

## badger_cdc
make -C badger/tests hw_test_cdc.txt

## badger_test
make -C badger/tests clean all
# XXX skip bash tftp_test.sh && bash speed_check.sh, which need tap0 set up
# by root.  See comments in badger/tests/tftp_test.sh.

## board_support_test
make -C board_support/bmb7_kintex jxj_gate_check

## chirp_test
make -C dsp/chirp all checks

## cmoc_test
make -C cmoc all checks

## cordic_test
make -C cordic clean all

## ctrace_test
make -C projects/ctrace

## digaree_test
make -C dsp/digaree

## dsp_hosted_test
PYTHONPATH=$PWD/build-tools make -C dsp/hosted all checks

## dsp_test
make -C dsp all checks

## feedforward_test
make -C dsp/feedforward

## homeless and freq_demo
make -C homeless all checks
make -C homeless/freq_demo

## localbus
make -C localbus

## make_docs
make -C build-tools/make-demo clean check consistency

## marble_cdc
make -C projects/test_marble_family marble_base_cdc.txt

## marble_i2c_check
make -C projects/test_marble_family/i2c tests

## marble_sim
make -C projects/test_marble_family all net_slave_check
make -C projects/test_marble_family/pps_lock

## oscope_top_test
# optional, since it requires nmigen==0.2 (nmigen is not in Debian)
if [ "$1" = "more" ]; then
make -C projects/oscope/bmb7_cu Voscope_top_tb
make -C projects/oscope/bmb7_cu Voscope_top_leep
make -C projects/oscope/bmb7_cu clean
fi

## peripheral_test
make -C peripheral_drivers
make -C peripheral_drivers/idelay_scanner
make -C peripheral_drivers/ds1822
make -C peripheral_drivers/i2cbridge

## rtsim_test
make -C rtsim clean all checks rtsim.dat

## serial_io_test
make -C serial_io all checks
make -C serial_io/chitchat all checks
make -C serial_io/EVG_EVR

## soc_picorv32_test
# optional, since it requires a riscv toolchain
if [ "$1" = "more" ]; then
make -C soc/picorv32/test check
fi
# XXX  Skips the formal verification steps entirely.  They need SymbiYosys,
# which is not available in Debian; it must be built from source.

## swap_gitid_test
(cd build-tools/vivado_tcl && tclsh test_swap_gitid.tcl)

## xilinx_test
make -C fpga_family/xilinx

## flake8
find . -name "*.py" -exec flake8 {} +

##
sleep 0.4
echo "selftest OK"
