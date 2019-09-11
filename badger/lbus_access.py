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
    def __init__(self, host, timeout=1.02, port=803, force_burst=False):
        self.dest = (host, int(port))
        self.sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM, 0)
        self.sock.settimeout(timeout)
        self.force_burst = force_burst

    def _burst_avail(self,):
        """Determines if device supports block-transfer/repeat-count
        """
        # TODO: Extract device capabilities automatically
        dev_burst_en = False

        return self.force_burst or dev_burst_en

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

        tosend = msg.tostring()
        # print("%s Send (%d) %s", self.dest, len(tosend), binascii.hexlify(tosend))
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
        if self._burst_avail() and (addrs == list(range(addrs[0], addrs[-1]+1))):
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
        if not val:
            print("%s: \t%08x" % (reg, retval[0]))


def mem_read(dev, args):
    for pair in args.mem:
        baseaddr, _eq, length = pair.partition(':')
        baseaddr = ast.literal_eval(baseaddr)
        length = ast.literal_eval(length)

        retmem = dev.exchange(range(baseaddr, baseaddr+length))
        print(retmem)


if __name__ == "__main__":
    p = argparse.ArgumentParser()
    p.add_argument('-a', '--address', help='IP address of device', default='localhost')
    p.add_argument('-p', '--port', help='UDP port for I/O', default=803)
    p.add_argument('-t', '--timeout', help='UDP timeout, in seconds', type=float, default=1.02)

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
