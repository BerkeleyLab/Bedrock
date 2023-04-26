# Keep in mind that I keep bit/channel numbering consistent, but
# it can look inconsistent: when they are arranged in a binary word,
# lsb is on the right, but when they are printed as a python list,
# lsb is on the left.

from __future__ import print_function


# returns the correctly ordered list of channels,
# or a blank list if the mask is invalid.
def banyan_ch_find(mask):
    '''
    mask: 0xa9 = 0b10101001 This means channels 7, 5, 3 and 0 are set
    This means lower is 0b1001 and upper is 0b1010
    '''
    mw = 8
    state = list(map(lambda y: (y, mask >> y & 1), range(mw)))
    ch_count = sum(x[1] for x in state)
    # print("banyan_ch_find", mask, ch_count)
    if ch_count in [1, 2, 4, 8]:
        return banyan_layer_permute(state)
    else:
        return []


# computations for a single layer; note the recursion
def banyan_layer_permute(state):
    '''
    Given a valid state, return the order of channels after balanced permuation
    state: [(n, nth_bit), (n+1, (n+1)th_bit) ...]
    '''
    ch_count = sum(x[1] for x in state)
    # print(ch_count, state)
    if ch_count > 1:
        # balance
        npt = len(state)
        M = npt // 2
        lower, upper = state[0:M], state[M:npt]
        imbalance = 0
        for ix in range(M):
            if imbalance:
                # If situation is currently IMbalanced and lower is set, but not upper
                # The channel will be swapped to feed the higher sink
                swap = not upper[ix][1] and lower[ix][1]
            else:
                # If situation is currently balanced and higher is set, but not lower
                # The channel will be swapped to feed the lower sink
                swap = upper[ix][1] and not lower[ix][1]
            imbalance ^= upper[ix][1] ^ lower[ix][1]
            if swap:
                upper[ix], lower[ix] = lower[ix], upper[ix]
        return banyan_layer_permute(lower) + banyan_layer_permute(upper)
    else:
        # no dealing here, just return
        return [x[0] for x in state if x[1]]


def genlist():
    for mask in range(256):
        o = banyan_ch_find(mask)
        if o:
            print("%2.2x" % (mask), o)


def vvp_parse_test(fd, verbose):
    '''
    feed this the output of vvp -n banyan_tb +trace +squelch
    '''
    fail = False
    mask_seen = {}
    for ll in fd.readlines():
        ll = ll.rstrip()
        if ll == "PASS":
            continue
        a = ll.split(" ")
        mask = int(a[0], 16)
        if not (mask in mask_seen):
            vvp = [int(x) for x in a[12:4:-1] if x != "."]
            chk = banyan_ch_find(mask)
            fault = chk != vvp
            if fault | verbose:
                if fault:
                    suffix = " != {} FAULT".format(chk)
                    fail = True
                else:
                    suffix = "."
                print("{} {} {}{}".format(a[0], a[3], vvp, suffix))
        mask_seen[mask] = 1
    # 107 = 1+70+28+8
    if fail or len(mask_seen) != 107:
        print("FAIL {}".format(len(mask_seen)))
        sys.exit(1)
    print("PASS  by banyan_ch_find vvp_parse_test()")


if __name__ == "__main__":
    import sys
    if len(sys.argv) > 1 and sys.argv[1] == "genlist":
        genlist()
    else:
        verbose = len(sys.argv) > 1 and sys.argv[1] == "verbose"
        vvp_parse_test(sys.stdin, verbose)
