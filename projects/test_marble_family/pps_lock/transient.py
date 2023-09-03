# Digital PLL simulation / analysis
# digital time detect between PPS input and divider, DAC output to VCXO
import numpy as np
from matplotlib import pyplot
fir_enable = True

# 125 MHz * 1 second * 14 ppm / 65535 counts
A = 0.028  # phase counts / DAC counts
Kp = -8  # DAC counts / phase counts
Ki = -1  # DAC counts / phase counts / cycle

f = np.arange(1, 499)/500.0 * 0.5  # Hz
T = 1  # second, sample rate
z = np.exp(2*np.pi*f*T*1j)
zi = 1/z

g1 = A * zi / (1-zi)        # plant
g2 = Kp + Ki * zi / (1-zi)  # controller
if fir_enable:
    g2 *= 0.5 * (1+zi)   # FIR filter

g_df = g1 / (1 - g1*g2)  # phase response to VCXO noise
g_dp = 1 / (1 - g1*g2)   # phase response to phase measurement noise

# Can also process this analytically.
# Without the FIR filter, use maxima to find the denominator:
#   g1: A * zi / (1-zi);
#   g2: Kp + Ki * zi / (1-zi);
#   ratsimp((1-zi)^2*(1-g1*g2));
# result:
#   1 + z^{-1}*(-2-Kp*A) + z^{-2}*(1+Kp*A-Ki*A)
# Repeat with the FIR filter:
#   g1: A * zi / (1-zi);
#   g2: (Kp + Ki * zi / (1-zi))*(1+zi)/2;
#   ratsimp((1-zi)^2*(1-g1*g2));
# result:
#   (2 + z^{-1}*(-4-Kp*A) + z^{-2}*(2-Ki*A) + z^{-3}*(Kp*A-Ki*A))/2
# Express that denominator as a polynomial in z:
if fir_enable:
    dpoly = [1, -2-0.5*Kp*A, 1-0.5*Ki*A, 0.5*A*(Kp-Ki)]
else:
    dpoly = [1, (-2-Kp*A), (1+Kp*A-Ki*A)]
dpoly = np.array(dpoly)

np.set_printoptions(precision=4, floatmode="fixed", suppress=False)
print("Poly", dpoly)
rr = np.roots(dpoly)
print("Roots", rr)
print("Root mags", abs(rr))
if all(abs(rr) < 1.0):
    print("Stable!  :-)")
else:
    print("Unstable!  :-(")

# then cross-check numerically
den = np.polyval(dpoly, zi)
g_dp2 = (1-zi)**2 / den

pyplot.plot(f, abs(g_df)/A, label='df')
pyplot.plot(f, abs(g_dp), label='dp')
pyplot.plot(f, abs(g_dp2), label='dp2')
pyplot.legend(frameon=False)
pyplot.show()
