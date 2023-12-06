# PoC Marble FMC tester based on IAM Electronic FPGA Mezzanine Card (FMC) Loopback Module
# https://www.iamelectronic.com/shop/produkt/fpga-mezzanine-card-fmc-loopback-module
# Still doesn't cover LA_1 to GBTCLK0_M2C or LA_18 to GBTCLK1_M2C (HPC)

import sys
bedrock_dir = "../../"
sys.path.append(bedrock_dir + "projects/common")
import leep
import time
from grok_iam import check_row


def tobin(x, count=8):
    # Integer to binary; count is number of bits
    # Credit to W.J. van der Laan in http://code.activestate.com/recipes/219300/
    return "".join([str((x >> y) & 1) for y in range(count-1, -1, -1)])


# stupidly customized for 68-pin LA banks (plus 4 clock pins) in this application
# input is numeric, 22 bits + 22 bits + 28 bits
def to_bin_fmc(v):
    al = tobin(v[0], count=22)
    am = tobin(v[1], count=22)
    ah = tobin(v[2], count=28)
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
        al = (a >> 0)  & 0x03fffff
        am = (a >> 22) & 0x03fffff
        ah = (a >> 44) & 0xfffffff
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


def test_iam_fmc(addr, plugged="12", verbose=False):
    gitid = addr.codehash
    fault = False
    print("# test_iam_fmc " + gitid)
    for px in [1, 2, 3]:
        for bx in range(48 if px == 3 else 72):
            set_iam_fmc(addr, px, bx)
            time.sleep(0.001)
            r = get_iam_fmc(addr)
            if verbose:
                print(px, "%3d" % bx, r[0], r[1], r[2])
            fault |= check_row(px, bx, r, plugged=plugged)
    return fault


if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser(
        description="Utility for testing IAM Electronic FMC Loopback Module on Marble")
    parser.add_argument('-a', '--addr', required=True, help='IP address (required)')
    parser.add_argument('-p', '--port', type=int, default=803, help='Port number (default 803)')
    parser.add_argument('--plugged', type=str, default="12", help='Which FMC have IAM loopback (defauilt "12")')
    parser.add_argument('-v', '--verbose', action='store_true', help='Verbose output')
    parser.add_argument('-d', '--debug', action='store_true', help='print raw arrays')

    args = parser.parse_args()
    leep_addr = "leep://" + str(args.addr) + str(":") + str(args.port)
    print(leep_addr)
    addr = leep.open(leep_addr, timeout=5.0)
    fault = test_iam_fmc(addr, plugged=args.plugged, verbose=args.verbose)
    print("FAIL" if fault else "PASS")
    exit(1 if fault else 1)
