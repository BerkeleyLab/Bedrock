#!/usr/bin/python

# transfers Verilog parameters to a .h file for use in C programs
from sys import argv, stdout
import re
ifile = open(argv[1], 'r')
ss = "/* Machine generated from paramh.py %s */\n" % argv[1]
fdata = ifile.read()
for iline in fdata.split('\n'):
    # print iline
    m1 = re.search(r'^\s*parameter\s+(\w+)\s*=\s*(\d+)', iline)
    if m1:
        ss += "#define %s %s\n" % (m1.group(1).upper(), m1.group(2))

if len(argv) > 2:
    ofile = open(argv[2], 'w')
else:
    ofile = stdout
ofile.write(ss)
