import numpy as np
from numpy import sqrt, arctan2, exp, mean, std, pi, zeros, hstack, vstack, arange, diff, linalg
from scipy import signal
from matplotlib import pyplot


class rf_waveforms:
    DAT_FMT = ["FWD_I", "FWD_Q",
               "REV_I", "REV_Q",
               "CAV_I", "CAV_Q",
               "LOOPB_I", "LOOPB_Q", ]  # Drive
    MIN_PTS = 256

    def __init__(self, data_file):
        self.waves = np.loadtxt(data_file).transpose()

        if self.waves.shape[0] != len(self.DAT_FMT) or\
           self.waves.shape[1] < self.MIN_PTS:
            print("ERROR: Bad data shape: {0}".format(self.waves.data.shape))
            exit(1)

    def get_ch(self, ch_key):
        if ch_key not in self.DAT_FMT:
            print("ERROR: No channel {} in waveform data".format(ch_key))

        return self.waves[self.DAT_FMT.index(ch_key)]


class digaree_coeff:
    CONFIG_PARAMS = ["bandwidth", "wvform_dt",
                     "freq_quantum", "digaree_dt",
                     "out_shift"]

    def __init__(self, c_dict, fir_gain=80, dig_data_w=20, dig_extra_w=4):
        for p in self.CONFIG_PARAMS:
            if p not in c_dict:
                print("ERROR: Parameter {} missing from config dict".format(p))
                exit(1)
        self.c_dict = c_dict
        self.dig_dw = dig_data_w   # Width of Digaree inputs/parameters
        self.dig_ew = dig_extra_w  # Extra guard bits
        self.fir_g = fir_gain      # pre-scaling for dV/dt

    def compute(self, wvf, plot=False, verbose=False):
        print("ERROR: This method must be overriden by a coefficient calculation method")
        exit(1)

    """
    Scale Beta and 1/T so output detune frequency is in units of scaled Hz.

    # Input Beta is in Hz.
    # conf.dict["freq_quantum"] determines the resolution of detune output.
    # conf.dict["out_shift"] compensates for resizing of detune output. E.g:
      if Digaree's data width is 20-bit but transmitted detune is 18-bit,
      this scaling factor must be set to 2**(20-18) = 4.
    # conf.dict["digaree_dt"] is pre-scaled by a constant FIR gain for dV/dt
      (see comments in cgen_srf.py)
    """
    def get_coeffs(self, beta):
        invT = 1.0/(self.c_dict["digaree_dt"]*self.fir_g)  # inverse seconds

        # Divide by 2pi to get Hz
        invT = invT / (2*pi)
        beta = beta  # beta is already in Hz

        # Scale by freq quantum and (optional) output shift
        invT = (invT * self.c_dict["out_shift"]) / self.c_dict["freq_quantum"]
        beta = (beta * self.c_dict["out_shift"]) / self.c_dict["freq_quantum"]

        detune_coeffs = [beta.real, beta.imag, invT, 32768]

        # Round to int and check for overflow wrt Digaree signed pipeline width
        sff = [int(round(x)) for x in detune_coeffs]
        ok = all([abs(x) < 2**(self.dig_dw+self.dig_ew-1) for x in sff])

        if not ok:
            print("ERROR: Computed coefficients exceed Digaree pipeline width")
            for idx, kx in enumerate(sff):
                print("sf_consts[%d] = %d" % (idx, kx))
            sff = None
        else:
            for idx, kx in enumerate(sff):
                print("sf_consts[%d] = %d" % (idx, kx))
            print("fq = %f" % (self.c_dict["freq_quantum"]))

        return sff


"""
Analyzes waveform data to get the setup parameters for detune computations.
Data is assumed to be in GDR mode, which is both good and bad:
simpler math, but need an externally-provided bandwidth.
Only needs/uses forward and cavity signals.

Depends on microphonics to make large variations in the imginary part
of the complex state parameter, while the real part (based on Q_L) is
relatively constant on these time scales.  With GDR mode holding the
cavity voltage fixed, the forward wave can be rotated and scaled to give
that state parameter.

Has been tested when ths system is parasiting off another controller.
It will be useful for in-situ correction of cable drift during long
CW GDR runs, which would otherwise introduce tune angle drift.
"""


class detune_gdr(digaree_coeff):

    def fwd_coeff(self, fwd, verbose=False):
        # This covariance and eigenvalue computation finds out how to
        # rotate the forward wave to give large imaginary fluctuations
        # but small real fluctuations.
        mmm1 = np.cov(fwd.real, fwd.imag)
        e_val, e_vec = np.linalg.eig(mmm1)

        # we need e_val sorted from larger to smaller
        ev_list = list(zip(e_val, e_vec))
        ev_list.sort(key=lambda tup: tup[0], reverse=True)
        e_val, e_vec = zip(*ev_list)
        fp0 = arctan2(e_vec[0][0], e_vec[0][1])
        coeff = exp(-1j*fp0)
        fwdx = fwd * coeff

        # eigenvectors have arbitrary sign
        if mean(fwdx).real < 0:
            fwdx = -fwdx
            coeff = -coeff
            fp0 = (fp0 + 2*pi) % (2*pi) - pi
        drv = fwdx.imag/mean(fwdx.real)
        coeff = coeff/mean(fwdx.real)
        if verbose:
            print("Orthogonal fwd rms (%.1f, %.1f)" % tuple(sqrt(e_val)))
            print("Forward phase zero %.3f radians" % fp0)
            print("Drive normalized variation %.3f rms" % std(drv))
        return coeff

    def compute(self, wvf, plot=False, verbose=False):
        # loopback and reverse not used
        fwd = wvf.get_ch("FWD_I") + 1j*wvf.get_ch("FWD_Q")
        cav = wvf.get_ch("CAV_I") + 1j*wvf.get_ch("CAV_Q")
        fwd_c = self.fwd_coeff(fwd, verbose=verbose)
        cav_c = 1/mean(cav)
        beta = self.c_dict["bandwidth"] * fwd_c / cav_c

        # Plot FWD, CAV and beta*FWD/CAV
        fwdx = fwd * fwd_c
        cavx = cav * cav_c
        a = beta * fwd / cav
        t = np.arange(len(cav)) * self.c_dict["wvform_dt"]
        f, (ax1, ax2) = pyplot.subplots(1, 2, figsize=(16, 8))
        ax1.plot(fwdx.real, fwdx.imag, label="Forward")
        ax1.plot(cavx.real, cavx.imag, label="Cavity")
        ax1.set_xlim(0.98, 1.02)
        ax1.set_ylim(-0.8, 0.8)
        ax1.set_xlabel('Real')
        ax1.set_ylabel('Imag')
        ax1.legend(frameon=False)
        ax1.set_title("Input waveforms, normalized and rotated")
        ax2.plot(t, a.real, label='real')
        ax2.plot(t, a.imag, label='imag')
        ax2.set_xlim(0, max(t))
        ax2.set_ylim(-12.0, 18.0)
        ax2.set_xlabel("Time (s)")
        ax2.set_ylabel("Frequency (Hz)")
        ax2.set_title("Resulting state-space coefficient")
        ax2.legend(frameon=False)
        # Note that the mean value of the coefficient's real part is,
        # by construction, equal to the bandwidth supplied to us in
        # c_dict["bandwidth"].
        # All the results are normalized based on that single number.

        fig_name = "cw_fit.png"
        pyplot.savefig(fig_name)
        print("Plot saved to {}".format(fig_name))
        if plot:
            pyplot.show()

        if verbose:
            print("SI beta %.3f%+.3fj Hz" % (beta.real, beta.imag))
        return self.get_coeffs(beta)


"""
Analyzes waveform data to get the setup parameters for detune computations.
Data is assumed to be in pulsed mode.
Only needs/uses forward and cavity signals.
"""


class detune_pulse(digaree_coeff):

    """
    Cardinal B-spline  https://en.wikipedia.org/wiki/B-spline
    Same as the output of a second-order CIC interpolator
    """
    def create_basist(self, block=15, n=10):
        npt = (n-1)*block+1
        basist = zeros([npt, n])
        x = arange(npt)/float(block)
        for jx in range(n):
            basist[:, jx] = signal.bspline(x-jx, 2)
        # end-effects, it's important that the sum is flat
        basist[:, 0] += signal.bspline(x+1, 2)
        basist[:, n-1] += signal.bspline(x-n, 2)
        return basist

    # basist is n*m, where n=len(cav)-1, m is number of time-dependent bases
    def compute(self, wvf, plot=False, verbose=False):
        basist = self.create_basist(block=10, n=24)
        cav = wvf.get_ch("CAV_I") + 1j*wvf.get_ch("CAV_Q")
        fwd = wvf.get_ch("FWD_I") + 1j*wvf.get_ch("FWD_Q")

        ny = basist.shape[0]+1
        cav = cav[:ny]
        fwd = fwd[:ny]

        acav = 0.5 * (cav[1:] + cav[:-1])
        afwd = 0.5 * (fwd[1:] + fwd[:-1])
        dcav = diff(cav)/self.c_dict["wvform_dt"]
        cave = acav * basist.T
        # Fit dcav to a*acav + b*afwd
        # Treat real and imaginary parts separately, since we want the imaginary
        # part of b to be sum_i g_i*f_i(t) while the real part is constant.
        goal = hstack([dcav.real, dcav.imag])
        basis1 = hstack([afwd.real, afwd.imag])   # b.real
        basis2 = hstack([-afwd.imag, afwd.real])  # b.imag
        basis3 = hstack([acav.real, acav.imag])   # a.real
        basisn = hstack([-cave.imag, cave.real])  # a.imag repeated
        basis = vstack([basis1, basis2, basis3, basisn])

        (fitc, resid, rank, sing) = linalg.lstsq(basis.T, goal, rcond=-1)

        beta = fitc[0]+1j*fitc[1]  # in rad/s
        beta_hz = beta / (2*pi)
        if verbose:
            print("SI beta %.3f%+.3fj Hz" % (beta.real, beta.imag))

        bw_rad = fitc[2]
        det_rad = fitc[3:]
        if verbose:
            print("Bandwidth rad/s", bw_rad, "Bandwidth Hz", bw_rad/(2*pi))
            print("Detune rad/s", det_rad, "Detune Hz", det_rad/(2*pi))
            print("SI beta %.3f%+.3fj Hz" % (beta.real, beta.imag))

        # Useful for plotting
        detune = basist.dot(fitc[3:])
        bandwidth = fitc[2]/2/pi  # Hz

        return self.get_coeffs(beta_hz), beta, detune, bandwidth


if __name__ == "__main__":
    from argparse import ArgumentParser

    parser = ArgumentParser(description="Detune coefficient computation")
    parser.add_argument("-m", "--mode", dest="mode", default="cw", const="cw", nargs="?",
                        choices=["cw", "pulse"], help="Coeff calculation mode")
    parser.add_argument("-f", "--datafile", dest="datafile", default=None, required=True,
                        help="IQ data input file")
    parser.add_argument("-v", "--verbose", action="store_true", dest="verbose", help="Verbode mode")
    parser.add_argument("-p", "--plot", action="store_true", dest="plot", help="Plot")

    args = parser.parse_args()

    # Read in IQ waveforms
    rf_wvf = rf_waveforms(args.datafile)

    adc_clk = 1320.0e6 / 14.0  # Hz

    # Waveform acquisition timestep
    wvform_dt = (1*2*33) / adc_clk

    # Digaree data stream timestep
    digaree_dt = (32*2*33) / adc_clk

    # Setup configuration dict for detune coefficient calculation
    detune_dict = {"bandwidth": 15.0,  # Ignored in pulse mode
                   "wvform_dt": wvform_dt,
                   "freq_quantum": 0.0355256,
                   "digaree_dt": digaree_dt,
                   "out_shift": 4}

    if args.mode == "cw":
        print("Calculating detune coefficients from CW data")
        detune_coeff = detune_gdr(detune_dict)
    else:
        detune_coeff = detune_pulse(detune_dict)

    detune_coeff.compute(rf_wvf, args.plot, args.verbose)
