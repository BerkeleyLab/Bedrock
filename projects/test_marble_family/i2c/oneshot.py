# Test i2cbridge features on the Marble platform

from marble_i2c import MarbleI2C
import marble_i2c_decoder
I2CBridgeDecoder = marble_i2c_decoder._decode.I2CBridgeDecoder

import leep
import time


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


def doI2CXact(args):
    marble = MarbleI2C()
    marble.set_resx()
    if args.value is not None:
        marble.write(args.ic, _int(args.reg_addr), [_int(args.value)], addr_bytes=1)
    else:
        regaddr = _int(args.reg_addr)
        regname = f"{args.ic}_{regaddr:x}"
        # print("reading {} bytes".format(_int(args.data_bytes)))
        marble.read(args.ic, regaddr, _int(args.data_bytes), addr_bytes=1, reg_name=regname)
    marble.buffer_flip()
    marble.stop()
    prog = marble.get_program()
    # decode(prog)
    dev = leep.open(args.dest)
    stop(dev)
    program(dev, prog)
    run(dev)
    stop(dev)
    wait_stopped(dev)
    regmap = marble.get_regmap()
    readback(dev, regmap)
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


def readback(dev, regmap):
    """Regmap is dict of {regname: (results_memory_offset, number_of_bytes)}"""
    readsize = 1
    for regname, _rd in regmap.items():
        offset, nbytes = _rd
        if offset + nbytes > readsize:
            readsize = offset + nbytes
    # print(f"readsize = {readsize}")
    name_sizes = ((I2C_RESULTS[0], readsize, I2C_RESULTS[1]),)  # (name, size, offset)
    results = dev.reg_read_size(name_sizes)[0]
    # print(f"results = {results}")
    for regname, _rd in regmap.items():
        # print(f"results offset 0x{offset:x}")
        offset, nbytes = _rd
        data = results[offset:offset+nbytes]
        # print(f"data = {data}")
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
    parser = argparse.ArgumentParser("Arbitrary I2C on Marble via i2cbridge")
    parser.add_argument("dest", help="LEEP-compatible destination, i.e. \"leep://192.168.19.48:803\"")
    ic_options = [x[0] for x in MarbleI2C.get_ics()]
    parser.add_argument("-i", "--ic", default=None, choices=ic_options, help="IC name")
    parser.add_argument("-a", "--reg_addr", default=0, help="Register address in IC's memory map")
    parser.add_argument("-v", "--value", default=None, help="Value to write to address REG_ADDR")
    parser.add_argument("-n", "--data_bytes", default=1, help="How many bytes to read from REG_ADDR")
    args = parser.parse_args()
    if args.ic is None:
        return decodeI2CProgram(args)
    return doI2CXact(args)


if __name__ == "__main__":
    exit(doI2C())
