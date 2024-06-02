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

# second_if_out_tb and ssb_out_tb use different settings
# Number of FFT points calculated so that IF line falls exactly in freq bucket;
# this removes the need for a window function
ssb_fs, ssb_if, ssb_npt = 1313.0/8.0, 13.0, 101*2
sec_fs, sec_if, sec_npt = 1320.0/7.0, IF_OUT, 132*2

# Normalized amplitude check is based on drive+LO settings of second_if_out_tb and ssb_out_tb
amp_out = 0.86085

f_samp, if_out, npt = (ssb_fs, ssb_if, ssb_npt) if SSB_OUT else (sec_fs, sec_if, sec_npt)

with open(fname, 'r') as f:
    if SSB_OUT and not SSB_SINGLE:
        # Combine I and Q components
        dat = []
        for line in f.readlines():
            x = line.split()
            # DAC1 is I, DAC2 is Q
            dat_i, dat_q = float(x[0])/(2**15), float(x[1])/(2**15)

            iq_cpx = dat_i + 1j*dat_q
            dat.append(iq_cpx*0.5)
    else:
        dat = [float(x)/(2**15) for x in f.readlines()]


if if_out > 0.5*f_samp:  # Second Nyquist zone
    if_out = f_samp - if_out

dat = dat[300:300+npt]
ss = 2*np.abs(fft(dat))/len(dat)  # Normalize and double since we only care about positive peak
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
# In the real SSB case, make sure to scan both positive and negative frequencies
# so we can correctly pick up the suppressed sideband as a potential spur.
npt_scan = npt if SSB_OUT and not SSB_SINGLE else int(npt/2)
for ix in range(npt_scan):
    if abs(freq_bins[ix] - if_out) > 1e-6 and ss[ix] > 0.003*peak:  # require spurs less than -50 dBc
        print("FAIL: Unexpected spur at %.3f MHz, amplitude %.4e" % (freq_bins[ix], ss[ix]))
        fail = 1

# possibly over-tight spec, but does work in all modes today with a comfortable margin
if abs(peak - amp_out) > 0.0001:
    print("FAIL: Unexpected peak amplitude: %.4e. Expected: %.4e" % (peak, amp_out))
    fail = 1

print("FAIL" if fail else "PASS")

sys.exit(fail)
