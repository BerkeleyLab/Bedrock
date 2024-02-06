'''
Access to Packet Badger's localbus gateway
'''
# mostly cribbed from FEED/src/python/leep/
import argparse
import socket
import numpy
import random
import ast
# import binascii
be32 = numpy.dtype('>u4')


class lbus_access:
    def __init__(self, host, timeout=1.02, port=803, force_burst=False, allow_burst=True, verbose=False):
        self.dest = (host, int(port))
        self.sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM, 0)
        self.sock.settimeout(timeout)
        self.verbose = verbose
        if force_burst:
            self.burst_avail = True
        elif allow_burst:
            self.burst_avail = self._burst_avail()
        else:
            self.burst_avail = False

    def _burst_avail(self):
        """Determines if device supports block-transfer/repeat-count
        """
        # TODO: Extract device capabilities automatically
        dev_burst_en = False

        # Ugly, noisy, fragile, and invasive PoC
        msg = numpy.zeros(14, dtype=be32)
        msg[0] = random.randint(0, 0xffffffff)
        msg[1] = msg[0] ^ 0xffffffff
        msg[2] = 0x10000002  # read 2
        msg[3] = 0xa5a5a5a5  # pad
        msg[4] = 0x10000001  # read 1
        msg[5] = 0xa5a5a5a5  # pad
        msg[6] = 0x20000002  # repeat 2 / write 2
        msg[7] = 0x10000001  # read 1 / write data
        msg[8] = 0x10000001  # pad / read 1
        msg[9] = 0xa5a5a5a5  # pad
        msg[10] = 0x20000002  # repeat 2 / write 2
        msg[11] = 0x10000001  # read 1 / write data
        msg[12] = 0x10000002  # pad / read 2
        msg[13] = 0xa5a5a5a5  # pad

        tosend = msg.tobytes()
        # print("%s Send (%d) %s", self.dest, len(tosend), binascii.hexlify(tosend))
        self.sock.sendto(tosend, self.dest)
        if True:
            reply, src = self.sock.recvfrom(15000)
            if len(reply) == 14*4:
                reply = numpy.frombuffer(reply, be32)
                for n in [0, 1, 2, 4, 6, 7, 10, 11]:
                    if reply[n] != msg[n]:
                        print("bad mismatch %8.8x != %8.8x" % (reply[n], msg[n]))
                r1 = reply[5]
                r2 = reply[3]
                if msg[8] == reply[8] and r1 == reply[9] and msg[12] == reply[12] and r2 == reply[13]:
                    if self.verbose:
                        print("Seems to be no-burst")
                    return False
                elif r1 == reply[8] and r2 == reply[9] and r1 == reply[12] and r2 == reply[13]:
                    if self.verbose:
                        print("Seems to be burst")
                    return True
                else:
                    if self.verbose:
                        print("Burst autodetect failed")
                    return False
                # for jx, x in enumerate(reply):
                #    print("%2d %8.8x" % (jx, x))

        return dev_burst_en

    def _exchange(self, addrs, values=None, drop_reply=False, burst=False):
        """Exchange a single low level message
        """

        if not burst:
            msg = numpy.zeros(2+2*len(addrs), dtype=be32)
        else:
            msg = numpy.zeros(2+2+len(addrs), dtype=be32)

        msg[0] = random.randint(0, 0xffffffff)
        msg[1] = msg[0] ^ 0xffffffff

        if not burst:
            for i, (A, V) in enumerate(zip(addrs, values), 1):
                A &= 0x00ffffff
                if V is None:
                    A |= 0x10000000
                msg[2*i] = A
                msg[2*i+1] = V or 0
        else:
            RC = (len(addrs) & 0x00ffffff) | 0x20000000
            A = addrs[0]
            A &= 0x00ffffff
            if values[0] is None:
                A |= 0x10000000
            msg[2] = RC
            msg[3] = A
            for i, V in enumerate(values, 4):
                msg[i] = V or 0

        tosend = msg.tobytes()
        if False:
            mm = ".".join(["%8.8x" % x for x in msg])
            print("%s Send (%d) %s" % (self.dest, len(tosend), mm))
        self.sock.sendto(tosend, self.dest)

        if drop_reply:
            return None

        while True:
            reply, src = self.sock.recvfrom(15000)
            # print("%s Recv (%d) %s", src, len(reply), binascii.hexlify(reply))

            byte_align = 8 if not burst else 4
            if len(reply) % byte_align:
                reply = reply[:-(len(reply) % byte_align)]

            if len(tosend) != len(reply):
                print("Reply truncated %d %d" % (len(tosend), len(reply)))
                continue

            reply = numpy.frombuffer(reply, be32)
            if (msg[:2] != reply[:2]).any():
                print('Ignore reply w/o matching nonce %s %s' % (msg[:2], reply[:2]))
                continue
            elif not burst and (msg[2::2] != reply[2::2]).any():
                print('reply addresses are out of order')
                continue
            elif burst and (msg[2:3] != reply[2:3]).any():
                print('Non-matching start address')
                continue
            break

        ret = reply[3::2] if not burst else reply[4::1]
        return ret

    def exchange(self, addrs, values=None, drop_reply=False):
        """Accepts a list of address and values (None to read).
        Returns a numpy.ndarray in the same order.
        """
        addrs = list(addrs)

        consec = False
        # Check for consecutive addresses if burst mode available
        if self.burst_avail and len(addrs) > 1 and (addrs == list(range(addrs[0], addrs[-1]+1))):
            consec = True

        if values is None:
            values = [None]*len(addrs)
        else:
            values = list(values)

        ret = numpy.zeros(len(addrs), be32)
        n_tx = 255 if consec else 127
        for i in range(0, len(addrs), n_tx):
            A, B = addrs[i:i+n_tx], values[i:i+n_tx]

            P = self._exchange(A, B, drop_reply=drop_reply, burst=consec)
            if not drop_reply:
                ret[i:i+n_tx] = P

        return ret


def read_write(dev, args):
    for pair in args.reg:
        reg, _eq, val = pair.partition('=')
        reg = ast.literal_eval(reg)
        if not len(val):  # read operation
            val = None
        else:
            val = ast.literal_eval(val)

        retval = dev.exchange([reg], [val])
        if val is None:
            print("%s: \t%08x" % (reg, retval[0]))


def mem_read(dev, args):
    for pair in args.mem:
        baseaddr, _eq, length = pair.partition(':')
        baseaddr = ast.literal_eval(baseaddr)
        length = ast.literal_eval(length)

        retmem = dev.exchange(range(baseaddr, baseaddr+length))
        if args.string:
            print("".join([chr(x) for x in retmem]))
        else:
            print(retmem)


if __name__ == "__main__":
    p = argparse.ArgumentParser()
    p.add_argument('-a', '--address', help='IP address of device', default='localhost')
    p.add_argument('-p', '--port', help='UDP port for I/O', default=803)
    p.add_argument('-t', '--timeout', help='UDP timeout, in seconds', type=float, default=1.02)
    p.add_argument('--string', help='Format output as string', action='store_true', dest='string')

    sp = p.add_subparsers()
    s = sp.add_parser('reg', help='read/write registers')
    s.set_defaults(func=read_write)
    s.add_argument('reg', nargs='+', help='register[=newvalue]')

    s = sp.add_parser('mem', help='read contiguous memory')
    s.set_defaults(func=mem_read)
    s.add_argument('mem', nargs='+', help='baseaddr:size')
    args = p.parse_args()

    lbus_acc = lbus_access(args.address, timeout=args.timeout, port=args.port, force_burst=False)

    args.func(lbus_acc, args)
