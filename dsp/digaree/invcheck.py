#!/usr/bin/python

# make sim1 && ./sim1 invcheck | awk '/plot/{$1=""; print $0}' > inverse.dat
import numpy
from matplotlib import pyplot
from sys import argv

d = numpy.loadtxt('inverse.dat')
d = d.transpose()

x = d[0]
perfect = d[5]
g = d[1]/perfect
r1 = d[2]/perfect
r2 = d[3]/perfect
r3 = d[4]/perfect

ix = numpy.nonzero(x > 8192)
min_r2 = numpy.min(r2[ix])
max_r2 = numpy.max(r2[ix])
print("r2 min/max %.5f %.5f" % (min_r2, max_r2))
min_r3 = numpy.min(r3[ix])
max_r3 = numpy.max(r3[ix])
print("r3 min/max %.5f %.5f" % (min_r3, max_r3))

if len(argv) > 1 and argv[1] == 'plot':
    pyplot.semilogx(x, g, x, r1, x, r2, x, r3)
    pyplot.legend(['guess', 'r1', 'r2', 'r3'], loc='upper left')
    pyplot.show()

# x range from 2^13 to 2^21 is 48 dB, but when used on |z|^2 in the
# context of cpx_inv_conj(), the dynamic range of z is only 24 dB.
if min(x[ix]) < 8300 and max(x) > 2050000 and\
   min_r2 > 0.995 and max_r2 < 1.0018 and\
   min_r3 > 0.9998 and max_r3 < 1.0018:
    print("PASS")
else:
    print("FAIL")
    exit(1)
