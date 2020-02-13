# Experimental implementation of a DSL for building an XDC file
# by remapping pin names from an existing XDC file
# See marble/pin_map.csv for the first (and currently only) use case.
from sys import argv
import re


converter = {"DIFF_HSTL_II_25": ("LVDS_25", "LVCMOS25")}

# original .xdc netlist fle
xdc_map = {}


def absorb_xdc(xdc_file):
    for ll in open(xdc_file).read().splitlines():
        bb = ll.split()
        pin_name = bb[-1].rstrip("]")
        rest = " ".join(bb[:-1])
        xdc_map[pin_name] = rest


def merge(xdc_info, vport, force_diff=False):
    # mostly simple but add a weird heuristic for converting FMC pins
    m1 = re.match(r"(.*IOSTANDARD *)(\w+)(.*)", xdc_info)
    if m1:
        ios = m1.group(2)
        if ios in converter:
            if force_diff:
                diff = True
            else:
                # Figure out if the port name "looks" differntial
                # XXX will need to add the case of foo_n[1]
                diff = len(vport) > 3 and vport[-2:] == "_N" or vport[-2:] == "_P"
            ios2 = converter[ios][0] if diff else converter[ios][1]
            # print("woo", ios, diff, ios2)
            # replace it!
            xdc_info = m1.group(1) + ios2 + m1.group(3)
            # Seems like a lot of work, and fragile, but I haven't
            # thought of a better solution yet.
    print(xdc_info + " " + vport + "]")


# mapping file
# TODO: Define what a mapping file is
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
            splitted = ll.split()
            iostd_flag = splitted[2] if len(splitted) > 2 else None
            pa, pb = splitted[0:2]
            if pa in xdc_map:
                merge(xdc_map[pa], pb, force_diff=(iostd_flag == "DIFF"))
            else:
                print("wtf: Can't interpret {} %%".format(pa))


if len(argv) < 3:
    print("usage: $PYTHON %s foo.xdc foo_1.csv .. foo_n.csv" % argv[0])
    print("  where foo_*.csv are re-mapping files")
    exit(1)


absorb_xdc(argv[1])
for fname in argv[2:]:
    absorb_map(fname)
