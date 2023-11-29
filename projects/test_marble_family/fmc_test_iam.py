# PoC Marble FMC tester based on IAM Electronic FPGA Mezzanine Card (FMC) Loopback Module
# https://www.iamelectronic.com/shop/produkt/fpga-mezzanine-card-fmc-loopback-module
# Still doesn't cover LA_1 to GBTCLK0_M2C or LA_18 to GBTCLK1_M2C (HPC)

import leep
from sys import argv


def tobin(x, count=8):
    # Integer to binary; count is number of bits
    # Credit to W.J. van der Laan in http://code.activestate.com/recipes/219300/
    return "".join([str((x >> y) & 1) for y in range(count-1, -1, -1)])


# stupidly customized for 68-pin LA banks in this application
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
    r_set2 += ["fmc2h_test_in_l", "fmc2h_test_in_h"]
    # print(r_set2)
    d = addr.reg_read(r_set2)
    # print(d)
    p1 = to_bin_fmc(d[0:3])
    p2 = to_bin_fmc(d[3:6])
    p2h = tobin(d[7], count=24) + tobin(d[6], count=24)
    return (p1, p2, p2h)


def set_iam_fmc(addr, p, bit):
    a = 1 << bit
    if p != 3:  # LPC
        al = (a >> 0)  & 0x3fffff
        am = (a >> 22) & 0x3fffff
        ah = (a >> 44) & 0xffffff
        port = "fmc%d" % p
        r_set = [(port+"_test_l", al), (port+"_test_m", am), (port+"_test_h", ah)]
    else:  # HPC
        al = (a >> 0)  & 0xffffff
        ah = (a >> 24) & 0xffffff
        port = "fmc2h"
        r_set = [(port+"_test_l", al), (port+"_test_h", ah)]
    if p != 1:
        port = "fmc1"
        r_set += [(port+"_test_l", 0), (port+"_test_m", 0), (port+"_test_h", 0)]
    if p != 2:
        port = "fmc2"
        r_set += [(port+"_test_l", 0), (port+"_test_m", 0), (port+"_test_h", 0)]
    if p != 3:
        port = "fmc2h"
        r_set += [(port+"_test_l", 0), (port+"_test_h", 0)]
    # print(r_set)
    addr.reg_write(r_set)


def test_iam_fmc(addr):
    gitid = addr.codehash
    print("# test_iam_fmc " + gitid)
    for px in [1, 2, 3]:
        for bx in range(48 if px == 3 else 68):
            set_iam_fmc(addr, px, bx)
            r = get_iam_fmc(addr)
            print(px, "%3d" % bx, r[0], r[1], r[2])


if __name__ == "__main__":
    leep_addr = argv[1]
    addr = leep.open(leep_addr, timeout=5.0)
    test_iam_fmc(addr)
