from matplotlib import pyplot
import numpy

d = numpy.loadtxt('perf.dat').transpose()

pyplot.plot(d[2], d[3], '-o', label='P to R peak')
pyplot.plot(d[2], d[4], '-o', label='P to R rms')
pyplot.plot(d[2], d[5], '-o', label='R to P peak')
pyplot.plot(d[2], d[6], '-o', label='R to P rms')
pyplot.xlim(min(d[2]), max(d[2]))
pyplot.ylim(0, None)
pyplot.legend(frameon=False)
pyplot.title('CORDIC performance for 18 bit data and 20 stages')
pyplot.xlabel('CORDIC accumulator bit width')
pyplot.ylabel('bits error')
# pyplot.show()
pyplot.savefig('perf.png')
