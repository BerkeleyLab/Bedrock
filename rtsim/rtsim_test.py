import numpy as np
from matplotlib import pyplot as plt

A = np.loadtxt('rtsim.dat')

plt.plot(abs(A[:,0] + 1j*A[:,1]), label='cav')
plt.plot(abs(A[:,2] + 1j*A[:,3]), label='fwd')
plt.plot(abs(A[:,4] + 1j*A[:,5]), label='rfl')
plt.legend()
plt.show()
