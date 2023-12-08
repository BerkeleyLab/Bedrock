#!/usr/bin/env python3
# 2022 replacement for lcls2_llrf software/prc/bitrot/sn.py
# uses zbar directly instead of qrtools
# I2C hookup uses Marble instead of BMB7

# Special note about zbar versions; see zbar issue #237
#      https://github.com/mchehab/zbar/issues/237
#   zbar-tools 0.10 in Debian Stretch worked fine
#   zbar-tools 0.22 in Debina Buster is broken
#   zbar-tools 0.23.90 in Debian Bullseye is still broken, but at least
#      includes the zbar.Config.BINARY flag that is used as a workaround below
# Hope we can get the patch accepted into mainline and then Debian Bookworm.

import sys
import os
bedrock_dir = os.path.dirname(__file__) + "/../../"
sys.path.append(bedrock_dir + "badger")
import re
import zbar
from zest_sn import run_eeprom
import leep
import time


# directly cribbed from zbar's zbar/python/examples/read_one.py
def get_codes(device, visible=True):
    # create and configure a Processor
    proc = zbar.Processor()
    proc.parse_config('enable')
    # special to work around bug introduced in commit 6d028759
    # see zbar issue #237  https://github.com/mchehab/zbar/issues/237
    proc.set_config(zbar.Symbol.QRCODE, zbar.Config.BINARY, 1)
    # initialize the Processor
    proc.init(device)
    # option to enable the preview window
    proc.visible = visible
    # read at least one barcode (or until window closed)
    proc.process_one()
    # make sure any preview window goes away
    if visible:
        proc.visible = False
    return proc.results


def get_qrcode(results):
    # extract results
    for symbol in results:
        # Skip over non-QR codes
        if symbol.type != zbar.Symbol.QRCODE:
            print('skipping type', symbol.type)
            continue
        ss = symbol.data
        # print(ord(ss[0]), ord(ss[1]), ord(ss[-1]))
        while len(ss) > 1 and ord(ss[0]) > 127:
            # Unicde 65279: Zero Width No-Break Space
            print("Discarding leading %d" % ord(ss[0]))
            ss = ss[1:]
        m = re.search(r'LBNL DIGITIZER V1.\d SN +(\d+)', ss)
        if m:
            sn = int(m.group(1))
            return (sn, ss)
        else:
            print("Unexpected string %s" % ss)
    return None


if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser(
        description="Utility for auto-configuring Zest serial number")
    parser.add_argument('-a', '--addr', required=True, help='IP address (required)')
    parser.add_argument('-p', '--port', type=int, default=803, help='Port number (default 803)')
    parser.add_argument('-c', '--camera', type=str, default='/dev/video0', help='Camera device')
    parser.add_argument('-w', '--write', action='store_true', help='Write to eeprom')
    args = parser.parse_args()

    # maybe add command-line option to set visible flag?
    results = get_codes(args.camera, visible=True)
    qrcode = get_qrcode(results)
    if qrcode is None:
        print("Aborting")
        exit(1)
    sn, ss = qrcode
    print("QR code SN  : %s" % ss)

    if args.addr is None:
        exit(0)
    leep_addr = "leep://" + args.addr + ":" + str(args.port)
    # print(leep_addr)
    dev = leep.open(leep_addr)
    if args.write:
        old_sn = run_eeprom(dev, ss)
        print("Previous SN : %s" % old_sn)
        time.sleep(0.05)
        cnf_sn = run_eeprom(dev, None)
        print("Confirm SN  : %s" % cnf_sn)
        if cnf_sn == ss:
            print("OK")
            exit(0)
        else:
            print("FAIL")
            exit(1)
    else:
        now_sn = run_eeprom(dev, None)
        print("Extant SN   : %s" % now_sn)
