import numpy
from numpy import exp, pi
from matplotlib import pyplot

# Style might look a little weird
# It's (almost) a line-by-line transcription of a .m file

d = numpy.loadtxt('cav_mode.dat')
npt = len(d)
d = d.transpose()

den = 33
n2 = int(npt/den)
dt = 14.0/1320  # us
n3 = n2*den
ix = numpy.arange(n3) + 1
t = dt*ix

mr = d[0][0:n3] + 1j*d[1][0:n3]  # multiplier result
st = d[2][0:n3] + 1j*d[3][0:n3]  # state
pr = d[4][0:n3]  # probe reflection
rf = d[5][0:n3]
m2 = d[6][0:n3]  # voltage magnitude squared

lo = exp(-ix*2*pi*1j*7/den)
rx = rf*lo
rxr = numpy.reshape(rx, [n2, den])
rxa = numpy.mean(rxr, 1)
t2 = dt*den*(numpy.arange(n2)+0.5)

kx = numpy.nonzero(t2 > 8)
pp = numpy.polyfit(t2[kx], numpy.angle(rxa[kx]), 1)
detune = pp[0]/(2*pi)
print('phase slope %.2f kHz' % (detune*1e3))

pyplot.plot(t2, rxa.real, label='real')
pyplot.plot(t2, rxa.imag, label='imag')
pyplot.plot(t2, abs(rxa), label='abs')
pyplot.legend()
pyplot.xlabel(u't (\u03bcsec)')
pyplot.title('cav_mode.v pulse response')
pyplot.savefig('cav_check1.png')

pyplot.figure(2)
pyplot.plot(t2, numpy.angle(rxa), label='phase simulated')
ss = 'phase fit, slope %.2f kHz' % (detune*1e3)
pyplot.plot(t2[kx], numpy.polyval(pp, t2[kx]), label=ss)
pyplot.legend()
pyplot.xlabel(u't (\u03bcsec)')
pyplot.ylabel('radians')
pyplot.savefig('cav_check2.png')

mech_freq = 2000000  # pasted from cav_mode_tb.v
detune_theory = -mech_freq/(2**32*dt)  # XXX negative is ugly
err = detune/detune_theory-1
print('err = %g' % err)
if abs(err) > 0.004:
    print('FAIL')
    exit(1)
else:
    print('PASS')
