# The whole idea of putting a Tx MAC on the network-accessible localbus
# sounds crazy, but it avoids building a soft-core into the initial test
# framework.
# This program takes the output of "python3 packetgen.py flip"
# and creates the localbus transactions for loading into a simulation
# or sending to real hardware.
# Output is the payload of a UDP packet destined for an LBNL localbus gateway.
from sys import stdin


def lb_write(a, v):
    print("%8.8x" % a)
    print("%8.8x" % v)


def lb_read(a):
    print("%4.4x0000" % a)


lines = stdin.read().split('\n')
aw = 10
mac_base = 0x100000  # defined in hw_test.v and rtefi_pipe_tb.v
mac_ctl = mac_base + (1 << aw)  # defined in mac_subset.v
buf_start = 16  # arbitrary
data_start = mac_base + buf_start + 1
n = 0
ov = None
# Pseudorandom numbers for nonce
lb_write(0x31415926, 0x53589793)
lb_write(mac_ctl + 1, 0)  # acknowledge last packet (!?)
for x in lines:
    if x == "":
        continue
    v = int(x, 16)
    if n % 2:
        vv = ov + (v << 8)  # little-endian
        lb_write(data_start + int(n/2), vv)
    n += 1
    ov = v
if n % 2:
    lb_write(data_start + int(n/2), v)
# length of packet
lb_write(mac_base + buf_start, n)
# trigger send by MAC
lb_write(mac_ctl, buf_start)
