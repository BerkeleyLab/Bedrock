#!/bin/env python

import bmb7_spartan as board
import argparse

parser = argparse.ArgumentParser(description='Display r1 FMC PROM data', formatter_class=argparse.ArgumentDefaultsHelpFormatter)
parser.add_argument('-t', '--target', default='192.168.1.127', help='Current unicast IP address of board')
parser.add_argument('--promtype', default='at24', choices=['at24', 'm24'], help='Type of EEPROM to interact with')
parser.add_argument('--bottom', action='store_true', help='EEPROM is on bottom site')
parser.add_argument('data', help='String to be written')
args = parser.parse_args()

assert len(args.data) <= 4096, "String too long for 32 kb device"

# Start the class
x = board.interface(args.target)

# Most PROMs have similar basic behavior on the QF2-pre, but the exact addressing varies.
# Typically, the PROM base address is (0x50 | ADDR), where ADDR == 0 to 7 depending on how GA0 & GA1 are wired up.
# In the QF2-pre, the top FMC is GA0 = GA1 = 0, the bottom FMC is GA0 = 1, GA1 = 0.

# For the HW-FMC-105-DEBUG: TOP FMC == 0x50, BOTTOM FMC == 0x52, DEVICE == m24c02
# For the LCLS-II ADC mezzanine: TOP FMC == 0x50, BOTTOM FMC == 0x51, DEVICE == at24c32d

# To read or write a byte from a given address, use:
# write_[DEVICE]_prom(PROM ADDRESS, ADDRESS, BYTE)
# read_[DEVICE]_prom(PROM ADDRESS, ADDRESS)

################################
# Example: Read first 10 bytes from M24C02 PROM on HW-FMC-105-DEBUG mounted on top FMC site
# Modified to read first 27 bytes from AT24C32D PROM on LBNL Digitizer board

bottom_site = args.bottom
PROM_ADDRESS = 0x52 if bottom_site else 0x50

for i in range(0, len(args.data)):
    if args.promtype == 'm24':
        pv = x.write_m24c02_prom(PROM_ADDRESS, i, ord(args.data[i]), bottom_site)
    else:
        pv = x.write_at24c32d_prom(PROM_ADDRESS, i, ord(args.data[i]), bottom_site)
