
import socket
import numpy
import json
import math
import random

from leep.build_rom import create_array
from leep.cli import parseTransaction


class LASS():
    be32 = numpy.dtype('>u4')
    be16 = numpy.dtype('>u2')
    # see badger/mem_gate.md
    OP_WRITE = 0b00
    OP_READ  = 0b01
    OP_BURST = 0b10

    _valid_ops = (OP_WRITE, OP_READ, OP_BURST)

    class InvalidPacket(Exception):
        def __init__(self, msg):
            super().__init__(msg)

    @classmethod
    def _pack(cls, addrs, values=None, request=True, nonce=None):
        """Returns (int nonce, bytes packet)"""
        pad = None
        if len(addrs) < 3:
            pad = 3 - len(addrs)
            addrs.extend([0] * pad)
            values.extend([None] * pad)
        msg = numpy.zeros(2 + 2 * len(addrs), dtype=cls.be32)
        if nonce is None:
            msg[0] = random.randint(0, 0xffffffff)
        else:
            msg[0] = int(nonce) & 0xffffffff
        msg[1] = msg[0] ^ 0xffffffff
        for i, (A, V) in enumerate(zip(addrs, values), 1):
            A &= 0x00ffffff
            if (request and (V is None)) or ((not request) and (V is not None)):
                A |= 0x10000000
            msg[2 * i] = A
            msg[2 * i + 1] = V or 0
        return (msg[0], msg.tobytes())

    @classmethod
    def _unpack(cls, pkt, request=True):
        """Returns (nonce, xacts) where 'xacts' is enumerator of (addr, value) pairs.
        For a request packet ('request' = True), for each (addr, value) pair, if 'value' is None,
        it's a read from address 'address', otherwise it's a write to address 'addr'.
        For a response packet ('request' = False), for each (addr, value) pair, if 'value' is None,
        it's a response to a write to address 'address', otherwise it's the value read from address 'addr'.
        """
        if len(pkt) % 4 > 0:
            raise cls.InvalidPacket("Fragmented packet")
        pkt_info = numpy.frombuffer(pkt, cls.be32)
        nonce, xor_nonce = pkt_info[0:2]
        if len(pkt_info) < 4:
            raise cls.InvalidPacket("Packet too small")
        if xor_nonce != (nonce ^ 0xffffffff):
            raise cls.InvalidPacket("Failed nonce check")
        expect_data = False
        burst_count = 0
        addrs = []
        values = []
        rnw = True
        addr = 0
        for word in pkt_info[2:]:
            if not expect_data:
                addr = word & 0xffffff
                cmd = (word >> 24)
                op = (cmd >> 4) & 3
                if op == cls.OP_BURST:
                    expect_data = False
                    burst_count = addr & 0x1ff  # 9-bit burst count
                elif op in (cls.OP_READ, cls.OP_WRITE):
                    expect_data = True
                    rnw = op == cls.OP_READ
            else:
                addrs.append(addr)
                if request:
                    if rnw:
                        values.append(None)
                    else:
                        values.append(word)
                else:
                    if rnw:
                        values.append(word)
                    else:
                        values.append(None)
                if burst_count == 0:
                    expect_data = False
                else:
                    addr = addr + 1
        return (nonce, addrs, values)

    @classmethod
    def pack_request(cls, addrs, values=None):
        return cls._pack(addrs, values, request=True)

    @classmethod
    def unpack_request(cls, pkt):
        """Returns (int nonce, list addrs, list values)
        For each (addr, value) pair, if 'value' is None, it's a read from address 'address'.
        Otherwise it's a write to address 'addr'."""
        return cls._unpack(pkt, request=True)

    @classmethod
    def pack_response(cls, nonce, addrs, values=None):
        return cls._pack(addrs, values, request=False, nonce=nonce)

    @classmethod
    def unpack_response(cls, pkt):
        """Returns (int nonce, list addrs, list values)
        For each (addr, value) pair, if 'value' is None, it's a response to a write to address 'address'.
        Otherwise it's the value read from address 'addr'."""
        return cls._unpack(pkt, request=False)


class RespondingDevice():
    @staticmethod
    def mem(aw, signed=True):
        if signed:
            dt = numpy.int32
        else:
            dt = numpy.uint32
        return numpy.zeros((1 << aw,), dtype=dt)

    def __init__(self, portnum, verbose=False):
        self._verbose = verbose
        self._port = int(portnum)
        self.regmap = {
            "foo": {
                "base_addr": 0,
                "addr_width": 8,
                "signed": True,
                "data_width": 32,
                "access": "rw",
            },
            "bar": {
                "base_addr": 0x1000,
                "addr_width": 1,
                "data_width": 32,
                "access": "rw",
            },
            "rom": {
                "base_addr": 0x4000,
                "addr_width": 10,
                "data_width": 16,
                "access": "r",
            },
        }
        self._regmap = self.regmap.copy()
        self.build_regmap()

    def build_regmap(self):
        # Make sure the ROM gets built first
        for name, entry in self.regmap.items():
            if name == "rom":
                entry["mem"] = self._mkROM()
                break
        # Then add memory regions
        for name, entry in self.regmap.items():
            if name != "rom":
                entry["mem"] = self.mem(entry.get("addr_width", 0), signed=entry.get("signed", False))
        return

    def _mkROM(self):
        json_file = "test.json"
        with open(json_file, "w") as fd:
            json.dump(self._regmap, fd)
        descrip = "RespondingDevice"
        arr = create_array(descrip.encode("utf-8"), json_file, placeholder_rev=True)
        aw = math.ceil(math.log2(len(arr)))
        mem = self.mem(aw, signed=False)
        mem[:len(arr)] = arr
        return mem

    def _print(self, *args, **kwargs):
        if self._verbose:
            print(*args, **kwargs)

    def runServer(self):
        server_sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM, 0)
        # server_sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM | socket.SOCK_NONBLOCK, 0)
        server_sock.bind(('', self._port))
        print("Listening on port {}".format(self._port))
        print("  Use keyboard interrupt (ctrl+c) to terminate")
        while True:
            try:
                msg, msg_addr = server_sock.recvfrom(1472)
                nonce, addrs, values = LASS.unpack_request(msg)
                for n in range(len(addrs)):
                    addr = addrs[n]
                    value = values[n]
                    if value is None:
                        # it's a read
                        self._print("Server Received: READ from 0x{:x}".format(addr))
                        rval = self.read(addr)
                        values[n] = rval
                    else:
                        # it's a write
                        self._print("Server Received: WRITE 0x{:x} to 0x{:x}".format(value, addr))
                        self.write(addr, value)
                        values[n] = None
                nonce_out, response = LASS.pack_response(nonce, addrs, values)
                server_sock.sendto(response, msg_addr)
            except KeyboardInterrupt:
                break
        print("Done")
        server_sock.close()
        return

    def read(self, addr):
        for name, entry in self.regmap.items():
            base = entry["base_addr"]
            end = entry["base_addr"] + (1 << entry["addr_width"])
            if addr >= base and addr < end:
                return entry["mem"][addr-base]
        return 0

    def write(self, addr, value):
        for name, entry in self.regmap.items():
            base = entry["base_addr"]
            end = entry["base_addr"] + (1 << entry["addr_width"])
            if addr >= base and addr < end:
                entry["mem"][addr-base] = value
                return None
        return None


def test_parseTransaction():
    # Baddies raise Exception, so we'll indicate this as the expected
    # result by setting the "result" value below to None
    dd = {
        # CLI string: result (reg, offset, read_size, write_vals)
        # regname                 Read from named register (str) 'regname'
        "foo": ("foo", 0, None, None),
        # regaddr                 Read from explicit address (int) 'regaddr'
        "0x100": (0x100, 0, None, None),
        # regname=val             Write (int) 'val' to named register (str) 'regname'
        "foo=42": ("foo", 0, 0, 42),
        "bar=0x42": ("bar", 0, 0, 0x42),
        "foo_baz=0b100": ("foo_baz", 0, 0, 0b100),
        # regaddr=val             Write (int) 'val' to explicit address (int) 'regaddr'
        "0x123=100": (0x123, 0, 0, 100),
        "123=0xabc": (123, 0, 0, 0xabc),
        "0b1010=-10": (0b1010, 0, 0, -10),
        # regname=val0,...,valN   Write (int) 'val0' through 'valN' to consecutive addresses beginning at the
        #                         address of named register (str) 'regname'
        "reg_foo=1,2,3,4,5": ("reg_foo", 0, 0, [1, 2, 3, 4, 5]),
        # regaddr=val0,...,valN   Write (int) 'val0' through 'valN' to consecutive addresses beginning at
        #                         address (int) 'regaddr'
        "0x4000=1,-1,0,42,0x10": (0x4000, 0, 0, [1, -1, 0, 42, 0x10]),
        # regname+offset          Read from address = romx['regname']['base_addr'] + (int) 'offset'
        "BINGO+100": ("BINGO", 100, None, None),
        # regaddr+offset          Read from address = (int) 'regaddr' + (int) 'offset'
        "0x100+100": (0x100, 100, None, None),
        # regname:size            Read (int) 'size' elements starting from address romx['regname']['base_addr']
        "_reg_:32": ("_reg_", 0, 32, None),
        # regaddr:size            Read (int) 'size' elements starting from (int) 'regaddr'
        "0:0xff": (0, 0, 0xff, None),
        # regname+offset=val      Write (int) 'val' to address romx['regname']['base_addr'] + (int) 'offset'
        "bandit+0x100=5000": ("bandit", 0x100, 0, 5000),
        # regname+offset=val0,...,valN    Write (int) 'val0' through 'valN' to consecutive addresses beginning at
        #                                 address romx['regname']['base_addr'] + (int) 'offset'
        "status+0x20=50,40,0x30": ("status", 0x20, 0, [50, 40, 0x30]),
        # regaddr+offset=val      Write (int) 'val' to address (int) 'regaddr' + (int) 'offset'
        "128+0xc0=-1000": (128, 0xc0, 0, -1000),
        # regaddr+offset=val0,...,valN    Write (int) 'val0' through 'valN' to consecutive addresses beginning at
        #                                 address (int) 'regaddr'
        "0x128+0xc0=1,0,1,0,2": (0x128, 0xc0, 0, [1, 0, 1, 0, 2]),
        # regname+offset:size     Read (int) 'size' elements starting from address romx['regname']['base_addr'] + \
        #                         (int) 'offset'
        "Socks+0x100:100": ("Socks", 0x100, 100, None),
        # regaddr+offset:size     Read (int) 'size' elements starting from (int) 'regaddr' + (int) 'offset'
        "0x4000+15:0b1111": (0x4000, 15, 0b1111, None),
    }
    errors = 0
    for _input, _expected in dd.items():
        try:
            result = parseTransaction(_input)
        except Exception:
            result = None
        if result != _expected:
            print("Failed on input: {}.\n  Expected: {}\n  Result:   {}".format(_input, _expected, result))
            errors += 1
    return errors


def doTests(args):
    errors = 0
    errors += test_parseTransaction()
    if errors == 0:
        print("PASSED")
        return 0
    else:
        print("FAILED with {} errors".format(errors))
    return 1


def runServer(args):
    dev = RespondingDevice(4592, verbose=False)
    dev.runServer()
    return 0


if __name__ == "__main__":
    import argparse
    import sys
    parser = argparse.ArgumentParser("LEEP CLI Test")
    parser.set_defaults(handler=lambda args: None)
    subparsers = parser.add_subparsers(help="Subcommands")
    parserServer = subparsers.add_parser("server", help="Run a simulated LEEPDevice server.")
    parserServer.set_defaults(handler=runServer)
    parserTest = subparsers.add_parser("test", help="Run regression tests.")
    parserTest.set_defaults(handler=doTests)
    args = parser.parse_args()
    sys.exit(args.handler(args))
