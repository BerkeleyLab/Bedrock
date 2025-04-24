import numpy as np
from numpy.fft import fft, fftfreq, fftshift
from matplotlib import pyplot as plt
import sys

fname = sys.argv[1]

sec_fs, sec_if, sec_npt = 1320.0/7.0, 145, 264

amp_out = 0.32798

f_samp, if_out, npt = sec_fs, sec_if, sec_npt

with open(fname, 'r') as f:
    dat = [float(x)/(2**15) for x in f.readlines()]


if if_out > 0.5*f_samp:  # Second Nyquist zone
    if_out = f_samp - if_out

dat = np.array(dat[300:300+npt])
# Normalize and double since we only care about positive peak
ss = 2*np.abs(fft(dat))/len(dat)
dt = 1.0/f_samp
freq_bins = fftfreq(len(dat), d=dt)

plot = True
if (plot):
    plt.semilogy(fftshift(freq_bins), abs(fftshift(ss)))
    plt.xlabel("f (MHz)")
    plt.ylabel("Amplitude")
    plt.show()


peak = np.max(ss)
peak_freq = freq_bins[np.argmax(ss)]
print("Peak at %.3f MHz, Amp=%.4e" % (peak_freq, peak))
fail = 0
npt_scan = npt//2
for ix in range(npt_scan):
    # require spurs less than -50 dBc
    if abs(freq_bins[ix] - if_out) > 1e-6 and ss[ix] > 0.003*peak:
        print("FAIL: Unexpected spur at %.3f MHz, amplitude %.4e" % (freq_bins[ix], ss[ix]))
        fail = 1

# possibly over-tight spec, but does work in all modes with a comfortable margin
if abs(peak - amp_out) > 0.0001:
    print("FAIL: Unexpected peak amplitude: %.4e. Expected: %.4e" % (peak, amp_out))
    fail = 1

print("FAIL" if fail else "PASS")

sys.exit(fail)
