import numpy as np
from numpy.fft import fft, fftfreq, fftshift
from matplotlib import pyplot as plt
import sys

fname = sys.argv[1]
with open(fname, 'r') as f:
    a = [int(x) for x in f.readlines()]

if_out = sys.argv[2]
if if_out == "145":
    if_out = 188.6 - 145.0
elif if_out == "60":
    if_out = 60.0
else:
    print("FAIL: Unsupported IF out frequency")
    sys.exit(1)

npt = 132*2
a = a[300:300+npt]
ss = np.abs(fft(a))
dt = 7/(1320)
freq_bins = fftfreq(len(a), d=dt)

if len(sys.argv) > 2 and sys.argv[2] == "plot":
    plt.plot(fftshift(freq_bins), fftshift(ss))
    plt.show()


peak = np.max(ss)
peak_freq = freq_bins[np.argmax(ss)]
print("Peak at %f MHz" % peak_freq)
fail = 0
e_delta = 0.05
for ix in range(int(npt/2)):
    if ss[ix] > 0.003*peak:  # require spurs less than -50 dBc
        print("%f MHz: %f" % (freq_bins[ix], ss[ix]))
        if freq_bins[ix] > if_out + e_delta or freq_bins[ix] < if_out - e_delta:
            print("FAIL: Unexpected spur", float(if_out))
            fail = 1
print("PASS" if not fail else "FAIL")
sys.exit(fail)
