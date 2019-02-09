#!/usr/bin/env python
from __future__ import print_function
# JTAG codes for V7
BYPASS = 0x3F
IDCODE = 0x09
JPROGRAM = 11
CFG_IN = 5
CFG_OUT = 4
JSTART = 12
JSHUTDOWN = 13
ISC_NOOP = 20
USER1 = 2
USER2 = 3
USER3 = 34
USER4 = 35


class Virtex7_JTAG_Exception(Exception):
    def __init__(self, value):
        self.value = value

    def __str__(self):
        return repr(self.value)


class interface():
    def __init__(self, target):
        self.target = target

    def program(self, data, position):

        # Start in idle
        self.target.go_to_run_test_idle()

        # IDCODE
        # No safety check on IDCODE match here, should be done beforehand when loading the bitfile
        self.target.go_to_shift_ir()
        self.target.write(IDCODE, 6, True)
        self.target.go_to_run_test_idle()

        self.target.go_to_shift_dr()
        print(hex(self.target.read(32, True)))
        self.target.go_to_run_test_idle()

        # BYPASS
        self.target.go_to_shift_ir()
        self.target.write(BYPASS, 6, True)
        self.target.go_to_run_test_idle()

        # Load the JPROGRAM instruction
        self.target.go_to_shift_ir()
        self.target.write(JPROGRAM, 6, True)
        self.target.go_to_run_test_idle()

        # RUNTEST 10000 - debatably required
        #self.target.jtag_clock(bytearray([0]) * 10000)

        tprev = time.time()
        init = 0

        # TODO: Check this bit - can we just do bypass?
        while time.time() - tprev < 2.0:

            # Check for init gone high
            self.target.go_to_shift_ir()
            init = self.target.write_read(ISC_NOOP, 6, True) & 16
            self.target.go_to_run_test_idle()
            if init:
                break

            #if init == 0:
            #raise Virtex7_JTAG_Exception('INIT_B did not go high')

            # Load IR with CFG_IN
        self.target.go_to_shift_ir()
        self.target.write(CFG_IN, 6, True)
        self.target.go_to_run_test_idle()

        # Go to SHIFT_DR
        self.target.go_to_shift_dr()

        # Load the bitstream
        i = 0
        subarray = data[i:i + 14000]

        print('{:<9}'.format(''), end=' ')

        while i + 14000 < len(data):
            self.target.write_bytearray(subarray, False, True)
            i = i + 14000
            subarray = data[i:i + 14000]
            print('\b\b\b\b\b\b\b\b\b\b' + '{:<9}'.format(str((i * 100) / len(data)) + '%'), end=' ')
            sys.stdout.flush()

        print()

        # Last block
        self.target.write_bytearray(subarray, True, True)
        self.target.go_to_run_test_idle()

        # End configuration fragment
        self.target.go_to_shift_ir()
        self.target.write(CFG_IN, 6, True)
        self.target.go_to_run_test_idle()

        # Magic data
        self.target.go_to_shift_dr()
        self.target.write_bytearray(
            bytearray([
                255, 255, 255, 255, 0x55, 0x99, 0xAA, 0x66, 0x04, 0x00, 0x00,
                0x00, 0x14, 0x40, 0x03, 0x80, 0x04, 0x00, 0x00, 0x00, 0x04,
                0x00, 0x00, 0x00, 0x0C, 0x00, 0x01, 0x80, 0x00, 0x00, 0x00,
                0x0B, 0x04, 0x00, 0x00, 0x00
            ]), True)
        self.target.go_to_run_test_idle()

        # CFG_OUT
        self.target.go_to_shift_ir()
        self.target.write(CFG_OUT, 6, True)
        self.target.go_to_run_test_idle()
        self.target.go_to_shift_dr()
        print(hex(self.target.read(32)))
        self.target.go_to_run_test_idle()

        # BYPASS
        self.target.go_to_shift_ir()
        self.target.write(BYPASS, 6, True)
        self.target.go_to_run_test_idle()

        # JSTART
        self.target.go_to_shift_ir()
        self.target.write(JSTART, 6, True)
        self.target.go_to_run_test_idle()
        self.target.jtag_clock(bytearray([0]) * 10000)

        # BYPASS
        self.target.go_to_shift_ir()
        self.target.write(BYPASS, 6, True)
        self.target.go_to_run_test_idle()

        # CFG_IN
        self.target.go_to_shift_ir()
        self.target.write(CFG_IN, 6, True)
        self.target.go_to_run_test_idle()

        # Magic data
        self.target.go_to_shift_dr()
        self.target.write_bytearray(
            bytearray([
                255, 255, 255, 255, 0x55, 0x99, 0xAA, 0x66, 0x04, 0x00, 0x00,
                0x00, 0x14, 0x00, 0x07, 0x80, 0x04, 0x00, 0x00, 0x00, 0x00,
                0x00, 0x00, 0x00, 0x04, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                0x00, 0x0C, 0x00, 0x01, 0x80, 0x00, 0x00, 0x00, 0x0B, 0x04,
                0x00, 0x00, 0x00, 0x04, 0x00, 0x00, 0x00
            ]), True)
        self.target.go_to_run_test_idle()

        # CFG_OUT
        self.target.go_to_shift_ir()
        self.target.write(CFG_OUT, 6, True)
        self.target.go_to_run_test_idle()
        self.target.go_to_shift_dr()
        print(hex(self.target.read(32, True)))
        self.target.go_to_run_test_idle()

        # BYPASS
        self.target.go_to_shift_ir()
        self.target.write(BYPASS, 6, True)
        self.target.go_to_run_test_idle()

        # BYPASS
        self.target.go_to_shift_ir()
        self.target.write(BYPASS, 6, True)
        self.target.go_to_run_test_idle()

        self.target.go_to_test_logic_reset()

        # JSTART
        self.target.go_to_shift_ir()
        self.target.write(JSTART, 6, True)
        self.target.go_to_run_test_idle()
        self.target.jtag_clock(bytearray([0]) * 10000)

        # BYPASS
        self.target.go_to_shift_ir()
        self.target.write(BYPASS, 6, True)
        self.target.go_to_run_test_idle()

        # BYPASS
        self.target.go_to_shift_ir()
        self.target.write(BYPASS, 6, True)
        self.target.go_to_run_test_idle()

    def enter_user_1_dr(self):
        self.target.go_to_run_test_idle()
        self.target.go_to_shift_ir()
        self.target.write(USER1, 6, True)
        self.target.go_to_shift_dr()
        self.target.jtag_clock(bytearray([0]))

    def enter_user_2_dr(self):
        self.target.go_to_run_test_idle()
        self.target.go_to_shift_ir()
        self.target.write(USER2, 6, True)
        self.target.go_to_shift_dr()
        self.target.jtag_clock(bytearray([0]))

    def enter_user_3_dr(self):
        self.target.go_to_run_test_idle()
        self.target.go_to_shift_ir()
        self.target.write(USER3, 6, True)
        self.target.go_to_shift_dr()
        self.target.jtag_clock(bytearray([0]))

    def enter_user_4_dr(self):
        self.target.go_to_run_test_idle()
        self.target.go_to_shift_ir()
        self.target.write(USER4, 6, True)
        self.target.go_to_shift_dr()
        self.target.jtag_clock(bytearray([0]))
