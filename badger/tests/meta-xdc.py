# Experimental implementation of a DSL for building an XDC file
# by remapping pin names from an existing XDC file
# See marble/pin_map.csv for the first (and currently only) use case.
import re


converter = {"DIFF_HSTL_II_25": ("LVDS_25", "LVCMOS25")}


# original .xdc netlist file
xdc_map = {}


def _extract_name(ss):
    """Extract name from:
        [get_ports foo]
        [get_ports { foo }]
        [get_ports " foo " ]
        [get_ports foo[0] ]
        [get_ports "foo[0]" ]
        [get_ports {foo[0]}]
    """
    bcnt = 0
    start = False
    buf = []
    for c in ss:
        if c == '[':
            start = True
            bcnt += 1
        elif c == ']':
            bcnt -= 1
        if start and (bcnt == 0):
            break
        if start:
            buf.append(c)
        if ''.join(buf[-9:]) == "get_ports":
            buf = []
    name = ''.join(buf).strip()
    pairs = (('{', '}'), ('"', '"'), ("'", "'"))
    for pair in pairs:
        if pair[0] in name and pair[1] in name:
            i0 = name.index(pair[0])
            i1 = name.rindex(pair[1])
            name = name[i0+1:i1].strip()
    return name


def test__extract_name():
    tests = (
        ("[get_ports foo]", "foo"),
        ("[get_ports { foo }]", "foo"),
        ("[get_ports \" foo \" ]", "foo"),
        ("[get_ports ' foo ' ]", "foo"),
        ("[get_ports foo[0] ]", "foo[0]"),
        ("[get_ports \"foo[0]\" ]", "foo[0]"),
        ("   [get_ports {foo[0]}]", "foo[0]"),
    )
    fails = 0
    for _input, _expected in tests:
        _result = _extract_name(_input)
        if _result != _expected:
            print(f"FAIL: _extract_name({_input}) = {_result} != {_expected}")
            fails += 1
    if fails == 0:
        print("PASS")
    return fails


def process_xdc_line(ss):
    """Only collects the 'set_property' lines (ignores 'create_clock', etc)."""
    if '#' in ss:
        ss = ss.split('#')[0]
    ss = ss.strip()
    if ss.startswith("set_property"):
        restr = r"\[\s*get_ports.*"
        _match = re.search(restr, ss)
        if _match:
            name = _extract_name(ss[slice(*_match.span())])
            preceding = ss[:_match.start()].strip() + " [get_ports"
            return name, preceding
    return None, None


def absorb_xdc(xdc_file):
    for ll in open(xdc_file).read().splitlines():
        if ll.startswith("#"):
            continue
        pin_name, rest = process_xdc_line(ll)
        if pin_name is not None:
            ll = xdc_map.get(pin_name, [])
            ll.append(rest)
            xdc_map[pin_name] = ll


def merge(xdc_info, vport, force_diff=False):
    # mostly simple but add a weird heuristic for converting FMC pins
    m1 = re.match(r"(.*IOSTANDARD *)(\w+)(.*)", xdc_info)
    if m1:
        ios = m1.group(2)
        if ios in converter:
            if force_diff:
                diff = True
            else:
                # Figure out if the port name "looks" differential
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
                for rest in xdc_map[pa]:
                    merge(rest, pb, force_diff=(iostd_flag == "DIFF"))
            else:
                print("wtf: Can't interpret {} %%".format(pa))


def main():
    from sys import argv
    import os
    if len(argv) < 3:
        print("usage: $PYTHON %s foo.xdc foo_1.csv .. foo_n.csv" % argv[0])
        print("  where foo_*.csv are re-mapping files")
        exit(1)
    csvs = []
    xdcs = []
    for fname in argv[1:]:
        _, ext = os.path.splitext(fname)
        if ext == ".csv":
            csvs.append(fname)
        elif ext == ".xdc":
            xdcs.append(fname)
    for xdc in xdcs:
        absorb_xdc(xdc)
    for csv in csvs:
        absorb_map(csv)
    return 0


if __name__ == "__main__":
    # exit(test__extract_name())
    exit(main())
