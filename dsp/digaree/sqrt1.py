#!/usr/bin/python
import numpy
from numpy import sqrt
from matplotlib import pyplot
from sys import argv
# Explains abstract theory for approximating 1/sqrt(x)
# (and one can get sqrt(x) by multiplying result by x)
# See https://en.wikipedia.org/wiki/Methods_of_computing_square_roots


def iterx(x, g):
    # Newton's method
    return g*(3-x*g**2)/2.0


x = numpy.arange(0.25, 1.0, 0.001)   # input, spans a factor of four
# initial guess function in sim1.c, needs to be added to sf_main.v
r0 = 1 + 0.25*(x < 0.75) + 0.25*(x < 0.5) + 0.25*(x < 0.375)
print("x*r0**2 span %.6f %.6f" % (min(r0**2*x), max(r0**2*x)))
r1 = iterx(x, r0)
print("x*r1**2 span %.6f %.6f" % (min(r1**2*x), max(r1**2*x)))
r2 = iterx(x, r1)
print("x*r2**2 span %.6f %.6f" % (min(r2**2*x), max(r2**2*x)))
r3 = iterx(x, r2)
print("x*r3**2 span %.6f %.6f" % (min(r3**2*x), max(r3**2*x)))
fail = min(r3**2*x) < 0.99999 or max(r3**2*x) > 1.00001

plot = len(argv) > 1 and argv[1] == "plot"
if plot:
    pyplot.plot(x, r0*sqrt(x), label='r0')
    pyplot.plot(x, r1*sqrt(x), label='r1')
    pyplot.plot(x, r2*sqrt(x), label='r2')
    pyplot.plot(x, r3*sqrt(x), label='r3')
    pyplot.legend()
    pyplot.show()

if fail:
    print("FAIL")
    exit(1)
else:
    print("PASS")

# Implementation model in sim1.c function invsqrt() is just like "r0" here, except:
#  - calculates 1/8*sqrt(x) instead of 1/sqrt(x)
#  - stitches together three of these to cover six octaves in x
# Iterative refinement is tested by sim1's invsqrtcheck().
