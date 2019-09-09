#!/usr/bin/python

# flake8: noqa: E221

# ifconfig eth0 up 192.168.21.1
# route add -net 192.168.8.0 netmask 255.255.255.0 dev eth0

# also see ~/llrf/eth_2012/lantest
# and ~/llrf/eth_2012/UDP_TxRx_test.lua

# Winbond W25X16, W25X32, W25X64
# See w25x.pdf and spi_flash_engine.v

import socket
import struct
import time
import logging
import sys
import getopt
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
READ_JEDEC_ID  = bafromhex(b'049f000000')      # 9F dd dd dd        Read JEDEC ID
READ_DEVICE_ID = bafromhex(b'06900000000000')  # 90 00 00 00 dd dd  Read Device ID

ERASE_SECTOR   = bafromhex(b'0420')            # 20 nn nn nn        Erase Sector (4kB)
ERASE_BLOCK_32 = bafromhex(b'0452')            # 52 nn nn nn        Erase Block  (32kB)
ERASE_BLOCK_64 = bafromhex(b'04d8')            # d8 nn nn nn        Erase Block  (64kB)
READ_FAST      = bafromhex(b'0d0b')            # 0b nn nn nn        Fast Read (261 bytes)
READ_DATA      = bafromhex(b'0c03')            # 03 nn nn nn        Read Data (260 bytes)
PAGE_PROG      = bafromhex(b'0c02')            # 02 nn nn nn dd     Page program (260 bytes)
WRITE_DISABLE  = bafromhex(b'0104')            # 04                 Write Disaable
WRITE_ENABLE   = bafromhex(b'0106')            # 06                 Write Enable
WRITE_STATUS   = bafromhex(b'0201')            # 05 dd              Write Status Register

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
        flusher = CHK_PREFIX + bytearray(len(p)*[0])
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
    r, addr = do_message(s, p)
    manu_id = r[len(r) - 2]
    dev_id = r[len(r) - 1]
    capacity = r[len(r) - 8]
    mem_type = r[len(r) - 9]
    logging.debug('From: %s \n Tx length: %d\n Rx length: %d\n' % (addr, len(p), len(r)))
    print('Manufacturer ID: %02x' % manu_id)
    print('Device ID:       %02x' % dev_id)
    print('Memory Type:     %02x' % mem_type)
    print('Capacity:        %02x' % capacity)
    return


# Read status reg 1, twice for good measure
def read_status(s):
    p = 2 * READ_STATUS_1
    r, addr = do_message(s, p)
    status_reg = r[len(r) - 1]
    logging.debug('From: %s \n Tx length: %d\n Rx length: %d\n' % (addr, len(p), len(r)))
    logging.info('Check Status Reg: %02x' % status_reg)
    return ~status_reg


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
    logging.info('Erasing at address 0x%x...', ad)
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
    return (status_reg & 0x3) == 0x2


# encode an integer as three bytes
# used to specify addresses when building SPI commands
def three_bytes(ad):
    adx = struct.pack('!i', ad)
    return bytearray(adx[1:4])


def page_read(s, ad, fast=False):
    if fast:
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


# Clifford's spiflash.v simulation of a W25Q128JV needs to hear this command
# before it will run normal commands
def power_up(s):
    p = RELEASE_PD
    r, addr = do_message(s, p)
    return


def page_program(s, ad, bd):
    # 256 bytes of data 'bd' to be writen to page at address 'ad'
    if len(bd) != PAGE:
        logging.warning('length of data %d not equal to 256' % (len(bd)))
        # pad with 0xff
        bd += (PAGE - len(bd)) * '\xFF'
        logging.warning('padded length now %d' % (len(bd)))
    logging.debug('Page Programming at %d...', ad)
    # sys.stdout.write('.')
    p = PAGE_PROG + three_bytes(ad) + bd
    r, addr = do_message(s, p)
    time.sleep(0.00055)
    logging.debug('From: %s \n Tx length: %d\n Rx length: %d\n' % (addr, len(p), len(r)))
    return


# Write Status Register
def write_status(s, v):
    p = WRITE_ENABLE + WRITE_STATUS
    vx = struct.pack('!i', v)
    pp = p + vx[3] + 7 * READ_STATUS_1
    logging.info('Write Status')
    r, addr = do_message(s, pp, verbose=True)


# Read flash content and dump
def flash_dump(s, file_name, ad, page_count):
    size = page_count << 8
    logging.info('Dumping flash content from add 0x%x to add 0x%x into %s, length = 0x%x...'
                 % (ad, ad + size, file_name, size))
    f = open(file_name, 'wb')
    for ba in range(ad >> 8, (ad + size) >> 8):
        bd = page_read(s, ba << 8)
        f.write(bd)
    f.close()
    return


# Read local file and write to flash from FF to 00
def remote_program(s, file_name, ad, size):
    start_p = ad >> 8
    start_a = start_p << 8
    stop_p = ((ad + size - 1) >> 8) + 1
    final_a = (stop_p << 8) - 1
    logging.info('Programming file %s to %s from add 0x%x to add 0x%x, length = 0x%x...'
                 % (file_name, IPADDR, ad, (((ad + size) >> 8) + 1) << 8, size))
    f = open(file_name, 'r')
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
def reboot_fpga(s, ad):
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
    if False:
        # This is now implemented in FPGA gateware
        print("bit-reversing bytes")
        prev = p[0]
        for ix in range(1, len(p)):   # don't bit-swap the length byte
            b = ord(p[ix])
            prev += byterev(b)
        p = prev
    s.send(p)
    # if the reboot succeeds, we don't get an answer.
    # could read with a timeout, as a way to report failure to reboot.
    return


def usage():
    print('usage: spi_test.py [commands]')
    print('Commands:')
    print('-h, --help')
    print('-a, --add <address in hex>')
    print('-d, --dump <filename>')
    print('-m, --mem_read # Read ROM info')
    print('-p, --program <filename>')
    print('-e, --erase <size in hex (min 64KB)>')
    print('-i, --id')
    print('-s, --status <new_value in hex>')
    print('-t, --test_tx')
    print('-r, --reboot')


# Main procedure
def main(argv):
    logging.basicConfig(format='%(levelname)s:%(message)s', level=logging.INFO)
    try:
        helps = ["dump=", "program=", "erase=", "add=", "size=", "id", "power",
                 "test_tx", "reboot", "status=", "ip=", "udp=", "pages=", "wait=",
                 "status_write="]
        opts, args = getopt.getopt(argv, "hie:td:p:ra:s:", helps)
    except getopt.GetoptError as err:
        print(str(err))
        usage()
        sys.exit(2)

    global IPADDR, PORTNUM, WAIT
    for opt, arg in opts:
        if opt in ("--ip"):
            IPADDR = arg
        if opt in ("--udp"):
            PORTNUM = int(arg)

    # initialize a socket, think of it as a cable
    # SOCK_DGRAM specifies that this is UDP
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM, 0)
    # connect the socket, think of it as connecting the cable to the address location
    s.connect((IPADDR, PORTNUM))

    # default starting address and length
    ad = 0x0
    # 1814 for XC6SLX16, could also get this from JEDEC status?
    page_count = 1814
    page_count = 2

    for opt, arg in opts:
        if opt in ("-a", "--add"):
            ad = int(arg, base=16)
        if opt in ("--pages"):
            page_count = int(arg)
        if opt in ("--wait"):
            WAIT = float(arg)

    for opt, arg in opts:
        if opt in ("-h", "--help"):
            usage()
            sys.exit()
        elif opt in ("--power"):
            power_up(s)
        elif opt in ("--dump", "-d"):
            dump_file = arg
            flash_dump(s, dump_file, ad, page_count)
        elif opt in ("--program", "-p"):
            prog_file = arg
            fileinfo = os.stat(prog_file)
            size = fileinfo.st_size
            print("file size %d" % size)
            remote_erase(s, ad, size)
            remote_program(s, prog_file, ad, size)
        elif opt in ("--erase", "-e"):
            size = int(arg, base=16)
            remote_erase(s, ad, size)
        elif opt in ("--id", "-i"):
            read_id(s)
            read_status(s)
        elif opt in ("--test_tx", "-t"):
            test_tx(s)
        elif opt in ("--status_write", "-s"):
            ws = int(arg, base=16)
            write_status(s, ws)
        elif opt in ("--reboot", "-r"):
            reboot_fpga(s, ad)
        # else:
        # assert False, "unhandled option"
    logging.info('Done.')

    # close the socket
    s.close()


if __name__ == "__main__":
    main(sys.argv[1:])
