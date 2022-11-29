# Measures the current output frequency from SI570
# also one can configure it to a different frequency
import sys
import numpy as np
bedrock_dir = "../../"
sys.path.append(bedrock_dir + "peripheral_drivers/i2cbridge")
sys.path.append(bedrock_dir + "badger")
sys.path.append(bedrock_dir + "projects/common")
import lbus_access
import assem
import testcase
from time import sleep


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


def hw_test_prog():
    s = assem.i2c_assem()
    si570_list = [0x0d, 0x0e, 0x0f, 0x10, 0x11, 0x12]
    a = []
    a += s.pause(2)  # ignored?
    a += s.set_resx(3)  # avoid any confusion
    a += busmux_reset(s)
    #
    a += busmux_sel(s, 6)  # App bus
    a += s.read(0xe0, 0, 1, addr_bytes=0)  # busmux readback

    a += s.write(0x42, 6, [0xfe, 0x77])  # U39 Configuration registers
    a += s.write(0x42, 2, [0x00, 0x88])  # U39 output register for clkmux_reset and SI570_OE
    # pull down MOD_SEL, RESET and LPMODE, i.e set them as outputs
    a += s.write(0x44, 6, [0x37, 0x37])  # U34 Configuration registers
    a += s.write(0x44, 2, [0x48, 0x48])  # U34 Output registers

    a += s.pause(100)
    for ax in si570_list:
        a += s.read(0xee, ax, 1)  # config register0 with 2 bytes to read

    a += s.trig_analyz()
    #
    jump_n = 9
    a += s.jump(jump_n)
    a += s.pad(jump_n, len(a))
    #
    # Start of polling loop
    a += s.set_resx(0)
    a += busmux_sel(s, 6)  # App bus
    # keep clkmux_reset high always
    a += s.write(0x42, 2, [0x00, 0x84])  # Output registers
    a += s.pause(2)
    a += s.read(0x42, 0, 2)  # Physical pin logic levels
    a += s.read(0x44, 0, 2)  # Physical pin logic levels

    a += s.buffer_flip()  # Flip right away, so most info is minimally stale
    # This does mean that the second readout of the PCA9555 will be extra-stale
    # or even (on the first trip through) invalid.
    a += s.pause(3470)
    #
    a += busmux_sel(s, 6)  # App bus
    a += s.write(0x42, 2, [0x00, 0x88])  # Output registers
    a += s.pause(2)
    a += s.read(0x42, 0, 2)  # Physical pin logic levels
    a += s.pause(3470)
    if False:  # extra weird little flicker
        a += s.write(0x42, 2, [0x00, 0x84])  # Output registers, LD12
        a += s.pause(1056)
        a += s.write(0x42, 2, [0x00, 0x88])  # Output registers, LD11
        a += s.pause(1056)
    a += s.jump(jump_n)
    return a


def hw_write_prog(reg):
    s = assem.i2c_assem()
    a = []
    a += s.pause(2)  # ignored?
    a += s.set_resx(3)  # avoid any confusion
    a += busmux_reset(s)
    #
    a += busmux_sel(s, 6)  # App bus
    a += s.read(0xe0, 0, 1, addr_bytes=0)  # busmux readback

    # Freeze the DCO by setting Freeze DCO=1 (bit 4 of register 137).
    a += s.write(0xee, 0x89, [0x10])
    # Write the new frequency configuration (RFREQ, HS_DIV, and N1)
    a += s.write(0xee, 0x0d, [reg[0]])
    a += s.write(0xee, 0x0e, [reg[1]])
    a += s.write(0xee, 0x0f, [reg[2]])
    a += s.write(0xee, 0x10, [reg[3]])
    a += s.write(0xee, 0x11, [reg[4]])
    a += s.write(0xee, 0x12, [reg[5]])
    # Unfreeze the DCO by setting Freeze DCO=0 (register 137 bit 4)
    a += s.write(0xee, 0x89, [0x00])
    # assert the NewFreq bit (bit 6 of register 135) within 10 ms.
    a += s.write(0xee, 0x87, [0x40])

    a += s.pause(100)

    si570_list = [0x0d, 0x0e, 0x0f, 0x10, 0x11, 0x12]
    for ax in si570_list:
        a += s.read(0xee, ax, 1)  # config register0 with 2 bytes to read
    a += s.trig_analyz()
    #
    jump_n = 9
    a += s.jump(jump_n)
    a += s.pad(jump_n, len(a))
    return a


# check if the final output frequency is <= 50 ppm
def check(fin):
    ppm = ((fin)*(1/args.new_freq) - 1.0)*1e6
    if (abs(ppm) <= 50):
        sys.exit(0)
    else:
        print('SI570 final frequency measurement is not correct, out of spec by %i ppm' % ppm)


def compute_si570(dev, addr, key):
    # using keyword just to keep print consistent
    prog = hw_test_prog()
    result = testcase.run_testcase(dev, prog, result_len=359, debug=args.debug)
    if args.debug:
        print(" ".join(["%2.2x" % p for p in prog]))
        print("")
        for jx in range(16):
            p = result[jx*16:(jx+1)*16]
            print("%x " % jx + " ".join(["%2.2x" % r for r in p]))

    ib = 3*32  # init result memory base, derived from set_resx(3)
    a = result[ib+1:ib+7]

    hs_div = (a[0] >> 5) + 4
    n1 = (((a[0] & 0x1f) << 2) | (a[1] >> 6)) + 1
    rfreq = np.uint64((((a[1] & 0x3f) << 32) | (a[2] << 24) | (a[3] << 16) | (a[4] << 8) | a[5])) / (2**28)

    freq_default = addr.reg_read(["frequency_si570"])
    default = (freq_default[0]/2**24.0)*125
    # keep everything in MHz
    fdco = default * n1 * hs_div
    fxtal = fdco / rfreq
    if args.verbose:
        print('%s SI570 settings:' % key)
        print('REFREQ: %4.4f' % rfreq)
        print('N1: %3d' % n1)
        print('HSDIV: %2d' % hs_div)
        print('Internal crystal frequency: %4.4f MHz' % fxtal)
        print('DCO frequency: %4.4f MHz' % fdco)
        print('Output frequency: %4.4f MHz' % default)
    else:
        print('%s SI570 output frequency: %4.4f MHz' % (key, default))
    return fxtal, default


def config_si570(dev, addr):
    if args.new_freq:
        fxtal, _ = compute_si570(dev, addr, "Measured")
        print("#######################################")
        print("Changing output frequency to %4.4f MHz" % args.new_freq)
        # DCO frequency range: 4850 - 5670MHz
        # HSDIV values: 4, 5, 6, 7, 9 or 11 (subtract 4 to store)
        # N1 values: 1, 2, 4, 6, 8...128
        # Find the lowest acceptable DCO value (lowest power) see page 15 from datasheet
        best = [0, 0, 6000.0]
        for i in range(0, 65):
            n1_i = i*2
            if i == 0:
                n1_i = 1
            for hsdiv_i in [4, 5, 6, 7, 9, 11]:
                fdco_i = args.new_freq * n1_i * hsdiv_i
                if (fdco_i > 4850.0) and (fdco_i < 5670.0):
                    # print(n1_i-1, hsdiv_i-4, fdco_i)
                    if fdco_i < best[2]:
                        best = [n1_i, hsdiv_i, fdco_i]

        if best[2] > 5700.0:
            raise Exception('Could not find appropriate settings for your new target frequency')

        if args.debug:
            print('New best option is:')
            print(best[0]-1, best[1]-4, best[2])

        rfreq = int(best[2] * float(2**28) / fxtal)
        rfreq_i = int(best[2] / fxtal)
        n1 = best[0]-1
        hs_div = best[1]-4
        if args.verbose:
            print('Expected SI570 settings:')
            print('REFREQ: %4.4f' % rfreq_i)
            print('N1: %3d' % best[0])
            print('HSDIV: %2d' % best[1])
            print('DCO frequency: %4.4f MHz' % best[2])
        reg = []
        # build registers
        reg7 = (hs_div << 5) | ((n1 & 0x7C) >> 2)  # reg 7: hs_div[2:0], n1[6:2]
        reg8 = ((n1 & 3) << 6) | (rfreq >> 32)  # reg 8: n1[1:0] rfreq[37:32]
        reg9 = (rfreq >> 24) & 0xff  # reg 9: rfreq[31:24]
        reg10 = (rfreq >> 16) & 0xff  # reg 10: rfreq[23:16]
        reg11 = (rfreq >> 8) & 0xff  # reg 11: rfreq[15:8]
        reg12 = rfreq & 0xff  # reg 12: rfreq[7:0]
        reg = [reg7, reg8, reg9, reg10, reg11, reg12]
        # write new registers
        chg = hw_write_prog(reg)
        result1 = testcase.run_testcase(dev, chg, result_len=359, debug=args.debug)
        if args.debug:
            print(" ".join(["%2.2x" % p for p in chg]))
            print("")
            for jx in range(16):
                p = result1[jx*16:(jx+1)*16]
                print("%x " % jx + " ".join(["%2.2x" % r for r in p]))
        # sleep for a second, so we can read the final frequency
        sleep(1)
        # read final values and output frequency?
        print("#######################################")
        _, freq = compute_si570(dev, addr, "Final")
        check(freq)
    else:  # read only current settings if you don't want to change anything
        print("#######################################")
        compute_si570(dev, addr, "Measured")


if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser(
        description="Utility for configuring SI570 with i2cbridge attached to Packet Badger")
    parser.add_argument('-a', '--addr', default='192.168.19.10', help='IP address')
    parser.add_argument('-p', '--port', type=int, default=803, help='Port number')
    parser.add_argument('-f', '--new_freq', type=float, default=None, help='Enter new SI570 output frequency in MHz')
    parser.add_argument('-v', '--verbose', action='store_true', help='Verbose output')
    parser.add_argument('-d', '--debug', action='store_true', help='print raw arrays')

    args = parser.parse_args()
    import leep
    leep_addr = "leep://" + str(args.addr) + str(":") + str(args.port)
    print(leep_addr)

    addr = leep.open(leep_addr, instance=[])

    dev = lbus_access.lbus_access(args.addr, port=args.port, timeout=3.0, allow_burst=False)

    config_si570(dev, addr)

# usage:
# To read current output frequency:
# python3 config_si570.py -a 192.168.19.31 -p 803 -d
# To change output frequency:
# python3 config_si570.py -a 192.168.19.31 -p 803 -d -f 185 -v
