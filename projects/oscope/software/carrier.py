import logging
Logger = logging.getLogger(__name__)
import socket
import sys
import time

import numpy as np

from litex import RemoteClient

from misc import ADC, DataBlock
from banyan_ch_find import banyan_ch_find
from get_raw_adcs import collect_adcs
from zest_setup import c_zest
from ltc_setup_litex_client import initLTC, get_data


class Carrier():
    def test_data(self, *args):
        while True:
            # https://docs.python.org/3/tutorial/classes.html#private-variables
            self._db = DataBlock(
                np.array([np.random.random_sample(self.pts_per_ch)
                          for _ in range(self.n_channels)]),
                time.time())
            self._process_subscriptions()
            time.sleep(0.2)

    def acquire_data(self, *args):
        raise NotImplementedError

    def _process_subscriptions(self):
        # TODO: Perhaps implement something to avoid race condition on results
        for sub_id, (single_subscribe, fn, *fn_args) in list(self.subscriptions.items()):
            self.results[sub_id] = fn(self._db, *fn_args)
            if single_subscribe:
                self.remove_subscription(sub_id)

    def add_subscription(self, sub_id, fn, *fn_args, single_subscribe=False):
        # TODO: Add args/kwargs to the function
        self.subscriptions[sub_id] = (single_subscribe, fn, *fn_args)
        Logger.info('Added subscription {}'.format(sub_id))

    def remove_subscription(self, sub_id):
        self.subscriptions.pop(sub_id)
        Logger.info('Removed subscription {}'.format(sub_id))


class LTCOnMarblemini(Carrier):
    def __init__(self,
                 count=10,
                 log_decimation_factor=0,
                 test=False):
        ADC.bits = 14
        ADC.sample_rate = 120000000.
        self.n_channels = 2
        self._db = None
        self.test = test
        self.pts_per_ch = 8192
        self.subscriptions, self.results = {}, {}
        self.set_log_decimation_factor(log_decimation_factor)
        self.wb = RemoteClient()
        self.wb.open()
        print(self.wb.regs.acq_buf_full.read())
        initLTC(self.wb)

    def set_log_decimation_factor(self, ldf):
        ADC.decimation_factor = 1 << ldf
        ADC.fpga_output_rate = ADC.sample_rate / ADC.decimation_factor
        if ldf != 0:
            '''
            This feature is missing in gateware
            '''
            raise NotImplementedError

    def acquire_data(self, *args):
        if self.test:
            return self.test_data(*args)

        while True:
            # self.wb.regs.acq_acq_start.write(1)
            d = get_data(self.wb)
            if d is None:
                print('recovering')
                time.sleep(0.1)
                continue
            self._db = DataBlock(d, int(time.time()))
            # ADC count / FULL SCALE => [-1.0, 1.]
            self._process_subscriptions()
            # time.sleep(0.1)
        self.wb.close()


class ZestOnBMB7Carrier(Carrier):
    '''
    Zest on BMB7 or Marblemini
    '''
    def __init__(self,
                 ip_addr='192.168.1.121',
                 mask="0xff",
                 npt_wish=0,
                 count=10,
                 log_decimation_factor=0,
                 test=False):

        self._db = None
        self.test = test
        self.log_decimation_factor = 0
        if self.test:
            banyan_aw = 13
            self.npt = 2**banyan_aw
            self.n_channels = 2
        else:
            self.carrier = c_zest(ip_addr)
            self.npt = ZestOnBMB7Carrier.get_npt(self.carrier)
            mask_int = int(mask, 0)
            self.n_channels, self.channel_order = ZestOnBMB7Carrier.write_mask(self.carrier, mask_int)

        self.set_log_decimation_factor(log_decimation_factor)
        self.pts_per_ch = self.npt * 8 // self.n_channels
        self.subscriptions, self.results = {}, {}

    def set_log_decimation_factor(self, ldf):
        Logger.info(f'Changed log_decimation factor from {self.log_decimation_factor} to {ldf}')
        ADC.decimation_factor = 1 << ldf
        if not self.test:
            try:
                self.carrier.leep.reg_write([('config_adc_downsample_ratio', ldf)])
            except socket.timeout:
                self.set_log_decimation_factor(ldf)
        ADC.fpga_output_rate = ADC.sample_rate / ADC.decimation_factor
        self.log_decimation_factor = ldf

    def acquire_data(self, *args):
        if self.test:
            return self.test_data(*args)

        while True:
            # collect_adcs is not normal:
            # It always collects npt * 8 data points.
            # Each channel gets [(npt * 8) // n_channels] datapoints
            start = time.time()
            print('tick ..')
            try:
                data_raw_, ts = collect_adcs(self.carrier.leep,
                                             self.npt, self.n_channels)
            except socket.timeout:
                print('foo')
                continue
            data_raw = [y for _, y in sorted(zip(self.channel_order, data_raw_))]
            print(self.npt, self.n_channels, time.time()-start, self.channel_order)
            self._db = DataBlock(ADC.counts_to_volts(np.array(data_raw)), ts)
            # ADC count / FULL SCALE => [-1.0, 1.]
            self._process_subscriptions()
            # time.sleep(0.1)  # This is now unnecessary, as this routine is the bottleneck

    def _process_subscriptions(self):
        # TODO: Perhaps implement something to avoid race condition on results
        for sub_id, (single_subscribe, fn, *fn_args) in list(self.subscriptions.items()):
            self.results[sub_id] = fn(self._db, *fn_args)
            if single_subscribe:
                self.remove_subscription(sub_id)

    def add_subscription(self, sub_id, fn, *fn_args, single_subscribe=False):
        # TODO: Add args/kwargs to the function
        self.subscriptions[sub_id] = (single_subscribe, fn, *fn_args)
        Logger.info('Added subscription {}'.format(sub_id))

    def remove_subscription(self, sub_id):
        self.subscriptions.pop(sub_id)
        Logger.info('Removed subscription {}'.format(sub_id))

    @staticmethod
    def write_mask(carrier, mask_int):
        carrier.leep.reg_write([('banyan_mask', mask_int)])
        channels = banyan_ch_find(mask_int)
        n_channels = len(channels)
        print((channels, 8 / n_channels))
        return n_channels, channels

    @staticmethod
    def get_npt(prc):
        banyan_status = prc.leep.reg_read(['banyan_status'])[0]
        npt = 1 << ((banyan_status >> 24) & 0x3F)
        if npt == 1:
            print("aborting since hardware module not present")
            sys.exit(2)
        return npt
