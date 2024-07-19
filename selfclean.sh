# Clean up after "selftest.sh"
make -C badger/tests clean
make -C board_support/bmb7_kintex clean
make -C dsp/chirp clean
PYTHONPATH=$PWD/build-tools make -C cmoc clean
make -C cordic clean
make -C dsp/digaree clean
make -C dsp/hosted clean
make -C dsp clean
make -C dsp/feedforward clean
make -C homeless/freq_demo clean
make -C homeless clean
make -C localbus clean
make -C build-tools/make-demo spotless
make -C projects/test_marble_family/pps_lock clean
make -C projects/test_marble_family clean
make -C projects/oscope/bmb7_cu clean
make -C peripheral_drivers clean
make -C peripheral_drivers/idelay_scanner clean
make -C peripheral_drivers/ds1822 clean
make -C peripheral_drivers/i2cbridge clean
make -C rtsim clean
make -C serial_io clean
make -C serial_io/chitchat clean
make -C serial_io/EVG_EVR clean
make -C soc/picorv32/test clean
make -C fpga_family/xilinx clean
