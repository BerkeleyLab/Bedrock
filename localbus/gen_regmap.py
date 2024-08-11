#!/usr/bin/env python
"""
    Generate a verilog header file from .json localbus address map
"""
import json
import datetime
import argparse
import os

header = """
// Automatically generated register map of the local bus
// Source:    {0}
// Generated: {1}
"""


def gen_addrmap(regmap, cut_off_aw=5):
    """
    Collect all addresses as keys to the addrmap dict. Values are the names.
    """
    addrmap = dict()
    for key, item in regmap.items():
        if "base_addr" in item:
            addr = item["base_addr"]
            aw = item["addr_width"]
            addri = int(str(addr), 0)
            if addri in addrmap:
                raise ValueError("Double assigned localbus address!")
            if addri >= (0x01000000 >> 2):
                raise ValueError("Localbus address outside valid range!")

            if 0 < aw <= cut_off_aw:  # cutoff array generation
                for ix in range(1 << aw):
                    addrmap[addri + ix] = key + '_' + str(ix)
            elif aw == 0:
                addrmap[addri] = key
            else:
                print(f"Large array ignored (len>{2**cut_off_aw}), key: {key}")
    return addrmap


def write_addrmap(addrmap, ifname, ofname, adrw=18):
    hf = header.format(
            os.path.abspath(ifname),
            datetime.datetime.now().strftime("%D, %T"))

    # header = ofname.replace('.', '_').upper()
    for addr in sorted(addrmap.keys()):
        hf += "localparam [{:d}:0] {:32s} = {:d}'h{:05x};\n".format(
                adrw-1, addrmap[addr].upper(), adrw, addr)

    with open(ofname, "w") as f:
        f.write(hf)


def main(json_fname, dest_fname, adrw=18, cut_off_aw=5):
    with open(json_fname) as s:
        regmap = json.load(s)
        addrmap = gen_addrmap(regmap, cut_off_aw=cut_off_aw)
        write_addrmap(addrmap, json_fname, dest_fname, adrw)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('-i', '--input', help='input json file')
    parser.add_argument('-o', '--output', help='output verilog header file')
    parser.add_argument('-w', '--adrw',
                        type=int, help='lb address width', default=24)
    parser.add_argument(
        '-c', '--cut-off-aw', type=int, default=5,
        help="cut off array generation if address width is greater")
    args = parser.parse_args()

    main(args.input, args.output, args.adrw, args.cut_off_aw)
