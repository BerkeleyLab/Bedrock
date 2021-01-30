# Digital PLL simulation / analysis
# digital time detect between PPS input and divider, DAC output to VCXO
import numpy as np
from matplotlib import pyplot

# 125 MHz * 17.7 ppm / 65535 counts
A = 0.034  # phase counts / DAC counts
Kp = -8  # DAC counts / phase counts
Ki = -1  # DAC counts / phase counts / cycle

f = np.arange(1, 499)/500.0 * 0.5  # Hz
T = 1  # second, sample rate
z = np.exp(2*np.pi*f*T*1j)
zi = 1/z

g1 = A * zi / (1-zi)
g2 = Kp + Ki * zi / (1-zi)

# g1: A * zi / (1-zi);
# g2: Kp + Ki * zi / (1-zi);
# ratsimp((1-zi)^2*(1-g1*g2));

g_df = g1 / (1 - g1*g2)  # phase response to VCXO noise
g_dp = 1 / (1 - g1*g2)  # phase response to phase measurement noise

# Can also do more of this analytically, find poles of
# 1 + z^{-1}(-2-Kp*A) + z^{-2}(1+Kp*A-Ki*A) ?
dpoly = [1, (-2-Kp*A), (1+Kp*A-Ki*A)]
print("Poly %.3f z^2 + %.3f z + %.3f" % tuple(dpoly))
rr = np.roots(dpoly)
rrp = rr[0].real, rr[0].imag, rr[1].real, rr[1].imag
print("roots %.3f %+.3f i,  %.3f %+.3f i" % rrp)
print("root mags %.3f,  %.3f" % (abs(rr[0]), abs(rr[1])))

den = 1 + zi*(-2-Kp*A) + zi*zi*(1+Kp*A-Ki*A)
den = np.polyval(dpoly, zi)
g_dp2 = (1-zi)**2 / den

pyplot.plot(f, abs(g_df)/A, label='df')
pyplot.plot(f, abs(g_dp), label='dp')
pyplot.plot(f, abs(g_dp2), label='dp2')
pyplot.legend(frameon=False)
pyplot.show()
