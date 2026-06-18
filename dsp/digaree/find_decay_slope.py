import numpy as np
from detune_coeff_calc import rf_waveforms


class decay_slope:
    def __init__(self, waveforms, acq_dt, n_pts=50, max_pw=500, verbose=False):
        self.FWD_CPX = waveforms.get_ch("FWD_I") + 1j*waveforms.get_ch("FWD_Q")
        self.CAV_CPX = waveforms.get_ch("CAV_I") + 1j*waveforms.get_ch("CAV_Q")
        self.acq_dt = acq_dt
        self.n_pts = n_pts
        self.max_pw = max_pw
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
        if start+self.n_pts > fwd_len:
            start = fwd_len - self.n_pts
        if start < self.n_pts or start > self.max_pw:
            print("Aborting due to lack of reasonable trailing edge (%d)" % start)
            exit(1)
        if self.verbose:
            print("Starting trailing waveform analysis at %d" % start)
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
        return self._calc_slope(range(0, s), range(s, s+self.n_pts), range(s, s+self.n_pts))


if __name__ == "__main__":
    from argparse import ArgumentParser

    parser = ArgumentParser(description="Approximate bandwidth and detune from decay waveform")
    parser.add_argument("-f", "--datafile", dest="datafile", default=None, required=True,
                        help="IQ data input file")
    parser.add_argument("-v", "--verbose", action="store_true", dest="verbose", help="Verbose mode")

    args = parser.parse_args()

    # Read in IQ waveforms
    rf_wvf = rf_waveforms(args.datafile, data_format=["UN_I", "UN_Q",
                                                      "FWD_I", "FWD_Q",
                                                      "REV_I", "REV_Q",
                                                      "CAV_I", "CAV_Q"])

    adc_clk = 1320.0e6 / 14.0  # Hz

    # Waveform acquisition timestep
    wvform_dt = (255*2*33) / adc_clk

    slp = decay_slope(rf_wvf, wvform_dt, verbose=args.verbose)
    slp.find_slope()
