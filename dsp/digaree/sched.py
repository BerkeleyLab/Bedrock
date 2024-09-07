#!/usr/bin/python

from re import search
from sys import argv

# list of variables, pointing to the operation that sources it
pipe_len = 5
source = {}
n_count = 0   # only used to summarize scheduling performance
pc_in_use = {}  # points to instruction instance
max_pc = 0
verbose = False   # can set to True for more verbose output, still compiles

# two things we need to know about a "variable"
becomes_valid = {}
last_used = {}
state_vars = {}   # need to be kept around forever


def tobin(x, count=8):
    # Integer to binary; count is number of bits
    # Credit to W.J. van der Laan in https://code.activestate.com/recipes/219300/
    return "".join([str((x >> y) & 1) for y in range(count-1, -1, -1)])


def next_avail(n):
    while n in pc_in_use:
        n += 1
    return n


def new_state_var(a):
    state_vars[a] = True
    becomes_valid[a] = 0


class afunc:
    def __init__(self, lhs, op, shift, args):
        self.lhs = lhs
        self.op = op
        self.shift = shift
        global n_count, max_pc, source, pipe_len
        n_count = n_count+1
        pc0 = 0
        source[lhs] = self
        self.args = args
        if lhs in state_vars and lhs in last_used:
            pc0 = last_used[lhs]
        for a in args:
            if a != lhs and pc0 < becomes_valid[a]:
                pc0 = becomes_valid[a]
        pc = next_avail(pc0)
        # print("// %s arglist (%s) pc %d -> %d" % (op, args, pc0, pc))
        self.pc = pc
        pc_in_use[pc] = self
        if pc > max_pc:
            max_pc = pc
        becomes_valid[lhs] = pc+pipe_len
        for a in args:
            if a != lhs and (a not in last_used or last_used[a] < pc):
                last_used[a] = pc

    def text(self):
        return "%s = %s(%s) << %d" % (self.lhs, self.op, ", ".join(self.args), self.shift)


def oplist(ov, fn, args):
    # print("oplist (%s) (%s) (%s)" % (ov, fn, args))
    x = [xx.strip() for xx in args.split(",")]
    shift = int(x.pop())
    afunc(ov, fn, shift, x)


def given(ov, sl):
    new_op = afunc(ov, "inp", 0, [])
    print("// given(%s, %s) pc=%d" % (ov, sl, new_op.pc))


def unmatched(line):
    print("// unmatched: " + line)


ifile = open(argv[1], 'r')
fdata = ifile.read()
print("// machine-generated by sched.py")
for line in fdata.split('\n'):
    if line.strip() and line.find("printf") != 0:
        if line[0:2] == "//":
            print(line)
            continue
        m1 = search(r"^ *(\w+) +([^ ]+) *= *(\w+)\((.*)\);", line)
        m2 = search(r"^ *(\w+) +([^ ]+) *= *given\[(\d+)\];", line)
        m3 = search(r"^ *set_result_([a-z]*)\((.*)\);", line)
        m4 = search(r"^ *static +int +(\w+);", line)
        if m1:
            de = m1.group(1)
            ov = m1.group(2)
            fn = m1.group(3)
            args = m1.group(4)
            if de == "int" or de == "ZZZ":
                oplist(ov, fn, args)
            else:
                unmatched(line)
        elif m2:
            de = m2.group(1)
            ov = m2.group(2)
            sl = m2.group(3)
            if de == "int" or de == "ZZZ":
                given(ov, sl)
            else:
                unmatched(line)
        elif m3:
            de = m3.group(1)  # should be ab or cd
            args = m3.group(2)
            oplist("terminus", "set_"+de, args+",0")
        elif m4:
            sv = m4.group(1)
            print("// state_var " + sv)
            new_state_var(sv)
        else:
            unmatched(line)

print("// %d instructions, %d highest pc in use" % (n_count, max_pc))

# Special case adjustment applies to state variables, that have to persist.
# It's important that this adjustment happens after instruction scheduling,
# but before register mapping.
for var in state_vars:
    becomes_valid[var] = 0
    last_used[var] = max_pc

regmap = {}
reg_assign = {}
reg_assign["terminus"] = 0  # maybe a mistake
highest_regnum = 0
cross_ref = {}


def regmap_entry(reg, n):
    return "%d:%d" % (reg, n) in regmap


def regmap_mark(reg, n):
    regmap["%d:%d" % (reg, n)] = 1


def regmap_range(v):
    return list(range(becomes_valid[v], last_used[v]+1))


def blacklist_reg(v, reg):
    for n in regmap_range(v):
        regmap_mark(reg, n)


def compat(v, reg):
    for n in regmap_range(v):
        if regmap_entry(reg, n):
            return 0
    return 1


def choose_reg(v):
    for n in range(1, 31):
        if compat(v, n):
            reg_assign[v] = n
            if n in cross_ref:
                cross_ref[n].append(v)
            else:
                cross_ref[n] = [v]
            blacklist_reg(v, n)
            global highest_regnum
            if n > highest_regnum:
                highest_regnum = n
            return n
    print("error: no space in register file for %s" % v)
    exit(1)


def assign_vars():
    for v in sorted(becomes_valid.keys()):
        if v in last_used:
            n = choose_reg(v)
            if verbose:
                print("// assigned %d for %s from %d to %d" % (n, v, becomes_valid[v], last_used[v]))
        else:
            print("// %s from %d never used" % (v, becomes_valid[v]))


def dump_regmap():
    print("// register blackout map")
    for n in range(0, max_pc+1):
        ss = "//  %3d:" % n
        for m in range(0, 31):
            ss = ss + (" X" if regmap_entry(m, n) else "  ")
        print(ss)


def show_xref():
    print("// register cross-reference")
    for n in sorted(cross_ref.keys()):
        print("//  %2d: %s" % (n, " ".join(cross_ref[n])))


assign_vars()
if verbose:
    dump_regmap()
show_xref()
print("// %d abstract results packed into %d registers" % (len(becomes_valid), highest_regnum))
print("// one instruction, as broken into pipeline stages:")
print("//                .  .  .    .   bbbbb aaaaa")
print("//                .  . ooo   .     .     .")
print("//                . ss  .    .     .     .")
print("//                .  .  .    .     .     .")
print("//                t  .  .  wwwww   .     .        symbolic form")

stream_ra = {}
stream_rb = {}
stream_wa = {}
stream_op = {}
stream_sv = {}
stream_st = {}

opcodes = {'nop': 0, 'inp': 0, 'set_ab': 1, 'set_cd': 2, 'mul': 4, 'inv': 5, 'add': 6, 'sub': 7}


def emit(pc, lhs, op, shift, a, b):
    # print("// %d: %d = %s (%d, %d) << %d" % (pc, lhs, op, a, b, shift))
    # note the pipelining encoded here, matches sf_main.v and the
    # graphic printed above as comments.
    stream_ra[pc-4] = a
    stream_rb[pc-4] = b
    stream_op[pc-3] = opcodes[op]
    stream_sv[pc-2] = shift
    stream_wa[pc-0] = lhs
    stream_st[pc-0] = op == "inp"


for pc in range(0, max_pc+6):
    if pc in pc_in_use:
        inst = pc_in_use[pc]
        aa = []
        for a in inst.args:
            aa.append(reg_assign[a])
        if inst.op == "inv":
            aa.append(0)
        if inst.op == "inp":
            aa.append(0)
            aa.append(0)
        emit(pc, reg_assign[inst.lhs], inst.op, inst.shift, aa[0], aa[1])
    else:
        emit(pc, 0, "nop", 0, 0, 0)


print("// inst coding:  st sv  op   wa    rb    ra")
for pc in range(0, max_pc+1):
    if pc in pc_in_use:
        comment = "  // " + pc_in_use[pc].text()
    else:
        comment = ""
    inst_p = tobin(stream_st[pc], 1) + "_" + \
        tobin(stream_sv[pc], 2) + "_" + \
        tobin(stream_op[pc], 3) + "_" + \
        tobin(stream_wa[pc], 5) + "_" + \
        tobin(stream_rb[pc], 5) + "_" + \
        tobin(stream_ra[pc], 5)
    print("%4d: inst <= 21'b%s;%s" % (pc, inst_p, comment))


print("default: inst <= 0;")
