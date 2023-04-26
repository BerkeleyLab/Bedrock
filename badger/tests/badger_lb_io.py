#!/usr/bin/env python
'''
Access to localbus gateway, supporting testing of Packet Badger
'''
import argparse
import random
import sys
import os
import time
import struct

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
    base_0 = 0x110000
    npt = 9
    addrs = list(range(base_0, base_0+npt))
    nbuf = 14
    rx_mac_b0 = 0x030000
    rx_mac_b1 = rx_mac_b0 + 1024
    addrs += list(range(rx_mac_b0, rx_mac_b0+nbuf))
    addrs += list(range(rx_mac_b1, rx_mac_b1+nbuf))
    xa = chip.exchange(addrs, [None]*len(addrs))
    for ix, x in enumerate(xa[0:npt]):
        if ix == 8:
            uptime = float(x)*1024*8e-9
            print("%d:  %10d   %.3f s uptime" % (ix, x, uptime))
        elif ix == 5:
            ppm = (float(x)/2**27-1.0)*1e6
            print("%d:  %10d   %+.2f ppm" % (ix, x, ppm))
        elif ix == 4:
            print("%d:  %10d" % (ix, x))
        else:
            print("%d:  %10d  %8x" % (ix, x, x))
    ss0 = "".join(" %4.4x" % x for x in xa[npt:npt+nbuf])
    print("Rx b0:" + ss0)
    ss0 = "".join(" %4.4x" % x for x in xa[npt+nbuf:npt+nbuf+nbuf])
    print("Rx b1:" + ss0)


def hello_test(chip):
    base_0 = 0x110000
    npt = 4
    addrs = list(range(base_0, base_0+npt))
    xa = chip.exchange(addrs, [None]*len(addrs))
    hello = ""
    for ix, x in enumerate(xa[0:npt]):
        xx = [((x >> (8*(3-ix))) & 0xff) for ix in range(4)]
        ss = "".join([chr(y) if y >= 32 and y < 128 else "?" for y in xx])
        print("%d:  %8x  %s" % (ix, x, ss))
        hello += ss
    rv = hello == "Hello world!(::)"
    print("PASS" if rv else "FAIL")
    return rv


def set_rx_mac_hbank(chip, hbank, verbose=False):
    base_0 = 0x110000
    rx_mac_status = base_0+7
    base_w = 0
    rx_mac_hbank = base_w+5
    addrs = [rx_mac_status, rx_mac_hbank, rx_mac_status]
    vals = [None, hbank, None]
    xa = chip.exchange(addrs, vals)
    if verbose:
        print(xa)


# This will poll for an available packet, return None if nothing's there.
# It will acknowledge a packet after grabbing it.
def get_rx_pack(chip, verbose=False):
    base_0 = 0x110000
    rx_mac_status = base_0+7
    rx_mac_b0 = 0x030000
    rx_mac_b1 = rx_mac_b0 + 1024
    addrs = [rx_mac_status, rx_mac_b0, rx_mac_b0+1, rx_mac_b1, rx_mac_b1+1]
    xa = chip.exchange(addrs, [None]*len(addrs))
    # print(" ".join(["%4.4x" % x for x in xa]))
    s = xa[0]
    mbank = s & 1
    hbank = s >> 1
    if mbank != hbank:
        if verbose:
            print("buf_stat %d, nothing to read" % s)
        return None
    else:
        hbank = 1-hbank
        lenw = xa[1+2*hbank]
        p_len = ((lenw & 0x7f00) >> 8) + ((lenw & 0x7) << 7)
        if verbose:
            print("buf_stat %s: want to read bank %d, length %d" % (s, hbank, p_len))
        set_rx_mac_hbank(chip, hbank)
        p_left = int((p_len+1)/2)  # reads 1 extra byte, for odd length packets
        a_base = rx_mac_b0 + 2 + 1024*hbank
        p_build = []
        while p_left > 0:
            addrs = list(range(a_base, a_base + min(p_left, 100)))
            xa = chip.exchange(addrs, [None]*len(addrs))
            # print(xa)
            xa_bytes = sum([[x >> 8, x & 0xff] for x in xa], [])
            p_build.extend(xa_bytes)
            p_left -= len(addrs)
        return bytes(p_build)


def tx_mac_build(contents):
    # Also see packet2txmac.py
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
    for v in contents:
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


def process_fd(fd):
    vv = []
    for x in fd.read().split('\n'):
        if x == "":
            continue
        vv += [int(x, 16)]
    return tx_mac_build(vv)


def twobyte(x):
    # network byte order
    return bytes([x >> 8, x & 0xff])


def chksum(msg, wrong=0):
    s = wrong
    for a, b in zip(msg[0::2], msg[1::2]):
        s += b + (a << 8)
    if len(msg) % 2:
        s += msg[-1] << 8
    s += s >> 16
    s = ~s & 0xffff
    # print(hex(s))
    return twobyte(s)


def eth_gen(
        contents,
        src_mac=bytes([0xda, 0x48, 0x9f, 0x29, 0x4d, 0x53]),
        dst_mac=bytes([0x12, 0x55, 0x55, 0x00, 0x01, 0x2d]),
        ethertype=0x00,
        pad=None):
    eth_head = dst_mac + src_mac + bytes([0x08, ethertype])
    content_len = len(contents)
    eth_pad_n = max(64-14-content_len, 0)
    if pad is not None:
        eth_pad_n = pad
    eth_pad = bytes([0]*max(eth_pad_n, 0))
    eth_pack = eth_head + contents + eth_pad
    if pad is not None and pad < 0:
        eth_pack = eth_pack[:pad]
    return eth_pack


def ip_gen(contents, src_ip, dst_ip, ident, ttl, prot, wrong=0, pad=0):
    ip_len = len(contents) + pad + 20
    ip_head_1 = bytes([0x45, 0]) + twobyte(ip_len) + twobyte(ident)
    ip_head_1 += bytes([0x40, 0x00, ttl, prot])
    ip_head_2 = src_ip + dst_ip
    ip_chk = chksum(ip_head_1 + ip_head_2, wrong=wrong)
    ip_head = ip_head_1 + ip_chk + ip_head_2
    padding = bytes([0]*max(pad, 0))
    return ip_head + contents + padding


def udp_gen(
        data=b"",
        src_ip=b"\0\0\0\0",
        dst_ip=b"\0\0\0\0",
        src_port=None,
        dst_port=1000,
        ttl=0x40,
        ident=0,
        udp_wrong=0,
        ip_wrong=0,
        pad=0):
    if src_port is None:
        src_port = int(random.uniform(32768, 65536))
        # src_port = 0x1234
    protocol = 17
    udp_len = len(data) + 8
    udp_chk = bytes([0, 0])  # don't bother
    udp_head = twobyte(src_port) + twobyte(dst_port) + twobyte(udp_len)
    udp_pseudo = src_ip + dst_ip + bytes([0, protocol]) + twobyte(udp_len)
    udp_chk = chksum(udp_pseudo + udp_head + data, wrong=udp_wrong)
    udp_head += udp_chk
    return ip_gen(udp_head + data, src_ip, dst_ip,
                  ident, ttl, protocol, wrong=ip_wrong, pad=pad)


def gen_udp_reply(in_pack, out_data):
    dst_mac = in_pack[6:12]
    src_mac = in_pack[0:6]
    ethertype = bytes([8, 0])
    eth_head = dst_mac + src_mac + ethertype
    #
    # XXX randomize ident
    dst_ip = in_pack[14+12:14+16]
    src_ip = in_pack[14+16:14+20]
    udp_dst, udp_src = struct.unpack('!HH', in_pack[14+20+0:14+20+4])
    body = udp_gen(
        data=out_data, src_ip=src_ip, dst_ip=dst_ip,
        src_port=udp_src, dst_port=udp_dst)
    full_pack = eth_head + body
    # enforce Ethernet minimum frame length
    if len(full_pack) < 60:
        full_pack += bytes((60-len(full_pack)) * [0])
    return full_pack


# RFC-1350 only
def handle_tftp(tid, p, in_pack):
    tftp_opcode = (p[0] << 8) + p[1]
    print("TFTP opcode %d" % tftp_opcode)
    if tftp_opcode == 1 or tftp_opcode == 2:
        filename = ""
        ix = 2
        while p[ix] != 0:
            filename += chr(p[ix])
            ix += 1
        mode = ""
        ix += 1
        while p[ix] != 0:
            mode += chr(p[ix])
            ix += 1
        print("RRQ/WRQ filename '%s' mode '%s' tid %d" % (filename, mode, tid))
    if tftp_opcode == 1:  # RRQ
        # opcode 3, block 1, data ABC\n
        fdata = list(range(65, 68)) + [10]
        reply = gen_udp_reply(in_pack, bytes([0, 3, 0, 1] + fdata))
        print("Generated reply " + " ".join(["%2.2x" % x for x in reply]))
        return reply
    else:
        return None


def handle_pack(chip, p):
    print(" ".join(["%2.2x" % x for x in p]))
    if p[14+9] == 17:  # UDP
        udp_srce_port = ((p[14+20]) << 8) + (p[14+21])
        udp_dest_port = ((p[14+22]) << 8) + (p[14+23])
        udp_data_leng = ((p[14+24]) << 8) + (p[14+25])
        udp_contents = p[14+28:14+28+udp_data_leng-8]
        print("packet for UDP port %d, len %d" % (udp_dest_port, udp_data_leng))
        if udp_dest_port == 69:
            rp = handle_tftp(udp_srce_port, udp_contents, p)
            if rp is not None:
                addrs, values = tx_mac_build(rp)
                foo.exchange(addrs, values)


def guess_mac(ifname="tap0"):
    # Determine our own MAC address; sort-of works on Linux.
    # Feel free to upgrade to portable code, if such a thing exists :-p
    try:
        mac_colons = open('/sys/class/net/%s/address' % ifname).read()
        dst_mac = bytes([int(x, 16) for x in mac_colons.split(':')])
    except Exception:
        dst_mac = bytes([0x12, 0x55, 0x55, 0x00, 0x01, 0x2d])
    return dst_mac


def create_emit(text):
    contents = udp_gen(
        data=text,
        src_ip=bytes([192, 168, 7, 4]),
        dst_ip=bytes([192, 168, 7, 1]),
        src_port=3001, dst_port=3011)
    dst_mac = guess_mac()
    # Using ourselves as the destination of this packet allows
    # simple confidence testing with "nc -l -u -p 3011".
    return eth_gen(
        contents,
        src_mac=bytes([0x12, 0x55, 0x55, 0x00, 0x01, 0x2d]),
        dst_mac=dst_mac)


if __name__ == "__main__":
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument(
        '--ip',
        help="IP address of FPGA",
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
        '--text',
        help="Text for emit command",
        default=b"Hello world\n"
    )
    p.add_argument(
        'command',
        help="reset | tx | rx | show | rxb0 | rxb1 | emit | get_rx1 | get_rxn | stop_sim"
    )
    args = p.parse_args()
    foo = lbus_access(args.ip, port=args.port)
    if not foo:
        print("lbus_access setup failed")
        exit(1)
    if args.command == "reset":
        reset_trace(foo)
    elif args.command == "hello":
        exit(0 if hello_test(foo) else 1)
    elif args.command == "show":
        show_short(foo)
    elif args.command == "rx":
        show_trace(foo, 0x010000)
    elif args.command == "tx":
        show_trace(foo, 0x020000)
    elif args.command == "rxb0":
        set_rx_mac_hbank(foo, 0)
    elif args.command == "rxb1":
        set_rx_mac_hbank(foo, 1)
    elif args.command == "emit":
        addrs, values = tx_mac_build(create_emit(args.text))
        foo.exchange(addrs, values)
    elif args.command == "get_rx1":
        p = get_rx_pack(foo, verbose=True)
        if p is not None:
            handle_pack(foo, p)
    elif args.command == "get_rxn":
        while True:
            p = get_rx_pack(foo)
            if p is not None:
                handle_pack(foo, p)
                time.sleep(0.1)
            else:
                time.sleep(0.5)
    elif args.command == "arb":
        if args.file is None:
            fd = sys.stdin
        else:
            fd = open(args.file, "r")
        addrs, values = process_fd(fd)
        foo.exchange(addrs, values)
    elif args.command == "stop_sim":
        try:
            # One weird hack
            foo.exchange([6], [1], drop_reply=True)
            print("finished stop_sim transaction - did it fail?")
        except Exception:
            print("incomplete stop_sim transaction - success?")
    else:
        print("unknown command %s: try python3 badger_lb_io.py --help" % args.command)
