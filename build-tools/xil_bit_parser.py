import argparse
import sys
import binascii
import re


# Work towards compatibility with both python2 and python3
def hexfromba(ba):
    if sys.version_info[0] < 3:
        return binascii.hexlify(ba)
    else:
        return ba.hex()


def decode_header(fname):
    """Returns strings of bytes up to pad sequence that precedes sync pattern (0xAA995566)"""

    with open(fname, 'rb') as FH:
        # Header
        hl = int(hexfromba((FH.read(2))), 16)
        h = hexfromba(FH.read(hl))
        if h != '0ff00ff00ff00ff000':
            print("ERROR: Unexpected magic number")
            exit(-1)

        h = FH.read(3)  # Skip lengh + token
        # Design info
        hl = int(hexfromba((FH.read(2))), 16)
        dsgn_info = FH.read(hl)[0:-1].decode('utf-8')  # Strip null byte

        h = FH.read(1)  # Skip token
        # Device name
        hl = int(hexfromba((FH.read(2))), 16)
        dev_name = FH.read(hl)[0:-1].decode('utf-8')

        h = FH.read(1)  # Skip token
        # Build date
        hl = int(hexfromba((FH.read(2))), 16)
        build_date = FH.read(hl)[0:-1].decode('utf-8')

    TOP_RE = r'^(\S+?);'
    UID_RE = r'UserID=(\S+?)(;|$)'
    VER_RE = r'Version=(\S+?)(;|$)'
    bit_dict = {}
    zz = zip(['top', 'uid', 'ver'], [TOP_RE, UID_RE, VER_RE])
    for z in zz:
        m = re.search(z[1], dsgn_info)
        bit_dict[z[0]] = m.group(1) if m else ''

    bit_dict['date'] = build_date
    bit_dict['dev'] = dev_name

    return bit_dict


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Reads and parses Series 6 and Series 7 Xilinx .bit bitfiles')
    parser.add_argument('bit', metavar='bit', type=str, help='Bitfile to parse')
    args = parser.parse_args()

    print(decode_header(args.bit))
