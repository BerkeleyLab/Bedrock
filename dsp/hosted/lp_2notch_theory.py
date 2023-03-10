# How to generate a low-latency notch filter in DSP,
# intended to keep the nearby passband modes of an SRF cavity
# from creating spurious oscillations in high-gain feedback
# or SEL operations modes.

# This simulation set up for the -750 kHz offset of the 8*pi/9
# mode and -3.0 MHz offset of the 7*pi/9 mode of a TTF-style cavity.
# Note that every cavity's nearby modes are at a slightly different
# frequency (have to love that sheet metal!), so the FPGA parameters
# need to be tunable at runtime.

# There is a second purpose to the filtering system, and that is
# to limit the broadband noise sent to the high power amplifier.
# A simple 100 kHz bandwidth requirement is assumed here, and the
# filters' implementations are intertwined.

# This analysis starts in the s (Laplace) domain, then moves on to an
# abstract DSP implementation (with or without pipelining) in the z domain.
# It has no vision of register scaling or quantization error.
# For that level of detail, see the Verilog code and associated
# python-driven tests in lp_2notch_test.py.

# Larry Doolittle, LBNL, July 2013
# z-domain added February, 2014
# converted to Python June, 2022
# added second notch June, 2022

import numpy as np
from numpy import pi, exp
from matplotlib import pyplot
from sys import argv
pyplot.rcParams["figure.figsize"] = [10, 8]

quiet = len(argv) > 1 and argv[1] == "quiet"
df = 0.0075
npt = 900
f = df * (np.arange(2*npt+1)-npt)  # MHz
w = 2*pi*f
s = 1j*w
T = 2*14/1320.0  # microsecond for LCLS-II

fl = 0.16    # MHz of noise-limiting low-pass filter
fn1 = -0.75  # MHz offset of nearby mode to be rejected
fl1 = 0.16   # MHz BW of first notch filter
fn2 = -3.00  # MHz offset of nearby mode to be rejected
fl2 = 0.60   # MHz BW of second notch filter
poles = np.array([-fl, -fl1-1j*fn1, -fl2-1j*fn2]) * 2 * pi  # in s domain
notches = np.array([-fn1, -fn2])


def lp_s(f, pole):
    # a simple LPF has a single pole on the negative real axis
    # H(s) = omega/(s+omega)
    # This generalizes to a complex-valued pole
    s = 2*pi*1j*f
    # normalize so output is unity when s = 1j*pole.imag
    num = -pole.real
    return num/(s-pole), pole, num


def lp_z(f, pole):
    z = exp(2*pi*1j*f*T)  # e^(sT)
    pole_z = exp(pole*T)  # transform the pole location the same way
    cent_z = exp(1j*pole.imag*T)
    num = cent_z-pole_z
    return num/(z-pole_z), pole_z, num


# matches comments at the top of lp.v
# y*z = y + ky*z^{-1}*y + kx*x
def lp_zz(f, pole):
    z = exp(2*pi*1j*f*T)
    pole_z = exp(pole*T)
    ky = pole_z*(pole_z-1)
    cent_z = exp(1j*pole.imag*T)
    den = z - 1 - ky*z**(-1)
    num = cent_z - 1 - ky*cent_z**(-1)
    return num/den, ky, num


# n notches, n+1 poles, first pole presumably at DC
def filter(func, poles, notches, f):
    foo = [func(notches, p) for p in poles]
    ky = [x[1] for x in foo]
    num = np.array([x[2] for x in foo])
    eq_B = -foo[0][0]
    eq_A = np.array([x[0] for x in foo[1:]]).transpose()
    # With only two notches, this is a 2x2 matrix,
    # and could be solved without help of a fancy library.
    x = np.linalg.solve(eq_A, eq_B)
    kx = np.array([1] + list(x))
    for ix, k in []:  # enumerate(kx):
        print("kx_%d = %9.6f%+9.6fj" % (ix, k.real, k.imag))
    gains = [func(f, p)[0] for p in poles]
    gain = np.array(gains).transpose().dot(kx)
    return gain, gains, kx*num, ky


print("s domain")
As, gains, kx, ky = filter(lp_s, poles, notches, f)

np1 = sum(np.square(abs(gains[0]))) * df  # simple Riemann sum
print("noise power bandwidth LPF only          %.4f MHz" % np1)
np2 = sum(np.square(abs(As))) * df
print("noise power bandwidth with two notches  %.4f MHz" % np2)

# Transfer function should have a notch at -fn1 and -fn2
pyplot.plot(f, abs(gains[0]), label='low-pass')
pyplot.plot(f, abs(gains[1]), label='offset low-pass 1')
pyplot.plot(f, abs(gains[2]), label='offset low-pass 2')
pyplot.plot(f, abs(As), label='total with notch')
pyplot.plot([-fn1, -fn1], [0, 0.1], color='grey')
pyplot.plot([-fn2, -fn2], [0, 0.1], color='grey')
pyplot.legend()
pyplot.xlabel('f offset from carrier (MHz)')
pyplot.xlim((min(f), max(f)))
pyplot.savefig("lp_2notch1.png")
if quiet:
    pyplot.clf()
else:
    pyplot.show()

# Compute group delay of low-pass only
ang = np.unwrap(np.angle(gains[0]))
gdl = -np.diff(ang)/(df*2*pi)*1e3

# Compute and plot the group delay
# Result is 1640 ns at the carrier; that value needs to be
# used in the feedback loop design.  Note that 1580 ns comes
# from the centered 100 kHz low-pass filter, and 60 ns from the
# additional term to create the notches.
fx = 0.5*(f[1:]+f[:-1])
ang = np.unwrap(np.angle(As))
gd = -np.diff(ang)/(df*2*pi)*1e3
print("group delays %.1f %.1f ns" % (max(abs(gdl)), max(abs(gd[npt-1:npt+3]))))
pyplot.plot(fx, gdl, label='low-pass')
pyplot.plot(fx, gd, label='total with notch')
pyplot.legend()
pyplot.xlim((min(f), max(f)))
pyplot.ylim((0, 1300))
pyplot.ylabel('group delay (ns)')
pyplot.xlabel('f offset from carrier (MHz)')
pyplot.savefig("lp_2notch2.png")
if quiet:
    pyplot.clf()
else:
    pyplot.show()

print("z domain")
Az, gains, kx, ky = filter(lp_z, poles, notches, f)
pyplot.plot(f, abs(As), label='s-plane')
pyplot.plot(f, abs(Az), label='z-plane')
print("z domain pipelined")
Azz, gains, kx, ky = filter(lp_zz, poles, notches, f)
pyplot.plot(f, abs(Azz), label='z-plane pipelined')
pyplot.plot([-fn1, -fn1], [0, 0.15], color='grey')
pyplot.plot([-fn2, -fn2], [0, 0.15], color='grey')
pyplot.text(-fn1, 0.16, "%.3f" % -fn1, horizontalalignment='center')
pyplot.text(-fn2, 0.16, "%.3f" % -fn2, horizontalalignment='center')
pyplot.xlabel('f offset from carrier (MHz)')
pyplot.xlim((-4.5, 4.5))
pyplot.legend()
print("")
pp = ["z*y_m = y_m + ky_m*z^(-1)*y_m + kx_m*x"]
for ix in range(len(kx)):
    # ll = ix, kx[ix].real, kx[ix].imag, ix, ky[ix].real, ky[ix].imag
    # pp += ["kx_%d = %9.6f%+9.6fj  ky_%d = %9.6f%+9.6fj" % ll]
    pp += ["kx_%d = %9.6f%+9.6fj" % (ix, kx[ix].real, kx[ix].imag)]
    pp += ["ky_%d = %9.6f%+9.6fj" % (ix, ky[ix].real, ky[ix].imag)]
pp += ["y = sum(y_m)"]
pp += ["z^(-1) is %.3f ns" % (T*1e3)]
py = 0.8
for p in pp:
    print(p)
    pyplot.text(-4.1, py, p, fontfamily="monospace")
    py -= 0.04
pyplot.savefig("lp_2notch3.png")
if quiet:
    pyplot.clf()
else:
    pyplot.show()

print("")
bb = "gain(DC) = %8.5f%+8.5fj"
print((bb+"  s-domain") % (As[npt].real, As[npt].imag))
print((bb+"  z-domain") % (Az[npt].real, Az[npt].imag))
print((bb+"  z-domain piped") % (Azz[npt].real, Azz[npt].imag))

# z implementation has some challenges:
#  1/(z-zp) becomes
#  y_new = y_old*zp + x
# and if zp is complex (as in zbp), and both x and y are complex
# (that's a given), there's a complex multiply-add to perform in a
# single cycle.  Well, presumably at least two cycles if real and
# imaginary components are multiplexed as I'm wont to do.  Comments
# in lp.v confirm 2 is the right factor in the expression above for T.
# Ignores simple additional pipeline delay (four cycles?).
