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
    Units = 'ADC Count'
    # 1.7V saturates 765kHz

    def counts_to_volts(raw_counts):
        # TODO: This should be adjusted to ADC.Vzp and verified
        return raw_counts


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
    stacked_H = {}
    stacked_data = {}
    stack_n = 100000
    old_data = None
    fft_stack_count = {0:0, 1:0}
    H_stack_count = {0:0, 1:0}

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
        data = args[0].data
        fname = time.strftime("%Y%m%d-%H%M%S")
        ADC_attrs = sorted(vdir(ADC))
        with open(fname, 'a') as f:
            for x, v in ADC_attrs:
                f.write('# {} {}\n'.format(x, v))
            np.savetxt(f, data.T, fmt='%d')

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
    def reset_ch_stack_count(ch_n):
        Processing.fft_stack_count[ch_n] = 0
        Processing.H_stack_count[ch_n] = 0

    @staticmethod
    def stacking_fft(data_block, ch_n, window):
        ch_data = data_block.data[ch_n]
        count = Processing.fft_stack_count[ch_n] % Processing.stack_n
        fft_x = np.fft.rfftfreq(len(ch_data), d=1 / ADC.fpga_output_rate)
        fft_result = np.abs(np.fft.rfft(ch_data))
        if count == 0:
            Processing.stacked_fft[ch_n] = fft_result
        else:
            Processing.stacked_fft[ch_n] = np.amax([fft_result, Processing.stacked_fft[ch_n]], axis=0)
            Processing.stacked_fft[ch_n] = fft_result
        amax = np.argmax(fft_result[10:])
        Processing.max_val_freq = fft_x[10:][amax]
        Processing.max_val = np.max(fft_result[10:])
        Processing.fft_stack_count[ch_n] += 1
        return (fft_x[10:],
                Processing.stacked_fft[ch_n][10:],
                Processing.max_val_freq,
                Processing.max_val)

    @staticmethod
    def stacking2_fft(data_block, ch_n, window):
        ch_data = data_block.data[ch_n]
        count = Processing.fft_stack_count[ch_n] % Processing.stack_n
        fft_x = np.fft.rfftfreq(len(ch_data), d=1 / ADC.fpga_output_rate)
        #fft_result = np.abs(np.fft.rfft(ch_data))
        fft_result = (np.fft.rfft(ch_data))
        if count == 0:
            Processing.stacked_fft[ch_n] = fft_result
        else:
            Processing.stacked_fft[ch_n] += fft_result
        amax = np.argmax(fft_result[10:])
        Processing.max_val_freq = fft_x[10:][amax]
        Processing.max_val = np.max(fft_result[10:])
        Processing.fft_stack_count[ch_n] += 1
        return (fft_x[10:],
                Processing.stacked_fft[ch_n][10:] / (count + 1),
                Processing.max_val_freq,
                Processing.max_val)



    @staticmethod
    def psd(data_block, ch_n, window='hanning'):
        x, y = signal.csd(data_block.data[ch_n], data_block.data[ch_n],
                          ADC.fpga_output_rate,
                          nperseg=len(data_block.data[ch_n])/4,
                          window=window)
        return x, y, 0, 0

    @staticmethod
    def csd(data_block, ch_1, ch_2, window='hanning'):
        ch1_data, ch2_data = data_block.data[ch_1], data_block.data[ch_2]
        x, y = signal.csd(ch1_data, ch2_data, ADC.fpga_output_rate,
                          window=window)
        return x, y, 0, 0

    def get_fft(data):
        fft_x = np.fft.rfftfreq(len(data), d=1 / ADC.fpga_output_rate)
        fft_result = np.abs(np.fft.rfft(data))
        return fft_x, fft_result

    @staticmethod
    def H(data_block, ch_1, ch_2, window='hanning'):
        ch1_data, ch2_data = data_block.data[ch_1], data_block.data[ch_2]

        x, fft1 = Processing.get_fft(ch1_data)
        x, fft2 = Processing.get_fft(ch2_data)

        count = Processing.H_stack_count[ch_1] % Processing.stack_n

        if count == 0:
            Processing.stacked_H[ch_1] = fft1
            Processing.stacked_H[ch_2] = fft2
        else:
            Processing.stacked_H[ch_1] += fft1
            Processing.stacked_H[ch_2] += fft2
        Processing.H_stack_count[ch_1] += 1
        return (x[10:],
                (Processing.stacked_H[ch_1][10:]/
                 Processing.stacked_H[ch_2][10:]),
                0,
                0)
