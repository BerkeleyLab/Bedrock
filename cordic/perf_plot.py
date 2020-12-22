from matplotlib import pyplot
import numpy

d = numpy.loadtxt('perf.dat').transpose()

bw = d[2]
pyplot.plot(bw, d[3], '-o', label='P to R peak')
pyplot.plot(bw, d[4], '-o', label='P to R rms')
pyplot.plot(bw, d[5], '-o', label='R to P peak')
pyplot.plot(bw, d[6], '-o', label='R to P rms')

thresh_peak = 1.0 + 2**(21-bw)
thresh_rms = 0.4 + 2**(18.5-bw)
fail = \
    any(d[3] > thresh_peak) or \
    any(d[4] > thresh_rms) or \
    any(d[5] > thresh_peak) or \
    any(d[6] > thresh_rms)
# Don't clutter up the plot if all is well,
# but do show the thresholds if something broke.
if fail:
    pyplot.plot(bw, thresh_rms, '-')
    pyplot.plot(bw, thresh_peak, '-')

pyplot.xlim(min(bw), max(bw))
pyplot.ylim(0, None)
pyplot.legend(frameon=False)
pyplot.title('CORDIC performance for 18 bit data and 20 stages')
pyplot.xlabel('CORDIC accumulator bit width')
pyplot.ylabel('bits error')
# pyplot.show()
pyplot.savefig('perf.png')
if fail:
    print("FAIL")
    exit(1)
else:
    print("PASS")
