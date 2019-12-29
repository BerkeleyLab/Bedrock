from fmc_test_l import fmc_decode, fmc_goal
import i2c_live

import sys
bedrock_dir = "bedrock/"
sys.path.append(bedrock_dir + "peripheral_drivers/i2cbridge")
from assem import i2c_assem


def build_i2c_reader(fmc_bus):
    s = i2c_assem()
    a = []
    a += s.pause(2)  # ignored?
    a += s.set_resx(0)  # avoid any confusion
    a += s.hw_config(fmc_bus)
    for mcp23017 in [0x4E, 0x48, 0x44, 0x4C, 0x42]:  # skip 0x4A
        a += s.write(mcp23017, 0x00, [0xff, 0xff])  # IODIR = input
        a += s.read(mcp23017, 0x12, 2)  # read pin values
    a += s.buffer_flip()
    a += [0]  # finish
    return a


# sig_num is 0 through 131
def fpga_out_one(sig_num):
    sig_num = int(sig_num) % 132
    q = int(sig_num/22)
    r = sig_num % 22
    push_add = [327696 + ix for ix in range(6)] + [327696 + q]
    push_val = [0 for ix in range(6)] + [1 << r]
    return push_add, push_val


def start_one(chip, sig_num):
    push_add, push_val = fpga_out_one(sig_num)
    # combine this with the run/stop commands
    push_add += [327687, 327687]
    push_val += [2, 0]
    chip.exchange(push_add, values=push_val)


def download_prog(chip, prog):
    i2c_base = 0x040000
    addr = range(i2c_base, i2c_base+len(prog))
    chip.exchange(addr, values=prog)


# fmc_bus_sel is 0 or 1 (for FMC1 or FMC2)
def run_set(xchip, fmc_bus_sel):
    fmc_bus_hw = 2 if fmc_bus_sel == 0 else 4
    a = build_i2c_reader(fmc_bus_hw)
    download_prog(xchip.dev, a)
    fault = False
    for ix in range(66):
        want = fmc_goal(ix)
        #
        start_one(xchip.dev, ix + fmc_bus_sel*66)
        xchip.wait_for_stop()
        result = xchip.read_result(result_len=10)
        #
        # XXX repeat temporarily needed to work around an acquisition problem
        start_one(xchip.dev, ix + fmc_bus_sel*66)
        xchip.wait_for_stop()
        result = xchip.read_result(result_len=10)
        #
        found = fmc_decode(fmc_bus_sel, result, squelch=True, verbose=False)
        if len(found) == 1 and found[0] == want:
            print(want + " good")
        else:
            print(want + " oops")
            fmc_decode(fmc_bus_sel, result, squelch=True)
            fault = True
    return fault


if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser(description="Marble FMC digital pin tester")
    parser.add_argument('--fmc', type=int, default=0, help="FMC slot (0 or 1)")
    #
    i2c_live.i2c_live_pre_args(parser)
    args = parser.parse_args()
    i2c = i2c_live.i2c_live_post_args(args)
    fault = run_set(i2c, args.fmc)
    if not fault:
        print("PASS")
