#!/usr/bin/python

# ifconfig eth0 up 192.168.21.1
# route add -net 192.168.8.0 netmask 255.255.255.0 dev eth0

# also see ~/llrf/eth_2012/lantest
# and ~/llrf/eth_2012/UDP_TxRx_test.lua

# Winbond W25X16, W25X32, W25X64
# See w25x.pdf and spi_flash_engine.v
# Cypress S25FL128S, S25FL256S
# See s25fl128s.pdf

# XC7A100T on Marble-Mini:  bitfile is 3727 kBytes
# XC7K160T on Marble:  bitfile is 6536 kBytes
# with 128 Mbit = 16 Mbyte flash chip,
# use TBPROT=1 BP2=1 BP1=1 BP0=0 to protect the lower half (8192 kByte),
# since Xilinx FPGAs SPI-boot from address zero.

import socket
import struct
import time
import logging
import sys
import os
import binascii


# Work towards compatibility with both python2 and python3
def bafromhex(bs):
    return bytearray(binascii.unhexlify(bs))


def hexfromba(ba):
    if sys.version_info[0] < 3:
        return binascii.hexlify(ba)
    else:
        return ba.hex()


# prefix
MSG_PREFIX     = bafromhex(b'5201')            # 52 01
CHK_PREFIX     = bafromhex(b'5200')            # 52 00

# instruction set
RELEASE_PD     = bafromhex(b'01ab')            # 01 ab              Release Power Down
READ_STATUS_1  = bafromhex(b'020500')          # 05 dd              Read Status Register
READ_STATUS_2  = bafromhex(b'023500')
READ_JEDEC_ID  = bafromhex(b'049f000000')      # 9F dd dd dd        Read JEDEC ID (RDID)
READ_DEVICE_ID = bafromhex(b'06900000000000')  # 90 00 00 00 dd dd  Read Device ID
READ_CONFIG_REG = bafromhex(b'023500')         # 35 dd              Read Configuration Register
CLEAR_STATUS   = bafromhex(b'0130')            # 30                 Clear Status Register
RESET_CHIP     = bafromhex(b'01f0')            # f0                 Software reset

ERASE_SECTOR   = bafromhex(b'0420')            # 20 nn nn nn        Erase Sector (4kB)
ERASE_BLOCK_32 = bafromhex(b'0452')            # 52 nn nn nn        Erase Block  (32kB)
ERASE_BLOCK_64 = bafromhex(b'04d8')            # d8 nn nn nn        Erase Block  (64kB)
READ_FAST      = bafromhex(b'0d0b')            # 0b nn nn nn        Fast Read (261 bytes)
READ_DATA      = bafromhex(b'0c03')            # 03 nn nn nn        Read Data (260 bytes)
PAGE_PROG      = bafromhex(b'0c02')            # 02 nn nn nn dd     Page program (260 bytes)
WRITE_DISABLE  = bafromhex(b'0104')            # 04                 Write Disaable
WRITE_ENABLE   = bafromhex(b'0106')            # 06                 Write Enable (WREN)
WRITE_STATUS   = bafromhex(b'0201')            # 01 dd              Write Status Register (WRR)
WRITE_CONFIG   = bafromhex(b'0301')            # 01 dd dd           Write Status and Config (WRR)
READ_OTP       = bafromhex(b'0d4b')            # 4b nn nn nn        Like Fast Read (261 bytes)

# ICAP_SPARTAN6 commands
# UG380 table 7-1
ICAP_DUMMY     = bafromhex(b'ffff')            # DUMMY
ICAP_SYNC_H    = bafromhex(b'aa99')
ICAP_SYNC_L    = bafromhex(b'5566')
ICAP_W_GEN1    = bafromhex(b'3261')
ICAP_W_GEN2    = bafromhex(b'3281')
ICAP_W_GEN3    = bafromhex(b'32a1')
ICAP_W_GEN4    = bafromhex(b'32c1')
ICAP_W_CMD     = bafromhex(b'30a1')
ICAP_IPROG     = bafromhex(b'000e')
ICAP_NOOP      = bafromhex(b'2000')            # NO OP for IPROG

# GENERAL 3,4, where Golden image lives
# GOLDEN_AD      = 0x10000
GOLDEN_AD      = 0x0

# addressing information of target
# grep "ip =" board_support/xilinx/ether_mc.vh
IPADDR = 'localhost'
PORTNUM = 4000
WAIT = 0.05
PAGE = 256


# Reverse bits within a byte
def byterev(n):
    unib = n >> 4
    lnib = n & 0x0f
    mapper = "084c2a6e195d3b7f"  # bit-reversed nibble lookup
    return (mapper[lnib] + mapper[unib]).decode('hex')


def do_message(s, p, verbose=False):
    pp = MSG_PREFIX + bytearray(p)
    if verbose:
        print("sending  " + hexfromba(pp))
    s.send(pp)
    rr, addr = s.recvfrom(1024)  # buffer size is 1024 bytes
    rr = bytearray(rr)
    r_status = rr[1]
    if verbose:
        print("initiator: status %d, length %d" % (r_status, len(rr)))
    # status 2: accepted command, not done
    # status 0: rejected command, still not done with previous one
    # status 1: rejected command, but at least the previous one is done
    retries = 0
    while r_status != 1:
        time.sleep(WAIT)
        flusher = CHK_PREFIX + bytearray(len(p) * [0])
        s.send(flusher)
        rr, addr = s.recvfrom(1024)  # buffer size is 1024 bytes
        rr = bytearray(rr)
        r_status = rr[1]
        retries += 1
        if verbose:
            print("retry %d: status %d, length %d" % (retries, r_status, len(rr)))
    if verbose:
        print("received " + hexfromba(rr))
    if verbose or rr[0] != 0x51:
        print("rtype  = 0x%02x (expected 0x51)" % rr[0])
    r = rr[2:]
    return r, addr


# Read Manufacturer ID, JEDEC ID and Device ID
def read_id(s):
    logging.info('Reading ID...')
    p = READ_STATUS_1 + READ_STATUS_2 + READ_STATUS_1 + READ_JEDEC_ID + READ_DEVICE_ID
    r, addr = do_message(s, p, verbose=False)
    manu_id = r[len(r) - 2]
    dev_id = r[len(r) - 1]
    capacity = r[len(r) - 8]
    mem_type = r[len(r) - 9]
    logging.debug('From: %s \n Tx length: %d\n Rx length: %d\n' % (addr, len(p), len(r)))
    manu_list = {1: "Cypress"}
    manu_name = manu_list[manu_id] if manu_id in manu_list else "Unknown"
    cap_list = {0x18: "128 Mb", 0x19: "256 Mb"}
    cap_name = cap_list[capacity] if capacity in cap_list else "Unknown"
    print('Manufacturer ID: %02x (%s)' % (manu_id, manu_name))
    print('Device ID:       %02x' % dev_id)
    print('Memory Type:     %02x' % mem_type)
    print('Capacity:        %02x (%s)' % (capacity, cap_name))
    return


# Read status reg 1, twice for good measure
def read_status_config(s, verbose=False):
    p = READ_CONFIG_REG + 2 * READ_STATUS_1
    r, addr = do_message(s, p, verbose=False)
    status_reg = r[len(r) - 1]
    config_reg = r[len(r) - 1 - 2 * len(READ_STATUS_1)]
    if verbose:
        print("CONFIG_REG (CR1) = 0x%2.2x" % config_reg)
        bits = ["LC1", "LC0", "TBPROT", "DNU", "BPNV", "TBPARM", "QUAD", "FREEZE"]
        for ix, b in enumerate(bits):
            v = (config_reg >> (7 - ix)) & 1
            print("%8s %d" % (b, v))
        logging.debug('From: %s \n Tx length: %d\n Rx length: %d\n' % (addr, len(p), len(r)))
        logging.info('Check Status Reg: %02x' % status_reg)
    return status_reg, config_reg


#  20 nn nn nn   Sector Erase (4 kB)
#  05 rr         Read status register until completion, S0=0
def erase_mem(s, ad, size):
    if size == 'SECTOR':
        p = ERASE_SECTOR
    elif size == '32KB':
        p = ERASE_BLOCK_32
    elif size == '64KB':
        p = ERASE_BLOCK_64
    else:
        logging.error('Wrong buffer size to erase.')
    logging.info('Erasing %s at address 0x%x...' % (size, ad))
    pp = p + three_bytes(ad) + 5 * READ_STATUS_1
    r, addr = do_message(s, pp)
    status_reg = r[-1]
    logging.debug('From: %s \n Tx length: %d\n Rx length: %d\n' % (addr, len(pp), len(r)))
    logging.debug('Check Status Reg: %x' % status_reg)
    return ~status_reg


#  06/04         Write Enable/Disable
#  05 rr         Read status register until completion, S0=0
def write_enable(s, enable):
    if enable is True:
        p = WRITE_ENABLE
        logging.debug('Enabling Write Register')
    else:
        p = WRITE_DISABLE
        logging.debug('Disabling Write Register')
    pp = p + 6 * READ_STATUS_1
    r, addr = do_message(s, pp)
    status_reg = r[-1]
    logging.debug('From: %s \n Tx length: %d\n Rx length: %d\n' % (addr, len(pp), len(r)))
    logging.debug('Check Write Enable Status Reg: %x' % status_reg)
    if (status_reg & 0x60) != 0:
        print("Aaaaugh!  Errors reported in write_enable status reg 0x%2.2x" % status_reg)
        exit()
    return (status_reg & 0x3) == 0x2


# encode an integer as three bytes
# used to specify addresses when building SPI commands
def three_bytes(ad):
    adx = struct.pack('!i', ad)
    return bytearray(adx[1:4])


def page_read(s, ad, fast=False, otp=False):
    if otp:
        #  4b nn nn nn xx dd dd ... dd  Fast Read (261 bytes)
        #  note padding byte between address and first data byte
        p = READ_OTP + three_bytes(ad) + bytearray(257 * [0])
    elif fast:
        #  0b nn nn nn xx dd dd ... dd  Fast Read (261 bytes)
        #  note padding byte between address and first data byte
        p = READ_FAST + three_bytes(ad) + bytearray(257 * [0])
    else:
        #  03 nn nn nn xx dd ... dd  Fast Read (260 bytes)
        p = READ_DATA + three_bytes(ad) + bytearray(256 * [0])
    r, addr = do_message(s, p)
    if len(r) != len(p):
        logging.warning('length error %d reading address %d\n' % (len(r), ad))
    block = r[-256:]
    return block


# C. Wolf's spiflash.v simulation of a W25Q128JV needs to hear this command
# before it will run normal commands
def power_up(s):
    p = RELEASE_PD
    r, addr = do_message(s, p)
    return


# Needed after an attempt to erase or program a write-protected block
def clear_status(s):
    p = CLEAR_STATUS
    r, addr = do_message(s, p)
    return


# Not currently used
def reset_chip(s):
    p = RESET_CHIP
    r, addr = do_message(s, p)
    return


def page_program(s, ad, bd):
    # 256 bytes of data 'bd' to be writen to page at address 'ad'
    if len(bd) != PAGE:
        logging.warning('length of data %d not equal to 256' % (len(bd)))
        # pad with 0xff
        pad = (PAGE - len(bd)) * bytearray(b'\xFF')
        bd += pad
        logging.warning('padded length now %d' % (len(bd)))
    logging.debug('Page Programming at %d...', ad)
    # sys.stdout.write('.')
    p = PAGE_PROG + three_bytes(ad) + bd
    r, addr = do_message(s, p)
    time.sleep(0.00055)
    logging.debug('From: %s \n Tx length: %d\n Rx length: %d\n' % (addr, len(p), len(r)))
    return


# Write Status Register (and optionally Config)
def write_status(s, v, config=None):
    clear_status(s)
    if config is None:
        p = WRITE_ENABLE + WRITE_STATUS + bytes([v])
    else:
        p = WRITE_ENABLE + WRITE_CONFIG + bytes([v, config])
    pp = p + 7 * READ_STATUS_1
    logging.info('Write Status')
    r, addr = do_message(s, pp, verbose=True)


# Read flash content and dump
def flash_dump(s, file_name, ad, page_count, otp=False):
    size = page_count << 8
    logging.info('Dumping flash content from add 0x%x to add 0x%x into %s, length = 0x%x...'
                 % (ad, ad + size, file_name, size))
    f = open(file_name, 'wb')
    for ba in range(ad >> 8, (ad + size) >> 8):
        bd = page_read(s, ba << 8, fast=False, otp=otp)
        f.write(bd)
    f.close()
    return


# Read local file and write to flash from FF to 00
def remote_program(s, file_name, ad, size):
    start_p = ad >> 8
    # start_a = start_p << 8
    stop_p = ((ad + size - 1) >> 8) + 1
    final_a = (stop_p << 8) + 255
    logging.info('Programming file %s to %s from add 0x%x to add 0x%x, length = 0x%x...'
                 % (file_name, IPADDR, ad, final_a, size))
    f = open(file_name, 'rb')
    # assume that '.bin' file size is always less than whole pages
    for ba in reversed(range(start_p, stop_p)):
        print("block %d" % ba)
        f.seek((ba << 8) - ad)
        bd = f.read(PAGE)
        while not (write_enable(s, True)):
            time.sleep(WAIT)
        page_program(s, ba << 8, bd)
    f.close()
    return


# Erase flash from 00 to FF, step 64KB
def remote_erase(s, ad, size):
    start_p = ad >> 16
    start_a = start_p << 16
    stop_p = ((ad + size - 1) >> 16) + 1
    final_a = (stop_p << 16) - 1
    logging.info('Erasing flash %s from addr 0x%x to addr 0x%x, length = 0x%x...'
                 % (IPADDR, start_a, final_a, size))
    for ba in range(start_p, stop_p):
        while not (write_enable(s, True)):
            time.sleep(WAIT)
        erase_mem(s, ba << 16, '64KB')
    return


# Specific to Spartan-6
def reboot_spartan6(s, ad):
    logging.info('Rebooting FPGA %s to add 0x%x...' % (IPADDR, ad))
    #      88ffffffffffffaa9955663261xxxx328103xx32a1xxxx32c103xx30a1000e
    # p = '88ffffffffffffaa995566326100003281030132a1000032c1031030a1000e'.decode('hex')
    p1 = bafromhex('88') + 3 * ICAP_DUMMY + ICAP_SYNC_H + ICAP_SYNC_L
    ad1 = bytearray(struct.pack('!i', ad))
    ad2 = bytearray(struct.pack('!i', GOLDEN_AD))
    p2 = ICAP_W_GEN1 + ad1[2:4] + ICAP_W_GEN2 + bytearray([READ_DATA[1], ad1[1]])
    p3 = ICAP_W_GEN3 + ad2[2:4] + ICAP_W_GEN4 + bytearray([READ_DATA[1], ad2[1]])
    p4 = ICAP_W_CMD + ICAP_IPROG
    p = p1 + p2 + p3 + p4 + 113 * ICAP_NOOP
    print(hexfromba(p))
    if len(p) != 257:
        print("internal error")
        sys.exit()
    s.send(MSG_PREFIX + p)
    # if the reboot succeeds, we don't get an answer.
    # could read with a timeout, as a way to report failure to reboot.


def reboot_7series(s, ad):
    '''
    ICAPE2 commands (7-series)
    UG953? no, that just covers instantiation
    XAPP1247? no
    UG470? yes, see example in Table 5-18, Configuration Packets on p. 103,
    and register address in Table 5-22.
    FFFFFFFF  dummy
    AA995566  sync
    20000000  Type 1 No Op
    30020001  Type 1 Write 1 word to WBSTAR
    00000000  Warm Boot Start Address
    30008001  Type 1 Write 1 word to CMD
    0000000F  IPROG command
    20000000  Type 1 No Op
    Our hardware uses 16-bit access to ICAPE2, but that's kind of hidden
    '''
    wbstar = "%8.8x" % ad
    # first command byte encodes payload length 256, route to ICAPE2
    cmds = "88" + "FFFFFFFFFFFFFFFFAA9955662000000030020001" + wbstar + "300080010000000F"
    icape2_noop = "20000000"
    print(cmds)
    cmdb = bafromhex(cmds + 56 * icape2_noop)
    if len(cmdb) != 257:
        print("internal error")
        sys.exit()
    s.send(MSG_PREFIX + cmdb)


def main():
    logging.basicConfig(format='%(levelname)s:%(message)s', level=logging.INFO)
    import argparse
    parser = argparse.ArgumentParser(
        description="Utility for working with SPI Flash chips attached to Packet Badger")
    parser.add_argument('--ip', default='192.168.19.8', help='IP address')
    parser.add_argument('--udp', type=int, default=804, help='UDP Port number')
    parser.add_argument('-a', '--add', type=lambda x: int(x, 0), help='Flash offset address')
    parser.add_argument('--pages', type=int, help='Number of 256-byte pages')
    parser.add_argument('--mem_read', action='store_true', help='Read ROM info')
    parser.add_argument('--id', action='store_true',
                        help='Read SPI flash chip identification and status')
    parser.add_argument('--erase', type=lambda x: int(x, 0),
                        help='Number of 256-byte sectors to erase')
    parser.add_argument('--power', action='store_true', help='power up the flash chip')
    parser.add_argument('--program', type=str, help='File to be stored in SPI Flash')
    parser.add_argument('--dump', type=str, help='Dump flash memory contents into file')
    parser.add_argument('--wait', default=0.001, type=float,
                        help='Wait time between consecutive writes (seconds)')
    parser.add_argument('--otp', action='store_true',
                        help='Access One Time Programmable area of S25FL chip')
    parser.add_argument('--clear_status', action='store_true',
                        help='Clear status (CLSR)')
    parser.add_argument('--status_write', type=lambda x: int(x, 0),
                        help='A value to be written to status register (Experts only)')
    parser.add_argument('--config_write', type=lambda x: int(x, 0),
                        help='A value to be written to the config register (Experts only)')
    parser.add_argument('--config_init', action='store_true',
                        help='Set OTP bits to Marble default')
    # TODO: Does the user really need to know this? Can this just be queried from the chip?
    parser.add_argument('--reboot6', action='store_true',
                        help='Reboot chip using Xilinx Spartan6 ICAP primitive')
    parser.add_argument('--reboot7', action='store_true',
                        help='Reboot chip using Xilinx 7-Series ICAPE2 primitive')
    args = parser.parse_args()

    # numeric_level = getattr(logging, "DEBUG", None)
    # logging.basicConfig(level=numeric_level)

    global IPADDR, PORTNUM, WAIT
    IPADDR, PORTNUM, WAIT = args.ip, args.udp, args.wait
    # initialize a socket, think of it as a cable
    # SOCK_DGRAM specifies that this is UDP
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM, 0)
    # connect the socket, think of it as connecting the cable to the address location

    sock.connect((IPADDR, PORTNUM))

    # default starting address and length
    ad = args.add if args.add is not None else 0x0
    # 1814 for XC6SLX16, could also get this from JEDEC status?
    page_count = 1814
    page_count = 2

    if args.pages is not None:
        page_count = args.pages

    if args.power:
        power_up(sock)

    if args.dump is not None:
        flash_dump(sock, args.dump, ad, page_count, otp=args.otp)

    if args.program is not None:
        cmd, cnf = read_status_config(sock)
        # require TBPROT set, BPNV clear
        # ignore DNU and TBPARM at least for now
        if (cnf & 0x28) != 0x20:
            print("CONFIG_REG 0x%2x OTP bits not good for programming!" % cnf)
            exit(1)
        prog_file = args.program
        fileinfo = os.stat(prog_file)
        size = fileinfo.st_size
        print("file size %d" % size)
        if size > 7*1024*1024:
            print("Too big!")
            exit(1)
        clear_status(sock)
        remote_erase(sock, ad, size)
        remote_program(sock, prog_file, ad, size)

    if args.erase:
        remote_erase(sock, ad, args.erase)

    if args.clear_status:
        clear_status(sock)

    if args.id:
        read_id(sock)
        read_status_config(sock, verbose=True)

    # TODO: Ignoring test_tx since no codepath exists

    if args.config_init:
        write_status(sock, 0x18, config=0x24)
        write_status(sock, 0x18, config=0x25)
    elif args.status_write is not None:
        write_status(sock, args.status_write, config=args.config_write)

    if args.reboot6:
        reboot_spartan6(sock, ad)
    elif args.reboot7:
        reboot_7series(sock, ad)

    logging.info('Done.')

    # close the socket
    sock.close()


if __name__ == "__main__":
    main()
