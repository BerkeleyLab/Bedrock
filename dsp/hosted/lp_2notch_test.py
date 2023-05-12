# Also see lp_2notch_theory.py
# Attempt to make this more modular

import numpy
from numpy import exp, pi
from subprocess import call


class lp_setup:
    " Setup low-pass filter in lp.v "

    def __init__(
            self,
            shift=2,
            datapath=22,  # see comments in integers()
            pole=0.93,  # dimensionless Z-plane pole location
            gain=1.0):  # peak gain, complex number is OK
        self.shift = shift
        self.datapath = datapath
        self.gain = gain
        self.pole = pole

    def response(self, z):
        zn = self.pole / abs(self.pole)
        # print("zn reconstructed", zn)
        ky = self.pole*(self.pole-1.0)
        num = self.gain * (zn - 1 - ky*zn**(-1))
        den = z - 1 - ky*z**(-1)
        return num/den

    def dsp(self):
        " Convert abstract setup to complex kx, ky "
        # z on the unit circle, for center of response
        zn = self.pole / abs(self.pole)
        ky = self.pole*(self.pole-1.0)
        num = self.gain * (zn - 1 - ky*zn**(-1))
        return num, ky

    def integers(self):
        # XXX fix scaling issues while using historical lp_notch.v (sfit=[2,2])
        " Convert abstract setup to specific lp.v hardware register values "
        kx, ky = self.dsp()
        scale_kx = 2**(self.datapath-1)
        scale_ky = 2**(17+self.shift)
        kxr = int(scale_kx * kx.real)
        kxi = int(scale_kx * kx.imag)
        kyr = int(scale_ky * ky.real)
        kyi = int(scale_ky * ky.imag)
        # Maybe hard to think about the scaling of kx register values, but
        # consider the following: if you take lp.v configured with a
        # negative-real 18-bit integer ky, paired with an equal valued
        # positive kx, the response will be a low-pass filter with DC gain
        # of unity, no matter the value of ky and the shift parameter.
        # But by unity, that means full-scale input maps to full-scale output.
        # Now look at the scaling of the outputs for the three lp instances in
        # lp_2notch.v, in the sum = y1+y2+y3 expression, where the three results
        # are lined up by their lsb.  That means their full-scale values are
        # scaled relative to each other by 2**shift.  That effect cancels the
        # 2**shift component in scale_ky.  What's left is effectively the
        # overall 22-bit output word-width of lp_2notch, or 2**21.  Whew.
        # Fortunately we have simulations to verify this analysis.
        # The datapath parameter is here to allow compatibility with the older
        # lp_notch.v, for which you should use datapath=20.

        mv = 2**17 - 1  # max allowed register value
        if abs(kxr) > mv or abs(kxi) > mv or abs(kyr) > mv or abs(kyi) > mv:
            printme = [kxr, kxi, kyr, kyi]
            print("Overflow!" + "".join([" %d" % r for r in printme]))
            return None
        return [kxr, kxi], [kyr, kyi]

    def poles(self):
        kx, ky = self.dsp()
        b = [1, -1, -ky]
        rr = numpy.roots(b)
        ok = all(abs(rr) < 1.0)
        return ok, rr

    def reg_list(self, base):
        ivals = self.integers()
        if ivals is None:
            return None
        rl = [(base + 'kx_0', ivals[0][0]), (base + 'kx_1', ivals[0][1])]
        rl += [(base + 'ky_0', ivals[1][0]), (base + 'ky_1', ivals[1][1])]
        return rl


class notch_setup:
    " Setup low-pass and notch filters in lp_notch.v or lp_2notch.v "

    def __init__(
            self,
            f_clk=1320e6 / 14.0,  # LCLS-II LLRF
            datapath=22,
            shifts=[4, 2, 0],  # hardware config; use [2, 2] for older lp_notch.v
            freqs=[0],     # Hz filter center frequencies
            bws=[300e3],   # Hz filter bandwidths
            targs=[1.0]):   # target gain at the given frequencies
        self.T = 2.0 / f_clk  # processing rate of IQ pairs
        self.bankn = len(freqs)
        self.hwbankn = len(shifts)
        if self.bankn > self.hwbankn:
            print("Bad construction of notch_setup! %d > %d" % (self.bankn, self.hwbankn))
            return None
        ixs = range(len(freqs))
        zcens = [exp(-2 * pi * 1j * freqs[ix] * self.T) for ix in ixs]
        poles = [exp(-2 * pi * (bws[ix] + 1j * freqs[ix]) * self.T) for ix in ixs]
        filts = [lp_setup(datapath=datapath, shift=shifts[ix], pole=poles[ix], gain=1.0) for ix in ixs]
        resps = [filts[ix].response(numpy.array(zcens)) for ix in ixs]
        eq_A = numpy.array(resps).transpose()
        eq_B = numpy.array(targs)
        raw_gains = numpy.linalg.solve(eq_A, eq_B)

        if abs(raw_gains[0]) > 0.9999:
            raw_gains = raw_gains * 0.9999 / abs(raw_gains[0])

        # create new filters with the right gains
        self.filts = [lp_setup(datapath=datapath, shift=shifts[ix], pole=poles[ix], gain=raw_gains[ix]) for ix in ixs]

    def response(self, z):  # z should be dimensionless numpy array
        A = 0*z
        for ix in range(self.bankn):
            A += self.filts[ix].response(z)
        return A

    def check(self):
        ok = True
        if self.bankn > 1:
            ok1, ps = self.filts[1].poles()
            if self.bankn > 2:
                ok2, ps2 = self.filts[2].poles()
                if not (ok1 and ok2):
                    print("Notch1 pole positions: ", ps)
                    print("Notch2 pole positions: ", ps2)
                ok &= ok2 & ok1
            else:
                if not ok1:
                    print("Notch1 pole positions: ", ps)
                ok &= ok1
        return ok

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
        olist = []
        for ix in range(self.hwbankn):
            if ix+1 > self.bankn:
                t = ([0, 0], [-20000, 0])
            else:
                t = self.filts[ix].integers()
            olist += [t]
        return olist

    def reg_list(self, base, leaves=["lp2a_", "lp2b_", "lp2c_"]):
        d1 = []
        for ix in range(self.hwbankn):
            bb = base + leaves[ix]
            if ix+1 > self.bankn:
                dd = [(bb + 'kx_0', 0), (bb + 'kx_1', 0), (bb + 'ky_0', -20000), (bb + 'ky_1', 0)]
            else:
                dd = self.filts[ix].reg_list(bb)
            if dd is None:
                return None
            d1 += dd
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


def notch_run(ns, dth=0.0, force=False):
    regs = ns.integers()
    command = 'vvp -N lp_2notch_tb +out_file=notch_test.dat'
    command += ' +dth=%f' % dth
    for ix, bank in enumerate(["a", "b", "c"]):
        ks = regs[ix]
        command += ' +k%sxr=%d +k%sxi=%d' % (bank, ks[0][0], bank, ks[0][1])
        command += ' +k%syr=%d +k%syi=%d' % (bank, ks[1][0], bank, ks[1][1])
    print(command)
    return_code = call(command, shell=True)
    if return_code != 0 and not force:
        print("vvp return_code %d" % return_code)
        print("FAIL")
        exit(1)
    a = numpy.loadtxt('notch_test.dat').T
    return a


def check_lp(a, bw, dsp, stim_amp=20000, offset=0, plot=False):
    " Returns True for OK, False for failure "
    if offset == 0 and max(abs(a[3])) != 0:
        print("Problem")
    sim_real = [a[2][ix] for ix in range(7, 107)]
    sim_imag = [a[3][ix] for ix in range(7, 107)]
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


def check_notch(bw, notch1, bw_n1, plot, notch2=None, bw_n2=0.0):
    dt = 2 * 14 / 1320e6
    if notch2 is None:
        ns = notch_setup(freqs=[0, notch1], bws=[bw, bw_n1], targs=[1.0, 0.0])
    else:
        ns = notch_setup(freqs=[0, notch1, notch2], bws=[bw, bw_n1, bw_n2], targs=[1.0, 0.0, 0.0])
    stab_ok = ns.check()
    print("Stability check: " + ("OK" if stab_ok else "FAIL"))
    dc_gain = ns.response(1.0)
    gain_ok = 0.9 < dc_gain.real < 1.0 and abs(dc_gain.imag) < 0.0002
    print("DC gain %.4f%+.4fj" % (dc_gain.real, dc_gain.imag))
    zn1 = exp(-2 * pi * 1j * notch1 * dt)  # z at notch1 frequency
    notch1_gain = ns.response(zn1)
    gain1_ok = gain_ok and abs(notch1_gain) < 0.0002
    if notch2 is not None:
        zn2 = exp(-2 * pi * 1j * notch2 * dt)  # z at notch2 frequency
        notch2_gain = ns.response(zn2)
        gain2_ok = gain_ok and abs(notch2_gain) < 0.0002
        if not (gain1_ok or gain2_ok):
            print("Gains flunk self-test")
        print("Notch1 gain %.4f%+.4fj" % (notch1_gain.real, notch1_gain.imag))
        print("Notch2 gain %.4f%+.4fj" % (notch2_gain.real, notch2_gain.imag))
    else:
        if not gain1_ok:
            print("Gains flunk self-test")
        print("Notch1 gain %.4f%+.4fj" % (notch1_gain.real, notch1_gain.imag))
    if plot:
        f = numpy.arange(-4.0, +4.0, 0.01)  # MHz for plot
        ns.plot(f)
    regs = ns.integers()
    if True:
        print("values for hardware: lpa_kx lpa_ky lpb_kx lpb_ky lpc_xk lpc_ky")
        print(regs)
    else:
        print(ns.reg_list("dsp_lp_notch_"))

    dth1 = -notch1 * 2 * pi * dt
    a1 = notch_run(ns, dth=dth1, force=plot)
    t1 = numpy.arange(len(a1[2])) * dt
    resp_z1 = numpy.array(a1[2]) + 1j * numpy.array(a1[3])
    p11 = max(abs(resp_z1[6:106]))
    p21 = max(abs(resp_z1[-51:-1]))
    if notch2 is not None:
        dth2 = -notch2 * 2 * pi * dt
        a2 = notch_run(ns, dth=dth2, force=plot)
        t2 = numpy.arange(len(a2[2])) * dt
        resp_z2 = numpy.array(a2[2]) + 1j * numpy.array(a2[3])
        p22 = max(abs(resp_z2[6:106]))
        p23 = max(abs(resp_z2[-51:-1]))
        notch_ok = p11 > 11000 and p21 < 40 and p22 > 3000 and p23 < 40
        msg = "" if notch_ok else "  FAULT"
        print("Transient max %.0f  Settled max %.0f%s" % (p11, p21, msg))
        print("Transient max %.0f  Settled max %.0f%s" % (p22, p23, msg))
    else:
        notch_ok = p11 > 11000 and p21 < 40
        msg = "" if notch_ok else "  FAULT"
        print("Transient max %.0f  Settled max %.0f%s" % (p11, p21, msg))

    if plot:
        from matplotlib import pyplot
        pyplot.plot(t1 * 1e6, a1[2], label='N1 Real')
        pyplot.plot(t1 * 1e6, a1[3], label='N1 Imag')
        if notch2 is not None:
            pyplot.plot(t2 * 1e6, a2[2], label='N2 Real')
            pyplot.plot(t2 * 1e6, a2[3], label='N2 Imag')
        pyplot.legend(loc='upper right', frameon=False)
        pyplot.xlabel(u't (\u03BCs)')
        pyplot.ylabel('Response')
        pyplot.xlim([0, max(t1) * 1e6])
        msg = 'PASS' if notch_ok else 'FAIL'
        pyplot.title('Notch filter time-domain check: ' + msg)
        pyplot.show()

    tests_pass = gain_ok and notch_ok and stab_ok
    return tests_pass


def notch_regs(regmap={}, bw=100e3, notch=None, notch2=-3.3e6):
    " create register list ready to send to leep.reg_write() "
    " assumes instance=[zone] will be part of the reg_write() call "
    " provides compatibility with both lp_notch and lp_2notch "
    " peeks at regmap to see which filter is instantiated "
    shifts = [4, 2, 0]
    freqs = [0, notch, notch2]
    bws = [bw, 200e3, 400e3]
    targs = [1.0, 0.0, 0.0]
    leaves = ["lp2a_", "lp2b_", "lp2c_"]
    datapath = 22
    if "shell_0_dsp_lp_notch_lp1b_kx_0" in regmap or notch2 is None:
        print("Disabling second notch")
        freqs = freqs[0:2]
        bws = bws[0:2]
        targs = targs[0:2]
    if "shell_0_dsp_lp_notch_lp1b_kx_0" in regmap:
        print("Using lp_notch config")
        shifts = [2, 2]
        leaves = ["lp1a_", "lp1b_"]
        datapath = 20
    elif "shell_0_dsp_lp_notch_lp2c_kx_0" in regmap:
        print("Using lp_2notch config")
    else:
        print("Error: No filter instantiation")
        return None
    if notch is None:
        print("Using low-pass only")
        freqs = freqs[0:1]
        bws = bws[0:1]
        targs = targs[0:1]
    ns_cav = notch_setup(shifts=shifts, freqs=freqs, bws=bws, targs=targs, datapath=datapath)
    lp_notch_base = 'dsp_lp_notch_'
    notch_reg = ns_cav.reg_list(lp_notch_base, leaves=leaves)
    return notch_reg


if __name__ == "__main__":
    import sys
    plot = len(sys.argv) > 1 and sys.argv[1] == "plot"
    if True:
        fake_regmap1 = {"shell_0_dsp_lp_notch_lp1b_kx_0": 0}
        fake_regmap2 = {"shell_0_dsp_lp_notch_lp2c_kx_0": 0}
        print("-- notch_regs test 1 --")
        print(notch_regs())
        print("-- notch_regs test 2 --")
        print(notch_regs(regmap=fake_regmap1))
        print("-- notch_regs test 3 --")
        print(notch_regs(regmap=fake_regmap2))
        print("-- notch_regs test 4 --")
        print(notch_regs(regmap=fake_regmap1, notch=750e3))
        print("-- notch_regs test 5 --")
        print(notch_regs(regmap=fake_regmap2, notch=750e3))
        print("-- notch_regs test 6 --")
        print(notch_regs(regmap=fake_regmap2, notch=750e3, notch2=None))
        print("-- notch_regs test 6 --")
        print(notch_regs(regmap=fake_regmap2, notch=750e3, notch2=9.0e6))
    if not plot:
        me = sys.argv[0]
        print(me + " testing for regressions only; plot option is available")
    dt = 2 * 14 / 1320e6
    bw = 240e3
    # check only low pass filter
    print("#######################")
    print("Testing low filter only with %.1f kHz bandwidth" % (bw * 0.001))
    if True:
        offset1 = 0
        ns = notch_setup(freqs=[offset1], bws=[bw], targs=[1.0])
        dth = offset1 * 2 * pi * dt
        a = notch_run(ns, dth=dth, force=plot)
        lp_ok = check_lp(
            a=a,
            bw=bw,
            dsp=ns.filts[0].dsp(),
            stim_amp=4 * 20000,
            offset=offset1,
            plot=plot)

    # check low pass filter + notch1
    print("#######################")
    notchf = -800e3
    print("Using %.1f kHz bandwidth" % (bw * 0.001))
    print("Testing notch filter setup for %.1f kHz offset" % (notchf * 0.001))
    test1 = check_notch(bw=bw, notch1=notchf, bw_n1=bw, plot=plot)

    # check low pass and both notch1 and notch2
    # these numbers align with example shown in lp_2notch_theory.py
    bw = 100e3
    notchf1 = -750e3
    notchf2 = -3.0e6
    bw_n1 = 200e3
    bw_n2 = 400e3
    print("#######################")
    print("Using %.1f kHz bandwidth" % (bw * 0.001))
    print("Testing notch filter setup for %.1f kHz and %.1f kHz offset"
          % (notchf1 * 0.001, notchf2 * 0.001))
    test2 = check_notch(bw=bw, notch1=notchf1, notch2=notchf2, bw_n1=bw_n1,
                        bw_n2=bw_n2, plot=plot)

    tests_pass = lp_ok and test1 and test2
    print("PASS" if tests_pass else "FAIL")
    exit(0 if tests_pass else 1)
