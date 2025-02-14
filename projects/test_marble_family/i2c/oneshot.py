# Test i2cbridge features on the Marble platform

from marble_i2c import MarbleI2C
import marble_i2c_decoder
I2CBridgeDecoder = marble_i2c_decoder._decode.I2CBridgeDecoder

import leep
import time
import re


I2C_CTL = "twi_ctl"
I2C_STATUS = "twi_status"
I2C_MEM = "twi_data"


# Bit offsets for I2C_CTL
CTL_FREEZE_OS = 0
CTL_FREEZE = 1 << CTL_FREEZE_OS
CTL_RUN_CMD_OS = 1
CTL_RUN_CMD = 1 << CTL_RUN_CMD_OS
CTL_TRIG_MODE_OS = 2
CTL_TRIG_MODE = 1 << CTL_TRIG_MODE_OS
CTL_TRACE_CMD_OS = 3
CTL_TRACE_CMD = 1 << CTL_TRACE_CMD_OS


# Bit offsets for I2C_STATUS
STATUS_UPDATED_OS = 0
STATUS_UPDATED = 1 << STATUS_UPDATED_OS
STATUS_ERR_FLAG_OS = 1
STATUS_ERR_FLAG = 1 << STATUS_ERR_FLAG_OS
STATUS_RUN_STAT_OS = 2
STATUS_RUN_STAT = 1 << STATUS_RUN_STAT_OS
STATUS_ANALYZE_ARMED_OS = 3
STATUS_ANALYZE_ARMED = 1 << STATUS_ANALYZE_ARMED_OS
STATUS_ANALYZE_RUN_OS = 4
STATUS_ANALYZE_RUN = 1 << STATUS_ANALYZE_RUN_OS


# Recall, structure of I2C_MEM
#   0x000 - 0x3ff   program
#   0x400 - 0x7ff   logic analyzer
#   0x800 - 0xbff   results
#   0xc00 - 0xfff   result buffer in progress (not meant for host access)


# (regname, offset)
I2C_PROG     = ("twi_prog", 0)
I2C_ANALYZER = ("i2c_analyz", 0)
I2C_RESULTS  = ("twi_data", 0)


def _int(x):
    try:
        return int(x)
    except ValueError:
        pass
    try:
        return int(x, 16)
    except ValueError:
        pass
    return int(x, 2)


def decode(prog):
    dec = I2CBridgeDecoder()
    dec.decode(prog)
    return


def decodeI2CProgram(args):
    """Readout current I2C program and decode"""
    dev = leep.open(args.dest)
    # Read program memory
    name_sizes = ((I2C_PROG[0], 0x400, I2C_PROG[1]),)  # (name, size, offset)
    prog = dev.reg_read_size(name_sizes)[0]
    decode(prog)
    return 0


class XactType:
    read = 0
    write = 1
    pause = 2


def parse_xact(ss):
    """
    Write transaction:
      ic.addr=val
    Read transaction:
      ic.addr[:n]
        :n = optionally indicate number of bytes to read (default = 1)
    Pause:
      wait[=duration]
        =duration = optional duration in cycles (default = 10)
    """
    if ss.startswith("wait") or ss.startswith("pause"):
        xact = XactType.pause
        if '=' in ss:
            duration = _int(ss.split('=')[1])
        else:
            duration = 10
        return xact, None, None, duration
    restr = r"^(\w+\.)?([0-9a-fA-Fx]+)([=:][0-9a-fA-Fx]+)?$"
    _match = re.match(restr, ss)
    if _match:
        ic_name, addr, val = _match.groups()
        if val is None:
            xact = XactType.read
            val = 1
        else:
            if val.startswith('='):
                xact = XactType.write
                val = _int(val.strip('='))
            elif val.startswith(':'):
                xact = XactType.read
                val = _int(val.strip(':'))
        if ic_name is not None:
            ic_name = ic_name.strip('.')
        return xact, ic_name, _int(addr), val
    return None, None, None, None


def test_parse_xact():
    tests = (
        ("foo",             (None, None, None, None)),
        ("J17.86=1",        (XactType.write, "J17", 86, 1)),
        ("U52.0x15=0xff",   (XactType.write, "U52", 0x15, 0xff)),
        ("U1.0",            (XactType.read, "U1", 0, 1)),
        ("50",              (XactType.read, None, 50, 1)),
        ("1=0",             (XactType.write, None, 1, 0)),
        ("50:8",            (XactType.read, None, 50, 8)),
        ("U100.12:6",       (XactType.read, "U100", 12, 6)),
        ("pause",           (XactType.pause, None, None, 10)),
        ("wait",            (XactType.pause, None, None, 10)),
        ("pause=100",       (XactType.pause, None, None, 100)),
        ("pause=1",         (XactType.pause, None, None, 1)),
        ("wait=0",          (XactType.pause, None, None, 0)),
    )
    fails = 0
    for _input, _expected in tests:
        _result = parse_xact(_input)
        if _result != _expected:
            fails += 1
            print(f"FAIL: parse_xact({_input}) = {_result} != {_expected}")
    if fails == 0:
        print("PASS")
    return fails


def doI2CXact(args):
    marble = MarbleI2C()
    marble.set_resx()
    val = None
    reads = 0
    for xact in args.xact:
        _type, ic_name, addr, val = parse_xact(xact)
        if _type in (XactType.write, XactType.read):
            if ic_name is None:
                ic_name = args.ic
            if ic_name is None:
                raise Exception("ERROR: Must specify the target IC for each transaction or provide a default.")
        if _type == XactType.write:
            if args.verbose:
                print(f"Writing 0x{val:x} to {ic_name} address {addr}")
            marble.write(ic_name, addr, [val], addr_bytes=1)
        elif _type == XactType.read:
            reads += 1
            regname = f"{ic_name}_{addr:x}"
            nbytes = val
            if args.verbose:
                ps = ""
                if nbytes > 1:
                    ps = "s"
                print(f"Reading {nbytes} byte{ps} from {ic_name} address {addr}")
            marble.read(ic_name, addr, nbytes, addr_bytes=1, reg_name=regname)
        elif _type == XactType.pause:
            marble.pause(val)
    marble.buffer_flip()
    if args.loop:
        marble.jump(0)
    else:
        marble.stop()
    prog = marble.get_program()
    if args.verbose:
        decode(prog)
    if args.dest == "test":
        print("Test done.")
        return 0
    dev = leep.open(args.dest)
    stop(dev)
    program(dev, prog)
    run(dev)
    stop(dev)
    wait_stopped(dev)
    if reads > 0:
        regmap = marble.get_regmap()
        readback(dev, regmap, verbose=args.verbose)
    return 0


def wait_stopped(dev):
    attempts = 10
    # wait for run_stat = 0
    name_sizes = ((I2C_STATUS, 1, 0),)
    while True:
        status = dev.reg_read_size(name_sizes)[0]
        if (status & STATUS_RUN_STAT) == 0:
            break
        if attempts == 0:
            raise Exception("Timeout waiting for run_stat = 0")
        attempts -= 1
        time.sleep(0.1)
    return


def stop(dev):
    # deassert run_cmd
    name_vals = ((I2C_CTL, 0, 0),)
    dev.reg_write_offset(name_vals)
    wait_stopped(dev)
    return


def run(dev):
    # reassert run_cmd
    ctl_val = CTL_RUN_CMD
    name_vals = ((I2C_CTL, ctl_val, 0),)
    dev.reg_write_offset(name_vals)
    return


def program(dev, prog):
    name_vals = ((I2C_PROG[0], prog, I2C_PROG[1]),)  # (name, values, offset)
    dev.reg_write_offset(name_vals)
    return


def readback(dev, regmap, verbose=False):
    """Regmap is dict of {regname: (results_memory_offset, number_of_bytes)}"""
    readsize = 1
    for regname, _rd in regmap.items():
        offset, nbytes = _rd
        if offset + nbytes > readsize:
            readsize = offset + nbytes
    if verbose:
        print(f"Reading {readsize} bytes")
    name_sizes = ((I2C_RESULTS[0], readsize, I2C_RESULTS[1]),)  # (name, size, offset)
    results = dev.reg_read_size(name_sizes)[0]
    if verbose:
        print(f"Result = {results}")
    for regname, _rd in regmap.items():
        offset, nbytes = _rd
        data = results[offset:offset+nbytes]
        if verbose:
            print(f"offset {offset}: data = {data}")
        print_data(regname, data)
    return


def print_data(regname, data):
    val = 0
    for n in range(len(data)):
        val = (val << 8) | (data[n] & 0xff)
    pf = ""
    if val > 9:
        pf = "0x"
    print(f"{regname}: {pf}{val:x}")
    return


def doI2C():
    import argparse
    ic_help = "\n  ".join([": ".join((ic_name, descript)) for ic_name, descript in MarbleI2C._descript.items()])
    parser = argparse.ArgumentParser("Arbitrary I2C on Marble via i2cbridge", epilog="Marble ICs:\n  " + ic_help,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("dest", help="LEEP-compatible destination, i.e. \"leep://192.168.19.48:803\"")
    ic_options = [x[0] for x in MarbleI2C.get_ics()]
    for ic, aliases in MarbleI2C._aliases.items():
        ic_options.extend(aliases)
    parser.add_argument("-i", "--ic", default=None, choices=ic_options, help="Default IC name")
    parser.add_argument("xact", nargs="+",
                        help="[IC_NAME.]ADDR[=VALUE]. Optional IC name, register address in IC's memory map"
                        + " (and optional value to write).")
    parser.add_argument("-v", "--verbose", default=False, action="store_true", help="Enable debug chatter")
    parser.add_argument("-l", "--loop", default=False, action="store_true",
                        help="Leave the program running in a loop after exiting.")
    parser.add_argument("-d", "--decode", default=False, action="store_true",
                        help="Read and decode the existing program in the target device.")
    args = parser.parse_args()
    if args.decode is None:
        return decodeI2CProgram(args)
    return doI2CXact(args)


if __name__ == "__main__":
    exit(doI2C())
    # exit(test_parse_xact())
