#!/usr/bin/python

# Barest working skeleton of an automatic Verilog module port connector
# Larry Doolittle, LBNL, 2014
# TODO:
# * Mirror read and write clk is currently hard-coded to lb_clk
# * Remove hierarchy from address_allocation
# * Currently we-strobe is being abused to generate registers of width > 1
# * Remove AUTOMATIC_map, still seems to be used in cryomodule.v

import argparse
import json

try:
    from StringIO import StringIO
except ImportError:
    from io import StringIO

MIN_MIRROR_AW = 5
MIN_MIRROR_ARRAY_SIZE = 1 << MIN_MIRROR_AW  # Minimum size of an array to be mirrored

gch = {}
g_flat_addr_map = {}
g_file_not_found = 0


def generate_mirror(dw, mirror_n):
    """
    Generates a dpram which mirrors the register values being written into the
    automatically generated addresses.
    dw, aw: data/address width of the ram
    mirror_base:
    mirror_n: A unique identifier for the mirror dpram
    """
    # HACK: HARD coding clk_prefix to be 'lb'
    cp = "lb"
    mirror_strobe = (
        "wire [%d:0] mirror_out_%d;"
        "wire mirror_write_%d = %s_write &(`ADDR_HIT_MIRROR);\\\n"
        % (dw - 1, mirror_n, mirror_n, cp)
    )
    dpram_a = (
        ".clka(%s_clk), .addra(%s_addr[`MIRROR_WIDTH-1:0]), "
        ".dina(%s_data[%d:0]), .wena(mirror_write_%d)" % (cp, cp, cp, dw - 1, mirror_n)
    )
    dpram_b = (
        ".clkb(%s_clk), .addrb(%s_addr[`MIRROR_WIDTH-1:0]), .doutb(mirror_out_%d)"
        % (cp, cp, mirror_n)
    )
    dpram_def = (
        "dpram #(.aw(`MIRROR_WIDTH),.dw(%d)) mirror_%d(\\\n\t%s,\\\n\t%s);\\\n"
        % (dw, mirror_n, dpram_a, dpram_b)
    )
    return mirror_strobe + dpram_def


def add_to_global_map(name, base_addr, sign, aw, dw, description):
    if name in g_flat_addr_map:
        x = g_flat_addr_map[name]
        assert x["base_addr"] == base_addr
    g_flat_addr_map[name] = {
        "base_addr": base_addr,
        "sign": sign,
        "access": "rw" if aw <= MIN_MIRROR_AW else "w",
        "addr_width": aw,
        "data_width": dw,
        "description": description,
    }


def generate_addresses(
    fd, names, base, low_res=False, gen_mirror=False, plot_map=False, lb_width=24
):
    """
    Generate addresses with increasing bitwidth
    """
    not_mirrored, mirrored = [], []
    mirror_base = -1
    register_names = sorted(names, key=lambda x: gch.get(x)[0], reverse=True)
    if gen_mirror:
        mirror_size = sum(
            [
                1 << gch[k][0]
                for k in register_names
                if (1 << gch[k][0]) <= MIN_MIRROR_ARRAY_SIZE
            ]
        )
    for k in register_names:
        bitwidth = gch[k][0]
        register_array_size = 1 << gch[k][0]
        if (
            gen_mirror and
            mirror_base == -1 and
            register_array_size <= MIN_MIRROR_ARRAY_SIZE
        ):
            mirror_base = base
            mirror_bit_len = mirror_size.bit_length()
            mirror_size_nearest_pow2 = 1 << mirror_bit_len
            if mirror_base & (mirror_size_nearest_pow2 - 1) != 0:
                print(
                    "Mirror base NOT aligned.\nMirror Base: {};\nMirror Size: {};".format(
                        format(base, "#x"), format(mirror_size, "#x")
                    )
                )
                mirror_base = (
                    (mirror_base + mirror_size_nearest_pow2) >> mirror_bit_len
                ) << mirror_bit_len
                base = mirror_base
                print(
                    "Aligning mirror base. New mirror base: {}".format(
                        format(base, "#x")
                    )
                )
            mirror_clk_prefix = "lb"  # TODO: This is a hack
            if fd:
                # Note the historical, buggy definition of lb_width as one less than
                # the actual address bus bit-width.
                mirror_pattern = (mirror_base & (2**(lb_width+1)-1)) >> mirror_bit_len
                s = (
                    "`define MIRROR_WIDTH %d\n"
                    "`define ADDR_HIT_MIRROR (%s_addr[`LB_HI:`MIRROR_WIDTH]==%d)\n"
                    % (mirror_bit_len, mirror_clk_prefix, mirror_pattern)
                )
                fd.write(s)
        sign = gch[k][2]
        datawidth = gch[k][3]
        description = gch[k][-1]
        k_aw = 1 << bitwidth  # address width of register name k
        if (k_aw - 1) & base == 0:
            next_addr = base
        else:
            # A way to come up with the next available address
            next_addr = ((base + k_aw) >> bitwidth) << bitwidth
        if bitwidth > 0 and not low_res:
            for reg_index in range(k_aw):
                r_name = k + "_" + str(reg_index)
                add_to_global_map(
                    r_name,
                    next_addr + reg_index,
                    sign,
                    bitwidth,
                    datawidth,
                    description,
                )
        else:
            add_to_global_map(k, next_addr, sign, bitwidth, datawidth, description)
        if fd:
            s = (
                "`define ADDR_HIT_%s (%s_addr%s[`LB_HI:%d]==%d) "
                "// %s bitwidth: %d, base_addr: %d\n"
            )
            # Note the historical, buggy definition of lb_width as one less than
            # the actual address bus bit-width.
            addr_pattern = (next_addr & (2**(lb_width+1)-1)) >> bitwidth
            fd.write(
                s
                % (
                    k,
                    gch[k][4],
                    gch[k][5],
                    bitwidth,
                    addr_pattern,
                    gch[k][1],
                    bitwidth,
                    next_addr,
                )
            )
        (not_mirrored if mirror_base == -1 else mirrored).append((next_addr, k_aw))
        base = next_addr + k_aw
    if plot_map and (mirrored or not_mirrored):
        from matplotlib import pyplot as plt
        import matplotlib.ticker as ticker

        if not_mirrored:
            plt.broken_barh(not_mirrored, (0, 1))
        if mirrored:
            plt.broken_barh(mirrored, (0, 1), facecolors=("red"))
        axes = plt.gca()
        axes.get_xaxis().set_major_formatter(ticker.FormatStrFormatter("%#x"))
        plt.show()
    return base


g_hierarchy = ["xxxx", "station", "cav4_elec", ["mode_", 3]]


def address_allocation(
    fd, hierarchy, names, address, low_res=False, gen_mirror=False, plot_map=False, lb_width=24
):
    """
    NOTE: The whole hierarchy thing is currently being bypassed
    TODO: Possibly remove hierarchy from here, or even make it optional
    hierarchy: Index into g_hierarchy (current hierarchy level)
    names: All signal names that belong in the current hierarchy
    address:
    for current index in g_hierarchy denoted with variable 'hierarchy'
    1. partition 'names' that belong inside vs outside the hierarchy
    2. (a) generate addresses for names (in_mod) that fall in the hierarchy
    (recurse)
    (b) generate addresses for signals outside the hierarchy (out_mod)
    """
    if hierarchy == len(g_hierarchy):
        return generate_addresses(fd, names, address, low_res, gen_mirror, plot_map, lb_width)
    h = g_hierarchy[hierarchy]
    in_mod, out_mod = [], []
    if type(h) is list:
        prefix = h[0]
        for hn in range(h[1]):
            hh = prefix + str(hn)
            address = address_allocation(
                fd,
                hierarchy + 1,
                [n for n in names if hh in n],
                address,
                low_res,
                gen_mirror,
                plot_map,
                lb_width,
            )
        out_mod = [n for n in names if prefix not in n]
    else:
        for n in names:
            (in_mod if h in n else out_mod).append(n)
        address = address_allocation(
            fd, hierarchy + 1, in_mod, address, low_res, gen_mirror, plot_map, lb_width
        )
    return generate_addresses(fd, out_mod, address, low_res, gen_mirror, plot_map, lb_width)


from parser import Parser
from comment_parser import CommentParser


def print_decode_header(fi, modname, fo, dir_list, lb_width, gen_mirror, use_yosys):
    clk_prefix = "lb"
    obuf = StringIO()
    if use_yosys:
        vfile_parser = Parser()
        vfile_parser.parse_vfile_yosys("", fi, obuf, dir_list, clk_prefix, False)
    else:
        vfile_parser = CommentParser()
        vfile_parser.parse_vfile_comments("", fi, obuf, dir_list, clk_prefix, False)

    global gch, g_flat_addr_map, g_file_not_found
    gch = vfile_parser.gch
    g_flat_addr_map = vfile_parser.g_flat_addr_map
    g_file_not_found = vfile_parser.file_not_found
    obuf.write("// machine-generated by newad.py\n")
    obuf.write("`ifdef LB_DECODE_%s\n" % modname)
    obuf.write('`include "addr_map_%s.vh"\n' % modname)
    # TODO: Merging clock domains: This doesn't need to be there?
    # needed for at least some test benches, like in rtsim
    obuf.write(
        "`define AUTOMATIC_self input %s_clk, input [31:0] %s_data,"
        " input %s_write, input [%d:0] %s_addr\n"
        % (clk_prefix, clk_prefix, clk_prefix, lb_width, clk_prefix)
    )
    obuf.write("`define AUTOMATIC_decode\\\n" + "".join(vfile_parser.decodes))
    if gen_mirror:
        obuf.write(generate_mirror(32, 0))
    obuf.write("\n")
    obuf.write("`else\n")
    obuf.write("`define AUTOMATIC_self" + " " + ",\\\n".join(vfile_parser.self_ports))
    obuf.write("\n")
    obuf.write("`define AUTOMATIC_decode\n")
    obuf.write("`endif\n")
    # Below only applies for modules with genvar constructions
    if modname in vfile_parser.self_map:
        obuf.write(
            "`define AUTOMATIC_map " +
            " ".join(vfile_parser.self_map[modname] if modname in vfile_parser.self_map else []) +
            "\n"
        )
    if fo:
        with open(fo, "w") as fd:
            fd.write(obuf.getvalue())
    obuf.close()


def write_address_header(
    output_file, low_res, lb_width, gen_mirror, base_addr, plot_map
):
    addr_bufs = StringIO()
    addr_bufs.write("`define LB_HI %d\n" % lb_width)
    address_allocation(
        addr_bufs, 0, sorted(gch.keys()), base_addr, low_res, gen_mirror, plot_map, lb_width
    )
    with open(output_file, "w") as fd:
        fd.write(addr_bufs.getvalue())
    addr_bufs.close()


def write_regmap_file(output_file, low_res, gen_mirror, base_addr, plot_map):
    address_allocation(
        fd=0,
        hierarchy=0,
        names=sorted(gch.keys()),
        address=base_addr,
        low_res=low_res,
        gen_mirror=gen_mirror,
        plot_map=plot_map,
    )
    addr_map = {x: g_flat_addr_map[x] for x in g_flat_addr_map}
    with open(output_file, "w") as fd:
        json.dump(addr_map, fd, sort_keys=True, indent=4, separators=(",", ": "))
        fd.write("\n")


def main(argv):
    parser = argparse.ArgumentParser(
        description="Automatic address generator: Parses verilog lines "
        "and generates addresses and decoders for registers declared "
        "external across module instantiations"
    )
    parser.add_argument(
        "-i", "--input_file", default="", help="A top level file to start the parser"
    )
    parser.add_argument(
        "-o", "--output", default="", help="Outputs generated header file"
    )
    parser.add_argument(
        "-y",
        "--yosys",
        action="store_true",
        help="Use yosys for backend, as opposed to poor mans parsing"
    )
    parser.add_argument(
        "-d",
        "--dir_list",
        default=".",
        type=str,
        help="A list of directories to look for verilog source files. <dir_0>[,<dir_1>]*",
    )
    parser.add_argument(
        "-a",
        "--addr_map_header",
        default="",
        help="Outputs generated address map header file",
    )
    parser.add_argument(
        "-r",
        "--regmap",
        default="",
        help="Outputs generated address map in json format",
    )
    parser.add_argument(
        "-l",
        "--low_res",
        action="store_true",
        default=False,
        help="When not selected generates a separate address name for each",
    )
    parser.add_argument(
        "-m",
        "--gen_mirror",
        action="store_true",
        default=False,
        help="Generates a mirror where all registers and register arrays with size < {}"
        "are available for readback".format(MIN_MIRROR_ARRAY_SIZE),
    )
    parser.add_argument(
        "-pl",
        "--plot_map",
        action="store_true",
        default=False,
        help="Plots the register map using a broken bar graph",
    )
    parser.add_argument(
        "-w",
        "--lb_width",
        type=int,
        default=10,
        help="One less than the address width of the local bus (from which the generated registers are decoded)",
    )
    parser.add_argument(
        "-b",
        "--base_addr",
        type=int,
        default=0,
        help="Set the base address of the register map to be generated from here",
    )
    parser.add_argument(
        "-p",
        "--clk_prefix",
        default="lb",
        help="Prefix of the clock domain in which decoding is done [currently ignored], appends _clk",
    )
    args = parser.parse_args()

    input_fname = args.input_file
    modname = input_fname.split("/")[-1].split(".")[0]
    dir_list = list(map(lambda x: x.strip(), args.dir_list.split(",")))
    addr_header_fname = args.addr_map_header
    regmap_fname = args.regmap

    print_decode_header(
        input_fname, modname, args.output, dir_list, args.lb_width, args.gen_mirror, args.yosys
    )

    if addr_header_fname:
        write_address_header(
            output_file=addr_header_fname,
            low_res=args.low_res,
            lb_width=args.lb_width,
            gen_mirror=args.gen_mirror,
            base_addr=args.base_addr,
            plot_map=args.plot_map,
        )
    if regmap_fname:
        write_regmap_file(
            output_file=regmap_fname,
            low_res=args.low_res,
            gen_mirror=args.gen_mirror,
            base_addr=args.base_addr,
            plot_map=args.plot_map,
        )


if __name__ == "__main__":
    import sys

    main(sys.argv[1:])
    if g_file_not_found > 0:
        print(g_file_not_found, "files not found")
        exit(1)
