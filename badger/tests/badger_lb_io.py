#!/usr/bin/env python
'''
Access to localbus gateway, supporting testing of Packet Badger
'''
import argparse
import sys
import os

sys.path.append(os.path.join(os.path.dirname(__file__), "../"))

from lbus_access import lbus_access


def show_trace(chip, b1):
    data = []
    # o = 0
    for ix in range(64):
        base = b1 + 64*ix
        addr_list = range(base, base+64)
        data = chip.exchange(addr_list, [None]*len(addr_list))
        # print("\n".join(["%8.8x" % x for x in data]))
        zz = zip(data[0::8], data[1::8], data[2::8], data[3::8], data[4::8], data[5::8], data[6::8], data[7::8])
        for a1, a2, a3, a4, a5, a6, a7, a8 in zz:
            ll = (a1 & 0x7f) + 128*(a2 & 0xf)  # length
            c = a3 & 0x3  # category
            f = (a3 >> 2) & 0x7  # flags
            u = (a3 >> 5) & 0x7  # udp port category
            # a4 is unused
            t = (((((a5 << 8) + a6) << 8) + a7) << 8) + a8
            # do = ll-o  # delta-length
            # print("%2x %2x %2x %2x %10d : %4d %d %x %d : %d" % (a1, a2, a3, a4, t, ll, c, f, u, do))
            print("%2x %2x %2x %2x %10d : %4d %d %x %d" % (a1, a2, a3, a4, t, ll, c, f, u))
            # o = ll  # old


def reset_trace(chip):
    chip.exchange([4, 4], [1, 0])


def show_short(chip):
    base = 0x110000
    xa = chip.exchange(range(base, base+6), [None]*6)
    for ix, x in enumerate(xa):
        if ix == 5:
            ppm = (float(x)/2**27-1.0)*1e6
            print("%d:  %10d   %+.2f ppm" % (ix, x, ppm))
        elif ix == 4:
            print("%d:  %10d" % (ix, x))
        else:
            print("%d:  %10d  %8x" % (ix, x, x))


def process_fd(fd):
    # Also ssee packet2txmac.py
    addrs = []
    values = []
    aw = 10
    mac_base = 0x100000  # defined in hw_test.v and rtefi_pipe_tb.v
    mac_ctl = mac_base + (1 << aw)  # defined in mac_subset.v
    buf_start = 16  # arbitrary
    data_start = mac_base + buf_start + 1
    n = 0
    ov = None
    addrs += [mac_ctl + 1]  # acknowledge last packet (!?)
    values += [0]
    for x in fd.read().split('\n'):
        if x == "":
            continue
        v = int(x, 16)
        if n % 2:
            vv = ov + (v << 8)  # little-endian
            addrs += [data_start + int(n/2)]
            values += [vv]
        n += 1
        ov = v
    if n % 2:
        addrs += [data_start + int(n/2)]
        values += [v]
    # length of packet
    addrs += [mac_base + buf_start]
    values += [n]
    # trigger send by MAC
    addrs += [mac_ctl]
    values += [buf_start]
    return addrs, values


if __name__ == "__main__":
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument(
        '--ip',
        help='IP address of FPGA',
        default="localhost"
    )
    p.add_argument(
        '--port',
        help="UDP port for I/O",
        default=803
    )
    p.add_argument(
        '--file',
        help="File with R/W commands in hex",
        default=None
    )
    p.add_argument(
        'command',
        help='reset | tx | rx | show'
    )
    args = p.parse_args()
    foo = lbus_access(args.ip, port=args.port)
    if not foo:
        print("lbus_access setup failed")
        exit(1)
    if args.command == "reset":
        reset_trace(foo)
    elif args.command == "show":
        show_short(foo)
    elif args.command == "rx":
        show_trace(foo, 0x010000)
    elif args.command == "tx":
        show_trace(foo, 0x020000)
    elif args.command == "arb":
        if args.file is None:
            fd = sys.stdin
        else:
            fd = open(args.file, "r")
        addrs, values = process_fd(fd)
        foo.exchange(addrs, values)
    else:
        print("usage: python badger_lb_io.py reset|show|tx|rx")
