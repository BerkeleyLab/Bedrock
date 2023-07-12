"""
This script decodify the iicCommandTable.dat used by Marble i2c_chunk.v (i2cBridge) printing a report
"""

import argparse
from os.path import isfile
from datetime import datetime

#import assem

# ========================= Platform-Specific Overrides =======================
def platform_write(devaddr, nbytes, cmd_table):
    return None, 0

def platform_read(devaddr, nbytes, cmd_table):
    return None, 0

def platform_write_rpt(devaddr, memaddr, nbytes, cmd_table):
    return None, 0
# =============================================================================

def decode(argv):
    if len(argv) > 1:
        filename = argv[1]
    else:
        print("No filename provided")
        return
    cmd_table = load_file(filename)
    pa = 0
    if not cmd_table: return
    else:
        report_file = f"File {cmd_table.name} - {datetime.now()}\n---- Start of report ----\n"
        report_file += "Prog Address : Cmd Byte : [op_code n_code] -> Description and data\n"
    for idx, cmd_line in enumerate(cmd_table):
        cmd_byte = int(cmd_line[:2], 16)
        op_code = cmd_byte >> 5
        n_code = cmd_byte & 0x1f

        report_file += f"{pa:03x}: {cmd_byte:02x} : [{op_code:03b} {n_code:05b}] -> "
        match op_code:
            case 0:  # special
                if n_code == 0:
                    report_file += f"STOP (sleep)\n"
                elif n_code == 2:
                    report_file += f"result buffer flip\n"
                elif n_code == 3:
                    report_file += f"trigger logic analyzer\n"
                elif n_code >= 16:
                    cfg = n_code & 0xf
                    report_file += f"hw_config 0b{cfg:04b}\n"

            case 1:  # read
                dlen = n_code-1
                devaddr = int(next(cmd_table)[:2], 16)
                pa += 1
                s, inc = platform_read(devaddr, dlen, cmd_table)
                if s is not None:
                    report_file += s + '\n'
                    pa += inc
                else:
                    report_file += f"read  - dev_addr: 0x{devaddr:02x} - data number: {dlen}\n"

            case 2:  # write
                #n_code = 1 + addr_bytes + len(data)
                nbytes = n_code-1
                devaddr = int(next(cmd_table)[:2], 16)
                pa += 1
                s, inc = platform_write(devaddr, nbytes, cmd_table)
                if s is not None:
                    report_file += s + '\n'
                    pa += inc
                else:
                    report_file += f"write - dev_addr:" + \
                                    f" 0x{devaddr:02x} - mem_addr+data:"
                    for j in range(nbytes):
                        data = int(next(cmd_table)[:2], 16)
                        pa += 1
                        report_file += f" 0x{data:02x}"
                    report_file += '\n'

            case 3:  # write followed by repeated start
                addr_bytes = n_code-1
                dlen = n_code-2
                devaddr = int(next(cmd_table)[:2], 16)
                memaddr = int(next(cmd_table)[:2], 16)
                pa += 2
                if addr_bytes == 2:
                    memaddr = (memaddr << 8) + int(next(cmd_table)[:2], 16)
                    pa += 1
                s, inc = platform_write_rpt(devaddr, memaddr, dlen, cmd_table)
                if s is not None:
                    report_file += s + '\n'
                    pa += inc
                else:
                    report_file += f"write - dev_addr:" + \
                                    f" 0x{devaddr:02x} - mem_addr: 0x{memaddr:04x} - START - data:"
                    for j in range(n_code-2):
                        data = int(next(cmd_table)[:2], 16)
                        pa += 1
                        report_file += f" 0x{data:02x}"
                    report_file += '\n'

            case 4:  # pause (ticks are 8 bit times)
                if n_code == 0:
                    report_file += f"pad\n"
                else:
                    report_file += f"short pause of {n_code} cycles\n"

            case 5:  # pause (ticks are 256 bit times)
                report_file += f"long pause of {n_code*32} cycles\n"

            case 6:  # jump
                jump_addr = n_code*32
                report_file += f"jump +{n_code} to address 0x{jump_addr:03x}" + \
                                f" ({hex(n_code)}) lines\n"

            case 7:  # set result address
                result_address = 0x800 + n_code*32
                report_file += f"set result address {n_code} to" + \
                                f" address 0x{result_address:03x} ({hex(n_code)})\n"
        pa += 1

    report_file += "---- End of report ----\n"
    print(report_file)
    return


def load_file(file_path=None):
    if file_path == None:
        return None
    binary = True
    if isfile(file_path):
        if is_plaintext(file_path):
            binary = False
        try:
            if binary:
                return iter(open(file_path, 'rb'))
            else:
                return iter(open(file_path, 'r'))
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
            except UnicodeDecodeError as e:
                _ascii = False
                break
    return _ascii


if __name__ == '__main__':
    import sys
    decode(sys.argv)
