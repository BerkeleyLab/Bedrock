#!/usr/bin/python

# Pretty simple code to map symbolic register names used in init.dat
# to hard register numbers in init2.dat.  The latter is needed by the
# user_tb simulator written in Verilog.  The cross-reference table
# between register name and number is given in ops.vh.  Only persistent
# state-variables need to be covered here, and they map 1:1 to registers.

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
        # print "looking up", v, persist[v]
        print("p %s %s" % (persist[v], a[2]))


def do_ops_line(line):
    a = line.split()
    if len(a) != 3:
        return
    n = a[1]
    if n[-1] != ":":
        return
    n = int(n[:-1])
    persist[a[2]] = n


xfile = open('ops.vh', 'r')
fdata = xfile.read()
for line in fdata.split('\n'):
    do_ops_line(line)

ifile = open('init.dat', 'r')
fdata = ifile.read()
for line in fdata.split('\n'):
    do_init_line(line)
