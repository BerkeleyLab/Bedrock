import leep
from time import sleep
import numpy as np
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
    import sys
    import argparse
    parser = argparse.ArgumentParser(
        description="Utility to read Ethernet packet statistics")
    parser.add_argument('-a', '--addr', default='192.168.19.10', help='IP address')
    parser.add_argument('-p', '--port', type=int, default=803, help='Port number')
    parser.add_argument('-i', '--interval', type=float, default=2.0, help='Polling inteval (seconds)')
    args = parser.parse_args()
    leep_addr = "leep://" + args.addr + ":" + str(args.port)
    print("Packet badger stats from", leep_addr)

    try:
        dev = leep.open(leep_addr)
    except OSError as err:
        print("Leep initialization error:", err)
        sys.exit(1)

    print("   n/a  !crc   arp  !MAC   !IP  other  ICMP  n/a   UDP     1     2     3")
    while True:
        try:
            counts = update(dev)
            print("".join(["%6d" % counts[ix] for ix in range(16)]))
            sleep(args.interval)
        except (KeyboardInterrupt, OSError) as err:
            if isinstance(err, KeyboardInterrupt):
                print("\nExiting")
            else:
                print("Polling error:", err)
            break
