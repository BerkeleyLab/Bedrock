# quick display of the results of "make parab.out"
import numpy as np
from matplotlib import pyplot

d = np.loadtxt('parab.out')
p = d.transpose()[0]
a = d.transpose()[1]
dp = np.array([x+1024*1024 if x < 0 else x for x in np.diff(p)])
am = np.array(a[:-1])

ascale = 0.005
fscale = 0.5**20 * 10000
dt = 1.0/10000.0
t = dt * np.arange(len(dp))
pyplot.plot(t, dp*fscale, label='f (Hz)')
pyplot.plot(t, am*ascale, label='amp (%)')
pyplot.ylim(0, 270)
pyplot.xlabel('Time (s)')
pyplot.legend(loc="upper left", frameon=False)
# pyplot.savefig("chirp.png")
pyplot.show()
