import numpy as np
from numpy.fft import fft, fftfreq, fftshift
from matplotlib import pyplot as plt
import sys

fname = sys.argv[1]

SSB_OUT = SSB_SINGLE = False
IF_OUT = 0
if len(sys.argv) > 2:
    if sys.argv[2] == "SSB_OUT":
        SSB_OUT = True
    else:
        IF_OUT = float(sys.argv[2])
if len(sys.argv) > 3 and sys.argv[3] == "SINGLE":
    SSB_SINGLE = True

# second_if_out_tb and ssb_out_tb use different settings:
ssb_fs, ssb_if = 1313.0/8.0, 13.0
sec_fs, sec_if = 1320.0/7.0, IF_OUT

f_samp, if_out = (ssb_fs, ssb_if) if SSB_OUT else (sec_fs, sec_if)

with open(fname, 'r') as f:
    if SSB_OUT and not SSB_SINGLE:
        # Combine I and Q components
        dat = []
        for l in f.readlines():
            x = l.split()
            dat_i, dat_q = int(x[0]), int(x[1])
            dat.append(dat_i + dat_q)
    else:
        dat = [int(x) for x in f.readlines()]


if if_out > 0.5*f_samp:  # Second nyquist zone
    if_out = f_samp - if_out

npt = 132*2
dat = dat[300:300+npt]
ss = np.abs(fft(dat))
dt = 1.0/f_samp
freq_bins = fftfreq(len(dat), d=dt)

if (len(sys.argv) > 3 and sys.argv[3] == "plot") or\
   (len(sys.argv) > 4 and sys.argv[4] == "plot"):
    plt.plot(fftshift(freq_bins), fftshift(ss))
    plt.xlabel("f (MHz)")
    plt.ylabel("Amplitude")
    plt.show()


peak = np.max(ss)
peak_freq = freq_bins[np.argmax(ss)]
print("Peak at %.3f MHz, Amp=%.4e" % (peak_freq, peak))
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
