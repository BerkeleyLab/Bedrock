# Digital PLL simulation / analysis
# digital time detect between PPS input and divider, DAC output to VCXO
import numpy as np
from matplotlib import pyplot
from scipy import signal
fir_enable = True


def getTransfer(z, clk_freq=125.0e6, dac_dw=16, vcxo_ppm=14, Kp=-8, Ki=-1):
    # 125 MHz * 1 second * 14 ppm / 65535 counts
    A = clk_freq*vcxo_ppm*(1.0e-6)/(1 << dac_dw)  # phase counts / DAC counts
    # Kp = -8  # DAC counts / phase counts
    # Ki = -1  # DAC counts / phase counts / cycle

    zi = 1/z

    g1 = A * zi / (1-zi)        # plant
    g2 = Kp + Ki * zi / (1-zi)  # controller
    if fir_enable:
        g2 *= 0.5 * (1+zi)   # FIR filter

    g_df = g1 / (1 - g1*g2)  # phase response to VCXO noise
    g_dp = 1 / (1 - g1*g2)   # phase response to phase measurement noise

    # Processing that equation analytically can convert those expressions into
    # the canonical ratio-of-z-polynomial form.  That's helpful for checking
    # stability, and for using scipy.signal.lfilter().
    # Both the above expressions have the same poles, and
    # zeros of the denominator of 1/(1-g1*g2) represent those poles.
    # Here I use maxima.
    #
    # Without the FIR filter:
    #   g1: A * zi / (1-zi);
    #   g2: Kp + Ki * zi / (1-zi);
    #   g: ratsimp(1/(1-g1*g2));
    #   num(g);  denom(g);
    #   denom(ratsimp((1/(1-g1*g2))));
    # hand-formatted result:
    #   1 + z^{-1}*(-2-Kp*A) + z^{-2}*(1+Kp*A-Ki*A)
    # Repeat with the FIR filter:
    #   g1: A * zi / (1-zi);
    #   g2: (Kp + Ki * zi / (1-zi))*(1+zi)/2;
    #   g: ratsimp(1/(1-g1*g2));
    #   num(g);  denom(g);
    # hand-formatted result:
    #   2 + z^{-1}*(-4-Kp*A) + z^{-2}*(2-Ki*A) + z^{-3}*(Kp*A-Ki*A)
    # Express those numerators and denomenators as polynomials in z:
    npoly = np.array([1, -2, 1])
    if fir_enable:
        dpoly = [1, -2-0.5*Kp*A, 1-0.5*Ki*A, 0.5*A*(Kp-Ki)]
    else:
        dpoly = [1, (-2-Kp*A), (1+Kp*A-Ki*A)]
    dpoly = np.array(dpoly)

    # Print the result, find the roots (poles) numerically, and see if
    # any of those roots are outside the unit circle, representing instability.
    np.set_printoptions(precision=4, floatmode="fixed", suppress=False)
    print("Denominator coefficients", dpoly)
    rr = np.roots(dpoly)
    print("Roots", rr)
    print("Root mags", abs(rr))
    if all(abs(rr) < 1.0):
        print("Stable!  :-)")
    else:
        print("Unstable!  :-(")

    return (g_df, g_dp, A, npoly, dpoly)


def plotTransfer(f, g_df, g_dp, g_dp2, A):
    pyplot.plot(f, abs(g_df)/A, label='df')
    pyplot.plot(f, abs(g_dp), label='dp')
    pyplot.plot(f, abs(g_dp2), label='dp2')
    pyplot.legend(frameon=False)
    pyplot.xlabel("Frequency (Hz)")
    pyplot.ylabel("Gain")
    pyplot.show()
    return


# span is in Hz
def genTransferPlot(npt=500, span=0.5, vcxo_ppm=14):
    f = (np.arange(1, npt)/npt) * span
    T = 1  # second, sample rate
    z = np.exp(2*np.pi*f*T*1j)
    zi = 1/z
    g_df, g_dp, A, npoly, dpoly = getTransfer(z, vcxo_ppm=vcxo_ppm)
    #
    # Quick evaluation of the canonical polynomial form.
    # If our symbolic math was done correctly,
    # it (g_dp2) should match the direct numerical calculation (g_dp).
    g_dp2 = np.polyval(npoly, zi) / np.polyval(dpoly, zi)
    plotTransfer(f, g_df, g_dp, g_dp2, A)
    return (npoly, dpoly)


def genTimeDomain(polys, data_file=None, label="computed"):
    npoly, dpoly = polys
    x_input = 100*[1]  # unit step input (relative to zero initial condition)
    y = signal.lfilter(npoly, dpoly, x_input)
    pyplot.plot(y, label=label)
    if data_file is not None:
        measurement = np.loadtxt(data_file).transpose()
        y = measurement[0]  # DAC (frequency) value
        # normalize, assuming measurement has reached equilibrium at its end
        y = y - y[-1]
        y = y / y[0]
        pyplot.plot(y, label='measured (normalized) DAC')
    pyplot.xlabel("time (s)")
    pyplot.legend()
    pyplot.show()


if __name__ == "__main__":
    from sys import argv
    vcxo_ppm = 18.2
    polys = genTransferPlot(vcxo_ppm=vcxo_ppm)
    data_file = None
    if len(argv) > 1:
        data_file = argv[1]
    label = "Computed for %.1f ppm VCXO" % vcxo_ppm
    genTimeDomain(polys, label=label, data_file=data_file)
