import numpy
import matplotlib.pyplot as plt
import sys

if len(sys.argv) == 1:
    print('Using cryomodule_p.dat as the input file')
    fname = 'cryomodule_p.dat'
elif len(sys.argv) != 2:
    print('Usage: python verify_cryomodule.py <cryomodule_p.dat>')
    exit()
else:
    fname = sys.argv[1].strip()

data = numpy.loadtxt(fname)
d1 = (data[:,0]**2 + data[:,1]**2)**0.5
d2 = (data[:,2]**2 + data[:,3]**2)**0.5
d3 = (data[:,4]**2 + data[:,5]**2)**0.5
plt.plot(d1)
plt.plot(d2)
plt.plot(d3)
plt.show()
