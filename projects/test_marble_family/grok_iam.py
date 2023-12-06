# Tie the raw results of fmc_test_iam bit-scanning process
# to the connectivity quirks of the 
# IAM Electronic FPGA Mezzanine Card (FMC) Loopback Module
# https://github.com/FMCHUB/FMC_LOOPBACK
# so as to generate a pass/fail result.

def set_maps(verbose=False):
    iam_map_l = {}
    for ix in range(1, 22, 2):
        iam_map_l[ix] = ix+1
        iam_map_l[ix+1] = ix
    iam_map_l[0] = 2
    iam_map_l[1] = None
    iam_map_l[2] = 0
    iam_map_l[17] = 23
    iam_map_l[18] = None
    iam_map_l[23] = 17
    for ix in range(24, 34, 2):
        iam_map_l[ix] = ix+1
        iam_map_l[ix+1] = ix
    for ix in range(34):
        iam_map_l[ix+34] = None if iam_map_l[ix] is None else iam_map_l[ix]+34
    # These next are a little fake:
    # we extend the pattern to cover CLK0_M2C and CLK1_M2C.
    for ix in range(68, 74, 2):
        iam_map_l[ix] = ix+1
        iam_map_l[ix+1] = ix
    if verbose:
        print("LA")
        for ix in range(34):
            print(ix, iam_map_l[ix])
    iam_map_h = {}
    for ix in range(0, 24, 2):
        iam_map_h[ix] = ix+1
        iam_map_h[ix+1] = ix
    iam_map_h[14] = 17
    iam_map_h[15] = 16
    iam_map_h[16] = 15
    iam_map_h[17] = 14
    iam_map_h[18] = 21
    iam_map_h[19] = 20
    iam_map_h[20] = 19
    iam_map_h[21] = 18
    for ix in range(24):
        iam_map_h[ix+24] = iam_map_h[ix]+24
    if verbose:
        print("HA")
        for ix in range(24):
            print(ix, iam_map_h[ix])
    return iam_map_l, iam_map_h


def check_bank(name, plugged, iam_map, bx, b_self, b_others):
    bxm = iam_map[bx]
    # print(bx, bxm, len(b_self), b_self)
    k = bytearray()
    k.extend(b_self.encode())
    k.reverse()
    k.extend(b_others.encode())
    # print(k)
    x_self = chr(k[bx])
    y_self = "-" if bxm is None else chr(k[bxm])
    k[bx] = ord("1")
    if bxm is not None:
        k[bxm] = ord("1")
    cross = all([x == ord("1") for x in k])
    # print(name, bx, bxm, x_self, y_self, cross)
    bad = not cross
    bad |= x_self == "1"
    bad |= y_self == ("1" if plugged else "0")
    # print("debug1", name, bx, bad)
    return bad


def check_row(px, bx, r, plugged="12"):
    iam_map_l, iam_map_h = set_maps()
    if px == 1:
        bad = check_bank("P1L", "1" in plugged, iam_map_l, bx, r[0], r[1]+r[2])
    if px == 2:
        bad = check_bank("P2L", "2" in plugged, iam_map_l, bx, r[1], r[0]+r[2])
    if px == 3:
        bad = check_bank("P2H", "2" in plugged, iam_map_h, bx, r[2], r[0]+r[1])
    return bad


if __name__ == "__main__":
    from sys import argv
    fname = argv[1]
    fd = open(fname, "r")
    fault = False
    plugged = "2"  # testing
    for ll in fd.readlines():
        if ll.startswith("#"):
            next
        a = ll.split()
        fault |= check_row(int(a[0]), int(a[1]), (a[2], a[3], a[4]), plugged)
    print("FAIL" if fault else "PASS")
