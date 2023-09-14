#!/usr/bin/env python
import argparse
import sys
import os
import time
sys.path.append(os.path.join(os.path.dirname(__file__), "../../badger"))
from lbus_access import lbus_access


def measure_1(chip, v, dac=2, pause=1.1, repeat=1, gps=False, verbose=False):
    '''
    v should be between 0 and 65535
    freq_count gateware module configured to update every 1.0737 s
    '''
    prefix_map = {1: 0x10000, 2: 0x20000}
    if dac in prefix_map:
        v |= prefix_map[dac]
    else:
        print("Invalid DAC choice")
        exit(1)
    if gps:
        pause = 0.3 * pause
    chip.exchange([327692, 327689], [0, v])  # pps_config, wr_dac
    ppm = []
    oldn = None
    while len(ppm) < repeat:
        time.sleep(pause)
        if gps:
            raw = chip.exchange([13])
            n = (raw >> 28) & 0xf
            ovf = (raw >> 27) & 0x1
            count = raw & 0x7ffffff
            ok = oldn is not None and n == ((oldn + 1) & 0xf) and not ovf
            if verbose and oldn is not None:
                print("chk %x %x %d %9d %s" % (
                    oldn, n, ovf, count, "OK" if ok else ".")
                )
            if ok:
                x = (float(count) / 125000000.0 - 1.0) * 1e6
                ppm += [x]
            oldn = n
        else:
            raw = chip.exchange([5])
            ppm += [(float(raw) / 2**27 - 1.0) * 1e6]
    return ppm


if __name__ == "__main__":
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('-a', '--addr', default="192.168.19.10",
                   help="IP address of FPGA")
    p.add_argument('-p', '--port', default=803,
                   help="UDP port for I/O")
    p.add_argument('--dac', default=1,
                   help="DAC (1 or 2), 1 tunes precision 25 MHz")
    p.add_argument('--plot', action='store_true',
                   help="Plot data")
    p.add_argument('--gps', action='store_true',
                   help="Use GPS-pps-based measurement")
    p.add_argument('--signed', action='store_true',
                   help="Assume DAC uses signed binary codes")
    p.add_argument('-v', '--verbose', action='store_true',
                   help="Produce extra chatter")
    args = p.parse_args()
    if args.plot:
        from matplotlib import pyplot

    chip = lbus_access(args.addr, port=args.port)
    print("Design run rate is 4.4 seconds per line, 75 s total")
    plx = []
    plot1 = []
    plot2 = []
    for jx in range(0, 17):
        v_unsigned = min(jx * 4096, 65535)
        v = v_unsigned-32768 if args.signed else v_unsigned
        ppm = measure_1(
            chip,
            v,
            dac=int(args.dac),
            repeat=4,
            gps=args.gps,
            verbose=args.verbose
        )
        print("%6d  %+7.3f %+7.3f %+7.3f ppm" % (v, ppm[1], ppm[2], ppm[3]))
        plx += [float(v) / 65535]
        plot1 += [ppm[1]]
        plot2 += [ppm[2]]
        sys.stdout.flush()
    if args.plot:
        pyplot.plot(plx, plot1, '-o')
        pyplot.plot(plx, plot2, '-x')
        pyplot.plot(plx, [0]*len(plx), ls='dashed')
        pyplot.xlabel('Control (normalized)')
        pyplot.ylabel('Frequency offset (ppm)')
        pyplot.title('Ethernet VCXO characterization')
        pyplot.show()
