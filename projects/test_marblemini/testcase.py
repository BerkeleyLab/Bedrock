from time import sleep
import sys
bedrock_dir = "../../"
sys.path.append(bedrock_dir + "peripheral_drivers/i2cbridge")
sys.path.append(bedrock_dir + "badger")
import lbus_access
from c2vcd import produce_vcd


def read_result(dev, i2c_base=0x040000, result_len=20, run=True):
    # freeze result buffer, usually keep running
    cmd = 3 if run else 1
    dev.exchange([327687], values=[cmd])
    # read out "results"
    if result_len > 0:
        addr = range(i2c_base+0x800, i2c_base+0x800+result_len)
        result = dev.exchange(addr)
    else:
        result = None
    # thaw result buffer, still keep running
    cmd = 2 if run else 0
    dev.exchange([327687], values=[cmd])
    return result


def wait_for_new(dev, timeout=120, sim=False):
    for ix in range(timeout):
        if sim:
            dev.exchange(125*[0])  # twiddle our thumbs for 1000 clock cycles
        else:
            sleep(0.02)
        updated = dev.exchange([9])
        # print("%d updated? %d" % (ix, updated))
        if updated & 1:
            sys.stdout.write("OK\n")
            break
        else:
            sys.stdout.write(".")
            sys.stdout.flush()


def wait_for_stop(dev, timeout=120, sim=False):
    for ix in range(timeout):
        if sim:
            dev.exchange(125*[0])  # twiddle our thumbs for 1000 clock cycles
        else:
            sleep(0.02)
        updated = dev.exchange([9])
        # print("%d updated? %d" % (ix, updated))
        if (updated & 4) == 0:
            sys.stdout.write("OK\n")
            if updated & 1:
                read_result(dev, result_len=0, run=False)  # clear "new" bit
            break
        else:
            sys.stdout.write("-")
            sys.stdout.flush()


def run_testcase(dev, prog, result_len=20, sim=False, capture=None, stop=False, debug=False):
    dev.exchange([327687], values=[0])  # run_cmd=0
    wait_for_stop(dev, sim=sim)
    # Upload program to i2c_chunk dpram
    i2c_base = 0x040000
    addr = range(i2c_base, i2c_base+len(prog))
    dev.exchange(addr, values=prog)
    dev.exchange([327687], values=[2])  # run_cmd=1
    wait_for_new(dev, sim=sim)
    result = read_result(dev, result_len=result_len)
    if stop:
        dev.exchange([327687], values=[0])  # run_cmd=0
    # read out "logic analyzer" data
    addr = range(i2c_base+0x400, i2c_base+0x400+1024)
    logic = dev.exchange(addr)
    if stop:
        wait_for_stop(dev, sim=sim)
    if sim:
        # stop simulation
        dev.exchange([327686], values=[1])
    if debug:
        print(logic)
    if capture is not None:
        # corresponds to hard-coded 6, 2 in i2c_chunk_tb.v
        mtime = 1 << 6
        dw = 2
        with open(capture, "w") as ofile:
            # 125 MHz clock and twi_q0=5
            produce_vcd(ofile, logic, dw=dw, mtime=mtime, t_step=8*32)
    return result


def print_sfp1(title, val):
    ss = "".join([chr(x) for x in val])
    print("  %s \"%s\"" % (title, ss))


def print_sfp(a):
    if all([x == 255 for x in a]):
        print("  hardware not present")
    else:
        print_sfp1("Vendor", a[0:16])
        print_sfp1("Part  ", a[16:32])
        print_sfp1("Serial", a[32:48])
        # see Table 3.8 of Finisar AN-2030
        suffix = "No internal cal; BAD!" if a[48] & 0x20 == 0 else "OK"
        print("  MonTyp  0x%2.2x  %s" % (a[48], suffix))


def print_sfp_z(a):
    if all([x == 255 for x in a]):
        pass
    else:
        aa = [float(x1*256+x2) for x1, x2 in zip(a[0::2], a[1::2])]
        if aa[0] >= 32768:  # Only temperature is signed
            aa[0] -= 65536
        print("  Temp     %.1f C" % (aa[0]/256.0))
        print("  Vcc      %.3f V" % (aa[1]*1e-4))
        print("  Tx bias  %.4f mA" % (aa[2]*2e-3))
        print("  Tx pwr   %.4f mW" % (aa[3]*1e-4))
        print("  Rx pwr   %.4f mW" % (aa[4]*1e-4))


def print_ina219(title, a):
    # hard-coded for default configuration 0x399F and 0.02 Ohm shunt
    shuntr = 0.02  # Ohm
    aa = [x1*256+x2 for x1, x2 in zip(a[0::2], a[1::2])]
    aa[0] = aa[0] if aa[0] < 32768 else aa[0]-65536  # only current is signed
    current = float(aa[0])/32768.0*0.32/shuntr
    busv = float(aa[1] & 0xfff8)/65536.0*32.0
    print("%s:  current %6.3f A   voltage %7.3f V" % (title, current, busv))


def print_ina219_config(title, a):
    x = a[0]*256 + a[1]
    suffix = "OK" if x == 0x399F else "BAD!"
    print("%s INA219 config: 0x%4.4X %s" % (title, x, suffix))


def print_result(result, args, poll_only=False):
    if args.debug:
        print(result)
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
        ib = 2*32  # init result memory base, derived from set_resx(2)
        print_ina219_config("FMC1", result[ib+1:ib+3])
        print_ina219_config("FMC2", result[ib+3:ib+5])
        if args.sfp:
            for ix in range(4):
                pitch = 50
                hx = ib + 7 + pitch*ix
                print("SFP%d:  busmux readback %x" % (ix+1, result[hx]))
                print_sfp(result[1+hx:pitch+hx])
            for ix in range(2):
                pitch = 28
                hx = ib + 207 + pitch*ix
                a1 = result[hx:hx+pitch]
                print("FMC%d: busmux 0x%2.2X" % (ix+1, a1[0]))
                print(a1[1:])
    if True:  # polling block
        if args.sfp:
            wp_bit = result[0] & 0x80
            ss = "Off" if wp_bit else "On"
            print("Write Protect switch is %s" % ss)
            sfp_pp = result[2]*256 + result[3]  # parallel SFP status via U34
            sfp_pp1 = [(sfp_pp >> ix*4) & 0xf for ix in [2, 1, 0, 3]]
            print_ina219("FMC1", result[4:4+4])
            print_ina219("FMC2", result[8:8+4])
            for ix in range(4):
                pitch = 10
                hx = 16 + pitch*ix
                a1 = result[hx:hx+pitch]
                print("SFP%d:  0x%X" % (ix+1, sfp_pp1[ix]))
                print_sfp_z(a1)
        else:
            wp_bit = result[32] & 0x80
            ss = "Off" if wp_bit else "On"
            print("Write Protect switch is %s" % ss)
            print_ina219("FMC1", result[38:38+4])
            print_ina219("FMC2", result[44:44+4])


if __name__ == "__main__":
    import argparse
    # import importlib
    parser = argparse.ArgumentParser(
        description="Utility for working with i2cbridge attached to Packet Badger")
    parser.add_argument('--ip', default='192.168.19.8', help='IP address')
    parser.add_argument('--udp', type=int, default=0, help='UDP Port number')
    parser.add_argument('--sim', action='store_true', help='simulation context')
    parser.add_argument('--ramtest', action='store_true', help='RAM test program')
    parser.add_argument('--sfp', action='store_true', help='SFP test program')
    parser.add_argument('--stop', action='store_true', help='stop after run')
    parser.add_argument('--debug', action='store_true', help='print raw arrays')
    parser.add_argument('--poll', action='store_true', help='only poll for results')
    parser.add_argument('--vcd', type=str, help='VCD file to capture')
    parser.add_argument('--rlen', type=int, default=327, help='result array length')

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
    elif args.sfp:
        import read_sfp
        prog = read_sfp.hw_test_prog()
    else:
        import poller
        prog = poller.hw_test_prog()

    # OK, setup is finished, start the actual work
    dev = lbus_access.lbus_access(ip, port=udp, allow_burst=False)
    if args.poll:
        while True:
            wait_for_new(dev, sim=sim)
            result = read_result(dev, result_len=args.rlen)
            print_result(result, args, poll_only=True)

    else:
        if args.debug:
            print(prog)
        print("Program size %d/1024" % len(prog))
        result = run_testcase(dev, prog, sim=sim, result_len=args.rlen,
                              debug=args.debug,
                              stop=args.stop, capture=args.vcd)
        print_result(result, args)
