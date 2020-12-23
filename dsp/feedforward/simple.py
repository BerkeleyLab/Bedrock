import numpy as np
from numpy import exp
from matplotlib import pyplot


def quad_setup(tfill):
    # kc[0]*(tfill**2 - 2*tfill + 2 - 2*exp(-tfill)) + kc[2]*(1 - exp(-t))
    #  = kc[2] + kc[0]*tfill**2
    # assume WLOG that kc[2] = 1
    # kc[0]*(-2*tfill + 2 - 2*exp(-tfill)) + (-exp(-tfill)) = 0
    # kc[0] = exp(-tfill) / (-2*tfill + 2 -2*exp(-tfill))
    emt = exp(-tfill)
    den = 2 * (1 - tfill - emt)
    kc0 = emt/den
    cav0 = 1 + kc0*tfill**2
    return kc0, cav0


def quad_curves(t, kc):
    # cries out for generalization; until then, kc must be length 3
    emt = exp(-t)
    ff0 = 1 - emt
    ff1 = t - 1 + emt
    ff2 = t**2 - 2*t + 2 - 2*emt
    drv = np.polyval(kc, t)
    cav = kc[2]*ff0 + kc[1]*ff1 + kc[0]*ff2
    return drv, cav


if __name__ == "__main__":
    # real-life periodicity 2048*2*255*33*14/1320e6
    # = 0.36557 s = 36 time constants
    dt = 0.002  # time constants
    t_fill = 1.728  # in units of time constants
    pe = 1  # plot exponent, presumably 1 or 2
    gap = 1.0
    t_set = np.array([])
    drv_set = np.array([])
    cav_set = np.array([])
    #
    # fill
    npt = int(t_fill / dt)
    t = dt * np.arange(npt)
    kc0, cav0 = quad_setup(t_fill)
    fmt = "t_fill = %.4f  quad. coeff. = %.4f  equilib = %.4f"
    print(fmt % (t_fill, kc0, cav0))
    kc = np.array([kc0, 0.0, 1.0])
    kc = kc / cav0
    drv, cav = quad_curves(t, kc)
    t_plot = t
    pyplot.plot(t_plot, drv**pe, label="drive")
    pyplot.plot(t_plot, cav**pe, label="cavity")
    pyplot.plot(t_fill, 1.0, 'o', color="gray")
    t_set = np.append(t_set, t_plot)
    drv_set = np.append(drv_set, drv)
    cav_set = np.append(cav_set, cav)
    #
    # flat top
    npt = int(gap / dt)
    t = dt * np.arange(npt)
    drv = t * 0 + 1.0
    cav = drv
    t_plot = t_fill + t
    pyplot.plot(t_plot, drv**pe, label="drive")
    pyplot.plot(t_plot, cav**pe, label="cavity")
    pyplot.plot(t_plot[-1], 1.0, 'o', color="gray")
    t_set = np.append(t_set, t_plot)
    drv_set = np.append(drv_set, drv)
    cav_set = np.append(cav_set, cav)
    #
    # trailing edge
    slp = 2*kc0/cav0*t_fill
    t_ramp = -1.0/slp
    npt = int(t_ramp / dt)
    t = dt * np.arange(npt)
    kc = np.array([0, slp, 1.0])
    drv, cav = quad_curves(t, kc)
    cav = cav + exp(-t)
    t_plot = t_fill + gap + t
    pyplot.plot(t_plot, drv**pe, label="drive")
    pyplot.plot(t_plot, cav**pe, label="cavity")
    v_trail = cav[-1]
    print("trailing ramp time = %.4f  end voltage = %.4f" % (t_ramp, v_trail))
    pyplot.plot(t_plot[-1], v_trail**pe, 'o', color="gray")
    t_set = np.append(t_set, t_plot)
    drv_set = np.append(drv_set, drv)
    cav_set = np.append(cav_set, cav)
    #
    # passive decay
    npt = int(4.0 / dt)
    npt = 8192 - len(t_set)
    t = dt * np.arange(npt)
    drv = t*0
    cav = v_trail * exp(-t)
    t_plot = t_fill + gap + t_ramp + t
    pyplot.plot(t_plot, drv**pe)
    pyplot.plot(t_plot, cav**pe)
    t_set = np.append(t_set, t_plot)
    drv_set = np.append(drv_set, drv)
    cav_set = np.append(cav_set, cav)
    #
    if False:
        print(t_set.shape, drv_set.shape, cav_set.shape)
        pyplot.plot(t_set, cav_set)
    #
    # pyplot.xlim((0, tfill))
    pyplot.legend(frameon=False)
    pyplot.show()
    #
    # pyplot.plot(t_set, cav_set**2)
    # pyplot.show()
    ss = np.fft.fft(cav_set**2)
    npt = len(cav_set)
    # print(npt)
    actual_tau = 0.01  # s
    thermal_len = np.sum(cav_set**2)*dt*actual_tau
    print("thermal len = %.2f ms" % (thermal_len*1000))
    f = np.arange(npt)/float(npt)/(dt*actual_tau)
    if False:
        ssa = abs(ss)
        ssa = ssa / max(ssa)
        pyplot.plot(f, 20*np.log10(ssa), 'x')
        pyplot.xlim((0, 100))
        pyplot.ylim((-55, 5))
        pyplot.xlabel("f (Hz)")
        pyplot.ylabel("Lorentz force (dB)")
        pyplot.show()
