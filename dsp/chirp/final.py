# quick display of the results of "make chirp_wrap.out"
import sys
import numpy as np
from matplotlib import pyplot

d = np.loadtxt('chirp_wrap.out')
y = d.transpose()[0]
a = d.transpose()[1]

# Must match chirp_wrap_tb settings
dt = (8.0*14.0)/(1320.0e6)
if len(sys.argv) < 2:
    t = dt * np.arange(len(y))
    pyplot.plot(t, a*1.0*1.64676)  # Cordic gain
    pyplot.plot(t, y)
    pyplot.xlim(0, max(t))
    pyplot.xlabel('Time (s)')
    # pyplot.legend(loc="upper left", frameon=False)
    # pyplot.savefig("final.png")
    pyplot.show()


ss = np.fft.fft(y)
freq = np.fft.fftfreq(y.size, d=dt)  # np.arange(npt/2)/dt/npt
ss = np.abs(ss)/ss.size*2

# Find chirp's frequency content from FFT
arg_pk = np.argmax(ss)
freq_pk = freq[arg_pk]
pk_val = ss[arg_pk]

# 6 dB ~= 0.25
band = np.where(ss > pk_val*0.25)[0]
freq_band = [freq[x] for x in band]
min_freq = np.min(freq_band)
max_freq = np.max(freq_band)
print("Peak freq = {} Hz, Min/Max -6dB Peak freq = ({},{}) Hz".format(freq_pk, min_freq, max_freq))

# Must match chirp_wrap_tb settings
dsgn_fmin = -50e3
dsgn_fmax = 50e3
fail = True if min_freq < dsgn_fmin or max_freq > dsgn_fmax else False
fail = True if min_freq > dsgn_fmin*0.8 or max_freq < dsgn_fmax*0.8 else False

if len(sys.argv) == 2 and sys.argv[1] == "plot":
    pyplot.xlim(left=-100e3, right=100e3)
    pyplot.plot(freq, ss)
    pyplot.xlabel('f (Hz)')
    pyplot.show()

print("FAULT" if fail else "PASS")
sys.exit(1 if fail else 0)
