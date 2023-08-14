import leep
from time import sleep
from sys import argv
import sys
import numpy as np
import socket
prevs = np.array([0]*16)


def update(dev):
    global prevs
    wrap = 2**16  # hard-coded width of rx_counters in lb_marble_slave.v
    totals = dev.reg_read(["rx_counters"])[0]
    counts = totals - prevs
    counts = [x & (wrap-1) for x in counts]
    prevs = totals
    return counts


if __name__ == "__main__":
    if len(argv) < 2:
        print("Usage: badger_stat <device> [<interval>]")
    if len(argv) > 2:
        interval = float(argv[2])
    else:
        interval = 2.0  # seconds
    try:
        dev = leep.open(argv[1])
    except TimeoutError:
        print("Socket error")
        sys.exit(1)

    print("Packet badger stats from", argv[1])
    print("   n/a  !crc   arp  !MAC   !IP  other  ICMP  n/a   UDP     1     2     3")
    while True:
        try:
            counts = update(dev)
            print("".join(["%6d" % counts[ix] for ix in range(16)]))
            sleep(interval)
        except (KeyboardInterrupt, TimeoutError) as err:
            if isinstance(err, KeyboardInterrupt):
                print("\nExiting")
            else:
                print("Socket timeout")
            break
