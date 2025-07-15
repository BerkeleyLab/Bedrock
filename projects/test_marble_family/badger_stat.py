import leep
from time import sleep
import numpy as np
prevs = np.array([0]*16)


def update(dev):
    global prevs
    wrap = 2**20  # hard-coded width of rx_counters in lb_marble_slave.v
    totals = dev.reg_read(["rx_counters"])[0]
    counts = totals - prevs
    counts = [x & (wrap-1) for x in counts]
    prevs = totals
    return counts


if __name__ == "__main__":
    import sys
    import argparse
    parser = argparse.ArgumentParser(
        description="Utility to read Ethernet packet statistics",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog='''
Packet Badger category semantics:
  n/a   not used
  !crc  incoming packet failed CRC
  arp   ARP request for us
  !MAC  Not our MAC and not broadcast
  !IP   Not an IP packet
  other other unrecognized, includes TCP and unused UDP ports
  ICMP  ICMP echo request
  n/a   not used
  UDP   channel 0, typically port 7 echo
  UDP   channel 1, typically port 801 Hello World
  UDP   channel 2, typically port 802 data integrity test
  UDP   channel 3, typically port 803 local bus access
  UDP   channel 4, typically port 804 spi_flash access
  UDP   channels 5-7, typically not used
As implemented in multi_counter.v and packet_categorize.v''')
    parser.add_argument('-a', '--addr', required=True, help='IP address (required)')
    parser.add_argument('-p', '--port', type=int, default=803, help='Port number (default 803)')
    parser.add_argument('-i', '--interval', type=float, default=2.0, help='Polling interval (seconds, default 2)')
    parser.add_argument('-c', '--count', dest="count", default=0, type=int,
                        help='Number of polling cycles (default 0 means go forever)')
    args = parser.parse_args()
    leep_addr = "leep://" + args.addr + ":" + str(args.port)
    print("Packet badger stats from", leep_addr)

    try:
        dev = leep.open(leep_addr)
    except OSError as err:
        print("Leep initialization error:", err)
        sys.exit(1)

    iter_count = 0
    print("   n/a   !crc    arp   !MAC    !IP   other   ICMP   n/a    UDP      1      2      3")
    while 0 == args.count or iter_count < args.count:
        try:
            counts = update(dev)
            print(" ".join(["%6d" % counts[ix] for ix in range(16)]))
            sys.stdout.flush()
            sleep(args.interval)
            iter_count += 1
        except (KeyboardInterrupt, OSError) as err:
            if isinstance(err, KeyboardInterrupt):
                print("\nExiting")
            else:
                print("Polling error:", err)
            break
