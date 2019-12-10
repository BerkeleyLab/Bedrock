import time

import numpy as np
from scipy import signal


class ADC:
    bits = 16
    scale = 1 << (bits - 1)  # signed
    sample_rate = 100000000.
    count_to_1volt = 1. / scale
    # 6dbm = 10 * log10(P/1e-3W)
    # 10 ** (6 / 10) = P / 1e-3
    # 10 ** (0.6) * 1e-3 = P
    # Assuming P = V**2 / 50 Ohms
    # V**2 = 1e-3 * (10 ** 0.6) * 50
    # V = np.sqrt(1e-3 * (10 ** 0.6) * 50)
    dbm_to_Vrms = np.sqrt(1e-3 * (10**0.6) * 50)
    Vzp = dbm_to_Vrms * np.sqrt(2)
    count_to_v = Vzp / scale
    count_to_v = 1.
    downsample_ratio = 1
    # 1.7V saturates 765kHz

    def counts_to_volts(raw_counts):
        # TODO: This should be adjusted to ADC.Vzp and verified
        return raw_counts * ADC.count_to_v


class DataBlock():
    def __init__(self, data_block, ts=time.time()):
        self.ts = ts
        self.data = data_block


def vdir(obj):
    return [(x, v) for x, v in vars(obj).items() if not x.startswith('__')]


class Processing:
    '''
    A set of data processing functions for an Oscilloscope
    TODO:
    1. Easily testable in itself. So add python unittests!
    '''
    max_val_freq, max_val = 0.0, 0.0
    stacked_fft = {}
    stack_n = 100
    stack_count = 0

    @staticmethod
    def time_domain(data_block, ch_n):
        ch_data = data_block.data[ch_n]
        with open('td_file', 'a') as f:
            f.write('{}, {}, {}, {}, {}\n'.format(np.max(ch_data),
                                                  np.max(ch_data) - np.min(ch_data),
                                                  Processing.max_val_freq,
                                                  Processing.max_val,
                                                  ch_n))
        T = np.arange(len(ch_data)) / ADC.fpga_output_rate  # in seconds
        return T, ch_data, np.max(ch_data) - np.min(ch_data)

    @staticmethod
    def save(data_block, *args):
        data = data_block.data
        print(data.shape)
        fname = time.strftime("%Y%m%d-%H%M%S")
        ADC_attrs = sorted(vdir(ADC))
        with open(fname, 'a') as f:
            for x, v in ADC_attrs:
                f.write('# {} {}\n'.format(x, v))
            np.savetxt(f, data.T)

    @staticmethod
    def fft(data_block, ch_n, window):
        ch_data = data_block.data[ch_n]
        fft_x = np.fft.rfftfreq(len(ch_data), d=1 / ADC.fpga_output_rate)
        fft_result = np.abs(np.fft.rfft(ch_data))
        amax = np.argmax(fft_result[10:])
        Processing.max_val_freq = fft_x[10:][amax]
        Processing.max_val = np.max(fft_result[10:])
        return (fft_x[10:], fft_result[10:],
                Processing.max_val_freq, Processing.max_val)

    @staticmethod
    def stacking_fft(data_block, ch_n, window):
        ch_data = data_block.data[ch_n]
        count = Processing.stack_count % 100
        fft_x = np.fft.rfftfreq(len(ch_data), d=1 / ADC.fpga_output_rate)
        fft_result = np.abs(np.fft.rfft(ch_data))
        if count == 0:
            Processing.stacked_fft[ch_n] = fft_result
        else:
            Processing.stacked_fft[ch_n] += fft_result
            Processing.stacked_fft[ch_n] /= count
        amax = np.argmax(fft_result[10:])
        Processing.max_val_freq = fft_x[10:][amax]
        Processing.max_val = np.max(fft_result[10:])
        Processing.stack_count += 1
        print(count)
        return (fft_x[10:], Processing.stacked_fft[ch_n][10:],
                Processing.max_val_freq, Processing.max_val)

    @staticmethod
    def csd(data_block, ch_1, ch_2, window='hanning'):
        ch1_data, ch2_data = data_block.data[ch_1], data_block.data[ch_2]
        return signal.csd(ch1_data, ch2_data,
                          ADC.fpga_output_rate,
                          window=window)
