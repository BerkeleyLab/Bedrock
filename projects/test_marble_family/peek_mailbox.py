#!/usr/bin/env python

# DEPRECATED. Use marble_mmc/scripts/decodembox.py for current mailbox compatibility
from sys import argv
import leep


def peek_mailbox(addr):
    foo = addr.reg_read(["spi_mbox"])[0]
    # XXX Want to set up a check that the counter is incrementing
    # Maybe make raw output optional?
    for page in range(5):
        subset = foo[page*16:page*16+16]
        print(page, " ".join([" %2.2x" % d for d in subset]))
    subset = foo[60:64]
    print("MMC gitid  " + "".join(["%2.2x" % d for d in subset]))
    n = foo[48]*256 + foo[49]
    print("mbox count  %d" % n)
    t0 = 0.5*(foo[52]*256 + foo[53])
    print("LM75 0  (U29)  %5.1f C" % t0)
    t1 = 0.5*(foo[54]*256 + foo[55])
    print("LM75 1  (U28)  %5.1f C" % t1)
    t1 = foo[64] + foo[65]*(0.5)**8
    print("MAX6639 T1   (U1)  %5.2f C" % t1)
    t2 = foo[66] + foo[67]*(0.5)**8
    print("MAX6639 T2  (U27)  %5.2f C" % t2)
    print("MAX6639 fan1 %3d %% D.F.  %3d tach" % (foo[70]*100/120.0, foo[68]))
    print("MAX6639 fan2 %3d %% D.F.  %3d tach" % (foo[71]*100/120.0, foo[69]))


if __name__ == "__main__":
    if len(argv) < 2:
        print("DEPRECATED. Use marble_mmc/scripts/decodembox.py for current mailbox compatibility")
        print("usage: peek_mailbox leep://$host:803")
        exit(1)
    leep_addr = argv[1]
    addr = leep.open(leep_addr, timeout=5.0)
    peek_mailbox(addr)
