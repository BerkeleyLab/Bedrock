# Experimental implementation of a DSL for building an XDC file
# by remapping pin names from an existing XDC file
# See marble/pin_map.csv for the first (and currently only) use case.
from sys import argv

if len(argv) < 3:
    print("usage: $PYTHON %s foo.xdc foo.csv" % argv[0])
    print("  where foo.csv is the mapping file")
    exit(1)

proplist = {}
for ll in open(argv[1]).read().splitlines():
    bb = ll.split()
    pin = bb[-1].rstrip("]")
    rest = " ".join(bb[:-1])
    proplist[pin] = rest

literal = False
for ll in open(argv[2]).read().splitlines():
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
            print(proplist[pa] + " " + pb + "]")
        else:
            print("wtf")
