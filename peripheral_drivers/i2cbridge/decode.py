"""
This script decodify the iicCommandTable.dat used by Marble i2c_chunk.v (i2cBridge) printing a report
"""

import sys
from os.path import isfile
from datetime import datetime
from assem import i2c_assem

# Op Codes
o_oo = (i2c_assem.o_oo >> 5) & 0x7
o_rd = (i2c_assem.o_rd >> 5) & 0x7
o_wr = (i2c_assem.o_wr >> 5) & 0x7
o_wx = (i2c_assem.o_wx >> 5) & 0x7
o_p1 = (i2c_assem.o_p1 >> 5) & 0x7
o_p2 = (i2c_assem.o_p2 >> 5) & 0x7
o_jp = (i2c_assem.o_jp >> 5) & 0x7
o_sx = (i2c_assem.o_sx >> 5) & 0x7

# Control Words
n_oo_zz = i2c_assem.n_oo_zz
n_oo_bf = i2c_assem.n_oo_bf
n_oo_ta = i2c_assem.n_oo_ta
n_oo_hw = i2c_assem.n_oo_hw


def _int(x, base=None):
    if base is not None:
        return int(x, base)
    try:
        return int(x)
    except ValueError:
        pass
    try:
        return int(x, 16)
    except ValueError:
        pass
    return int(x, 2)


# ========================= Platform-Specific Overrides =======================
break_on_stop = False


def platform_write(devaddr, nbytes, cmd_table):
    return None, 0


def platform_read(devaddr, nbytes, cmd_table):
    return None, 0


def platform_write_rpt(devaddr, memaddr, nbytes, cmd_table):
    return None, 0
# =============================================================================


def decode_file(filename, break_on_stop=True, base=None):
    # progname = os.path.split(filename)[1]
    prog = load_file(filename, base=base)
    decoder = I2CBridgeDecoder(report_filename=None, break_on_stop=break_on_stop)
    return decoder.decode(prog)


class I2CBridgeDecoder():
    def __init__(self, report_filename=None, break_on_stop=False):
        self._filename = report_filename
        self._break_on_stop = break_on_stop
        self._fd = None
        self._opened = False

    def print(self, *args, **kwargs):
        if self._fd is None:
            if not self._opened and self._filename is not None:
                try:
                    self._opened = True
                    self._fd = open(self._filename, "w")
                except OSError:
                    self._fd = None
        if self._fd is not None:
            fd = self._fd
        else:
            fd = sys.stdout
        print(*args, **kwargs, file=fd)
        return

    def decode(self, prog):
        cmd_table = iter(prog)
        pa = 0
        if not cmd_table:
            return
        if self._filename is not None:
            self.print(f"File {self._filename} - {datetime.now()}")
        self.print("---- Start of report ----")
        self.print("Prog Address : Cmd Byte : [op_code n_code] -> Description and data")
        for idx, cmd_line in enumerate(cmd_table):
            cmd_byte = _int(cmd_line)
            op_code = cmd_byte >> 5
            n_code = cmd_byte & 0x1f

            self.print(f"{pa:03x}: {cmd_byte:02x} : [{op_code:03b} {n_code:05b}] -> ", end="")
            # Control Words
            if cmd_byte == n_oo_zz:
                self.print("STOP (sleep)")
                if break_on_stop or self._break_on_stop:
                    self.print("Terminating decoding due to break_on_stop policy")
                    break
            elif cmd_byte == n_oo_bf:
                self.print("Result buffer flip")
            elif cmd_byte == n_oo_ta:
                self.print("Trigger logic analyzer")
            elif (cmd_byte & 0xf0) == n_oo_hw:
                cfg = n_code & 0xf
                self.print(f"Set hw_config = 0b{cfg:04b}")

            elif op_code == o_rd:  # read
                dlen = n_code-1
                devaddr = _int(next(cmd_table))
                pa += 1
                s, inc = platform_read(devaddr, dlen, cmd_table)
                if s is not None:
                    self.print(s)
                    pa += inc
                else:
                    self.print(f"Read  - dev_addr: 0x{devaddr:02x} - data number: {dlen}")

            elif op_code == o_wr:  # write
                nbytes = n_code-1
                devaddr = _int(next(cmd_table))
                pa += 1
                s, inc = platform_write(devaddr, nbytes, cmd_table)
                if s is not None:
                    self.print(s)
                    pa += inc
                else:
                    self.print(f"Write - dev_addr: 0x{devaddr:02x} - mem_addr+data:", end="")
                    for j in range(nbytes):
                        data = _int(next(cmd_table))
                        pa += 1
                        self.print(f" 0x{data:02x}", end="")
                    self.print()

            elif op_code == o_wx:  # write followed by repeated start
                addr_bytes = n_code-1
                dlen = n_code-2
                devaddr = _int(next(cmd_table))
                memaddr = _int(next(cmd_table))
                pa += 2
                if addr_bytes == 2:
                    memaddr = (memaddr << 8) + _int(next(cmd_table))
                    pa += 1
                s, inc = platform_write_rpt(devaddr, memaddr, dlen, cmd_table)
                if s is not None:
                    self.print(s)
                    pa += inc
                else:
                    self.print(f"Write - dev_addr: 0x{devaddr:02x} - mem_addr:" +
                               f" 0x{memaddr:04x} - START - data:", end="")
                    for j in range(n_code-2):
                        data = _int(next(cmd_table))
                        pa += 1
                        self.print(f"0x{data:02x}", end="")
                    self.print()

            elif op_code == o_p1:  # pause (ticks are 8 bit times)
                if n_code == 0:
                    self.print("pad")
                else:
                    self.print(f"Short pause of {n_code} cycles")

            elif op_code == o_p2:  # pause (ticks are 256 bit times)
                self.print(f"Long pause of {n_code*32} cycles")

            elif op_code == o_jp:  # jump
                jump_addr = n_code*32
                self.print(f"Jump to address 0x{jump_addr:03x}")

            elif op_code == o_sx:  # set result address
                result_address = 0x800 + n_code*32
                self.print(f"Set result address to 0x{result_address:03x}" +
                           f" (0x{n_code:02x})")
            pa += 1

        self.print("---- End of report ----")
        return 0


def load_file(file_path=None, base=None):
    print(f"file_path={file_path}")
    if file_path is None:
        return None
    binary = True
    if isfile(file_path):
        if is_plaintext(file_path):
            binary = False
        try:
            if binary:
                return iter(open(file_path, 'rb'))
            else:
                fd = open(file_path, "r")
                sl = fd.read().split()
                ll = []
                for x in sl:
                    if len(x.strip()) > 0:
                        ll.append(_int(x, base))
                return ll
        except Exception as e:
            print(f"Error during file opening: [{e}]")
            return None
    else:
        print(f'File "{file_path}" not found')
        return None


def is_plaintext(file):
    """Returns True if file with filename 'file' is plaintext (ASCII/utf-8), False otherwise."""
    _ascii = True
    with open(file, 'r') as fd:
        line = True
        while line:
            try:
                line = fd.read(100)
            except UnicodeDecodeError:
                _ascii = False
                break
    return _ascii


def main():
    import argparse
    parser = argparse.ArgumentParser("I2CBridge Program Decoder")
    parser.add_argument("prog_file", default=None, help="Program file (binary or hex ASCII) to decode")
    parser.add_argument("-c", "--continue_on_stop", default=False,
                        help="Instead of breaking decoding when 'stop' byte reached, continue parsing with warning.")
    parser.add_argument("-d", "--decimal", default=False, help="Interpret ASCII input as base-10 (instead of base-16).")
    args = parser.parse_args()
    base = 16
    if args.decimal:
        base = 10
    return decode_file(args.prog_file, break_on_stop=not args.continue_on_stop, base=base)


if __name__ == '__main__':
    exit(main())
