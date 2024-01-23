#!/usr/bin/env python
import sys
import os
import time
import datetime
sys.path.append(os.path.join(os.path.dirname(__file__), "../../badger"))
from lbus_access import lbus_access
global old_pps_cnt
old_pps_cnt = None


def set_lock(chip, v, dac=1, fir=False, fine_sel=False, verbose=False):
    '''
    experimental
    '''
    prefix_map = {1: 0x10000, 2: 0x20000}  # 1=25 MHz VCTCXO, 2=20 MHz VCXO
    cfg = 1
    if fir:
        cfg += 16
    if fine_sel:
        cfg += 32
    if dac in prefix_map:
        v |= prefix_map[dac]
        cfg |= prefix_map[dac] >> 14
    else:
        print("Invalid DAC choice")
        exit(1)
    print("# DAC v = %d (%x)" % ((v & 0xffff), v))
    chip.exchange([327692], [0])  # pps_config
    chip.exchange([327689], [v])  # wr_dac
    time.sleep(0.1)
    chip.exchange([327692], [cfg])  # pps_config


def poll_lock(chip, verbose=False, timeout=10, log=False):
    global old_pps_cnt
    rct = 0
    start = time.time()
    while True:
        dsp_status, gps_status, cfg = chip.exchange([14, 12, 327692])
        dac = dsp_status >> 16
        dsp_arm = (dsp_status >> 12) & 1
        dsp_on = (dsp_status >> 13) & 1
        pps_cnt = (gps_status >> 4) & 0xf
        pps_lcnt = (gps_status >> 12) & 0xfff
        pha = dsp_status & 0xfff
        if pha > 2047:
            pha -= 4096
        if verbose or pps_cnt != old_pps_cnt:
            break
        if (timeout > 0) and ((time.time() - start) > timeout):
            return None
        time.sleep(0.20)
        rct += 1
    old_pps_cnt = pps_cnt
    ss = "{:5d} {:6d} {:7d} {:5d} {:7d} {:3d} {:3d} {:8d}".format(
        dac, dsp_on, dsp_arm, pha, pps_cnt, cfg, rct, pps_lcnt)
    if log:
        _log = (dac, dsp_on, dsp_arm, pha, pps_cnt, cfg, rct, pps_lcnt)
    else:
        _log = None
    return ss, _log


def monitor(addr, port, init_val, npts=60, dac_n=1, use_fir=False, cont=False, timeout=10, verbose=False, log=False):
    """Monitor (and initialize if cont==False) the VCXO frequency-locking feedback loop.
    Returns log of monitored values (2D list).
    If log==False, the returned log is empty.  Otherwise, each row is:
        (int DAC value, bool dsp_on, bool dsp_arm, int phase, int pps_cnt (0-15), bitmap cfg, int rct, int pps_lcnt)
    """
    chip = lbus_access(addr, port=port, verbose=verbose)
    print("# " + datetime.datetime.utcnow().isoformat() + "Z")
    first = False
    if not cont:
        set_lock(chip, int(init_val), dac=int(dac_n), fir=use_fir, verbose=verbose)
        first = True  # don't want to see stale DAC value in plots
    print("#{:>5s} {:>6s} {:>7s} {:>5s} {:>7s} {:>3s} {:>3s} {:>8s}".format(
        "dac", "dsp_on", "dsp_arm", "pha", "pps_cnt", "cfg", "rct", "pps_lcnt"))
    _log = []
    for ix in range(int(npts)):
        try:
            ss, _nlog = poll_lock(chip, verbose=verbose, timeout=int(timeout))[0]
            if ss is None:
                print("Timeout waiting for PPS signal")
                break
            _log.append(_nlog)
            print(("#" if first else " ") + ss)
            sys.stdout.flush()
            time.sleep(0.85)
            first = False
        except KeyboardInterrupt:
            print("# Exiting")
            break
    return _log


def main(args):
    monitor(addr=args.addr,
            port=int(args.port),
            init_val=int(args.val),
            npts=int(args.npt),
            dac_n=int(args.dac),
            use_fir=args.fir,
            cont=args.cont,
            timeout=int(args.timeout),
            verbose=args.verbose)


def ArgumentParser(parent_parser=None, **kwargs):
    import argparse
    if parent_parser is not None:
        p = parent_parser
    else:
        p = argparse.ArgumentParser(**kwargs)
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('-a', '--addr', required=True,
                   help="IP address of FPGA (required)")
    p.add_argument('-p', '--port', default=803,
                   help="UDP port for I/O (default 803)")
    p.add_argument('-d', '--dac', default=1,
                   help="DAC (1 or 2), 1 tunes precision 25 MHz")
    p.add_argument('-i', '--val', default=0,
                   help="Initial DAC value")
    p.add_argument('-f', '--fir', action="store_true",
                   help="enable FIR filter")
    p.add_argument('-v', '--verbose', action='store_true',
                   help="Produce extra chatter")
    p.add_argument('-n', '--npt', default=60,
                   help="Number of time steps to collect")
    p.add_argument('-c', '--cont', action='store_true',
                   help="Monitor only, don't initialize")
    p.add_argument('-t', '--timeout', default=10,
                   help="Time (in seconds) to exit after last PPS signal (negative values disable timeout)")
    return p


if __name__ == "__main__":
    p = ArgumentParser()
    args = p.parse_args()
    main(args)
