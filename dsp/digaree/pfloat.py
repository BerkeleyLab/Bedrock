# Processes a waveform acquired on actual hardware, runs it through
# the state equation described in tuning_dsp4 both by running it through
# sim1, and with a natural (floating-point, SI unit-based) numpy calculation.

# When run without any arguments, it writes the init_run2.dat file with
# the constants needed for the sim1 run.
# When run with 1 argument, the filename of the acquired waveforms,
# does the numpy calculation.
# When run with 2 arguments, the second is the filename with sim1 output,
# it's compared with the numpy calculation.

# To do: also handle the power balance half of sim1

# purposely kept compatible with python2 and python3
import numpy
from numpy import sqrt, pi
from sys import argv

# (crudely estimated) scale factors from ADC to SI Watts and Volts
# specifically set up to be consistent with run2.dat
ck = sqrt(10000)/32768
cv = 27e6/32768
fshift = numpy.exp(-0.086j)
wave_samp_per = 255
dt = wave_samp_per*2*33*14/1320e6  # s

omega_0 = 2*pi*1300e6  # /s
b = omega_0*sqrt(1036.0/4.4e7)  # sqrt(Ohm)/s
beta = b * (ck/cv)
beta = beta * fshift

# Note that if beta == 0 we get an analysis of frequency based on
# cavity rotation rate alone, relevant to SEL mode, but we get
# no information about the decay rate.

# See comment in tuning_dsp4:
# "So far this analysis has used s^{-1} as the units for 1/T, beta, and
# therefore a. Some other choice of inverse-time units will make sense
# when implementing this with fixed-point DSP."

print("Using computed beta %.2f%+.2fi /s" % (beta.real, beta.imag))


def xprint(fv, key, ix, x):
    xfs = 2**17
    xi = int(x*xfs+0.5)
    if xi >= xfs or xi < -xfs:
        print("Overflow in setup: %s %d %.4f\n" % (key, ix, x))
    fv.write("%s %d %7.0f\n" % (key, ix, x*2**17))
    # EXTRA is 4, so simloop.c will multiply by an extra 2**4


fq = 0.0003  # Hz frequency quantum
fs = 2**17  # or 2**17 or 2**23?
ffs = fq*fs*2*pi  # s^{-1} full-scale
print("Output frequency full-scale %.1f Hz" % ffs)
if True:  # in the scaleint context
    T = dt
    fir_gain = 80
invT = 1/(T*fir_gain*ffs)


def write_init(fname, sbeta, invT):
    fv = open(fname, 'w')
    fv.write('''# Persistent state initialization

# Don't worry about values here
p v1_r 0
p v1_i 0
p v2_r 0
p v2_i 0
p v3_r 0
p v3_i 0
p v4_r 0
p v4_i 0
# Filler, will be overwritten by values from run2.dat
s 0 0
s 1 0
s 2 0
s 3 0
s 4 0
s 5 0
# Actual host-writable
# Cut-and-pasted from pfloat.py output, based on analysis of run2.dat
''')
    xprint(fv, "h", 0, sbeta.real)
    xprint(fv, "h", 1, sbeta.imag)
    xprint(fv, "h", 2, 1/(T*fir_gain*ffs))  # invT
    xprint(fv, "h", 3, 1/16.0)  # "two" supports inverse function
    fv.write('''h 4       0
h 5       0
h 6       0
h 7       0
''')


if len(argv) < 2:
    print('Writing init_run2.dat')
    write_init('init_run2.dat', beta/ffs, invT)
    exit(0)
d = numpy.loadtxt(argv[1]).transpose()
fwd = d[2] + 1j * d[3]
rev = d[4] + 1j * d[5]
cav = d[6] + 1j * d[7]

if False:
    fwd = fwd * fshift  # empirical correction for cables etc.
cav = cav * (1j)  # fixed
fwd = fwd * (1j)  # for consistency
# pyplot.plot(cav.real, cav.imag, fwd.real, fwd.imag)

npt = len(cav)

mean_v = numpy.mean(abs(cav*cv))
mean_k2 = numpy.mean(abs(fwd*ck)**2)
print("Possibly calibrated %.3f MV, %.4f kW" % (mean_v*1e-6, mean_k2*1e-3))

from matplotlib import pyplot

t = numpy.array(range(npt)) * dt

cav_deriv = numpy.diff(cav)/dt
cav_deriv = numpy.append(cav_deriv, 0)  # keep constant number of points


# For direct computations here, use SI instead of ffs
a_l = cav_deriv / cav
a_r = beta*fwd / cav
a = (cav_deriv - beta*fwd) / cav
a = a / (2*pi)
print("Mean bandwidth %.3f Hz, std %.3f Hz" % (-numpy.mean(a.real), numpy.std(a.real)))

phase_deriv = numpy.diff(numpy.angle(cav))/dt
phase_deriv = numpy.append(phase_deriv, 0)  # keep constant number of points

if len(argv) > 2:
    # Output from simloop, pure integer
    d2 = numpy.loadtxt(argv[2]).transpose()
    a2 = (d2[0] + (1j)*d2[1]) * ffs  # Convert to /s
    a2 = a2 / (2*pi)
    a2_bw = -a2[4:].real
    print("CAS  bandwidth %.3f Hz, std %.3f Hz" % (numpy.mean(a2_bw), numpy.std(a2_bw)))
    # pyplot.plot(t, a.real, t, a2.real)
    pyplot.plot(t, a.imag, t, a2.imag)
    pyplot.legend(['Numpy', 'sim1'], loc='upper right')
    pyplot.xlabel('t (s)')
    pyplot.ylabel('a (Hz)')
    pyplot.xlim((0, 800*dt))
elif False:
    drive_freq = -fwd.imag/fwd.real * 16
    pyplot.plot(t, a.imag, t, phase_deriv/(2*pi), t, drive_freq)
    pyplot.xlabel('t (s)')

pyplot.show()
