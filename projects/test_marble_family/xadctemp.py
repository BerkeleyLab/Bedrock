#!/usr/bin/python3
# Convert xadc internal temperature register value (leep xadc_internal_temperature)
# to degrees Celsius.
import sys
import re
bedrock_dir = "../../"
sys.path.append(bedrock_dir + "projects/common")
import leep


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


def xadc_int_volts(r):
    """Convert XADC internal voltage measurements from register value to voltage.
    See UG480 (v1.11) Equation 2-7"""
    # 12 bits of ADC stuffed into an MSB-aligned 16-bit register
    return 3*r/(0x10000)


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


def has_register(dev, regname):
    try:
        dev.get_reg_info(regname)
    except KeyError:
        return False
    return True


def doLeep(ipaddr, port):
    rval = None
    rmap = {
        "xadc_internal_temperature": None,
        "xadc_vccint": None,
        "xadc_vccaux": None,
        "xadc_vbram": None,
    }
    if ipaddr is not None:
        addr = "leep://" + ipaddr + ":" + str(port)
        dev = leep.open(addr, timeout=5.0)
        regs = []
        for regname in rmap.keys():
            try:
                if has_register(dev, regname):
                    regs.append(regname)
            except RuntimeError:
                pass
        rvals = dev.reg_read(regs)
        for n in range(len(rvals)):
            regname = regs[n]
            rmap[regname] = rvals[n]
    for regname, rval in rmap.items():
        if rval is None:
            print("Could not read {}".format(regname))
        else:
            if regname == "xadc_internal_temperature":
                tval = txadc(rval)
                try:
                    print("{}: {:.2f}\u00b0C".format(regname, tval))
                except Exception:
                    print("{}: {:.2f} degC".format(regname, tval))
            else:
                tval = xadc_int_volts(rval)
                print("{}: {:.3} V".format(regname, tval))
    return 0


if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser(
        description="Utility to read internal temperature of ")
    parser.add_argument('-a', '--addr', required=True, help='IP address (required)')
    parser.add_argument('-p', '--port', type=int, default=803, help='Port number (default 803)')

    args = parser.parse_args()
    sys.exit(doLeep(args.addr, args.port))
