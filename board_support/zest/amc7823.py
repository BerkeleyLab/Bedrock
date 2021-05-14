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
        return res

    def cmddecode(self, cmdval):
        rw = cmdval >> 15
        pg = (cmdval >> 12) & 0x3
        saddr = (cmdval >> 6) & 0x1f
        eaddr = cmdval & 0x1f
        return [rw, pg, saddr, eaddr]


def amc_dprint(cc, suffix=None):
    oo = " ".join([format(i, '04x') for i in cc])
    if suffix is not None:
        oo += suffix
    print(oo)


def usage():
    print('python %s -a [IP ADDR]' % sys.argv[0])


if __name__ == "__main__":
    import getopt
    from zest_setup import c_zest

    opts, args = getopt.getopt(sys.argv[1:], 'ha:p:',
                               ['help', 'addr='])
    ip_addr = '192.168.21.11'
    for opt, arg in opts:
        if opt in ('-h', '--help'):
            usage()
            sys.exit()
        elif opt in ('-a', '--address'):
            ip_addr = arg

    prc = c_zest(ip_addr)

    addrs = list(range(0x16))
    addrs.append(0x1e)
    if True:
        print("Read page 0:")
        for addr in range(11):
            adcs = prc.amc_read(0, addr)
            vv = (adcs[4] & 0xfff) * 2.5 / 2**12
            amc_dprint(adcs, '  %6.3f' % vv)

        print("Read page 1:")
        for addr in addrs:
            rb = prc.amc_read(1, addr)
            amc_dprint(rb)

        print("Write DACs 1-8:")
        for addr in range(8):
            prc.amc_write(1, addr, addr << 8)

        # Load DAC
        prc.amc_write(1, 0x09, 0xbb00)

    if True:
        print("Write and readback GPIO register")
        prc.amc_write(0, 0x0a, 0xffff)
        rb = prc.amc_read(0, 0x0a)
        amc_dprint(rb)
        time.sleep(1)
        prc.amc_write(0, 0x0a, 0xffc0)
        rb = prc.amc_read(0, 0x0a)
        amc_dprint(rb)
        time.sleep(1)

    print("Power-down")
    prc.amc_write(1, 0xd, 0xffdf)
