#!/bin/sh
# Mostly covers the test stage of bedrock gitlab CI, plus flake8.
# Collected and cleaned up from scattered .gitlab* .yml files.
# Running this script is possibly easier than fussing with Docker,
# and definitely gives more test coverage than typing "make" in whatever
# directory you're developing in.  Measured execution time is under
# two minutes on decent hardware (Ryzen 5 PRO 5650GE).

# Can be run as an unprivileged user on a pretty basic Debian Bullseye or Bookworm system.
# apt-get install -y build-essential git iverilog tcl
# apt-get install -y python3-yaml python3-scipy python3-matplotlib
# plus verilator v4.220 or later, built from source, since that's not (yet) in Debian

# Suggest (but don't mandate) running with flags set:
# sh -ex selftest.sh

# XXX consider adding -Wno-macro-redefinition to build-tools/top_rules.mk
# XXX should we do a git clean -fdx before each make?

## badger_test
make -C badger/tests clean all
# XXX skip bash tftp_test.sh && bash speed_check.sh, which need help from root

## chirp_test
make -C dsp/chirp all checks

## cmoc_test
PYTHONPATH=$PWD/build-tools make -C cmoc all checks

## cordic_test
make -C cordic clean all

## digaree_test
make -C dsp/digaree

## dsp_test
make -C dsp all checks

## feedforward_test
make -C dsp/feedforward

## freq_demo
make -C homeless/freq_demo

## leep_test
(cd projects/common && python3 -m unittest -v)

## make_docs
make -C build-tools/make-demo clean check consistency

## marble_sim
make -C projects/test_marble_family all net_slave_check

## oscope_top_test
# XXX skip for now, to avoid requiring nmigen==0.2 (nmigen is not in Debian)

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
# XXX skip for now, since it needs a riscv toolchain

## swap_gitid_test
(cd build-tools/vivado_tcl && tclsh test_swap_gitid.tcl)

## flake8
find . -name "*.py" -exec flake8 {} +

##
sleep 0.4
echo "selftest OK"
