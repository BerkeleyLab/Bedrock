import numpy as np
from numpy.fft import fft, fftfreq, fftshift
from matplotlib import pyplot as plt
import sys

fname = sys.argv[1]
with open(fname, 'r') as f:
    a = [int(x) for x in f.readlines()]

f_samp = 1320.0/7.0
if_out = float(sys.argv[2])
if if_out > 0.5*f_samp:
    if_out = f_samp - if_out

npt = 132*2
a = a[300:300+npt]
ss = np.abs(fft(a))
dt = 1.0/f_samp
freq_bins = fftfreq(len(a), d=dt)

if len(sys.argv) > 3 and sys.argv[3] == "plot":
    plt.plot(fftshift(freq_bins), fftshift(ss))
    plt.xlabel("f (MHz)")
    plt.ylabel("Amplitude")
    plt.show()


peak = np.max(ss)
peak_freq = freq_bins[np.argmax(ss)]
print("Peak at %.3f MHz" % peak_freq)
fail = 0
e_delta = 0.05
for ix in range(int(npt/2)):
    if ss[ix] > 0.003*peak:  # require spurs less than -50 dBc
        print("%.3f MHz: amplitude %.4e" % (freq_bins[ix], ss[ix]))
        if abs(freq_bins[ix] - if_out) > e_delta:
            print("FAIL: Unexpected spur", float(if_out))
            fail = 1
print("FAIL" if fail else "PASS")
sys.exit(fail)
