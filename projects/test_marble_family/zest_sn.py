# Reads and optionally sets a serial number string onto a Zest board
# using Marble i2c bridge functionality.
# More, generally, interacts with EEPROM address 0xa0 on FMC 1.
import sys
# bedrock_dir = "../../"
import os
bedrock_dir = os.path.dirname(__file__) + "/../../"
sys.path.append(bedrock_dir + "peripheral_drivers/i2cbridge")
sys.path.append(bedrock_dir + "badger")
import assem
import testcase
import leep


# select one port of an I2C bus multiplexer
# port_n must be between 0 and 7
def busmux_sel(s, port_n):
    tca9548a_addr = 0xe0
    return s.write(tca9548a_addr, 1 << port_n, [])


def busmux_reset(s):
    a = []
    a += s.pause(10)
    a += s.hw_config(1)  # turn on reset
    a += s.pause(10)
    a += s.hw_config(0)  # turn off reset
    a += s.pause(10)
    return a


def hw_test_prog(rom_addr=0, new_sn=None):
    s = assem.i2c_assem()
    a = []
    a += s.pause(2)  # ignored?
    a += s.set_resx(3)  # avoid any confusion
    a += busmux_reset(s)
    #
    a += busmux_sel(s, 0)  # App bus
    a += s.read(0xe0, 0, 1, addr_bytes=0)  # busmux readback

    a += s.pause(100)
    a += s.read(0xa0, rom_addr, 16, addr_bytes=2)
    a += s.read(0xa0, rom_addr+16, 16, addr_bytes=2)
    if new_sn is not None:
        ll = len(new_sn)
        avail = 32 - (rom_addr & 0x1f)  # in page
        if ll > 0 and ll <= avail:
            print("Will attempt to write SN len %d: %s" % (ll, new_sn))
            dd = [ord(x) for x in new_sn]
            a += s.write(0xa0, rom_addr, dd, addr_bytes=2)

    jump_n = 9
    a += s.jump(jump_n)
    a += s.pad(jump_n, len(a))
    #
    # Start of dummy polling loop; no actual I2C transactions
    a += s.set_resx(0)
    a += busmux_sel(s, 6)  # App bus
    a += s.pause(2)

    a += s.buffer_flip()  # Flip right away, so most info is minimally stale
    a += s.pause(3470)
    a += s.jump(jump_n)
    return a


# returns previous serial number
def run_eeprom(dev, new_sn, verbose=False, debug=False):
    # using keyword just to keep print consistent
    prog = hw_test_prog(new_sn=new_sn)
    result = testcase.run_testcase(dev, prog, result_len=359, debug=debug, verbose=verbose)
    if debug:
        print(" ".join(["%2.2x" % p for p in prog]))
        print("")
        for jx in range(16):
            p = result[jx*16:(jx+1)*16]
            print("%x " % jx + " ".join(["%2.2x" % r for r in p]))

    ib = 3*32  # init result memory base, derived from set_resx(3)
    rr = result[ib+1:ib+33]
    # unwritten EEPROM locations come back 255
    sn = "".join([chr(a) for a in rr if a != 255])
    return sn


if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser(
        description="Utility for configuring Zest (FMC) serial string with i2cbridge attached to Packet Badger")
    parser.add_argument('-a', '--addr', default='192.168.19.10', help='IP address')
    parser.add_argument('-p', '--port', type=int, default=803, help='Port number')
    parser.add_argument('-s', '--new_sn', type=str, default=None, help='New FMC serial ID')
    parser.add_argument('-v', '--verbose', action='store_true', help='Verbose output')
    parser.add_argument('-d', '--debug', action='store_true', help='print raw arrays')

    args = parser.parse_args()

    # dev = lbus_access.lbus_access(args.addr, port=args.port, timeout=3.0, allow_burst=False)
    leep_addr = "leep://" + args.addr + ":" + str(args.port)
    # print(leep_addr)
    dev = leep.open(leep_addr)

    sn = run_eeprom(dev, args.new_sn, verbose=args.verbose, debug=args.debug)
    print(sn)

# usage:
# To read existing serial number:
# python3 zest_sn.py -a $IP
# To write new serial number:
# python3 zest_sn.py -a $IP --new_sn "LBNL DIGITIZER V1.1 SN 342"
