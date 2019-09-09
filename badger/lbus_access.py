'''
Access to Packet Badger's localbus gateway
'''
# mostly cribbed from FEED/src/python/leep/
import argparse
import socket
import numpy
import random
import ast
be32 = numpy.dtype('>u4')


class lbus_access:
    def __init__(self, host, timeout=1.02, port=803):
        self.dest = (host, int(port))
        self.sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM, 0)
        self.sock.settimeout(timeout)

    def _exchange(self, addrs, values=None, drop_reply=False):
        """Exchange a single low level message
        """

        msg = numpy.zeros(2+2*len(addrs), dtype=be32)
        msg[0] = random.randint(0, 0xffffffff)
        msg[1] = msg[0] ^ 0xffffffff

        for i, (A, V) in enumerate(zip(addrs, values), 1):
            A &= 0x00ffffff
            if V is None:
                A |= 0x10000000
            msg[2*i] = A
            msg[2*i+1] = V or 0

        tosend = msg.tostring()
        # print("%s Send (%d) %s", self.dest, len(tosend), repr(tosend))
        self.sock.sendto(tosend, self.dest)

        if drop_reply:
            return None

        while True:
            reply, src = self.sock.recvfrom(15000)
            # print("%s Recv (%d) %s", src, len(reply), repr(reply))

            if len(reply) % 8:
                reply = reply[:-(len(reply) % 8)]

            if len(tosend) != len(reply):
                print("Reply truncated %d %d" % (len(tosend), len(reply)))
                continue

            reply = numpy.frombuffer(reply, be32)
            if (msg[:2] != reply[:2]).any():
                print('Ignore reply w/o matching nonce %s %s' % (msg[:2], reply[:2]))
                continue
            elif (msg[2::2] != reply[2::2]).any():
                print('reply addresses are out of order')
                continue

            break

        ret = reply[3::2]
        return ret

    def exchange(self, addrs, values=None, drop_reply=False):
        """Accepts a list of address and values (None to read).
        Returns a numpy.ndarray in the same order.
        """
        addrs = list(addrs)

        if values is None:
            values = [None]*len(addrs)
        else:
            values = list(values)

        ret = numpy.zeros(len(addrs), be32)
        for i in range(0, len(addrs), 127):
            A, B = addrs[i:i+127], values[i:i+127]

            P = self._exchange(A, B, drop_reply=drop_reply)
            if not drop_reply:
                ret[i:i+127] = P

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

    lbus_acc = lbus_access(args.address, timeout=args.timeout, port=args.port)

    args.func(lbus_acc, args)
