from time import sleep
import sys
import numpy as np
bedrock_dir = "../../"
sys.path.append(bedrock_dir + "peripheral_drivers/i2cbridge")
sys.path.append(bedrock_dir + "badger")
sys.path.append(bedrock_dir + "projects/common")
import leep
from c2vcd import produce_vcd
from fmc_test_l import fmc_decode


# given a 2*n long array of 8-bit values,
# return an n-long array of 16-bit values, still integer
# constructed assuming 8-bit values are arranged in pairs, msb-first
def merge_16(a):
    aa = [x1*256+x2 for x1, x2 in zip(a[0::2], a[1::2])]
    return aa


def read_result(dev, i2c_base=0x040000, result_len=20, run=True):
    # freeze result buffer, usually keep running
    cmd = 3 if run else 1
    dev.reg_write([("twi_ctl", cmd)])  # twi_ctl
    # read out "results"
    if result_len > 0:
        result = dev.reg_read(["twi_data"])[0]
    else:
        result = None
    # thaw result buffer, still keep running
    cmd = 2 if run else 0
    dev.reg_write([("twi_ctl", cmd)])
    return result


def wait_for_bit(dev, mask, equal, timeout=520, sim=False, progress=".", verbose=False):
    for ix in range(timeout):
        if sim:
            dev.reg_read(125*["hello_0"])  # twiddle our thumbs for 1000 clock cycles
        else:
            sleep(0.02)
        updated = dev.reg_read(["twi_status"])[0]
        if verbose:
            print("%d updated? %d" % (ix, updated))
        if (updated & mask) == equal:
            if verbose:
                sys.stdout.write("OK\n")
            break
        else:
            if verbose:
                sys.stdout.write(progress)
                sys.stdout.flush()
    else:
        sys.stdout.write("timeout\n")
    return updated


def wait_for_new(dev, timeout=520, sim=False, verbose=False):
    if verbose:
        print("wait_for_new")
    wait_for_bit(dev, 1, 1, timeout=timeout, sim=sim, progress=".", verbose=verbose)


def wait_for_stop(dev, timeout=220, sim=False, verbose=False):
    if verbose:
        print("wait_for_stop")
    updated = wait_for_bit(dev, 4, 0, timeout=timeout, sim=sim, progress="-")
    if updated & 1:
        read_result(dev, result_len=0, run=False)  # clear "new" bit


def wait_for_trace(dev, timeout=520, sim=False):
    print("wait_for_trace")
    wait_for_bit(dev, 24, 0, timeout=timeout, sim=sim, progress="=")


def acquire_vcd(dev, capture, i2c_base=0x040000, sim=False, timeout=None, debug=False):
    wait_for_trace(dev, sim=sim)
    # read out "logic analyzer" data
    logic = dev.reg_read(["twi_analyz"])[0]
    if debug:
        print(logic)
    # corresponds to hard-coded 6, 2 in i2c_chunk_tb.v
    mtime = 1 << 6
    dw = 2
    tq = 6  # should match twi_q0 in lb_marble_slave.v
    t_step = 8*(2**tq)  # 125 MHz clock
    with open(capture, "w") as ofile:
        produce_vcd(ofile, logic, dw=dw, mtime=mtime, t_step=t_step)


def run_testcase(dev, prog, result_len=20, sim=False, capture=None, stop=False, debug=False, verbose=True):
    dev.reg_write([("twi_ctl", 0)])  # run_cmd=0
    wait_for_stop(dev, sim=sim, verbose=verbose)
    # Upload program to i2c_chunk dpram
    # leep can't write an incomplete memory block
    if len(prog) < 1024:
        prog += (1024-len(prog))*[0]
    dev.reg_write([("twi_prog", prog)])
    dev.reg_write([("twi_ctl", 10)])  # run_cmd=1, trig_run=1
    wait_for_new(dev, sim=sim, verbose=verbose)
    result = read_result(dev, result_len=result_len)
    if stop:
        dev.reg_write([("twi_ctl", 0)])  # run_cmd=0
    if stop:
        wait_for_stop(dev, sim=sim)
    if capture is not None:
        acquire_vcd(dev, capture, sim=sim, timeout=500, debug=debug)
    if sim and False:
        # stop simulation
        dev.reg_write([("stop_sim", 1)])  # stop_sim not yet in leep
    return result


def print_qsfp1(title, val):
    ss = "".join([chr(x) for x in val])
    print("  %s \"%s\"" % (title, ss))


def print_qsfp(a):
    if all([x == 255 for x in a]):
        print("  hardware not present")
    else:
        print_qsfp1("Vendor", a[0:16])
        print_qsfp1("Part  ", a[16:32])
        print_qsfp1("Serial", a[32:48])
        # see Table 3.8 of Finisar AN-2030
        suffix = "No internal cal; BAD!" if a[48] & 0x20 == 0 else "OK"
        print("  MonTyp  0x%2.2x  %s" % (a[48], suffix))


def print_sfp_z(a):
    if all([x == 255 for x in a]):
        pass
    else:
        aa = [float(x) for x in merge_16(a)]
        if aa[0] >= 32768:  # Only temperature is signed
            aa[0] -= 65536
        print("  Temp     %.1f C" % (aa[0]/256.0))
        print("  Vcc      %.3f V" % (aa[1]*1e-4))
        print("  Tx bias  %.4f mA" % (aa[2]*2e-3))
        print("  Tx pwr   %.4f mW" % (aa[3]*1e-4))
        print("  Rx pwr   %.4f mW" % (aa[4]*1e-4))


def print_qsfp_z(a):
    if all([x == 255 for x in a]):
        pass
    else:
        aa = [float(x) for x in merge_16(a)]
        if aa[0] >= 32768:  # Only temperature is signed
            aa[0] -= 65536
        print("  Temp     %.1f C" % (aa[0]/256.0))
        print("  Vcc      %.3f V" % (aa[1]*1e-4))
        print("  Lane      TX bias       Tx pwr        Rx pwr")
        print("  0        %.4f mA     %.4f mW     %.4f mW" % (aa[2]*2e-3, aa[6]*1e-4, aa[10]*1e-4))
        print("  1        %.4f mA     %.4f mW     %.4f mW" % (aa[3]*2e-3, aa[7]*1e-4, aa[11]*1e-4))
        print("  2        %.4f mA     %.4f mW     %.4f mW" % (aa[4]*2e-3, aa[8]*1e-4, aa[12]*1e-4))
        print("  3        %.4f mA     %.4f mW     %.4f mW" % (aa[5]*2e-3, aa[9]*1e-4, aa[13]*1e-4))


def print_ina219(title, a):
    # hard-coded for default configuration 0x399F and 0.02 Ohm shunt
    shuntr = 0.02  # Ohm
    aa = merge_16(a)
    aa[0] = aa[0] if aa[0] < 32768 else aa[0]-65536  # only current is signed
    current = float(aa[0])/32768.0*0.32/shuntr
    busv = float(aa[1] & 0xfff8)/65536.0*32.0
    print("%s:  current %6.3f A   voltage %7.3f V" % (title, current, busv))


def print_ina219_config(title, a):
    x = a[0]*256 + a[1]
    suffix = "OK" if x == 0x399F else "BAD!"
    print("%s INA219 config: 0x%4.4X %s" % (title, x, suffix))


def compute_si570(a):
    # DCO frequency range: 4850 - 5670MHz
    # HSDIV values: 4, 5, 6, 7, 9 or 11 (subtract 4 to store)
    # N1 values: 1, 2, 4, 6, 8...128
    hs_div = (a[0] >> 5) + 4
    n1 = (((a[0] & 0x1f) << 2) | (a[1] >> 6)) + 1
    rfreq = np.uint64((((a[1] & 0x3f) << 32) | (a[2] << 24) | (a[3] << 16) | (a[4] << 8) | a[5])) / (2**28)

    import leep
    leep_addr = "leep://" + str(args.ip) + str(":") + str(args.port)
    print(leep_addr)

    addr = leep.open(leep_addr, instance=[])
    freq_default = addr.reg_read(["frequency_si570"])
    default = (freq_default[0]/2**24.0)*125
    fxtal = default * hs_div * n1 / rfreq
    fdco = default * n1 * hs_div
    if args.debug:
        print('Default SI570 settings:')
        print('REFREQ: %4.3f' % rfreq)
        print('N1: %3d' % n1)
        print('HSDIV: %2d' % hs_div)
        print('Internal crystal frequency: %4.3f MHz' % fxtal)
        print('DCO frequency: %4.3f MHz' % fdco)
        print('Output frequency: %4.3f MHz' % default)
    else:
        print('SI570 output frequency: %4.3f MHz' % default)


def print_result(result, args, poll_only=False):
    n_fmc = 2 if args.fmc else 0
    tester = 2 if args.fmc_tester else 0
    transceiver = 2 if args.marble else 4
    if args.debug:
        for jx in range(16):
            p = result[jx*16:(jx+1)*16]
            print("%x " % jx + " ".join(["%2.2x" % r for r in p]))
    if args.ramtest:
        print("I2C RAM test")
        template = {0: 0x5a, 1: 0xa5, 2: 0x5a, 3: 0, 32: 0xa5, 33: 0}
        fault = False
        for kx in sorted(template.keys()):
            t = template[kx]
            v = result[kx]
            ss = "OK"
            if t != v:
                ss = "BAD!"
                fault = True
            print("%2.2x == %2.2x ?  %s" % (v, t, ss))
        if not fault:
            print("PASS")
        else:
            exit(1)
        return
    if not poll_only:  # init block
        ib = 3*32  # init result memory base, derived from set_resx(3)
        print_ina219_config("FMC1", result[ib+1:ib+3])
        print_ina219_config("FMC2", result[ib+3:ib+5])
        print_ina219_config("MAIN", result[ib+5:ib+7])
        if args.si570:
            print("########################################################################")
            pitch = 6
            hx = ib + 1 + pitch
            compute_si570(result[hx:hx+pitch])
        if args.trx:
            for ix in range(transceiver):
                print("########################################################################")
                pitch = 50
                hx = ib + 6 + 7 + pitch*ix
                print("Transceiver%d:  busmux readback 0x%2.2x" % (ix+1, result[hx]))
                print_qsfp(result[1+hx:pitch+hx])
            for ix in range(n_fmc):
                print("########################################################################")
                pitch = 48
                hx = ib + 207 + 6 + pitch*ix
                a1 = result[hx:hx+pitch]
                print("FMC%d: busmux readback 0x%2.2X" % (ix+1, a1[0]))
                print(a1[1:])
    if True:  # polling block
        if True:
            print("########################################################################")
            wp_bit = result[0] & 0x80
            ss = "Off" if wp_bit else "On"
            print("Write Protect switch is %s" % ss)
            if args.marble:
                qsfp_pp1 = [result[2], result[3]]
            else:
                qsfp_pp = result[2]*256 + result[3]  # parallel SFP status via U34
                qsfp_pp1 = [(qsfp_pp >> ix*4) & 0xf for ix in [2, 1, 0, 3]]
            ina_base = 4
            print_ina219("FMC1", result[ina_base+0:ina_base+4])
            print_ina219("FMC2", result[ina_base+4:ina_base+8])
            print_ina219("MAIN", result[ina_base+8:ina_base+12])
        if args.trx:
            for ix in range(transceiver):
                print("########################################################################")
                if args.marble:
                    pitch = 28
                else:
                    pitch = 10
                hx = 16 + pitch*ix
                a1 = result[hx:hx+pitch]
                print("Status pin monitor Transceiver%d:  0x%X" % (ix+1, qsfp_pp1[ix]))
                print_qsfp_z(a1) if args.marble else print_sfp_z(a1)
            for ix in range(tester):
                print("########################################################################")
                pitch = 10
                hx = 16 + 40 + pitch*ix
                fmc_dig = result[hx:hx+pitch]
                fmc_decode(ix, fmc_dig, squelch=args.squelch)
            for ix in range(tester):
                print("########################################################################")
                pitch = 6
                hx = 16+40+20 + pitch*ix
                fmc_ana = merge_16(result[hx:hx+pitch])
                print("FMC%d analog" % (ix+1))
                if fmc_ana[0] == 0xffff:
                    print("  not present")
                else:
                    # Cross-check:  these should be results from channels 6 to 8
                    # reference Tables 13 and 14 in AD7997 data sheet
                    if any([ix+5 != (x >> 12) for ix, x in enumerate(fmc_ana)]):
                        print(fmc_ana)
                        ss = "bad"
                    else:
                        fmc_v = [float(x & 0xfff)/4096.0 * 2.5 for x in fmc_ana]
                        setup = [
                            ("VS_VADJ", 1.58, 1.75),
                            ("VS_P12V_x", 1.88, 2.13),
                            ("VS_P3V3_x", 1.64, 1.82)]
                        for jx in range(3):
                            v = fmc_v[jx]
                            rr = setup[jx]
                            oor = v < rr[1] or v > rr[2]
                            suffix = "out of (%.2f, %.2f) range" % (rr[1], rr[2]) if oor else "OK"
                            print("  %-9s  = %5.3f V  %s" % (rr[0], v, suffix))
                # Table on EDA-02327-V1-0 schematic:
                # Valid voltage values [V] (5% tolerance)
                #  P3V3         1.58 - 1.89
                #  P12V         1.80 - 2.21
                #  Vadj (2.5V)  1.53 - 1.81


if __name__ == "__main__":
    import argparse
    # import importlib
    parser = argparse.ArgumentParser(
        description="Utility for working with i2cbridge attached to Packet Badger")
    parser.add_argument('--ip', default='192.168.19.10', help='IP address')
    parser.add_argument('--udp', type=int, default=0, help='UDP Port number')
    parser.add_argument('--port', type=int, default=803, help='Port number')
    parser.add_argument('--marble', type=int, default=1, help='Select the carrier board, Marble or Marble-Mini')
    parser.add_argument('--sim', action='store_true', help='simulation context')
    parser.add_argument('--ramtest', action='store_true', help='RAM test program')
    parser.add_argument('--trx', action='store_true',
                        help='Transceiver test program, QSFP for Marble and SFP for Marble-Mini')
    parser.add_argument('--si570', action='store_true',
                        help='Read current status fo SI570')
    parser.add_argument('--stop', action='store_true', help='stop after run')
    parser.add_argument('--debug', action='store_true', help='print raw arrays')
    parser.add_argument('--poll', action='store_true', help='only poll for results')
    parser.add_argument('--vcd', type=str, help='VCD file to capture')
    parser.add_argument('--fmc', action='store_true', help='connect to Zest')
    parser.add_argument('--fmc_tester', action='store_true', help='connect to CERN FMC tester')
    parser.add_argument('--rlen', type=int, default=359, help='result array length')
    parser.add_argument('--squelch', action='store_true', help='squelch non-LA FMC pins')

    args = parser.parse_args()
    ip = args.ip
    udp = args.udp
    sim = args.sim
    if sim:
        ip = 'localhost'
        if args.udp == 0:
            udp = 8030
    else:
        if args.udp == 0:
            udp = 803

    # Consider importlib instead to give more flexibility at runtime
    # will require turning ramtest and poller into actual classes
    # Or, better, turning this inside out and encapsulating the
    # infrastructure part of this file as a class.
    if args.ramtest:
        import ramtest
        prog = ramtest.ram_test_prog()
    elif args.trx:
        import read_trx
        prog = read_trx.hw_test_prog(args.marble)
    else:
        import poller
        prog = poller.hw_test_prog()

    # OK, setup is finished, start the actual work
    # dev = lbus_access.lbus_access(ip, port=udp, timeout=3.0, allow_burst=False)
    leep_addr = "leep://" + ip + ":" + str(udp)
    print(leep_addr)
    dev = leep.open(leep_addr, timeout=5.0)
    if args.poll:
        while True:
            wait_for_new(dev, sim=sim)
            result = read_result(dev, result_len=args.rlen)
            print_result(result, args, poll_only=True)

    else:
        if args.debug:
            print(" ".join(["%2.2x" % p for p in prog]))
        print("Program size %d/1024" % len(prog))
        result = run_testcase(dev, prog, sim=sim, result_len=args.rlen,
                              debug=args.debug,
                              stop=args.stop, capture=args.vcd)
        print_result(result, args)
