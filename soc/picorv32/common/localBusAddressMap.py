#!/usr/bin/env python
"""
    Generate a C header file from .json localbus address map
    Usage:
        python localBusAddressMap.py source.json headerFile.h
"""
import json
import datetime
import os
import sys


def gen_addrmap(regmap):
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

            if 0 < aw <= 6:  # cutoff array generation if length > 32.
                for ix in range(1 << aw):
                    addrmap[addri + ix] = key + '_' + str(ix)
            elif aw == 0:
                addrmap[addri] = key
            else:
                print("Large array ignored (len>32), key: {}".format(key))
    return addrmap


def write_addrmap(addrmap, ifname, ofname):
    """
    Iterate through all sorted keys of the addrmap dict and genereate #define strings
    """
    hf = """// Automatically generated register map of the local bus
// Source:    {0}
// Generated: {1}

""".format(os.path.abspath(ifname), datetime.datetime.now().strftime("%D, %T"))

    header = ofname.replace('.', '_').upper()
    hf += "#ifndef " + header + "\n"
    hf += "#define " + header + "\n\n"
    for addr in sorted(addrmap.keys()):
        hf += "#define {0:32s} 0x{1:08x}\n".format(addrmap[addr].upper(), addr)
    hf += "\n#endif\n"

    with open(ofname, "w") as f:
        f.write(hf)


def main(argv):
    json_fname = argv[0]
    dest_fname = argv[1]

    with open(json_fname) as s:
        regmap = json.load(s)
        addrmap = gen_addrmap(regmap)
        write_addrmap(addrmap, json_fname, dest_fname)


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print(__doc__)
        sys.exit()

    main(sys.argv[1:])
