#!/usr/bin/python3
# Convert xadc internal temperature register value (leep xadc_internal_temperature)
# to degrees Celsius.
import re


def _allhex(s):
    """Return True if s is a string composed only of hexadecimal characters (or 'x')."""
    if re.search("[^a-fA-F0-9x]", s.strip()):   # Try to match any non-hex characters
        return False
    return True


def _isip(s):
    """Return True if string 's' is a valid IP address string."""
    if re.search("[^0-9.]", s.strip()):   # Try to match anything except numbers and period
        return False
    return True


def txadc(r):
    """XADC internal temperature conversion function"""
    return 503.975*r/(0x10000) - 273.15


def _int(s):
    return int(s, 16)


def doConvert(argv):
    USAGE = "python3 {} rval\n  rval = xadc internal temperature register value (hex)"
    if len(argv) < 2:
        # Read from pipe if no command line args
        argv = sys.stdin.readline().strip('\n').split()
    rval = None
    for arg in argv[1:]:
        if _allhex(arg):
            rval = arg
    if rval is None:
        if rval in (None, ""):
            print(USAGE)
            return 1
    tval = txadc(_int(rval))
    try:
        print("{} = {:.2f}\u00b0C".format(hex(rval), tval))
    except Exception:
        print("{} = {:.2f} degC".format(hex(rval), tval))
    return 0


def doLeep(ipaddr, port):
    USAGE = "USAGE: python3 xadctemp.py -a {} -p {}".format(ipaddr, port)
    rval = None
    if ipaddr is not None:
        addr = "leep://" + ipaddr + ":" + str(port)
        dev = leep.open(addr, timeout=5.0)
        rval = dev.reg_read(("xadc_internal_temperature",))[0]
    if rval is None:
        print(USAGE)
        return -1
    tval = txadc(rval)
    try:
        print("{} = {:.2f}\u00b0C".format(hex(rval), tval))
    except Exception:
        print("{} = {:.2f} degC".format(hex(rval), tval))
    return 0


if __name__ == "__main__":
    import sys
    import argparse
    parser = argparse.ArgumentParser(
        description="Utility to read internal temperature of ")
    parser.add_argument('-a', '--addr', default='192.168.19.10', help='IP address')
    parser.add_argument('-p', '--port', type=int, default=0, help='Port number')

    import leep
    args = parser.parse_args()
    sys.exit(doLeep(args.addr, args.port))
