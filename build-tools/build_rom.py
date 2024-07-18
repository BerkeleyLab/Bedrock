import subprocess
import zlib
import math
import struct
import hashlib
import sys
import os


def chunk(li, flag=1):
    '''
    l: list of 16-bit ints
    flag: type
    Each chunk has an ID that precedes it
    ID is 16-bit {2 bits: type, 14 bits: length of the chunk}
    '''
    chunk_size = len(li)
    if chunk_size >= (1 << 14):
        raise Exception
    else:
        return [chunk_size + (flag << 14)] + li


def sixteen(ss, pad=b'\0'):
    if len(ss) % 2:  # need an even number of octets
        # Pad with \0 if pad char not specified
        ss += pad
    return list(struct.unpack("!" + "H" * int(len(ss) / 2), ss))


def compress_file(fname):
    sha = hashlib.sha1()
    fv = open(fname, 'r').read().encode('utf-8')
    sha.update(fv)
    file_zip = zlib.compress(fv, 9)
    return sha.hexdigest(), sixteen(file_zip)


def create_array(descrip, json_file, placeholder_rev=False):
    if placeholder_rev:
        # output of sha1sum < /dev/null
        # sure hope this doesn't collide with an actual commit ID
        git_sha = "da39a3ee5e6b4b0d3255bfef95601890afd80709"
    else:
        try:
            git_sha = subprocess.check_output(['git', 'rev-parse', 'HEAD'])
        except subprocess.CalledProcessError:
            print("Warning: no git info found, filling in with zeros")
            git_sha = 40*"0"
    git_binary = [int(git_sha[ix * 4 + 0:ix * 4 + 4], 16) for ix in range(10)]
    sha1sum, regmap = compress_file(json_file)
    json_sha1_binary = [
        int(sha1sum[ix * 4 + 0:ix * 4 + 4], 16) for ix in range(10)
    ]
    descrip_binary = sixteen(descrip, pad=b'.')  # Pad description string with '.', not null (non-printable)
    final = (chunk(
        json_sha1_binary, flag=2) + chunk(
            git_binary, flag=2) + chunk(descrip_binary) + chunk(
                regmap, flag=3))
    return final


def decode_array(a):
    rec_num = 0
    result = []
    while len(a):
        clen = a[0]
        flag = clen >> 14
        clen = clen & 0x3fff
        data = a[1:clen + 1]
        a = a[clen + 1:]
        # print(clen, flag)
        if flag == 0:
            break
        print("Record %d type %d length %d" % (rec_num, flag, clen))
        if flag == 1:
            result += [struct.pack("!" + "H" * len(data), *data).decode("utf-8")]
        elif flag == 2:
            result += ["".join([format(x, "04x") for x in data])]
        elif flag == 3:
            zipped = struct.pack("!" + "H" * len(data), *data)
            result += [zlib.decompress(zipped).decode("utf-8")]
        rec_num += 1
    return result


def verilog_rom(a, suffix="", prefix=""):
    min_rom_size = 2048
    max_rom_size = 16384
    print("%d/%d ROM entries used" % (len(a), max_rom_size))  # Upper boundary for maximum ROM size, fixed
    if len(a) > max_rom_size:
        raise RuntimeError("ROM_size input exceeds MAX_ROM_SIZE")
        return ""
    max_addr_size = opt_bus_width(len(a), min_rom_size, max_rom_size) - 1
    config_case = '\n'.join([
        '''\t%i'h%3.3x: dxx <= 16'h%4.4x;''' % (max_addr_size+1, ix, a[ix])
        for ix in range(len(a))
    ])
    outputMessage = ("// 16k x 16 ROM machine generated by python verilog_rom()",
        "module {}config_romx{}(".format(prefix, suffix),
        "\tinput clk,",
        "\tinput [" + str(max_addr_size) + ":0] address,",
        "\toutput [15:0] data",
        ");",
        "reg [15:0] dxx = 0;",
        "assign data = dxx;",
        "always @(posedge clk) case(address)",
        config_case,
        "\tdefault: dxx <= 0;",
        "endcase",
        "endmodule",
        ""
        )
    return '\n'.join(outputMessage)


# New as of 2023-12-27.  Not as well tested as other routines here.
def c_rom(a, suffix="", prefix=""):
    min_rom_size = 2048
    max_rom_size = 16384
    print("%d/%d ROM entries used" % (len(a), max_rom_size))  # Upper boundary for maximum ROM size, fixed
    if len(a) > max_rom_size:
        raise RuntimeError("ROM_size input exceeds MAX_ROM_SIZE")
        return ""
    max_addr_size = opt_bus_width(len(a), min_rom_size, max_rom_size) - 1
    d_list = ["0x%4.4x" % d for d in a]
    d_list2 = [", ".join(d_list[ix*8:ix*8+8]) for ix in range((len(a)+7)//8)]
    config_data = "  " + ",\n  ".join(d_list2)
    outputMessage = ("// 16k x 16 ROM machine generated by python c_rom()",
        "static uint16_t config_romx[] = {",
        config_data,
        "};",
        "#define CONFIG_ROM_SIZE (%s)" % (2**max_addr_size),
        ""
        )
    return '\n'.join(outputMessage)


def opt_bus_width(entries, min_rom_size, max_rom_size):
    '''
    In order to limit blockRAM resource utilization, the port size has to be a function of ROM size.
    Returns the optimal bus width. The port's upper bound is -1 that.
    '''
    fits_in_xbits = math.log(entries, 2)
    lo_lim = int(math.log(min_rom_size, 2))
    up_lim = int(math.log(max_rom_size, 2))

    for port_size in range(lo_lim, up_lim + 1):
        if fits_in_xbits <= lo_lim:
            return int(lo_lim)
        elif fits_in_xbits <= port_size:
            return int(port_size)

    raise RuntimeError("Too many entries. Did you exceed the MAX_ROM_SIZE?")


def read_live_array(dev):
    sys.path.append(os.path.join(os.path.dirname(__file__), "../projects/common"))
    import leep
    leep_dev = leep.open(addr=dev, timeout=20)
    foo = leep_dev.the_rom
    return foo


def desc_limit_check(dev_desc):
    '''
    Limits the ROM description length/size to comply with leep's preamble checking.
    Leep has a 64x16-bit max preamble size. This leaves 40x16-bit words for the description.
    Limit is controlled by dev_desc_lim, local to this function (limit in bytes).
    '''
    dev_desc_lim = 80
    if len(dev_desc) > dev_desc_lim:
        raise RuntimeError("Please provide a description up to " +
                           str(dev_desc_lim) + " characters.")


if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser(description='Read/Write from FPGA memory')
    parser.add_argument(
        '--loopback',
        dest='loopback',
        help='Encode and decode config_rom array',
        action='store_true',
        default=False)
    parser.add_argument(
        '--live',
        help='Read config_rom from device,'
        'decode and print',
        dest='live',
        action='store_true',
        default=False)
    parser.add_argument(
        '-a',
        '--ip',
        help='ip_address',
        dest='ip',
        type=str,
        default='192.168.21.11')
    parser.add_argument(
        '-p', '--port', help='port', dest='port', type=int, default=50006)
    parser.add_argument(
        '-v',
        '--verilog_file',
        dest='verilog_file',
        help='Destination config_rom filename',
        type=str,
        default='')
    parser.add_argument(
        '-c',
        '--c_file',
        dest='c_file',
        help='Destination config_rom filename',
        type=str,
        default='')
    parser.add_argument(
        '-j',
        '--json',
        dest='json',
        help='Register map filename',
        type=str)
    parser.add_argument(
        '-d',
        '--dev_descript',
        dest='dev_descript',
        help='ASCII string to use as device description',
        type=str,
        default='LBNL BEDROCK ROM')
    parser.add_argument(
        '--mod_suffix',
        dest='mod_suffix',
        help='Suffix for Verilog module name',
        default='')
    parser.add_argument(
        '--mod_prefix',
        dest='mod_prefix',
        help='Prefix for Verilog module name',
        default='')
    parser.add_argument(
        '--placeholder_rev',
        help='Use placeholder instead of git commit ID',
        dest='placeholder_rev',
        action='store_true',
        default=False)
    args = parser.parse_args()
    if args.live:
        dev = str(args.ip) + ':' + str(args.port)
        a = read_live_array(dev)
        # print(" ".join(["%4.4x"%x for x in a]))
        r = decode_array(a)
        for rr in r:
            print(rr)
    else:
        if not args.json:
            print("JSON register map must be specified so ROM can be built")
            sys.exit(2)

        dev_desc = args.dev_descript.encode('utf-8')
        desc_limit_check(dev_desc)
        a = create_array(dev_desc, args.json, placeholder_rev=args.placeholder_rev)
        if args.loopback:
            r = decode_array(a)
            for rr in r:
                print(rr)
        elif args.verilog_file != '':
            with open(args.verilog_file, 'w') as f:
                f.write(verilog_rom(a, suffix=args.mod_suffix, prefix=args.mod_prefix))
        elif args.c_file != '':
            with open(args.c_file, 'w') as f:
                f.write(c_rom(a, suffix=args.mod_suffix, prefix=args.mod_prefix))
        else:
            print(len(a))
            print(a)
