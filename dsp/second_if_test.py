import numpy
import sys

fname = sys.argv[1]
with open(fname, 'r') as f:
    a = [int(x) for x in f.readlines()]

npt = 132*2
a = a[300:300+npt]
ss = numpy.abs(numpy.fft.fft(a))
peak = numpy.max(ss)
fail = 0
for ix in range(int(npt/2)):
    if ss[ix] > 0.003*peak:  # require spurs less than -50 dBc
        print("%d %f" % (ix, ss[ix]))
        if ix != 61:
            fail = 1
print("PASS" if not fail else "FAIL")
sys.exit(fail)
