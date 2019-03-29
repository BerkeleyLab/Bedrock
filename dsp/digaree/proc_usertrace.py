#!/usr/bin/python

import re
from sys import argv

ifile = open(argv[1], 'r')
fdata = ifile.read()
for line in fdata.split('\n'):
    m1 = re.search(r"= *([-0-9]+)", line)
    m2 = re.search(r"// *(\w*)", line)
    if m1 and m2 and line.find("terminus") == -1:
        print(m2.group(1) + " " + m1.group(1))
