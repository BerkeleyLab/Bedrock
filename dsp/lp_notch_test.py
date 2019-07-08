# Also see doc/lp_notch.m

import numpy
from numpy import exp, pi
from subprocess import call


class lp_setup:
    " Setup low-pass filter in lp.v "

    def __init__(
            self,
            pole=0.93,  # dimensionless Z-plane pole location
            gain=1.0):  # peak gain, complex number is OK
        self.gain = gain
        self.pole = pole

    def response(self, z):
        # exp(-2*pi*1j*self.notch*self.T)
        zn = self.pole / abs(self.pole)
        # print "zn reconstructed", zn
        # return self.gain * (zn-self.pole) / (z-self.pole)
        return self.gain * (zn - self.pole) / (z - 1 - (self.pole - 1) / z)

    def dsp(self):
        " Convert abstract setup to complex kx, ky "
        zn = self.pole / abs(self.pole)
        num = self.gain * (zn - self.pole)
        pm1 = self.pole - 1.0
        return num, pm1

    def integers(self):
        " Convert abstract setup to specific lp.v hardware register values "
        # zn = self.pole / abs(self.pole)
        # num = self.gain * (zn-self.pole)
        # pm1 = self.pole - 1.0
        kx, ky = self.dsp()
        scale = 2**19
        kxr = int(scale * kx.real)
        kxi = int(scale * kx.imag)
        kyr = int(scale * ky.real)
        kyi = int(scale * ky.imag)
        mv = 2**17 - 1
        if abs(kxr) > mv or abs(kxi) > mv or abs(kyr) > mv or abs(kyi) > mv:
            printme = [kxr, kxi, kyr, kyi]
            print("Overflow!" + "".join([" %d" % r for r in printme]))
            return None
        return [kxr, kxi], [kyr, kyi]

    def dict(self, base):
        ivals = self.integers()
        return {base + 'kx': ivals[0], base + 'ky': ivals[1]}


class notch_setup:
    " Setup low-pass and notch filters in lp.v and lp_notch.v "

    def __init__(
            self,
            f_clk=1320e6 / 14.0,  # LCLS-II LLRF
            bw=300e3,  # Hz bandwidth of low-pass filter
            offset=0,  # Hz offset of low-pass filter
            notch=None,  # Hz offset of notch, sign flipped
            gain=1.0):
        self.f_clk = f_clk
        self.bw = bw
        self.offset = offset
        self.notch = notch
        self.gain = gain
        self.T = 2.0 / self.f_clk  # processing rate of IQ pairs
        # self.T = 4/102.143e6  # fake for lp_notch.m compatibility
        # dimensionless Z-plane pole location
        zlp = exp(2 * pi * (-self.bw + 1j * self.offset) * self.T)
        self.cl_lp = lp_setup(pole=zlp, gain=self.gain)
        if self.notch is not None:
            zbp = exp(-2 * pi *
                      (self.bw + 1j * self.notch) * self.T)  # pole position
            # set up two reference filters with unity gain
            cl0_lp = lp_setup(pole=zlp, gain=1.0)
            cl0_bp = lp_setup(pole=zbp, gain=1.0)
            # evaluate their gains at DC
            Alp_dc = cl0_lp.response(1.0)
            Abp_dc = cl0_bp.response(1.0)
            # evaluate their gains at the notch frequency
            zn = exp(
                -2 * pi * 1j * self.notch * self.T)  # z at notch frequency
            Alp_zn = cl0_lp.response(zn)
            Abp_zn = cl0_bp.response(zn)
            # solve for the final gains
            mat = numpy.array([[Alp_dc, Abp_dc], [Alp_zn, Abp_zn]])
            target_gains = numpy.array([[self.gain], [0]])
            raw_gains = numpy.linalg.inv(mat).dot(target_gains)
            # prevent the low-pass component from clipping
            if abs(raw_gains[0]) > 0.99:
                raw_gains = raw_gains * 0.99 / abs(raw_gains[0])
            lp_gain, bp_gain = raw_gains
            # create new filters with the right gains
            self.cl_lp = lp_setup(pole=zlp, gain=lp_gain)
            self.cl_bp = lp_setup(pole=zbp, gain=bp_gain)

    def response(self, z):  # z should be dimensionless numpy array
        A = self.cl_lp.response(z)
        if self.notch is not None:
            Afz = self.cl_bp.response(z)
            A = A + Afz
        return A

    # confidence-building
    def plot(self, f):  # f should be numpy array in MHz
        z = exp(2 * pi * 1j * f * 1e6 * self.T)
        A = self.response(z)
        from matplotlib import pyplot
        pyplot.plot(f, numpy.abs(A))
        pyplot.xlabel('f (MHz)')
        pyplot.ylabel('Gain')
        pyplot.title('Notch filter frequency response')
        pyplot.show()

    def integers(self):
        lpa = self.cl_lp.integers()
        lpb = ([0, 0], [-20000, 0])
        if self.notch is not None:
            lpb = self.cl_bp.integers()
        return lpa, lpb

    def dict(self, base, lp_leaf="lpa_", notch_leaf="lpb_"):
        d1 = self.cl_lp.dict(base + lp_leaf)
        if self.notch is not None:
            d1.update(self.cl_bp.dict(base + notch_leaf))
        return d1


def lp_run(ns):
    regs = ns.integers()
    command = 'vvp -N lp_tb +out_file=notch_test.dat'
    lpa = regs[0]
    command += ' +kxr=%d +kxi=%d' % (lpa[0][0], lpa[0][1])
    command += ' +kyr=%d +kyi=%d' % (lpa[1][0], lpa[1][1])
    print(command)
    return_code = call(command, shell=True)
    if return_code != 0:
        print("vvp return_code %d" % return_code)
        print("FAIL")
        exit(1)
    a = numpy.loadtxt('notch_test.dat').T
    return a


def notch_run(ns, dth=0.0):
    regs = ns.integers()
    command = 'vvp -N lp_notch_tb +out_file=notch_test.dat'
    command += ' +dth=%f' % dth
    lpa = regs[0]
    command += ' +kaxr=%d +kaxi=%d' % (lpa[0][0], lpa[0][1])
    command += ' +kayr=%d +kayi=%d' % (lpa[1][0], lpa[1][1])
    lpb = regs[1]
    command += ' +kbxr=%d +kbxi=%d' % (lpb[0][0], lpb[0][1])
    command += ' +kbyr=%d +kbyi=%d' % (lpb[1][0], lpb[1][1])
    print(command)
    return_code = call(command, shell=True)
    if return_code != 0:
        print("vvp return_code %d" % return_code)
        print("FAIL")
        exit(1)
    a = numpy.loadtxt('notch_test.dat').T
    return a


def check_lp(a, bw, dsp, stim_amp=20000, offset=0, plot=False):
    " Returns True for OK, False for failure "
    if offset == 0 and max(abs(a[3])) != 0:
        print("Problem")
    sim_real = [a[2][ix] for ix in range(6, 106)]
    sim_imag = [a[3][ix] for ix in range(6, 106)]
    sim_z = numpy.array(sim_real) + 1j * numpy.array(sim_imag)
    dt = 2 * 14 / 1320e6
    t = numpy.arange(100) * dt
    s_theory = stim_amp * (
        1 - exp(-t * bw * 2 * pi)) * exp(t * 2 * pi * 1j * offset)
    kx, ky = dsp
    a = [kx, 0]
    b = [1, -1, -ky]
    z0 = exp(2 * pi * 1j * offset * dt)
    g0 = numpy.polyval(a, z0) / numpy.polyval(b, z0)
    print("Gain at %.0f Hz = %.5f" % (offset, abs(g0)))
    stim = (t >= dt) * stim_amp * exp(2 * pi * 1j * offset * (t + dt * 2))
    from scipy import signal
    z_theory = signal.lfilter(a, b, stim)
    rms = numpy.sqrt(numpy.mean(numpy.square(abs(sim_z - z_theory))))
    # error caused by quantization of coefficients and intermediate results
    print("Low-pass simulation error %.2f rms out of %.0f" % (rms, stim_amp))
    lp_ok = rms < 20.0
    if not lp_ok:
        print("Error too big!")
    if plot:
        from matplotlib import pyplot
        if True:
            pyplot.plot(t * 1e6, sim_real, label="Verilog")
            pyplot.plot(t * 1e6, s_theory.real, label="s-plane nominal")
            pyplot.plot(t * 1e6, z_theory.real, label="z-plane exact")
        if True and offset != 0:
            pyplot.plot(t * 1e6, sim_imag, label="Verilog imag")
            pyplot.plot(t * 1e6, s_theory.imag, label="s-plane nominal")
            pyplot.plot(t * 1e6, z_theory.imag, label="z-plane exact")
        if False and offset != 0:
            pyplot.plot(t * 1e6, abs(sim_z), label="Verilog imag")
            pyplot.plot(t * 1e6, abs(s_theory), label="s-plane nominal")
            pyplot.plot(t * 1e6, abs(z_theory), label="z-plane exact")
        pyplot.legend(loc='lower right', frameon=False)
        pyplot.xlabel(u't (\u03BCs)')
        pyplot.ylabel('Response')
        pyplot.xlim([0, max(t) * 1e6])
        msg = 'PASS' if lp_ok else 'FAIL'
        pyplot.title('Low-pass response check: ' + msg)
        pyplot.show()
    return lp_ok


if __name__ == "__main__":
    import sys
    plot = len(sys.argv) > 1 and sys.argv[1] == "plot"
    if not plot:
        me = sys.argv[0]
        print(me + " testing for regressions only; plot option is available")
    dt = 2 * 14 / 1320e6
    bw = 300e3
    if True:
        offset1 = 0
        ns = notch_setup(bw=bw, offset=offset1)
        dth = offset1 * 2 * pi * dt
        a = notch_run(ns, dth=dth)
        lp_ok = check_lp(
            a=a,
            bw=bw,
            dsp=ns.cl_lp.dsp(),
            stim_amp=4 * 20000,
            offset=offset1,
            plot=plot)
    notchf = -800e3
    print("Testing notch filter setup for %.1f kHz offset" % (notchf * 0.001))
    ns = notch_setup(bw=bw, notch=notchf)
    dc_gain = ns.response(1.0)
    gain_ok = 0.9 < dc_gain.real < 1.0 and abs(dc_gain.imag) < 0.0002
    print("DC gain %.4f%+.4fj" % (dc_gain.real, dc_gain.imag))
    zn = exp(-2 * pi * 1j * notchf * dt)  # z at notch frequency
    notch_gain = ns.response(zn)
    gain_ok = gain_ok and abs(notch_gain) < 0.0002
    if not gain_ok:
        print("Gains flunk self-test")
    print("Notch gain %.4f%+.4fj" % (notch_gain.real, notch_gain.imag))
    if plot:
        f = numpy.arange(-3.0, +3.0, 0.01)  # MHz for plot
        ns.plot(f)
    regs = ns.integers()
    if True:
        print("values for hardware: lpa_kx lpa_ky lpb_kx lpb_ky")
        print(regs)
    else:
        print(ns.dict("shell_0_dsp_lp_notch_"))
    dth = -notchf * 2 * pi * dt
    a = notch_run(ns, dth=dth)
    dt = 2 * 14 / 1320e6
    t = numpy.arange(len(a[2])) * dt
    resp_z = numpy.array(a[2]) + 1j * numpy.array(a[3])
    p1 = max(abs(resp_z[6:106]))
    p2 = max(abs(resp_z[256:306]))
    notch_ok = p1 > 25000 and p2 < 40
    msg = "" if notch_ok else "  FAULT"
    print("Transient max %.0f  Settled max %.0f%s" % (p1, p2, msg))
    if plot:
        from matplotlib import pyplot
        pyplot.plot(t * 1e6, a[2], label='Real')
        pyplot.plot(t * 1e6, a[3], label='Imag')
        pyplot.legend(loc='upper right', frameon=False)
        pyplot.xlabel(u't (\u03BCs)')
        pyplot.ylabel('Response')
        pyplot.xlim([0, max(t) * 1e6])
        msg = 'PASS' if notch_ok else 'FAIL'
        pyplot.title('Notch filter time-domain check: ' + msg)
        pyplot.show()
    tests_pass = lp_ok and gain_ok and notch_ok
    print("PASS" if tests_pass else "FAIL")
    exit(0 if tests_pass else 1)
