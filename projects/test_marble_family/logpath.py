#! python3

# Get the logfile path for test/bringup data logs

def sanitize_sn(sn):
    sn = sn.strip().strip("#")
    # This is just to fail if sn is not numeric
    try:
        int(sn)
    except ValueError:
        return None
    return sn


def get_version_from_sn(sn):
    """Guess at the Marble board version from the serial number."""
    sn = int(sn)
    if sn < 20:         # TODO, get correct number
        return "1.2"
    elif sn < 40:       # TODO, get correct number
        return "1.3"
    return "1.4"


def get_log_path(serial_num, base=None, version=None, absolute=False):
    sn = sanitize_sn(args.serial_number)
    if sn is None:
        return None
    import os
    if args.base is not None:
        base = args.base
    else:
        base = os.environ.get("MARBLE_LOGPATH", "~/marble_logfiles")
    if args.version is not None:
        version = args.version
    else:
        version = get_version_from_sn(sn)
    if absolute:
        base = os.path.expanduser(base)
        base = os.path.abspath(base)
    log_path = os.path.join(base, version, sn)
    return log_path


def main(args):
    log_path = get_log_path(args.serial_number, base=args.base, version=args.version, absolute=args.absolute)
    if log_path is None:
        print("ERROR: Serial number must be numeric, not {}".format(args.serial_number), file=sys.stderr)
        return 1
    print(log_path)
    return 0


if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser(description="Marble test data log file path exporter")
    parser.add_argument("serial_number", help="Marble board serial number")
    parser.add_argument('-b', '--base', default=None, help="Base logfile directory (attempts to use $MARBLE_LOGPATH by default)")
    parser.add_argument('-v', '--version', default=None, help="Marble board version (e.g. 1.2, 1.3, 1.4, 1.4.1, etc)")
    parser.add_argument('-a', '--absolute', default=False, action="store_true", help="Return an absolute path instead of a relative one.")
    args = parser.parse_args()
    import sys
    sys.exit(main(args))
