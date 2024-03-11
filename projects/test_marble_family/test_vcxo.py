# mostly repackaging and sequencing of features in scan_vcxo.py
from scan_vcxo import collect_scan, check_answer, measure_1
import argparse
import sys
import os
sys.path.append(os.path.join(os.path.dirname(__file__), "../../badger"))
from lbus_access import lbus_access


def run_test_vcxo(args):
    chip = lbus_access(args.addr, port=args.port)

    # Step 1: calibrate Ethernet Tx clock to GPS
    est_t = int(round(4.4*args.npt))
    print("Checking primary 125 MHz clock (Y1) vs. GPS")
    print("Design run rate is 4.4 seconds per line, %d s total" % est_t)
    scan_data = collect_scan(
        chip, 1, npt=args.npt, signed=args.signed, gps=True)
    if scan_data is None:
        exit(1)
    x, plot1, plot2 = scan_data
    ok1, center = check_answer(x, plot1, plot2, dac=1)
    # print(ok, center)

    # Step 2: check results
    if ok1:
        print("centering and testing")
        ppm = measure_1(chip, center, dac=1, repeat=4, gps=True)
        if ppm is None:
            exit(1)
        # This seems like a pretty stringent test on the lock,
        # but my tests usually show about 0.05 ppm residual error.
        if abs(ppm[2]) > 0.2 or abs(ppm[3]) > 0.2:
            ok1 = False
        ll = (center, ppm[1], ppm[2], ppm[3], "OK" if ok1 else "BAD")
        print("%6d  %+8.3f %+8.3f %+8.3f ppm  %s" % ll)

    # Step 3: report Rx clock
    raw = chip.exchange([5])[0]  # tx_freq, actually Rx relative to Tx
    ppm = (float(raw) * (0.5**27) - 1.0) * 1e6
    ok_rx = abs(ppm) < 50
    print("Rx clock from Ethernet switch %+8.3f ppm  %s" % (ppm, "OK" if ok_rx else "BAD"))

    # Step 4: calibrate auxiliary 20 MHz clock,
    # relative to the (just calibrated) Ethernet clock
    print("Checking secondary 20 MHz clock (Y3) against primary")
    print("Design run rate is 4.4 seconds per line, %d s total" % est_t)
    scan_data = collect_scan(
        chip, 2, npt=args.npt, signed=args.signed, gps=False)
    if scan_data is None:
        exit(1)
    x, plot1, plot2 = scan_data
    ok2, center = check_answer(x, plot1, plot2, dac=2)
    return ok1 and ok_rx and ok2


if __name__ == "__main__":
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('-a', '--addr', required=True,
                   help="IP address of FPGA (required)")
    p.add_argument('-p', '--port', default=803,
                   help="UDP port for I/O (default 803)")
    p.add_argument('--npt', default=12, type=int,
                   help="number of points in scan")
    p.add_argument('--signed', action='store_true',
                   help="Assume DAC uses signed binary codes")
    args = p.parse_args()
    ok = run_test_vcxo(args)
    if ok:
        print("PASS")
    else:
        exit(1)
