# FMC tester based on IAM Electronic FPGA Mezzanine Card (FMC) Loopback Module
# https://www.iamelectronic.com/shop/produkt/fpga-mezzanine-card-fmc-loopback-module

import leep
from sys import argv


def tobin(x, count=8):
    # Integer to binary; count is number of bits
    # Credit to W.J. van der Laan in http://code.activestate.com/recipes/219300/
    return "".join([str((x >> y) & 1) for y in range(count-1, -1, -1)])


# highly customized for this application
# input is numeric, 22 bits + 22 bits + 24 bits
def to_bin_fmc(v):
    al = tobin(v[0], count=22)
    am = tobin(v[1], count=22)
    ah = tobin(v[2], count=24)
    return ah+am+al


def get_iam_fmc(addr):
    r_set = ["_test_in_" + s for s in ["l", "m", "h"]]
    # print(r_set)
    r_set2 = ["fmc1" + r for r in r_set] + ["fmc2" + r for r in r_set]
    # print(r_set2)
    d = addr.reg_read(r_set2)
    # print(d)
    p1 = to_bin_fmc(d[0:3])
    p2 = to_bin_fmc(d[3:6])
    return (p1, p2)


def set_iam_fmc(addr, p, bit):
    a = 1 << bit
    al = (a >> 0)  & 0x3fffff
    am = (a >> 22) & 0x3fffff
    ah = (a >> 44) & 0xffffff
    port = "fmc%d" % p
    r_set = [(port+"_test_l", al), (port+"_test_m", am), (port+"_test_h", ah)]
    port = "fmc%d" % (3-p)
    r_set += [(port+"_test_l", 0), (port+"_test_m", 0), (port+"_test_h", 0)]
    # print(r_set)
    addr.reg_write(r_set)


def test_iam_fmc(addr):
    gitid = addr.codehash
    print("# test_iam_fmc " + gitid)
    for px in [1, 2]:
        for bx in range(68):
            set_iam_fmc(addr, px, bx)
            r = get_iam_fmc(addr)
            print(px, "%3d" % bx, r[0], r[1])


if __name__ == "__main__":
    leep_addr = argv[1]
    addr = leep.open(leep_addr, timeout=5.0)
    test_iam_fmc(addr)
