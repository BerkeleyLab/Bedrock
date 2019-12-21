# Experimental implementation of a DSL for building an XDC file
# by remapping pin names from an existing XDC file
# See marble/pin_map.csv for the first (and currently only) use case.
from sys import argv
import re
converter = {"DIFF_HSTL_II_25": ("LVDS_25", "LVCMOS25")}


def merge(prefix, vport):
    # mostly simple but add a weird heuristic for converting FMC pins
    m1 = re.match(r"(.*IOSTANDARD *)(\w+)(.*)", prefix)
    if m1:
        ios = m1.group(2)
        if ios in converter:
            # now figure out if the port name "looks" differntial
            # XXX will need to add the case of foo_n[1]
            diff = len(vport) > 3 and vport[-2:] == "_N" or vport[-2:] == "_P"
            ios2 = converter[ios][0] if diff else converter[ios][1]
            # print("woo", ios, diff, ios2)
            # replace it!
            prefix = m1.group(1) + ios2 + m1.group(3)
            # Seems like a lot of work, and fragile, but I haven't
            # thought of a better solution yet.
    print(prefix + " " + vport + "]")


if len(argv) < 3:
    print("usage: $PYTHON %s foo.xdc foo.csv" % argv[0])
    print("  where foo.csv is the mapping file")
    exit(1)

# original .xdc netlist fle
proplist = {}
for ll in open(argv[1]).read().splitlines():
    bb = ll.split()
    pin = bb[-1].rstrip("]")
    rest = " ".join(bb[:-1])
    proplist[pin] = rest


# mapping file
def absorb_map(fname):
    literal = False
    for ll in open(fname).read().splitlines():
        if ll == "# Literal output follows":
            literal = True
        elif len(ll) == 0 or ll[0] == "#":
            if len(ll) > 1 and ll[1] == "#":
                pass  # special case, don't print lines that start with ##
            else:
                print(ll)
        elif literal:
            print(ll)
        else:
            pa, pb = ll.split()
            if pa in proplist:
                merge(proplist[pa], pb)
            else:
                print("wtf")


for fname in argv[2:]:
    absorb_map(fname)
