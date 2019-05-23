import struct
import time


def too_cute_los_mangle(ss, los):
    # print len(ss), ss, los
    if len(ss) == 40:
        ss = list(ss)
        for ix in range(4):
            if los[ix] != '0':
                ss[7 * ix + 15] = "!"
        ss = "".join(ss)
    else:
        ss += "  LOS " + "".join(los[:4])
    return ss


def qsfp_i2c_decode_lower(single, desc):
    # Latched LOS indicators, {Tx4, Tx3, Tx2, Tx1, Rx4, Rx3, Rx2, Rx1}
    los = single[3]  # see p. 62 of qsfp_plus_spec.pdf
    # Convert LOS status to list and reverse order
    # Order is now {Rx1, Rx2, Rx3, Rx4, Tx1, Tx2, Tx3, Tx4}
    los_status = list('{0:08b}'.format(los))[::-1]

    a = [
        single[ix] * 256 + single[ix + 1] for ix in [22, 26] + range(34, 50, 2)
    ]
    if all(v == 65535 for v in a):
        return desc + "  --\n" + desc + "  --"
    temperature = a[0] / 256.0
    if temperature >= 128:
        temperature -= 256.0
    srx = "  Rx POW: " + "  ".join(
        ["%5.3f" % (x * .0001) for x in a[2:6]]) + "  mW"
    stx = "  Tx CUR: " + "  ".join(
        ["%5.3f" % (x * .002) for x in a[6:10]]) + "  mA"
    srx = too_cute_los_mangle(srx, los_status[0:4])
    stx = too_cute_los_mangle(stx, los_status[4:8])
    s = desc
    s += "  Temp: %5.2f C" % temperature
    s += srx
    s += "\n"
    s += desc
    s += "  VCC:  %5.3f V" % (a[1] * .0001)
    s += stx
    return s


def pchr(x):
    return chr(x) if (x >= 32) and (x < 127) else " "


def qsfp_i2c_decode_upper(single, desc):
    if all(v == 255 for v in single[20:36]):
        return desc + "  --\n" + desc + "  --"
    s = desc
    s += "  Vendor: " + "".join([pchr(v) for v in single[20:36]])
    s += "  Part: " + "".join([pchr(v) for v in single[40:56]])
    s += "\n"
    s += desc
    s += "  Serial: " + "".join([pchr(v) for v in single[68:84]])
    wavelength = (single[58] * 256 + single[59]) * 0.05
    s += "  Wavelength: %5.2f nm" % wavelength
    return s


def qsfp_i2c_status(prc, verbose=False, base=0x00, decoder=None):
    addr = 0x153000
    prc.reg_write([{"qsfp_i2c_reg": ((base << 16) + 3)}])
    foo = prc.reg_read_alist(range(addr, addr + 256))
    prc.reg_write([{"qsfp_i2c_reg": ((base << 16) + 2)}])
    uuu = [struct.unpack('!I', x[2])[0] for x in foo]
    if verbose:
        print("raw I2C mem:", " ".join(['%2.2x' % v for v in uuu]))
    if decoder:
        # indices below work around off-by-one error in FPGA code
        # U50_modsel = qsfp_i2c_modsel[0];  modsel_word == 0
        # U32_modsel = qsfp_i2c_modsel[1];  modsel_word == 1
        print(decoder(uuu[1:128], "U50"))
        print(decoder(uuu[129:256], "U32"))


def qsfp_i2c_init(prc):
    prc.reg_write([{"qsfp_i2c_reg": 2}])  # Run (important the first time)
    time.sleep(0.01)
    prc.reg_write([{"qsfp_i2c_reg": 0}])  # Stop
    time.sleep(0.2)


def qsfp_i2c_reset(prc, verbose, do_init):
    if not do_init:
        # no need to do this twice
        prc.reg_write([{"qsfp_i2c_reg": 0}])  # Stop
        time.sleep(0.2)
    # U50_resetl = periph_config[12]
    # U32_resetl = periph_config[13]
    prc.reg_write([{"periph_config": 0xcffd}])
    time.sleep(0.1)
    # 0xdffd only enables U50, that's the second half, Serial: QF290B0M
    # 0xeffd only enables U32, that's the first  half, Serial: QF290B16
    # 0xfffd enables them both
    prc.reg_write([{"periph_config": 0xfffd}])
    # Reset Assert Time spec: 2000 ms
    time.sleep(2.0)
    if verbose:
        print("Reset over, starting run")
    base = 0x80
    prc.reg_write([{"qsfp_i2c_reg": ((base << 16) + 2)}])  # Run
    time.sleep(0.2)  # should really check "new" bit
    qsfp_i2c_status(prc, verbose, decoder=qsfp_i2c_decode_upper)
    time.sleep(0.2)


def usage():
    print('python qsfp_i2c_setup.py -a 192.168.21.12 -i -r')


if __name__ == "__main__":
    from llrf_bmb7 import c_llrf_bmb7
    import sys
    import getopt
    opts, args = getopt.getopt(
        sys.argv[1:], 'ha:p:irvc:',
        ['help', 'addr=', 'port=', 'reset', 'verbose', 'count=', 'init'])
    ip_addr = '192.168.21.48'
    port = 50006
    do_init = False
    do_reset = False
    verbose = False
    count = 1
    for opt, arg in opts:
        if opt in ('-h', '--help'):
            usage()
            sys.exit()
        elif opt in ('-a', '--address'):
            ip_addr = arg
        elif opt in ('-p', '--port'):
            port = int(arg)
        elif opt in ('-i', '--init'):
            do_init = True
        elif opt in ('-r', '--reset'):
            do_reset = True
        elif opt in ('-v', '--verbose'):
            verbose = True
        elif opt in ('-c', '--count'):
            count = int(arg)
    prc = c_llrf_bmb7(ip_addr, port, use_spartan=False)
    if do_init:
        qsfp_i2c_init(prc)
    if do_reset:
        qsfp_i2c_reset(prc, verbose, do_init)
    if do_reset or not do_init:
        for ix in range(count):
            if ix != 0:
                time.sleep(0.2)
            qsfp_i2c_status(prc, verbose, decoder=qsfp_i2c_decode_lower)
