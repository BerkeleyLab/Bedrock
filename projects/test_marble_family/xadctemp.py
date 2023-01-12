#!/usr/bin/python3
# Convert xadc internal temperature register value (leep xadc_internal_temperature)
# to degrees Celsius.


import re
try:
    from leep.raw import LEEPDevice
    _useLeep = True
except Exception:
    _useLeep = False


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
    print("{} = {:.2f}\u00b0C".format(rval, tval))
    return 0


def doLeep(argv):
    USAGE = "USAGE: python3 {} [ip_address|reg_value]".format(argv[0])
    if len(argv) < 2:
        # Read from pipe if no command line args
        argv = sys.stdin.readline().strip('\n').split()
    else:
        argv = argv[1:]
    ipaddr = None
    rval = None
    for arg in argv:
        if _isip(arg):
            ipaddr = arg.strip()
        if _allhex(arg):
            try:
                rval = _int(arg.strip())
            except Exception as e:
                print(e)
                return -1
    if ipaddr is not None:
        if _useLeep:
            dev = LEEPDevice(ipaddr+":803")
            try:
                rval = dev.reg_read(("xadc_internal_temperature",))[0]
            except Exception as e:
                print(e)
                return -1
        else:
            print("Set PYTHONPATH to include 'leep' directory.")
            return -1
    if rval is None:
        print(USAGE)
        return -1
    tval = txadc(rval)
    print("{} = {:.2f}\u00b0C".format(hex(rval), tval))
    return 0


if __name__ == "__main__":
    import sys
    # sys.exit(doConvert(sys.argv))
    sys.exit(doLeep(sys.argv))
