# python3 only
# for x in arp icmp udp; do diff <(python3 packetgen.py $x) ${x}3.dat; done
import random
from binascii import crc32, unhexlify
from sys import argv


def read_lb_pack(fname):
    ''' Kind of special purpose
    lines of hex-encoded bytes, doesn't matter how many bytes per line
    multiple bytes per line are interpreted as big-endian (network byte order)
    '''
    d = b""
    with open(fname, "r") as fd:
        for line in fd.read().split("\n"):
            if line == "":
                continue
            ll = int(len(line)/2)
            xx = [int(line[ix*2:ix*2+2], 16) for ix in range(ll)]
            d += bytes(xx)
    return d


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
    udp_head = twobyte(src_port) + twobyte(dst_port) + twobyte(udp_len)
    udp_pseudo = src_ip + dst_ip + bytes([0, protocol]) + twobyte(udp_len)
    udp_chk = chksum(udp_pseudo + udp_head + data, wrong=udp_wrong)
    udp_head += udp_chk
    return ip_gen(udp_head + data, src_ip, dst_ip,
                  ident, ttl, protocol, wrong=ip_wrong, pad=pad)


def icmp_gen(
        data=b"",
        src_ip=b"\0\0\0\0",
        dst_ip=b"\0\0\0\0",
        ip_ident=0,
        ttl=0x40,
        protocol=1,
        icmp_type=8,
        icmp_code=0,
        icmp_ident=0,
        icmp_seq=0,
        icmp_wrong=0,
        ip_wrong=0):
    icmp_h1 = bytes([icmp_type, icmp_code])
    icmp_h2 = twobyte(icmp_ident) + twobyte(icmp_seq)
    icmp_chk = chksum(icmp_h1 + icmp_h2 + data, wrong=icmp_wrong)
    icmp_head = icmp_h1 + icmp_chk + icmp_h2
    return ip_gen(icmp_head + data, src_ip, dst_ip,
                  ip_ident, ttl, protocol, wrong=ip_wrong)


def eth_gen(
        contents,
        goal=None,
        src_mac=bytes([0xda, 0x48, 0x9f, 0x29, 0x4d, 0x53]),
        dst_mac=bytes([0x12, 0x55, 0x55, 0x00, 0x01, 0x2d]),
        ethertype=0x00,
        pad=None,
        mac_only=False):
    gmii_pre = bytes([0x55]*7 + [0xd5])
    eth_head = dst_mac + src_mac + bytes([0x08, ethertype])
    content_len = len(contents)
    eth_pad_n = max(64-14-content_len, 0)
    if pad is not None:
        eth_pad_n = pad
    eth_pad = bytes([0]*max(eth_pad_n, 0))
    eth_pack = eth_head + contents + eth_pad
    if pad is not None and pad < 0:
        eth_pack = eth_pack[:pad]
    ec = crc32(eth_pack)
    eth_crc = bytes([ec & 0xff, (ec >> 8) & 0xff, (ec >> 16) & 0xff, ec >> 24])
    if mac_only:
        out_pack = eth_pack
    else:
        out_pack = gmii_pre + eth_pack + eth_crc
    for b in out_pack:
        print("%2.2X" % b)
    if goal is not None:
        print("stop %2X" % goal)


def arp_gen(
        goal=None,
        src_ip=b"\0\0\0\0",
        dst_ip=b"\0\0\0\0",
        src_mac=bytes([0xda, 0x48, 0x9f, 0x29, 0x4d, 0x53]),
        dst_mac=bytes([0xff]*6),
        hardware_space=1,
        protocol_space=0x800,
        hardware_len=6,
        protocol_len=4,
        opcode=1):
    arp_head = twobyte(hardware_space) + twobyte(protocol_space)
    arp_head += bytes([hardware_len, protocol_len]) + twobyte(opcode)
    zero_mac = bytes([0]*6)
    contents = arp_head + src_mac + src_ip + zero_mac + dst_ip
    eth_gen(contents, goal=goal,
            src_mac=src_mac, dst_mac=dst_mac, ethertype=0x06)


def guess_mac(ifname="tap0"):
    # Determine our own MAC address; sort-of works on Linux.
    # Feel free to upgrade to portable code, if such a thing exists :-p
    try:
        mac_colons = open('/sys/class/net/%s/address' % ifname).read()
        dst_mac = bytes([int(x, 16) for x in mac_colons.split(':')])
    except Exception:
        dst_mac = bytes([0x12, 0x55, 0x55, 0x00, 0x01, 0x2d])
    return dst_mac


if __name__ == '__main__':
    src_ip = bytes([192, 168, 7, 1])
    dst_ip = bytes([192, 168, 7, 4])
    if len(argv) > 1 and argv[1] == "udp":
        # recreate file udp3.dat
        udp_data = b"Testing 1 2 3\n"
        contents = udp_gen(
            data=udp_data, src_ip=src_ip, dst_ip=dst_ip,
            src_port=0xecb0, ident=0x1a59)
        eth_gen(contents)
    elif len(argv) > 1 and argv[1] == "icmp":
        # recreate file icmp3.dat
        icmp_data = unhexlify(
            "D916FC5B00000000BC52060000000000101112131415161718191A1B")
        icmp_data += unhexlify(
            "1C1D1E1F202122232425262728292A2B2C2D2E2F3031323334353637")
        contents = icmp_gen(
            data=icmp_data, src_ip=src_ip, dst_ip=dst_ip,
            ip_ident=0x6cc5, icmp_ident=0x513e, icmp_seq=1)
        eth_gen(contents)
    elif len(argv) > 1 and argv[1] == "arp":
        # recreate file arp3.dat
        arp_gen(src_ip=src_ip, dst_ip=dst_ip)
    elif len(argv) > 1 and argv[1] == "flip":
        # test packet for exercising Tx mac
        udp_data = b"Tx MAC exercise (a bit longer) 10\n"
        contents = udp_gen(
            data=udp_data, src_ip=dst_ip, dst_ip=src_ip,
            src_port=3001, dst_port=3011)
        dst_mac = guess_mac()
        # Using ourselves as the destination of this packet allows
        # simple confidence testing with "nc -l -u -p 3011".
        eth_gen(
            contents,
            src_mac=bytes([0x12, 0x55, 0x55, 0x00, 0x01, 0x2d]),
            dst_mac=dst_mac,
            mac_only=True)
    elif len(argv) > 2 and argv[1] == "lb":
        udp_data = read_lb_pack(argv[2])
        contents = udp_gen(
            data=udp_data, src_ip=src_ip, dst_ip=dst_ip,
            dst_port=803)
        eth_gen(
            contents,
            src_mac=bytes([0xc6, 0x35, 0xe7, 0x83, 0x1c, 0x4d]),
            dst_mac=bytes([0x12, 0x55, 0x55, 0x00, 0x01, 0x2d]),
            goal=0x10)
        print("wait 1557")
        arp_gen(src_ip=src_ip, dst_ip=dst_ip, goal=0x05)
    else:
        # note lsb of first byte is 1
        multicast_mac = bytes([0xdb, 0x48, 0x9f, 0x29, 0x4d, 0x53])
        #
        # 1 - OK - UDP
        # this data is short enough to trigger Ethernet padding
        udp_data = b"Testing 1 2 3\n"
        contents = udp_gen(
            data=udp_data, src_ip=src_ip, dst_ip=dst_ip,
            src_port=0xecb0, ident=0x1a59)
        eth_gen(contents, goal=0x3f)
        # 2 - bad - zero TTL
        contents = udp_gen(
            data=udp_data, src_ip=src_ip, dst_ip=dst_ip,
            src_port=0xecb0, ident=0x1a59, ttl=0)
        eth_gen(contents, goal=0x0c)
        # 3 - bad - source port < 1024
        contents = udp_gen(
            data=udp_data, src_ip=src_ip, dst_ip=dst_ip,
            src_port=0x03ff, ident=0x1a59)
        eth_gen(contents, goal=0x1c)
        # 4 - bad - multicast source MAC
        contents = udp_gen(
            data=udp_data, src_ip=src_ip, dst_ip=dst_ip,
            src_port=0xecb0, ident=0x1a59)
        eth_gen(contents, goal=0x0c, src_mac=multicast_mac)
        # 5 - bad - not our MAC address (first octet)
        eth_gen(contents, goal=0x04,
                dst_mac=bytes([0x32, 0x55, 0x55, 0x00, 0x01, 0x2d]))
        # 6 - bad - not our MAC address (last octet)
        eth_gen(contents, goal=0x04,
                dst_mac=bytes([0x12, 0x55, 0x55, 0x00, 0x01, 0x2c]))
        # 7 - bad - not our IP address (first octet)
        contents = udp_gen(
            data=udp_data, src_ip=src_ip, dst_ip=bytes([193, 168, 7, 4]))
        eth_gen(contents, goal=0x0c)
        # 8 - bad - not our IP address (last octet)
        contents = udp_gen(
            data=udp_data, src_ip=src_ip, dst_ip=bytes([192, 168, 7, 6]))
        eth_gen(contents, goal=0x0c)
        # 9 - bad - wrong IP checksum
        contents = udp_gen(
            data=udp_data, src_ip=src_ip, dst_ip=dst_ip, ip_wrong=1)
        eth_gen(contents, goal=0x0c)
        # 10 - OK - extra padding in IP
        contents = udp_gen(
            data=udp_data, src_ip=src_ip, dst_ip=dst_ip, pad=1)
        eth_gen(contents, goal=0x3f)
        # 11 - bad - negative padding in IP
        contents = udp_gen(
            data=udp_data, src_ip=src_ip, dst_ip=dst_ip, pad=-1)
        eth_gen(contents, goal=0x1c)
        # 12 - OK - moderate length data, add useless Ethernet padding
        udp_data = b"The rain in Spain stays mainly in the plain"
        udp_data += b"."*212 + b"\n"
        contents = udp_gen(
            data=udp_data, src_ip=src_ip, dst_ip=dst_ip)
        eth_gen(contents, goal=0x3f, pad=1)
        # 13 - bad - negative Ethernet padding
        contents = udp_gen(
            data=udp_data, src_ip=src_ip, dst_ip=dst_ip)
        eth_gen(contents, goal=0x0c, pad=-1)
        # 14 - OK - long but still within bounds
        udp_data = b"A" * 1490
        contents = udp_gen(
            data=udp_data, src_ip=src_ip, dst_ip=dst_ip)
        eth_gen(contents, goal=0x3f)
        # 15 - bad - too long, triggers "drop" in input state machine
        #   Note that these long-packet tests would be really hard to
        #   accomplish if running through a Linux networking stack that
        #   will have its own MTU.
        udp_data = b"A" * 1491
        contents = udp_gen(
            data=udp_data, src_ip=src_ip, dst_ip=dst_ip)
        eth_gen(contents, goal=0x08)
        # 16 - OK - ICMP echo request
        icmp_data = unhexlify(
            "D916FC5B00000000BC52060000000000101112131415161718191A1B")
        icmp_data += unhexlify(
            "1C1D1E1F202122232425262728292A2B2C2D2E2F3031323334353637")
        contents = icmp_gen(
            data=icmp_data, src_ip=src_ip, dst_ip=dst_ip,
            ip_ident=0x6cc5, icmp_ident=0x513e, icmp_seq=1)
        eth_gen(contents, goal=0x1e)
        # 17 - bad - wrong ICMP checksum
        contents = icmp_gen(
            data=icmp_data, src_ip=src_ip, dst_ip=dst_ip,
            ip_ident=0x6cc5, icmp_ident=0x513e, icmp_seq=1, icmp_wrong=1)
        eth_gen(contents, goal=0x1c)
        # 18 - bad - wrong IP checksum
        contents = icmp_gen(
            data=icmp_data, src_ip=src_ip, dst_ip=dst_ip,
            ip_ident=0x6cc5, icmp_ident=0x513e, icmp_seq=1, ip_wrong=1)
        eth_gen(contents, goal=0x0c)
        # 19 - bad - wrong protocol
        contents = icmp_gen(
            data=icmp_data, src_ip=src_ip, dst_ip=dst_ip,
            ip_ident=0x6cc5, icmp_ident=0x513e, icmp_seq=1, protocol=2)
        eth_gen(contents, goal=0x1c)
        # 20 - bad - wrong ICMP type
        contents = icmp_gen(
            data=icmp_data, src_ip=src_ip, dst_ip=dst_ip,
            ip_ident=0x6cc5, icmp_ident=0x513e, icmp_seq=1, icmp_type=1)
        eth_gen(contents, goal=0x1c)
        # 21 - bad - wrong ICMP code
        contents = icmp_gen(
            data=icmp_data, src_ip=src_ip, dst_ip=dst_ip,
            ip_ident=0x6cc5, icmp_ident=0x513e, icmp_seq=1, icmp_code=1)
        eth_gen(contents, goal=0x1c)
        # 22 - OK - ARP request
        arp_gen(src_ip=src_ip, dst_ip=dst_ip, goal=0x05)
        # 23 - bad - multicast source mac
        arp_gen(src_ip=src_ip, dst_ip=dst_ip, src_mac=multicast_mac, goal=0x04)
        # 24 - bad - not our IP address (first octet)
        arp_gen(src_ip=src_ip, dst_ip=bytes([193, 168, 7, 4]), goal=0x04)
        # 25 - bad - not our IP address (last octet)
        arp_gen(src_ip=src_ip, dst_ip=bytes([192, 168, 7, 6]), goal=0x04)
        # 26 - bad - ARP reply
        arp_gen(src_ip=src_ip, dst_ip=dst_ip, opcode=2, goal=0x04)
        # 27 - bad - wrong hardware_space
        arp_gen(src_ip=src_ip, dst_ip=dst_ip, hardware_space=0x100, goal=0x04)
        # 28 - bad - wrong protocol_space
        arp_gen(src_ip=src_ip, dst_ip=dst_ip, protocol_space=0x806, goal=0x04)
        # 29 - bad - wrong hardware_len
        arp_gen(src_ip=src_ip, dst_ip=dst_ip, hardware_len=16, goal=0x04)
        # 30 - bad - wrong protocol_len
        arp_gen(src_ip=src_ip, dst_ip=dst_ip, protocol_len=0, goal=0x04)
        # 31 - OK - UDP with zero-length data
        #   Makes it through the scanner OK, but weird for the client ABI
        #   because raw_s never goes high.  Nothing the client can do will
        #   keep Packet Badger from sending a similar zero-data-length packet
        #   back to the source, and that could be considered a mistake.
        #   Consider rejecting these packets in the scanner.
        udp_data = b""
        contents = udp_gen(
            data=udp_data, src_ip=src_ip, dst_ip=dst_ip,
            src_port=0xecb0, dst_port=7)
        eth_gen(contents, goal=0x1f)
        # 32 - bad - unknown port
        contents = udp_gen(
            data=udp_data, src_ip=src_ip, dst_ip=dst_ip,
            src_port=0xecb0, dst_port=22)
        eth_gen(contents, goal=0x1c)
        # close it out
        print("tests 32")
