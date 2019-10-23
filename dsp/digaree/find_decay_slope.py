import numpy as np
# from matplotlib import pyplot
from detune_coeff_calc import rf_waveforms


class decay_slope:
    def __init__(self, waveforms, acq_dt, verbose=False):
        self.FWD_CPX = waveforms.get_ch("FWD_I") + 1j*waveforms.get_ch("FWD_Q")
        self.CAV_CPX = waveforms.get_ch("CAV_I") + 1j*waveforms.get_ch("CAV_Q")
        self.acq_dt = acq_dt
        self.verbose = verbose

    def _find_decay(self):
        fwd = self.FWD_CPX
        fwd_mag = abs(fwd)  # Forward wave magnitude
        fwd_max = max(fwd_mag)
        fwd_end = max(np.nonzero(fwd_mag > 0.5*fwd_max)[0])
        if self.verbose:
            print("find_decay: magnitude %.5f, end of pulse at %d" % (fwd_max, fwd_end))
        return fwd_end

    def _set_start(self):
        start = self._find_decay()+4
        fwd_len = len(self.FWD_CPX)
        if start+50 > fwd_len:
            start = fwd_len - 50
        if self.verbose:
            print("Starting trailing waveform analysis at %d" % start)
        if start < 50 or start > 500:
            print("Aborting due to lack of reasonable trailing edge")
        return start

    """
    arange for amplitude printout
    prange for phase fitting (frequency offset)
    drange for log amplitude fitting (decay time)
    """
    def _calc_slope(self, arange, prange, drange):
        cav = self.CAV_CPX
        phase = np.angle(cav)
        phase_unw = np.unwrap(phase[prange])
        ix = range(len(phase_unw))
        poly_fit = np.polyfit(ix, phase_unw, 1)
        delta_f = poly_fit[0]/self.acq_dt/(2.0*np.pi)  # Hz

        amp = np.abs(cav)
        amp_log = np.log(amp[drange])
        ix = range(len(amp_log))
        poly_fit = np.polyfit(ix, amp_log, 1)
        bw = -poly_fit[0]/self.acq_dt/(2.0*np.pi)  # Hz
        max_amp = max(amp[arange])
        tup = bw, delta_f, max_amp
        print("Measured bandwidth %.6f Hz, detune %.6f Hz, max amp %.5f" % tup)

        return (delta_f, bw, max_amp)

    def find_slope(self):
        s = self._set_start()
        return self._calc_slope(range(0, s), range(s, s+50), range(s, s+50))


if __name__ == "__main__":
    from argparse import ArgumentParser

    parser = ArgumentParser(description="Approximate bandwidth and detune from decay waveform")
    parser.add_argument("-f", "--datafile", dest="datafile", default=None, required=True,
                        help="IQ data input file")
    parser.add_argument("-v", "--verbose", action="store_true", dest="verbose", help="Verbode mode")
    # parser.add_argument("-p", "--plot", action="store_true", dest="plot", help="Plot")

    args = parser.parse_args()

    # Read in IQ waveforms
    rf_wvf = rf_waveforms(args.datafile)

    adc_clk = 1320.0e6 / 14.0  # Hz

    # Waveform acquisition timestep
    wvform_dt = (1*2*33) / adc_clk
    wvform_dt = 1e-6

    slp = decay_slope(rf_wvf, wvform_dt, verbose=args.verbose)
    slp.find_slope()
