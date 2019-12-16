#!/usr/bin/env python
import argparse
import sys
import os
import time
sys.path.append(os.path.join(os.path.dirname(__file__), "bedrock/badger"))
from lbus_access import lbus_access


def measure_1(chip, v, dac=2, pause=1.1, repeat=1):
    '''
    v should be between 0 and 65535
    freq_count gateware module configured to update every 1.0737 s
    '''
    prefix_map = {1: 0x10000, 2: 0x20000}
    if dac in prefix_map:
        v |= prefix_map[dac]
    chip.exchange([327689], [v])
    ppm = []
    for ix in range(repeat):
        time.sleep(pause)
        raw = chip.exchange([5])
        ppm += [(float(raw)/2**27-1.0)*1e6]
    return ppm


if __name__ == "__main__":
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--ip', default="192.168.19.8",
                   help="IP address of FPGA")
    p.add_argument('--port', default=803,
                   help="UDP port for I/O")
    p.add_argument('--dac', default=2,
                   help="DAC (1 or 2)")
    p.add_argument('--plot', action='store_true',
                   help="Plot data")
    args = p.parse_args()
    if args.plot:
        from matplotlib import pyplot

    chip = lbus_access(args.ip, port=args.port)
    print("Design run rate is 3.3 seconds per line, 56 s total")
    plx = []
    plot1 = []
    plot2 = []
    for jx in range(0, 17):
        v = min(jx*4096, 65535)
        ppm = measure_1(chip, v, dac=args.dac, repeat=3)
        print("%5d  %+.2f %+.2f ppm" % (v, ppm[1], ppm[2]))
        plx += [float(v)/65535]
        plot1 += [ppm[1]]
        plot2 += [ppm[2]]
    if args.plot:
        pyplot.plot(plx, plot1, '-o')
        pyplot.plot(plx, plot2, '-x')
        pyplot.xlabel('Control (normalized)')
        pyplot.ylabel('Frequency offset (ppm)')
        pyplot.title('Ethernet VCXO characterization')
        pyplot.show()
