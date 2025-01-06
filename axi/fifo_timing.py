#! python3

# Calculate FIFO depths and read enable delay based on clock frequencies
# and transaction rates

import math

# See mem_gate.md's note about MTU-limited single-beat transactions
RTEFI_MTU_LIMITED_MAX_XACTS = 183


def FIFO_OUT_depth(fh, fp, HOST_XACT_CYCLES=8, RLAT=3, MAX_XACTS=RTEFI_MTU_LIMITED_MAX_XACTS):
    cdc0 = (1/fh + 1/fp)
    # print(f"fh/HOST_XACT_CYCLES = {fh/HOST_XACT_CYCLES}; fp/RLAT = {fp/RLAT}")
    if fh/HOST_XACT_CYCLES > fp/RLAT:
        p0 = fp/RLAT
        depth = MAX_XACTS*(1-HOST_XACT_CYCLES*p0/fh) + cdc0*fh/HOST_XACT_CYCLES
    else:
        p0 = fh/HOST_XACT_CYCLES
        depth = cdc0*fh/HOST_XACT_CYCLES
    return depth


def FIFO_IN_depth(fh, fp, HOST_XACT_CYCLES=8, RLAT=3, MAX_XACTS=RTEFI_MTU_LIMITED_MAX_XACTS, ENABLE_DELAY=100):
    cdc0 = (1/fh + 1/fp)
    cdc1 = cdc0
    # recall: s1 = s0 + i*RLAT/fp
    # recall: s0 = cdc0
    s1 = cdc0 + RLAT/fp
    h0 = fh/HOST_XACT_CYCLES
    if ENABLE_DELAY/fh > MAX_XACTS*RLAT/fp:
        # p side will finish filling before h side begins to drain
        depth = MAX_XACTS
    else:
        # h side will begin draining before p side finishes filling
        if fp/RLAT < h0:
            # the p side is slower than the h side (the exact case this solution is tailored for)
            if (s1 + cdc1) > ENABLE_DELAY/fh:
                # This path will only work for small clock ratios
                depth = cdc1*fp/RLAT
            else:
                depth = (ENABLE_DELAY/fh - cdc0)*fp/RLAT - 1
        else:
            # the p side can keep up with the h side
            if (s1 + cdc1) > ENABLE_DELAY/fh:
                # This path will only work for small clock ratios
                depth = fh*cdc1/HOST_XACT_CYCLES
            else:
                depth = ENABLE_DELAY/HOST_XACT_CYCLES - (cdc0 + RLAT/fp)*fh/HOST_XACT_CYCLES
    return depth


def min_Enable_delay(fh, fp, HOST_XACT_CYCLES=8, RLAT=3, MAX_XACTS=RTEFI_MTU_LIMITED_MAX_XACTS):
    cdc0 = (1/fh + 1/fp)
    h0 = fh/HOST_XACT_CYCLES
    if fp/RLAT < h0:
        # the p side is slower than the h side (the exact case this solution is tailored for)
        enable_delay = fh*(cdc0 + (MAX_XACTS + 1)*(RLAT/fp)) - HOST_XACT_CYCLES*MAX_XACTS
    else:
        # The p side can keep up with the h side; no ENABLE_DELAY is needed
        enable_delay = 0
    if enable_delay < 0:
        print(f"enable_delay = {enable_delay} < 0!")
        print(f"fh*(cdc0 + (MAX_XACTS + 1)*(RLAT/fp)) = {fh*(cdc0 + (MAX_XACTS + 1)*(RLAT/fp))};" +
              f" HOST_XACT_CYCLES*MAX_XACTS = {HOST_XACT_CYCLES*MAX_XACTS}")
    return enable_delay


def clog2(n):
    return math.ceil(math.log2(n+1))


def doFifoTiming(args):
    if args.fh is not None:
        fh = 1.0e6*float(args.fh)
    else:
        fh = 1.0e9/float(args.ph)
    if args.fp is not None:
        fp = 1.0e6*float(args.fp)
    else:
        fp = 1.0e9/float(args.pp)
    rlat = int(args.rlat)
    host_xact_cycles = int(args.xact_cycles)
    max_xacts = int(args.max_xacts)
    out_depth = FIFO_OUT_depth(fh, fp, HOST_XACT_CYCLES=host_xact_cycles, RLAT=rlat+1, MAX_XACTS=max_xacts)
    # print(f"out_depth = {out_depth}")
    en_delay = min_Enable_delay(fh, fp, HOST_XACT_CYCLES=host_xact_cycles, RLAT=rlat+1, MAX_XACTS=max_xacts)
    # print(f"en_delay = {en_delay}")
    in_depth = FIFO_IN_depth(fh, fp, HOST_XACT_CYCLES=host_xact_cycles, RLAT=rlat+1, MAX_XACTS=max_xacts,
                             ENABLE_DELAY=en_delay)
    # print(f"in_depth = {in_depth}")
    FIFO_OUT_AW = clog2(out_depth)
    FIFO_IN_AW = clog2(in_depth)
    ENABLE_DELAY = math.ceil(en_delay)
    if args.vh is not None:
        fd = open(args.vh, 'w')
    else:
        fd = None
    print(f"// freq(h_clk) = {fh*1.0e-6} MHz", file=fd)
    print(f"// freq(p_clk) = {fp*1.0e-6} MHz", file=fd)
    print(f"// RLAT = {rlat}", file=fd)
    print(f"// XACT_CYCLES = {host_xact_cycles}", file=fd)
    print(f"// MAX_XACTS = {max_xacts}", file=fd)
    print(f"localparam FIFO_OUT_AW = {FIFO_OUT_AW};", file=fd)
    print(f"localparam FIFO_IN_AW = {FIFO_IN_AW};", file=fd)
    print(f"localparam ENABLE_DELAY = {ENABLE_DELAY};", file=fd)
    return


if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser("LocalBus CDC FIFO Parameters Calculator")
    groupHost = parser.add_mutually_exclusive_group(required=True)
    groupHost.add_argument("--fh", default=None, help="Host clock frequency (in MHz)")
    groupHost.add_argument("--ph", default=None, help="Host clock period (in ns)")
    groupPeri = parser.add_mutually_exclusive_group(required=True)
    groupPeri.add_argument("--fp", default=None, help="Peripheral clock frequency (in MHz)")
    groupPeri.add_argument("--pp", default=None, help="Peripheral clock period (in ns)")
    parser.add_argument("-r", "--rlat", default=3,
                        help="Read cycle latency: how many cycles to assert 'raddr' before latching 'rdata'")
    parser.add_argument("-c", "--xact_cycles", default=8,
                        help="Number of host clock cycles between transactions (1/xact_rate).")
    parser.add_argument("-x", "--max_xacts", default=RTEFI_MTU_LIMITED_MAX_XACTS,
                        help="Maximum number of transactions per burst (packet).")
    parser.add_argument("--vh", default=None, help="Filename for auto-generated Verilog Header (.vh) file.")
    args = parser.parse_args()
    doFifoTiming(args)
