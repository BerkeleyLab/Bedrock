#!/usr/bin/env python

import time
import sys
import os
import argparse
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
from configuration.jtag import *
from configuration.spi import *

CONFIG_ADDRESS = 24 * spi.SECTOR_SIZE

parser = argparse.ArgumentParser(description='Program BMB7 Spartan-6 boot configuration',
                                 formatter_class=argparse.ArgumentDefaultsHelpFormatter)
parser.add_argument('-t', '--target', default='192.168.1.127', help='Current unicast IP address of board')
parser.add_argument('-i', '--ip', help='Unicast IP address to be written into flash')
parser.add_argument('-m', '--mac', help='Unicast MAC address to be written into flash')
parser.add_argument('-s', '--hash', help='Kintex-7 boot firmware SHA256 hash')
args = parser.parse_args()

def fletcher(data):

    sum1 = 0xAA
    sum2 = 0x55

    for i in data:
        sum1 = sum1 + int(i)
        sum2 = sum1 + sum2

    sum1 = sum1 % 255
    sum2 = sum2 % 255

    return bytearray([sum1, sum2])

def fletcher_check(data):

    v = fletcher(data)

    sum1 = 0xFF - ((int(v[0]) + int(v[1])) % 255)
    sum2 = 0xFF - ((int(v[0]) + sum1) % 255)

    return bytearray([sum1, sum2])

# Initialise the interface to the PROM
prom = spi.interface(jtag.chain(ip=args.target, stream_port=50005, input_select=0, speed=0, noinit=True))

# Read the VCR and VECR
print 'PROM ID (0x20BA, Capacity=0x19, EDID+CFD length=0x10, EDID (2 bytes), CFD (14 bytes)',

print 'VCR (should be 0xfb by default):', hex(prom.read_register(spi.RDVCR, 1)[0])
print 'VECR (should be 0xdf):', hex(prom.read_register(spi.RDVECR, 1)[0])

if prom.prom_size() != 25:
    print 'PROM size incorrect, read', interface.prom_size()
    exit()

print 'PROM size: 256Mb == 500 x 64KB blocks'

print 'Programming Spartan-6 configuration settings'

pd = prom.read_data(CONFIG_ADDRESS, 256)

valid_checksum = True
v = fletcher_check(pd[0:85])

if (v != pd[85:87]):
    valid_checksum = False

x = bytearray(85)

# Multicast MAC
x[0] = 0x01
x[1] = 0x00
x[2] = 0x5E
x[3] = 0x73
x[4] = 0x47
x[5] = 0x01

# Multicast IP
x[6] = 0xE0
x[7] = 0xF3
x[8] = 0x47
x[9] = 0x01

# Multicast port
x[10] = 0x04
x[11] = 0xEC

# Set the BMB7 unicast MAC either a new value, the current one if PROM checksum is valid, or AA:BB:CC:DD:EE:FF as default.
if (args.mac != None):
    mac = args.mac.split(':')
    if (len(mac) != 6):
        print 'Bad MAC address argument'
        sys.exit(1)
    print 'New unicast MAC is:', args.mac
    for i in range(0, 6):
        x[12+i] = int(mac[i], 16)
elif (valid_checksum == True):
    print 'PROM configuration checksum is valid - copying unicast MAC from PROM'
    x[12:18] = pd[12:18]
else:
    print 'PROM configuration checksum is invalid - setting unicast MAC to AA:BB:CC:DD:EE:FF'
    x[12] = 0xAA
    x[13] = 0xBB
    x[14] = 0xCC
    x[15] = 0xDD
    x[16] = 0xEE
    x[17] = 0xFF

# Set the BMB7 unicast IP either a new value, the current one if PROM checksum is valid, or 192.168.1.127 as default.
if (args.ip != None):
    ip = args.ip.split('.')
    if (len(ip) != 4):
        print 'Bad IP address argument'
        sys.exit(1)
    print 'New unicast IP is:', args.ip
    for i in range(0, 4):
        x[18+i] = int(ip[i], 10)
elif (valid_checksum == True):
    print 'PROM configuration checksum is valid - copying unicast IP from PROM'
    x[18:22] = pd[18:22]
else:
    print 'PROM configuration checksum is invalid - setting unicast IP to 192.168.1.127'
    x[18] = 0xC0
    x[19] = 0xA8
    x[20] = 0x01
    x[21] = 0x7F

# Set the Kintex-7 boot firmware hash to either a new value, the current one if PROM checksum is valid, or NULL as default.
if (args.hash != None):
    s = args.hash
    if (len(s) != 64):
        print 'Bad Kintex-7 SHA256 hash argument'
        sys.exit(1)
    print 'New Kintex-7 boot firmware SHA256 hash is:', s
    for i in range(0, 32):
        x[i+22] = int(s[i*2:i*2+2], 16)
elif (valid_checksum == True):
    print 'PROM configuration checksum is valid - copying Kintex-7 boot firmware SHA256 hash from PROM'
    x[22:54] = pd[22:54]
else:
    print 'PROM configuration checksum is invalid - setting Kintex-7 boot firmware SHA256 hash to 00000000000000000000000000000000'

x[61] = 0x00
x[62] = 0x01
x[63] = 0x3F
x[64] = 0x01
x[65] = 0x00
x[66] = 0x0E
x[67] = 0x02
x[68] = 0xBB

x[69] = 0xEA
x[70] = 0xD4
x[71] = 0x9B
x[72] = 0x03
x[73] = 0x00
x[74] = 0x04
x[75] = 0x01
x[76] = 0xB2

x[77] = 0x01
x[78] = 0xB2
x[79] = 0x7F
x[80] = 0xFF
x[81] = 0x02
x[82] = 0x03
x[83] = 0x00  # 1 # [0] == POWER BURST MODE ENABLE
x[84] = 0xFF

# Append checksum
v = fletcher_check(x)
x += v

# Pad with 0xFF
x += bytearray([0xFF]) * (256 - len(x))

if (x == pd):
    print 'Values already programmed'
    exit()

prom.subsector_erase(CONFIG_ADDRESS)
prom.page_program(x, CONFIG_ADDRESS)

pd = prom.read_data(CONFIG_ADDRESS, 256)

if (x != pd):
    print 'Update failed'
