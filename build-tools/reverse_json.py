'''
Rummage through application_top.v and construct a JSON file representing
most of the read address space.  Depends on stylized Verilog representation
of the first stage of the (scalar) read data multiplexer, using reg_bank_n
pipeline registers.  Attempts to deduce signed-ness and bit width for each
entry by peeking at wire declarations in the Verilog.
'''
import re
from sys import stderr
import sys
# feel free to find a portable way to do this
if sys.version_info > (3, 0):
    trantab = {"[": "_", "]": "_"}
else:
    from string import maketrans
    trantab = maketrans("[]", "__")

wire_info = {}
addr_found = {}
name_found = {}
fail = 0

# Bugs:
#   brittle to variations in Verilog code formatting
#   Hard-coded filename
#   Not yet compatible with python3


def ponder_int(s):
    try:
        r = int(s)
    except Exception:
        r = 31
        m4 = re.search(r'(\w+)-(\d+)', s)
        if m4:
            p = m4.group(1)
            o = int(m4.group(2))
            if p in param_db:
                pv = param_db[p]
                # stderr.write('p, pv, o = %s, %d, %d\n' % (p, pv, o))
                return pv - o
            else:
                stderr.write('ERROR: parameter %s not found?\n' % p)
        else:
            stderr.write("ERROR: Couldn't" + ' understand "%s", using 31\n' %
                         s)
    return r


def rprint(g, l, alias):
    global fail
    addr = int(g(2) + g(1), 16)
    # Given g(2) that might have the form m_accum[1], construct
    # m_accum_1 for the JSON name, and
    # m_accum as the name with which to look up the wire properties.
    name = g(3).translate(trantab).rstrip("_")
    if alias is not None:
        name = alias
    wname = g(3).split('[')[0]
    # print addr, name, wname, g(1), g(2), g(3), l
    if name in name_found:
        stderr.write('ERROR: Duplicate name "%s"\n' % name)
        fail = 1
    name_found[name] = True
    if addr in addr_found:
        stderr.write('ERROR: Duplicate address "0x%x"\n' % addr)
        fail = 1
    addr_found[addr] = True
    # default width and signed-ness should only apply to strange
    # cases where the width is parameterized
    wid = 32
    sign = "unsigned"
    if wname in wire_info:
        # print a, n, info[nn]
        sign, wid = wire_info[wname].split(':')
        wid = ponder_int(wid) + 1
    else:
        stderr.write('WARNING: Taking default sign and wid for "%s"\n' % wname)
    s = '''    "%s": {
        "access": "r",
        "addr_width": 0,
        "sign": "%s",
        "base_addr": %d,
        "data_width": %d
    }''' % (name, sign, addr, wid)
    return s


def memorize(g):
    # print g(1), g(2), g(3)
    sign = "signed" if g(1) else "unsigned"
    wire_info[g(3)] = sign + ":" + g(2)


f = open("application_top.v", "r")
print("{")
sl = []
param_db = {}
for l in f.read().split('\n'):
    if "4'h" in l and ": reg_bank_" in l:
        m1 = re.search(r"4'h(\w):\s*reg_bank_(\w)\s*<=\s*(\S+);", l)
        if m1:
            alias = None
            m1a = re.search(r";\s*//\s*alias:\s*(\w+)", l)
            if m1a:
                # stderr.write('INFO: alias "%s"\n' % m1a.group(1))
                alias = m1a.group(1)
            sl += [rprint(m1.group, l, alias)]
        else:
            stderr.write("WARNING: Surprising regexp failure: %s\n" % l)
    if "wire" in l:
        m2 = re.search(r"wire\s+(signed)?\s*\[([^:]+):0\]\s*(\w+)", l)
        if m2:
            memorize(m2.group)
    if "reg " in l:
        m2 = re.search(r"reg\s+(signed)?\s*\[([^:]+):0\]\s*(\w+)", l)
        if m2:
            memorize(m2.group)
    if "parameter " in l:
        m3 = re.search(r"parameter\s+(\w+)\s*=\s*(\d+);", l)
        if m3:
            p, v = m3.group(1), int(m3.group(2))
            param_db[p] = v
            # stderr.write('INFO: found parameter "%s" with value %d\n' % (p, v))
print(",\n".join(sl))
print("}")
exit(fail)
