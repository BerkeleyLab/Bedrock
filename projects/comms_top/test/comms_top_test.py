#!/usr/bin/python3

from collections import OrderedDict
import binascii
from socket import socket, AF_INET, SOCK_DGRAM
import argparse
import sys
import time


class udpPacket:
    NONCE_SIZE = 8
    PAYLOAD_SIZE = 8

    SRCPORT = 'srcport'
    DSTPORT = 'dstport'
    LEN = 'len'
    CHECKS = 'checks'
    NONCE = 'nonce'
    PAYL = 'payl'

    # LBUS Dictionary
    CTL_SIZE = 1
    ADDR_SIZE = 3
    DATA_SIZE = 4

    CTL = 'ctl'
    ADDR = 'addr'
    DATA = 'data'

    def to_bytes(self, int_in, n_bytes, big_endian=True):
        BYTEMASK = 0xFF

        bytes = bytearray(n_bytes)
        for i in range(0, n_bytes):
            bytes[i] = (int_in & (BYTEMASK << (n_bytes-(i+1))*8)) >> (n_bytes-(i+1))*8

        return bytes

    def __init__(self, dst_ip, dst_port, verbose=False):

        self.verbose = verbose

        self.dst_ip = dst_ip
        self.dst_port = int(dst_port)
        self.nonce = 0

        self.udp_dict = OrderedDict({})
        self.udp_dict[self.NONCE] = self.to_bytes(self.nonce, self.NONCE_SIZE)
        self.udp_dict[self.PAYL] = self.to_bytes(0, self.PAYLOAD_SIZE)

    def to_udp_dgram(self, bdata):
        self.udp_dict[self.PAYL] = bdata

        self.nonce += 1
        self.udp_dict[self.NONCE] = self.to_bytes(self.nonce, self.NONCE_SIZE)

        udp_dgram = bytearray()
        for val in list(self.udp_dict.values()):
            udp_dgram += val

        if self.verbose:
            print("==> UDP DGRAM LEN: %d" % len(udp_dgram))
            print("==> UDP DGRAM: %s" % binascii.hexlify(udp_dgram))

        return udp_dgram

    def local_bus_access(self, rnw, addr, data):
        self.lbus_dict = OrderedDict({})
        self.lbus_dict[self.CTL] = self.to_bytes(rnw, self.CTL_SIZE)
        self.lbus_dict[self.ADDR] = self.to_bytes(addr, self.ADDR_SIZE)
        self.lbus_dict[self.DATA] = self.to_bytes(data, self.DATA_SIZE)

        lbus_payload = bytearray()
        for k in list(self.lbus_dict.keys()):
            lbus_payload += self.lbus_dict[k]

        # Form UDP datagram
        return self.to_udp_dgram(lbus_payload)

    def get_lbus_read(self, addr):
        return self.local_bus_access(0x10, addr, 0)

    def get_lbus_write(self, addr, wdata):
        return self.local_bus_access(0, addr, wdata)

    def send_recv(self, bdata_send):
        bdata_size = len(bdata_send)

        tsend = time.perf_counter()
        UDPSock.sendto(bdata_send, (self.dst_ip, self.dst_port))

        data_recv = str()
        data_recv = UDPSock.recv(bdata_size)
        trcv = time.perf_counter()

        if not data_recv:
            print("Warning: No data received")
            return None
        else:
            dgram_hex = binascii.hexlify(data_recv)
            dgram_data_hex = binascii.hexlify(data_recv[12:])
            dgram_data_ascii = data_recv[12:]
            if self.verbose:
                print("<== Received DGRAM: {}".format(dgram_hex))
                print("<== # Hex data: {}".format(dgram_data_hex))
                print("<== # Ascii data: {}".format(dgram_data_ascii))
                print("(Time elapsed %f us)" % ((trcv-tsend)*1e6))
                print("===========")

            return (dgram_data_hex, dgram_data_ascii)


class cfileParser:

    def _badarg(self, cmd):
        print("ERROR: Bad arguments to command {}".format(cmd))

    def _pprint(self, cmd, args):
        if (len(args) == 0):
            self._badarg(cmd)
            return
        print("\n> {}\n".format(" ".join(args)))

    def _pread(self, cmd, args):
        if (len(args) != 1):
            self._badarg(cmd)
            return
        raddr = int(args[0].lstrip(':'), 0)
        bdata = udp_packet.get_lbus_read(raddr)
        (d_hex, d_asc) = udp_packet.send_recv(bdata)

        print("{} {} RDATA = {} ({})".format(cmd, " ".join(args), d_hex, d_asc))

    def _pwrite(self, cmd, args):
        if (len(args) != 2):
            self._badarg(cmd)
            return
        waddr = int(args[0].lstrip(':'), 0)
        wdata = int(args[1], 0)
        bdata = udp_packet.get_lbus_write(waddr, wdata)
        udp_packet.send_recv(bdata)

        print("{} {}".format(cmd, " ".join(args)))

    def _prdmem(self, cmd, args):
        if (len(args) != 3):
            self._badarg(cmd)
            return
        base_addr = int(args[0].lstrip(':'), 0)
        read_length = int(args[1], 0)
        out_file = args[2]
        with open(out_file, 'w') as FW:
            for i in range(0, read_length):
                bdata = udp_packet.get_lbus_read(base_addr+i)
                (d_hex, d_asc) = udp_packet.send_recv(bdata)

                # Convert to decimal; pay attention to endianness
                d_dec = int.from_bytes(binascii.unhexlify(d_hex), byteorder='big')
                FW.write("{} ".format(d_dec))

        print("{} {} : Successfully read {} memory positions".format(cmd, " ".join(args), read_length))

    def _pwait(self, cmd, args):
        if (len(args) != 1):
            self._badarg(cmd)
            return
        tsleep = int(args[0])

        print("{} {}".format(cmd, " ".join(args)))
        time.sleep(tsleep)

    def _pcmp(self, cmd, args):
        if (len(args) != 2):
            self._badarg(cmd)
            return

        raddr = int(args[0].lstrip(':'), 0)
        bdata = udp_packet.get_lbus_read(raddr)
        (d_hex, d_asc) = udp_packet.send_recv(bdata)

        ref_data = int(args[1], 0)
        passnfail = "OK"
        if int(d_hex, 16) != ref_data:
            passnfail = "BAD"
            self.n_err += 1

        print("{} {} == {} {} ({})".format(cmd, args[0], args[1], passnfail, d_hex))

    def _parse_map(self, cmd, args):
        func_map = {"PRINT": self._pprint,
                    "WRW": self._pwrite,
                    "RDW": self._pread,
                    "RDMEM": self._prdmem,
                    "WAIT": self._pwait,
                    "CMP": self._pcmp,
                    }
        f = func_map.get(cmd, None)
        if not f:
            print(("ERROR: Unrecognized command {}".format(cmd)))
        f(cmd, args)

    def __init__(self, udp_packet, ifile=None):
        self.udp_packet = udp_packet

        self.n_err = 0

        if not ifile:
            print("Warning: No command file specified, test read sequence will be issued instead.")
        else:
            self.FH = open(ifile, 'r')

    def run_test_seq(self):
        for i in range(10):
            bdata = udp_packet.get_lbus_read(i)
            udp_packet.send_recv(bdata)

    def parse_and_run(self):
        lines = self.FH.readlines()

        for line in lines:
            if line.startswith('#') or line.startswith('\n'):
                continue

            line_s = line.rstrip('\n').split()
            self._parse_map(line_s[0], line_s[1:])

    def run(self):
        if not self.FH:
            self.run_test_seq()
        else:
            self.parse_and_run()

        return self.n_err


parser = argparse.ArgumentParser(description='Write raw UDP', formatter_class=argparse.ArgumentDefaultsHelpFormatter)
parser.add_argument('-t', '--target', default='192.168.1.173', help='Target IP address')
parser.add_argument('-p', '--port', default='803', help='Target port')
parser.add_argument('-cf', '--cfile', default=None, help='Command file')
args = parser.parse_args()

UDPSock = socket(AF_INET, SOCK_DGRAM)
UDPSock.settimeout(2)

print("Targeting %s:%s" % (args.target, args.port))

udp_packet = udpPacket(args.target, args.port, verbose=False)

cfile_parser = cfileParser(udp_packet, ifile=args.cfile)

n_err = cfile_parser.run()
print(("="*40))
print(("Reached the end of {} with {} errors.".format(args.cfile, n_err)))
print(("="*40))

sys.exit(n_err)


UDPSock.close()
