#!/usr/bin/env python
import argparse
import sys
import os
import time
import numpy as np
sys.path.append(os.path.join(os.path.dirname(__file__), "../../badger"))
from lbus_access import lbus_access


def set_1(chip, v, dac=2):
    '''
    v is 16-bit tuning word
    that can be written as either between 0 and 65535 or -32768 and 32767
    '''
    v &= 0xffff
    prefix_map = {1: 0x10000, 2: 0x20000}
    if dac in prefix_map:
        v |= prefix_map[dac]
    else:
        print("Invalid DAC choice")
        return None
    chip.exchange([327692, 327689], [0, v])  # pps_config, wr_dac


def measure_1(chip, v, dac=2, pause=1.1, repeat=1, gps=False, verbose=False):
    set_1(chip, v, dac)
    # freq_count gateware module is configured to update every 1.0737 s
    if gps:
        pause = 0.3 * pause
    ppm = []
    oldn = None
    while len(ppm) < repeat:
        time.sleep(pause)
        if gps:
            raw = chip.exchange([13])  # gps_pps_data
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
        elif dac == 2:
            raw = chip.exchange([20])  # aux_freq
            ppm += [(float(raw) * (0.5**27) * 125.0/20.0 - 1.0) * 1e6]
        else:
            raw = chip.exchange([5])  # tx_freq
            ppm += [(float(raw) * (0.5**27) - 1.0) * 1e6]
    return ppm


def check_one_curve(title, data, theory, mintune=4.5):
    max1 = max(data)
    min1 = min(data)
    ok = True
    ok &= max1 > mintune
    ok &= min1 < -mintune
    if theory is not None:
        dev = max(abs(data - theory))
        ok &= dev < 0.3
    else:
        dev = float('nan')
    ll = title, min1, max1, dev, "OK" if ok else "BAD"
    print("%s:  min %6.2f  max %6.2f  fit err %6.2f  %s" % ll)
    return ok


def check_answer(x, plot1, plot2, dac=1, plot=False):
    ok = True
    center = None
    theory = None
    x = np.array(x)
    if dac == 1:
        y = 0.5*(np.array(plot1) + np.array(plot2))
        basis = np.vstack((x, 0*x+1)).T
        fitc, resid, rank, sing = np.linalg.lstsq(basis, y, rcond=-1)
        theory = np.polyval(fitc, x)
        ok &= check_one_curve("col1", plot1, theory)
        ok &= check_one_curve("col2", plot2, theory)
        if ok:
            center = int(round(-fitc[1] / fitc[0]))
            print("center at x = %d" % center)
            # print(center, np.polyval(fitc, center))
    else:
        ok &= check_one_curve("col1", plot1, None, mintune=55.0)
        ok &= check_one_curve("col2", plot2, None, mintune=55.0)
    if plot:
        otype = "20 MHz" if dac == 2 else "Ethernet"
        plx = x / 65535.0
        style_pre = "-" if theory is None else ""
        pyplot.plot(plx, plot1, style_pre+'o')
        pyplot.plot(plx, plot2, style_pre+'x')
        pyplot.plot(plx, [0]*len(plx), ls='dashed')
        if theory is not None:
            pyplot.plot(plx, theory, '-')
        if center is not None:
            pc = center / 65535.0
            pyplot.plot([pc, pc], [-2, 2], '-', label="centered at %d" % center)
            pyplot.legend()
        pyplot.xlabel('Control (normalized)')
        pyplot.ylabel('Frequency offset (ppm)')
        pyplot.title(otype + ' VCXO characterization')
        pyplot.show()
    return ok, center


def collect_scan(chip, dac, npt=12, signed=False, gps=False, verbose=False):
    x = []
    plot1 = []
    plot2 = []
    for jx in range(npt):
        v_unsigned = int(min(jx * (65536/(npt-1)), 65535))
        v = v_unsigned-32768 if signed else v_unsigned
        ppm = measure_1(chip, v, dac=dac, repeat=4, gps=gps, verbose=verbose)
        if ppm is None:
            return None
        print("%6d  %+8.3f %+8.3f %+8.3f ppm" % (v, ppm[1], ppm[2], ppm[3]))
        x += [float(v)]
        plot1 += [ppm[1]]
        plot2 += [ppm[2]]
        sys.stdout.flush()
    return x, plot1, plot2


if __name__ == "__main__":
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('-a', '--addr', required=True,
                   help="IP address of FPGA (required)")
    p.add_argument('-p', '--port', default=803,
                   help="UDP port for I/O (default 803)")
    p.add_argument('--dac', default=1, type=int,
                   help="DAC (1 or 2), 1 tunes precision 25 MHz")
    p.add_argument('--npt', default=12, type=int,
                   help="number of points in scan")
    p.add_argument('--plot', action='store_true',
                   help="Plot data")
    p.add_argument('--gps', action='store_true',
                   help="Use GPS-pps-based measurement")
    p.add_argument('--center', action='store_true',
                   help="Center DAC 1 when done")
    p.add_argument('--signed', action='store_true',
                   help="Assume DAC uses signed binary codes")
    p.add_argument('-v', '--verbose', action='store_true',
                   help="Produce extra chatter")
    args = p.parse_args()
    if args.plot:
        from matplotlib import pyplot

    chip = lbus_access(args.addr, port=args.port)
    est_t = int(round(4.4*args.npt))
    print("Design run rate is 4.4 seconds per line, %d s total" % est_t)
    scan_data = collect_scan(
        chip, args.dac, npt=args.npt, signed=args.signed,
        gps=args.gps, verbose=args.verbose)
    if scan_data is None:
        exit(1)
    x, plot1, plot2 = scan_data
    ok, center = check_answer(x, plot1, plot2, dac=args.dac, plot=args.plot)
    if ok and args.dac == 1 and args.center:
        set_1(chip, center, dac=args.dac)
        print("pushed %d to DAC 1" % center)
    exit(0 if ok else 1)
