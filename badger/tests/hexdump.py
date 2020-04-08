#!/bin/env python
import sys
for x in open(sys.argv[1]).read():
    sys.stdout.write("%02x\n" % ord(x))
