#!/usr/bin/env python

from __future__ import print_function
import sys
import time

# JTAG codes for 7 series
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


class Kintex7_JTAG_Exception(Exception):
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
        # self.target.go_to_shift_ir()
        # self.target.write(IDCODE, 6, True)
        # self.target.go_to_run_test_idle()

        # self.target.go_to_shift_dr()
        # if self.target.read(32, True) != self.target.idcode(0):
        #    raise Kintex7_JTAG_Exception('IDCODE doesn\'t match expected target!')
        # self.target.go_to_run_test_idle()

        # BYPASS
        # self.target.go_to_shift_ir()
        # self.target.write(BYPASS, 6, True)
        # self.target.go_to_run_test_idle()

        # Load the JPROGRAM instruction
        self.target.go_to_shift_ir()
        self.target.write(JPROGRAM, 6, True)
        self.target.go_to_run_test_idle()

        tprev = time.time()
        init = 0

        # to fix timer
        while time.time() - tprev < 2.0:

            # Check for init gone high
            self.target.go_to_shift_ir()
            init = self.target.write_read(ISC_NOOP, 6, True) & 16
            self.target.go_to_run_test_idle()

            if init:
                break

        if init == 0:
            raise Kintex7_JTAG_Exception('INIT_B did not go high')

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
            print(
                '\b\b\b\b\b\b\b\b\b\b' +
                '{:<9}'.format(str((i * 100) / len(data)) + '%'),
                end=' ')
            sys.stdout.flush()

        print()

        # Last block
        self.target.write_bytearray(subarray, True, True)
        self.target.go_to_run_test_idle()

        return

        # End configuration fragment
        self.target.go_to_shift_ir()
        self.target.write(CFG_IN, 6, True)
        self.target.go_to_run_test_idle()

        # Magic data
        self.target.go_to_shift_dr()
        self.target.write_bytearray(
            bytearray([
                255,
                255,
                255,
                255,  # Dummy
                0x55,
                0x99,
                0xAA,
                0x66,  # SYNC
                0x04,
                0x00,
                0x00,
                0x00,  # NOOP
                0x14,
                0x40,
                0x03,
                0x80,  # Read 1 word from BOOTSTS
                0x04,
                0x00,
                0x00,
                0x00,  # NOOP
                0x04,
                0x00,
                0x00,
                0x00,  # NOOP
                0x0C,
                0x00,
                0x01,
                0x80,  # Write 1 word to CMD
                0x00,
                0x00,
                0x00,
                0xB0,  # DESYNC
                0x04,
                0x00,
                0x00,
                0x00,  # NOOP
                0x04,
                0x00,
                0x00,
                0x00  # NOOP
            ]),
            True)

        self.target.go_to_run_test_idle()

        # CFG_OUT
        self.target.go_to_shift_ir()
        self.target.write(CFG_OUT, 6, True)
        self.target.go_to_run_test_idle()
        self.target.go_to_shift_dr()
        # Should be 0x00000000 mask 0x1f000000
        print(hex(self.target.read(32)))
        self.target.go_to_run_test_idle()

        # BYPASS
        self.target.go_to_shift_ir()
        self.target.write(BYPASS, 6, True)
        self.target.go_to_run_test_idle()

        # JSTART
        # self.target.go_to_shift_ir()
        # self.target.write(JSTART, 6, True)
        # self.target.go_to_run_test_idle()
        # self.target.jtag_clock(bytearray([0]) * 10000)

        # BYPASS
        # self.target.go_to_shift_ir()
        # self.target.write(BYPASS, 6, True)
        # self.target.go_to_run_test_idle()

        # CFG_IN
        self.target.go_to_shift_ir()
        self.target.write(CFG_IN, 6, True)
        self.target.go_to_run_test_idle()

        # Magic data
        self.target.go_to_shift_dr()
        self.target.write_bytearray(
            bytearray([
                255,
                255,
                255,
                255,  # Dummy
                0x55,
                0x99,
                0xAA,
                0x66,  # SYNC
                0x04,
                0x00,
                0x00,
                0x00,  # NOOP
                0x14,
                0x00,
                0x07,
                0x80,  # Read 1 word from STAT
                0x04,
                0x00,
                0x00,
                0x00,  # NOOP
                0x04,
                0x00,
                0x00,
                0x00,  # NOOP
                0x0C,
                0x00,
                0x01,
                0x80,  # Write 1 word to CMD
                0x00,
                0x00,
                0x00,
                0xB0,  # DESYNC
                0x04,
                0x00,
                0x00,
                0x00,  # NOOP
                0x04,
                0x00,
                0x00,
                0x00  # NOOP
            ]),
            True)
        self.target.go_to_run_test_idle()

        # CFG_OUT
        self.target.go_to_shift_ir()
        self.target.write(CFG_OUT, 6, True)
        self.target.go_to_run_test_idle()
        self.target.go_to_shift_dr()

        # Status register:
        # R[5] BUS_WIDTH[2] R[1]
        # R[3] STARTUP_STATE[3] XADC_OVER_TEMP DEC_ERROR
        # ID_ERROR DONE RELEASE_DONE INIT_B INIT_COMPLETE MODE[3]
        # GHGH_B GWE GTS_CFG_B EOS DCI_MATCH MMCM_LOCK PART_SECURED CRC_ERROR

        # Should be 0x01180000 0x01180000
        print('STAT register:', hex(self.target.read(32, True)))
        self.target.go_to_run_test_idle()
        0x3fbe0802
        # JSTART
        self.target.go_to_shift_ir()
        self.target.write(JSTART, 6, True)
        self.target.go_to_run_test_idle()
        self.target.jtag_clock(bytearray([0]) * 100)

        # BYPASS
        # Check done went high
        # SIR 6 TDI (3f) TDO (21) MASK (20) ;
        self.target.go_to_shift_ir()
        self.target.write(BYPASS, 6, True)
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
        # SIR 6 TDI (3f)
        # SDR 1 TDI 00 SMASK 01
        self.target.go_to_shift_ir()
        self.target.write(BYPASS, 6, True)
        self.target.go_to_shift_dr()
        print(hex(self.target.read(1, True)))

        # to fix timer
        # done = 0
        # tprev = time.time()
        # while time.time() - tprev < 2.0:

    # Check for init gone high
    #    self.target.go_to_shift_ir()
    #    done = self.target.write_read(ISC_NOOP, 6, True) & 0x20
    #    self.target.go_to_run_test_idle()

    # if done:
    #        break

    # if done == 0:
    #    raise Kintex7_JTAG_Exception('DONE did not go high')

    # self.target.go_to_run_test_idle()

    # def enter_user_1_dr(self):
    #    self.target.go_to_run_test_idle()
    #    self.target.go_to_shift_ir()
    #    self.target.write(USER1, 6, True)
    #    self.target.go_to_shift_dr()
    #    self.target.jtag_clock(bytearray([0]))

    # def enter_user_2_dr(self):
    #    self.target.go_to_run_test_idle()
    #    self.target.go_to_shift_ir()
    #    self.target.write(USER2, 6, True)
    #    self.target.go_to_shift_dr()
    #    self.target.jtag_clock(bytearray([0]))

    # def enter_user_3_dr(self):
    #    self.target.go_to_run_test_idle()
    #    self.target.go_to_shift_ir()
    #    self.target.write(USER3, 6, True)
    #    self.target.go_to_shift_dr()
    #    self.target.jtag_clock(bytearray([0]))

    # def enter_user_4_dr(self):
    #    self.target.go_to_run_test_idle()
    #    self.target.go_to_shift_ir()
    #    self.target.write(USER4, 6, True)
    #    self.target.go_to_shift_dr()
    #    self.target.jtag_clock(bytearray([0]))
