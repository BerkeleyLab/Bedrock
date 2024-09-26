import numpy
from numpy import angle, unwrap, diff, pi
from matplotlib import pyplot
from detune_coeff_calc import detune_pulse, rf_waveforms

"""
Find Lorentz coefficient by curve-fitting
  Works because there's a nice broad-band term,
  and the excitation term is relatively narrow-band
g: cavity field in MV/m
ssmi: state-space model imaginary part in Hz
"""


def fit_lorentz(g, ssmi, plot=False):
    fit_x = g[2:-1]**2
    fit_y = ssmi[2:]
    pp = numpy.polyfit(fit_x, fit_y, 1)
    g_squared = numpy.polyval(pp, g**2)
    lor_coeff = -pp[0]  # Hz/(MV/m)^2
    lor_label = "%.0f - %.2f*Gradient^2" % (pp[1], lor_coeff)
    if plot:  # messes up later plots when run from fitter_test.py
        pyplot.figure(2)
        pyplot.plot(fit_x, fit_y)
        pyplot.plot(fit_x, numpy.polyval(pp, fit_x))
        pyplot.title(lor_label)
        pyplot.show()
    return g_squared, lor_label, lor_coeff


def liver(cav, fwd, b, ix=None, dt=1, axes=None, dest={}):
    acav = 0.5 * (cav[1:] + cav[:-1])
    afwd = 0.5 * (fwd[1:] + fwd[:-1])
    dcav = diff(cav)/dt
    t = (numpy.arange(len(acav))+0.5)*dt
    a = (dcav - b*afwd)/acav
    simple = diff(unwrap(angle(cav)))/dt/2/pi
    if "ssmr" in dest:
        dest["ssmr"].set_data(t, a.real/2/pi)
    if "ssmi" in dest:
        dest["ssmi"].set_data(t, a.imag/2/pi)
    if "simp" in dest:
        dest["simp"].set_data(t, simple)
    if False:  # axes is not None:
        axes[0].plot(t, a.real/2/pi, label='State-space model')
        axes[1].plot(t, a.imag/2/pi, label='State-space model')
        axes[1].plot(t, simple, label='Simple dphase/dt')


def axes_setup(axes, maxt):
    axes[1].set_ylim([-130, 130])
    axes[0].set_ylim([-19.5, -13.5])
    axes[1].set_xlim([0, maxt])
    axes[1].set_xlabel('Time (s)')
    axes[0].set_ylabel('Bandwidth (Hz)')
    axes[1].set_ylabel('Detune (Hz)')


def run1(wvf, det_dict, axes=None, dest={}, fname=None):
    detune_coeff = detune_pulse(det_dict)

    # Compute beta, detune, bandwidth
    coeffs, mr, detune, bandwidth = detune_coeff.compute(rf_wvf, plot=True, verbose=True)

    basist = detune_coeff.create_basist(block=10, n=24)
    cav = wvf.get_ch("CAV_I") + 1j*wvf.get_ch("CAV_Q")
    fwd = wvf.get_ch("FWD_I") + 1j*wvf.get_ch("FWD_Q")

    n1 = basist.shape[0]
    tt = (numpy.arange(n1)+0.5)*det_dict["wvform_dt"]
    bandlabel = "Fit %.2f Hz" % -bandwidth
    if "fitr" in dest:
        dest["fitr"].set_label(bandlabel)
        dest["fitr"].set_data(tt, tt*0+bandwidth)
        if "fiti" in dest:
            dest["fiti"].set_data(tt, detune)
        if axes is not None:
            axes[0].plot(tt, tt*0+bandwidth, label=bandlabel)
            axes[1].plot(tt, detune, label='Fit')

    ix = range(3, 380)
    liver(cav[ix], fwd[ix], mr, ix=range(4, 25), dt=det_dict["wvform_dt"], axes=axes, dest=dest)

    string_mr = "b = %6.1f%+6.1fj /s" % (mr.real, mr.imag)

    t = (numpy.arange(len(ix))+0.5)*det_dict["wvform_dt"]
    adc_fs = 519636.5
    cav_fs = 33.37
    g = abs(cav[ix]) * cav_fs / adc_fs  # MV/m  XXX get from JSON file
    g_squared, lor_label, lor_coeff = fit_lorentz(g, dest["ssmi"].get_data()[1], plot=False)
    print(lor_label)
    if "gsqr" in dest:
        dest["gsqr"].set_data(t, g_squared)
    if "gsqr" in dest:
        dest["gsqr"].set_label(lor_label)
    if "txmr" in dest:
        dest["txmr"].set_text(string_mr)


def plot_post(dest, fname):
    if "legr" in dest:
        dest["legr"].remove()
    if "axes" in dest:
        dest["axes"][0].legend(frameon=False, loc='lower right', prop={'size': 12})
    if "leg1" in dest:
        dest["leg1"].remove()
    if "axes" in dest:
        dest["axes"][1].legend(frameon=False, loc='lower right', prop={'size': 12})
    if "fig0" in dest:
        dest["fig0"].suptitle(fname)


dest = {}
global fdir
fdir = ""


def r_init():
    # used when resizing the window
    global dest
    axes_setup(axes, 0.06)
    dest["fitr"], = axes[0].plot([], [], label='Fit', animated=True)
    dest["fiti"], = axes[1].plot([], [], label='Fit', animated=True)
    dest["ssmr"], = axes[0].plot([], [], label='State-space model', animated=True)
    dest["ssmi"], = axes[1].plot([], [], label='State-space model', animated=True)
    dest["simp"], = axes[1].plot([], [], label='Simple dphase/dt', animated=True)
    # dest["gsqr"], = axes[1].plot([], [], label='Gradient^2', animated=True)
    dest["gsqr"], = axes[1].plot([], [], label='Lorentz', animated=True)
    dest["txmr"] = axes[0].text(0.01, -19, '')
    dest["axes"] = axes
    dest["fig0"] = fig
    dest["legr"] = axes[0].legend(frameon=False, loc='lower right', prop={'size': 12})
    dest["leg1"] = axes[1].legend(frameon=False, loc='lower right', prop={'size': 12})
    axes[1].legend(frameon=False, loc='lower right', prop={'size': 12})


if __name__ == "__main__":
    from argparse import ArgumentParser

    parser = ArgumentParser(description="Pulse fitter test")
    parser.add_argument("-f", "--datafile", dest="datafile", default=None, required=True,
                        help="IQ data input file")
    parser.add_argument("-v", "--verbose", action="store_true", dest="verbose", help="Verbose mode")
    args = parser.parse_args()

    pyplot.rcParams["figure.figsize"] = [10, 7.5]
    fig, axes = pyplot.subplots(2, 1, sharex='col')
    fig.subplots_adjust(hspace=0.0)
    axes_setup(axes, 0.06)
    r_init()

    # Read in IQ waveforms
    rf_wvf = rf_waveforms(args.datafile, data_format=["UN_I", "UN_Q",
                                                      "FWD_I", "FWD_Q",
                                                      "REV_I", "REV_Q",
                                                      "CAV_I", "CAV_Q"])

    adc_clk = 1320.0e6 / 14.0  # Hz
    wvform_dt = (255*2*33) / adc_clk
    digaree_dt = (32*2*33) / adc_clk

    # Setup configuration dict for detune coefficient calculation
    detune_dict = {"bandwidth": 15.0,  # Ignored in pulse mode
                   "wvform_dt": wvform_dt,
                   "freq_quantum": 0.0355256,
                   "digaree_dt": digaree_dt,
                   "basist_block": 10,
                   "basist_n": 24,
                   "out_shift": 4}
    run1(rf_wvf, detune_dict, axes=None, dest=dest, fname=args.datafile)
    plot_post(dest, args.datafile)

    fig_name = "pulse_fit.png"
    pyplot.savefig(fig_name)
    print("Plot saved to {}".format(fig_name))
