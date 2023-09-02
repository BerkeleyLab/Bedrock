#!/usr/bin/env python
import argparse
import sys
import os
import time
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


def poll_lock(chip, verbose=False):
    global old_pps_cnt
    rct = 0
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
        time.sleep(0.20)
        rct += 1
    old_pps_cnt = pps_cnt
    ss = "%5d %d %d %4d %2d %d %d %4d" % (dac, dsp_on, dsp_arm, pha, pps_cnt, cfg, rct, pps_lcnt)
    return ss


if __name__ == "__main__":
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('-a', '--addr', default="192.168.19.8",
                   help="IP address of FPGA")
    p.add_argument('-p', '--port', default=803,
                   help="UDP port for I/O")
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

    args = p.parse_args()

    chip = lbus_access(args.addr, port=args.port)
    if not args.cont:
        set_lock(chip, int(args.val), dac=int(args.dac), fir=args.fir, verbose=args.verbose)
    for ix in range(int(args.npt)):
        ss = poll_lock(chip, verbose=args.verbose)
        print(ss)
        sys.stdout.flush()
        time.sleep(0.85)
