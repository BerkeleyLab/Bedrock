#!/usr/bin/python
from numpy import sqrt, pi, exp, real, imag, conj
from sys import stderr

RoverQ = 1036  # Ohms
omega0 = 2*pi*1300e6  # /s
Q1 = 4e7  # unitless
Q0 = 2e10  # unitless
omegad = 2*pi*5  # /s
i = 0+1j
a = i*omegad - 0.5*omega0*(1/Q0 + 1/Q1)
b = omega0*sqrt(RoverQ/Q1)

# Baseline in honest SI units
K = sqrt(1600)*exp(-i*0.2)
# At the moment this only works for V in the range 0.5*cv to 1.0*cv;
# maybe I should fuss with the dynamic range of 1/x
# V = sqrt(Q1*RoverQ)*2*K  # equilibrium, not counting Q0 or omegad
V = 15.8e6*exp(i*0.1)
dVdt = a*V + b*K
R = V/sqrt(Q1*RoverQ) - K
dUdt = 2*real(V*conj(dVdt))/omega0/RoverQ
print("# SRF cavity initial setup")
print("# a = %.3f%+.3fj /s   b = %.3f sqrt(Ohm)/s" % (a.real, a.imag, b))
print("# V = %.0f%+.0fj V   dVdt = %.0f%+.0fj V/s" % (V.real, V.imag, dVdt.real, dVdt.imag))
print("# K = %.3f%+.3fj   R = %.3f%+.3fj" % (K.real, K.imag, R.real, R.imag))
print("# dU/dt = %.3f W   Pemit = %.3f W" % (dUdt, abs(V)**2/(Q1*RoverQ)))

# add "random" cable lengths
if 1:
    rot_V = exp(i*0.8)
    rot_R = exp(i*2.4)
    rot_K = exp(i*1.1)
    V = V * rot_V
    dVdt = dVdt * rot_V
    R = R * rot_R
    K = K * rot_K
    b = b / rot_K * rot_V

# Scaling to hardware
cv = 22e6  # Volts full-scale
ck = sqrt(4400)  # sqrt(W) full-scale forward
cr = sqrt(7100)  # sqrt(W) full-scale reverse
beta = b*(ck/cv)  # /s
fs = 2**17  # full-scale for an 18-bit signed register
fq = 0.010  # Hz frequency quantum
ffs = fq*fs*2*pi  # s^{-1} full-scale
print("# beta = %.2f%+.2fj /s   beta/ffs = %.4f%+.4fj" % (beta.real, beta.imag, beta.real/ffs, beta.imag/ffs))

a = (dVdt - b*K)/V  # desired result in s^{-1}
ai = a/ffs*fs*16  # 22 bit internal vs. 18 bit external; see parameter extra in sf_main.v
wave_samp_per = 32  # or equivalent
use_hb = 0
T = wave_samp_per*(use_hb+1)*33*14/1320.0e6  # s time interval between loop iterations
fir_gain = 80  # prescale on dV/dt, see FIR filter comments in cgen_srf.py
v_series = [(V-tx*T*dVdt)/cv*fs for tx in range(5)]

# x5 = conj(cv/V)/8
# print("# conj(1/v) (x5) %f+%f" % (x5.real, x5.imag))
print("#")
print("# %.3f us time step (T)" % (T*1e6))
print("# %.2f /s frequency full-scale" % ffs)
print("# Time history of V for loading into persistent state registers")
for vx in range(1, len(v_series)):
    vp = v_series[vx]*16  # 22-bit internal, vs. 18-bit I/O
    print("# v%d = %.0f%+.0fj" % (vx, vp.real, vp.imag))

# print "# scaled dVdT (dvdt)", dVdt/ffs/cv*2
print("#")
print("# # (scaled)     SI   analog state equation")
print("# (%+8.5f)  %9.2f  MV    Re(V) (v_r)" % (V.real/cv, V.real*1e-6))
print("# (%+8.5f)  %9.2f  MV    Im(V) (v_i)" % (V.imag/cv, V.imag*1e-6))
print("# (%+8.5f)  %9.2f  MV/s  Re(dV/dt) (dvdt_r)" % (dVdt.real/ffs/cv*2, dVdt.real*1e-6))
print("# (%+8.5f)  %9.2f  MV/s  Im(dV/dt) (dvdt_i)" % (dVdt.imag/ffs/cv*2, dVdt.imag*1e-6))
drive_product = (b*K) / ffs / cv * 2
print("# (%+8.5f)  %9.2f  MV/s  Re(b*K) (x3_r)" % (drive_product.real, (b*K*1e-6).real))
print("# (%+8.5f)  %9.2f  MV/s  Im(b*K) (x3_i)" % (drive_product.imag, (b*K*1e-6).imag))
rate_diff = (dVdt - b*K) / ffs / cv * 4
print("# (%+8.5f)  %9.2f  MV/s  Re(difference) (x4_r)" % (rate_diff.real, ((dVdt - b*K)*1e-6).real))
print("# (%+8.5f)  %9.2f  MV/s  Im(difference) (x4_i)" % (rate_diff.imag, ((dVdt - b*K)*1e-6).imag))
# print "# difference (x4)", dVdt/ffs/cv*2 - b*K/ffs/cv*2
# print "# SI final", a
# print "# normalized final", a/ffs
# print "# integer final", int(real(ai)), int(imag(ai))

print("# (%+8.5f)  %9.2f  /s  Re(a)  (a_r)" % (a.real/ffs, a.real))
print("# (%+8.5f)  %9.2f  /s  Im(a)  (a_i)" % (a.imag/ffs, a.imag))
print("# where  difference = dV/dt - b*K  and  a = difference / V")
print("#")

# At one point we planned to send delta-V to the computer, rather than
# let it compute differences.  Instead we are now set up to figure the
# differences in the computer with a [-2 -1 0 1 2] FIR, with zero extra
# hardware footrpint.

sclv = 2*cv*cv/(T*fir_gain)/omega0/RoverQ
sclf = ck**2
sclr = cr**2
print("# Full scale power values in SI")
print("# %8.1f W  sclv" % sclv)
print("# %8.1f W  sclf" % sclf)
print("# %8.1f W  sclr" % sclr)
# Any output unit is a good output unit, if all the terms use it
maxscale = max(sclf, sclr) * 1.0001
print("# Full scale power values in internal units of %.1f W" % maxscale)
sclv = sclv / maxscale
sclf = sclf / maxscale
sclr = sclr / maxscale
print("# %8.4f    sclv" % sclv)
print("# %8.4f    sclf" % sclf)
print("# %8.4f    sclr" % sclr)

net = abs(K)**2 - abs(R)**2 - dUdt
print("# # (scaled)   SI Power balance")
print("# (%+8.5f)  %6.1f W  Forward (powf)" % (abs(K)**2/maxscale, abs(K)**2))
print("# (%+8.5f)  %6.1f W  Reverse (powr)" % (abs(R)**2/maxscale, abs(R)**2))
print("# (%+8.5f)  %6.1f W  dU/dt (dudt)" % (dUdt/maxscale, dUdt))
print("# (%+8.5f)  %6.1f W  net absorbed (diss)" % (net/maxscale, net))

# allowed cavity dissipation and/or measurement error tolerance
diss_allow = 30  # Watts
powt = diss_allow / maxscale

m_v = V/cv
m_k = K/ck
m_r = R/cr
m_dv = dVdt * (T*fir_gain)/cv


def xprint(key, ix, x):
    xi = int(x*fs+0.5)
    if xi >= fs or xi < -fs:
        stderr.write("Overflow in setup: %s %d %.4f\n" % (key, ix, x))
        exit(1)
    print("%s %s %d" % (key, ix, xi))


print("#")
print("# Persistent state initialization")
print("# Symbolic register names will be used by sim1 directly.")
print("# init_xindex.py will convert them to decimal for use by user_tb.")
for vx in range(1, len(v_series)):
    vp = v_series[vx]/fs  # 22-bit internal, vs. 18-bit I/O
    xprint("p", "v%d_r" % vx, vp.real)
    xprint("p", "v%d_i" % vx, vp.imag)

print("#")
print("# Test stream (conveyor belt) values")
xprint("s", 0, real(m_k))
xprint("s", 1, imag(m_k))
xprint("s", 2, real(m_r))
xprint("s", 3, imag(m_r))
xprint("s", 4, real(m_v))
xprint("s", 5, imag(m_v))

print("#")
print("# values for host loading")
xprint("h", 0, beta.real/ffs)
xprint("h", 1, beta.imag/ffs)
xprint("h", 2, 1/(T*fir_gain)/ffs)  # invT
xprint("h", 3, 1/16.0)  # "two" supports inverse function
# next three set scaling of the power-balance code
xprint("h", 4, sclr)
xprint("h", 5, sclf)
xprint("h", 6, sclv/32)  # put in a factor of 4 with barrel shifter
xprint("h", 7, powt)
