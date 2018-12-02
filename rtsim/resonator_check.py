import numpy
from scipy import signal
import matplotlib
matplotlib.use('Agg')
from matplotlib import pyplot

# Style might look a little weird
# It's (almost) a line-by-line transcription of a .m file

d = numpy.loadtxt('resonator.dat')
npt = len(d)
d = d.transpose()
z = d[0] + 1j*d[1]

# register settings, copied from resonator_tb.v
init_reg = 100000000 + 50000000j
init_reg = 100000000
drive_reg = 0 + 1000j
a_reg = -80000 + 120000j
scale_reg = 7

# abstract values
init = init_reg*0.5**18
drive = drive_reg/16.0  # XXX depends on scale_reg
a = 1+a_reg*0.5**17*0.5**18*4**scale_reg
# now z*v = a*v + drive
print('a = %g%+gj' % (a.real, a.imag))

# in equilibrium, v=drive/(1-a)
term = drive/(1.0-a)
# should be about -756 + 503i;

zz = z-term
r = numpy.mean(zz[1:50]/zz[0:50-1])
# and this checks, a \approx r
print('r = %g%+gj' % (r.real, r.imag))

# direct model, matches except for roundoff errors?
filt_drive = numpy.arange(npt)*0+drive
filt_ic = [init*a]
sim, final = signal.lfilter([1.0], [1.0, -a], filt_drive, zi=filt_ic)

pyplot.plot(z.real, z.imag, label='Simulated resonator.v')
pyplot.plot(sim.real, sim.imag, label='Scipy lfilter()')
pyplot.plot(term.real, term.imag, '+')
pyplot.legend()
pyplot.axis('square')
pyplot.axis(numpy.array([-1, 1, -1, 1])*1000)
pyplot.title('1 of m mechanical modes, response to DC drive')
pyplot.savefig('resonator_check.png')

err = numpy.std(z-sim, ddof=1)
print('err = %g' % err)
if abs(err) > 0.6:
    print('FAIL')
    exit(1)
else:
    print('PASS')
