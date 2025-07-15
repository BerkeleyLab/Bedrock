#!/usr/bin/python

# Pretty simple code to map symbolic register names used in init.dat
# to hard register numbers in init2.dat.  The latter is needed by the
# user_tb simulator written in Verilog.  The cross-reference table
# between register name and number is given in ops.vh.  Only persistent
# state-variables need to be covered here, and they map 1:1 to registers.

from sys import stderr
persist = {}


def do_init_line(line):
    a = line.split(" ")
    if len(a) != 3:
        return
    t = a[0]
    if t == "s" or t == "h":
        print(line)
    elif t == "p":
        v = a[1]
        if v not in persist:
            stderr.write("ERROR: %s missing map in ops.vh\n" % v)
            exit(1)
        print("p %s %s" % (persist[v], a[2]))


# Example: //  16: v1_i
# persistent state variables can't share their register with others
def do_ops_line(line):
    a = line.split()
    if len(a) != 3:
        return
    n = a[1]
    if n[-1] != ":":
        return
    n = int(n[:-1])
    # print("found persistent %s: %s" % (a[2], line))
    persist[a[2]] = n


xfile = open('ops.vh', 'r')
for line in xfile.readlines():
    do_ops_line(line.rstrip())

ifile = open('init.dat', 'r')
for line in ifile.readlines():
    do_init_line(line.rstrip())
