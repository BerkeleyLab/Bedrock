#!/usr/bin/python

# Explains abstract theory for approximating 1/x
import numpy
from matplotlib import pyplot

x = numpy.arange(1, 2, 0.001)   # input, spans a factor of two
g = 0.5 + (x < 1.5)*0.25        # first guess from look-up table
r1 = g*(2-g*x)     # first refinement
r2 = r1*(2-r1*x)   # second refinement, peak error 0.4%
print("r2*x span %.6f %.6f" % (min(r2*x), max(r2*x)))
r3 = r2*(2-r2*x)   # third refinement, peak error 15 ppm
print("r3*x span %.6f %.6f" % (min(r3*x), max(r3*x)))

pyplot.plot(x, r1*x, x, r2*x, x, r3*x)
pyplot.ylim((0.92, 1))
pyplot.show()

# Implementation in sf_main.v module sf_inv() -- and its model in
# sim1.c function inv -- is just like "g" here, except:
#  - calculates 1/(256*x) instead of 1/x
#  - stitches together about eight of these to cover eight octaves in x
# iterative refinement is handled in cgen_lib.py as inv_iter and inv_full.
# See invcheck.py for a crosscheck that at least the C simulation of
# that process works.
