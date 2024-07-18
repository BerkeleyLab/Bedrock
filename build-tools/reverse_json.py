'''
Rummage through input (Verilog) file and construct a JSON file representing
most of the read address space.  Depends on stylized Verilog representation
of the first stage of the (scalar) read data multiplexer, using reg_bank_n
pipeline registers.  Attempts to deduce signed-ness and bit width for each
entry by peeking at wire, reg, and input declarations in the Verilog.
'''
import re
from sys import stderr, argv

trantab = {"[": "_", "]": ""}

wire_info = {}
addr_found = {}
name_found = {}
fail = 0

# Bugs:
#   brittle to variations in Verilog code formatting
#   Hard-coded filename


def reg_trans(s, trandict):
    for k, v in trandict.items():
        s = s.replace(k, v)
    return s


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


def rprint(g, line, alias, address_offset):
    global fail
    addr = int(g(2) + g(1), 16) + address_offset
    # Given g(2) that might have the form m_accum[1], construct
    # m_accum_1 for the JSON name, and
    # m_accum as the name with which to look up the wire properties.
    name = reg_trans(g(3), trantab)  # Apply regname replacements
    if alias is not None:
        name = alias
    wname = g(3).split('[')[0]
    # print addr, name, wname, g(1), g(2), g(3), line
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


f = open(argv[1], "r")
print("{")
sl = []
param_db = {}
address_offset = 0
bank_state = None  # keep track of current block
line_no = 0
for line in f.read().split('\n'):
    line_no += 1
    ehead = 'ERROR:%s:%d:' % (argv[1], line_no)  # just in case
    if "reverse_json_offset" in line:
        m1 = re.search(r"\s*//\s*reverse_json_offset\s*:\s*(\d+)\s*", line)
        if m1:
            address_offset = int(m1.group(1))
    # All other directives are ignored if they're on a pure // comment line.
    # Yes, we can still get confused by /* */ comments, `ifdef, and generate.
    if re.search(r"^\s*//", line):
        continue
    #
    if "4'h" in line and ": reg_bank_" in line:
        m1 = re.search(r"4'h(\w):\s*reg_bank_(\w)\s*<=\s*(\S+);", line)
        if m1:
            alias = None
            m1a = re.search(r";\s*//\s*alias:\s*(\w+)", line)
            if m1a:
                # stderr.write('INFO: alias "%s"\n' % m1a.group(1))
                alias = m1a.group(1)
            tbank = m1.group(2)
            if bank_state == "=armed=":
                bank_state = tbank
            if bank_state != tbank:
                stderr.write(ehead + ' bank %s assignment found in bank %s stanza\n' % (tbank, bank_state))
                fail = 1
            sl += [rprint(m1.group, line, alias, address_offset)]
        else:
            stderr.write("WARNING: Surprising regexp failure: %s\n" % line)
    if "default" in line and ": reg_bank_" in line:
        m1 = re.search(r"default:\s*reg_bank_(\w)\s*<=\s*32'h", line)
        if m1:
            # stderr.write('INFO: default %s\n' % line)
            tbank = m1.group(1)
            if bank_state != tbank:
                stderr.write(ehead + ' bank %s assignment found in bank %s stanza\n' % (tbank, bank_state))
                fail = 1
    if "wire" in line:
        m2 = re.search(r"\bwire\s+(signed)?\s*\[([^:]+):0\]\s*(\w+)", line)
        if m2:
            memorize(m2.group)
    if "reg" in line:
        m2 = re.search(r"\breg\s+(signed)?\s*\[([^:]+):0\]\s*(\w+)", line)
        if m2:
            memorize(m2.group)
    if "input" in line:
        m2 = re.search(r"\binput\s+(signed)?\s*\[([^:]+):0\]\s*(\w+)", line)
        if m2:
            memorize(m2.group)
    if any(x in line for x in ["parameter", "localparam"]):
        m3 = re.search(r"\b(?:parameter|localparam)\s+(\w+)\s*=\s*(\d+);", line)
        if m3:
            p, v = m3.group(1), int(m3.group(2))
            param_db[p] = v
            # stderr.write('INFO: found parameter "%s" with value %d\n' % (p, v))
    if "endcase" in line:
        bank_state = None
    if "case" in line and "addr" in line:
        m4 = re.search(r"\bcase\s*\(\w*addr", line)
        if m4:
            bank_state = "=armed="
print(",\n".join(sl))
print("}")
exit(fail)
