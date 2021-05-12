import sys
import time


class c_amc7823:
    def __init__(self):
        self.init()

    def init(self):
        pass

    def cmd(self, rw=1, pg=1, saddr=0x1e, eaddr=0x1e):
        return (rw << 15) + (pg << 12) + (saddr << 6) + eaddr

    def dataaddr(self, data, addr):
        res = (data << 16) + addr
        # print hex(res),
        return res

    def cmddecode(self, cmdval):
        rw = cmdval >> 15
        pg = (cmdval >> 12) & 0x3
        saddr = (cmdval >> 6) & 0x1f
        eaddr = cmdval & 0x1f
        return [rw, pg, saddr, eaddr]


def usage():
    print('python %s -a [IP ADDR]' % sys.argv[0])


if __name__ == "__main__":
    import getopt
    from prc import c_prc

    opts, args = getopt.getopt(sys.argv[1:], 'ha:p:',
                               ['help', 'addr=', 'port='])
    ip_addr = '192.168.21.11'
    port = 50006
    for opt, arg in opts:
        if opt in ('-h', '--help'):
            usage()
            sys.exit()
        elif opt in ('-a', '--address'):
            ip_addr = arg
        elif opt in ('-p', '--port'):
            port = int(arg)

    prc = c_prc(ip_addr, port)

    addrs = list(range(0x16))
    addrs.append(0x1e)
    if 1:
        print("Read page 0:")
        for addr in range(11):
            adcs = prc.amc_read(0, addr)
            print(([format(i, '04x') for i in adcs], '%6.3f' % (
                (adcs[4] & 0xfff) * 2.5 / 2**12)))

        print("Read page 1:")
        for addr in addrs:
            print([format(i, '04x') for i in prc.amc_read(1, addr)])

        print("Write DACs 1-8:")
        for addr in range(8):
            prc.amc_write(1, addr, addr << 8)

        # Load DAC
        prc.amc_write(1, 0x09, 0xbb00)

    if 1:
        print("Write and readback GPIO register")
        prc.amc_write(0, 0x0a, 0xffff)
        rb = prc.amc_read(0, 0x0a)
        print((rb, hex(rb[4])))
        time.sleep(1)
        prc.amc_write(0, 0x0a, 0xffc0)
        rb = prc.amc_read(0, 0x0a)
        print((rb, hex(rb[4])))
        time.sleep(1)

    print("Power-down")
    prc.amc_write(1, 0xd, 0xffdf)
