#!/usr/bin/python
from sys import stderr
from numpy import exp

print("# tst mode initial setup")
fs = 2**17  # full-scale for an 18-bit signed register

mode = 3

if mode == 1:
    beta = 0.5
    kick = 0.1
    sv = 0
elif mode == 2:
    beta = 0.5
    kick = 0
    sv = 0.202245
elif mode == 3:
    beta = 0.5 * exp(0.02j)
    kick = 0
    sv = 0.223594


def xprint(key, ix, x):
    xi = int(x*fs+0.5)
    if xi >= fs or xi < -fs:
        stderr.write("Overflow in setup: %s %d %.4f\n" % (key, ix, x))
        exit(1)
    print("%s %s %d" % (key, ix, xi))


print("#")
print("# Persistent state initialization")
print("# Symbolic register names will be used by sim1 directly.")
print("# init_xindex.py will convert them to decimal for use by user_tb.")
xprint("p", "sv_r", sv.real)
xprint("p", "sv_i", sv.imag)

print("#")
print("# Test stream (conveyor belt) values ignored")
xprint("s", 0, 0)
xprint("s", 1, 0)
xprint("s", 2, 0)
xprint("s", 3, 0)
xprint("s", 4, 0)
xprint("s", 5, 0)

print("#")
print("# values for host loading")
xprint("h", 0, beta.real)
xprint("h", 1, beta.imag)
xprint("h", 2, 0)
xprint("h", 3, 2.8/16.0)  # "two" supports amplitude lock
xprint("h", 4, 0)
xprint("h", 5, 0)
xprint("h", 6, kick.real)
xprint("h", 7, kick.imag)
