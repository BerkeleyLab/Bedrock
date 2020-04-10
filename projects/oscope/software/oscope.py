from kivy.logger import Logger
from kivy.garden.matplotlib.backend_kivyagg import FigureCanvas
from kivy.clock import Clock
from kivy.uix.boxlayout import BoxLayout
from kivy.app import App
from kivy.lang import Builder
from kivy.properties import ObjectProperty
'''
top-level multichannel plotter.
Revamp with kivy started
TODO:
1. Move away from Matplotlib to MeshLinePlot in hope that things get fast
2. Verify the performance of gather data and plot (for now different threads)
3.
'''
import copy
import sys
import time
from threading import Thread

import numpy as np
from matplotlib import pyplot as plt

from misc import ADC, DataBlock, Processing

from banyan_ch_find import banyan_ch_find
from get_raw_adcs import collect_adcs
from prc import c_prc


def write_mask(prc, mask_int):
    prc.leep.reg_write([('banyan_mask', mask_int)])
    channels = banyan_ch_find(mask_int)
    n_channels = len(channels)
    print((channels, 8 / n_channels))
    return n_channels, channels


def get_npt(prc):
    banyan_status = prc.leep.reg_read(['banyan_status'])[0]
    npt = 1 << ((banyan_status >> 24) & 0x3F)
    if npt == 1:
        print("aborting since hardware module not present")
        sys.exit(2)
    return npt


class Carrier():
    def test_data(self, *args):
        raise NotImplementedError

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
                 ip_addr='192.168.1.121',
                 port=50006,
                 count=10,
                 log_decimation_factor=0,
                 verbose=False,
                 test=False):
        ADC.bits = 14
        ADC.sample_rate = 120000000.
        ADC.decimation_factor = 1 << log_decimation_factor
        self.n_channels = 2
        self._db = None
        self.test = test
        self.pts_per_ch = 8192
        self.subscriptions, self.results = {}, {}
        ADC.fpga_output_rate = ADC.sample_rate / ADC.decimation_factor

        from litex import RemoteClient
        from ltc_setup_litex_client import initLTC, get_data

        self.wb = RemoteClient()
        self.wb.open()
        print(self.wb.regs.acq_buf_full.read())
        initLTC(self.wb)

    def acquire_data(self, *args):
        while True:
            self.wb.regs.acq_acq_start.write(1)
            self._db = DataBlock(get_data(self.wb), int(time.time()))
            # ADC count / FULL SCALE => [-1.0, 1.]
            self._process_subscriptions()
            time.sleep(0.1)
        self.wb.close()


class ZestOnBMB7Carrier(Carrier):
    def __init__(self,
                 ip_addr='192.168.1.121',
                 port=50006,
                 mask="0xff",
                 npt_wish=0,
                 count=10,
                 log_decimation_factor=0,
                 verbose=False,
                 use_spartan=False,
                 test=False):

        ADC.decimation_factor = 1 << log_decimation_factor
        self._db = None
        self.test = test
        if not test:
            self.carrier = c_prc(
                ip_addr,
                port,
                use_spartan=use_spartan)

            self.npt = get_npt(self.carrier)
            mask_int = int(mask, 0)
            self.n_channels, channels = write_mask(self.carrier, mask_int)
            self.carrier.leep.reg_write([('config_adc_downsample_ratio',
                                          log_decimation_factor)])
        else:
            banyan_aw = 13
            self.npt = 2**banyan_aw
            self.n_channels = 2

        self.pts_per_ch = self.npt * 8 // self.n_channels
        self.subscriptions, self.results = {}, {}
        ADC.fpga_output_rate = ADC.sample_rate / ADC.decimation_factor

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
        if self.test:
            return self.test_data(*args)

        while True:
            # collect_adcs is not normal:
            # It always collects npt * 8 data points.
            # Each channel gets [(npt * 8) // n_channels] datapoints
            data_raw, ts = collect_adcs(self.carrier.leep,
                                        self.npt, self.n_channels)
            print(time.strftime("%Y%m%d-%H%M%S"))
            self._db = DataBlock(ADC.counts_to_volts(np.array(data_raw)), ts)
            # ADC count / FULL SCALE => [-1.0, 1.]
            self._process_subscriptions()
            time.sleep(0.1)

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


g_scope_channels, g_plot_type_limits = {}, {}


class GUIGraphLimits:
    def __init__(self, plot_type, **kwargs):
        self.plot_type = plot_type
        self.xlim = kwargs.get('xlim')
        self.ylim = kwargs.get('ylim')
        self.xlabel = kwargs.get('xlabel')
        self.ylabel = kwargs.get('ylabel')
        self.ylog = kwargs.get('ylog')
        self.xlog = kwargs.get('xlog')
        self.autoscale = kwargs.pop('autoscale', False)


# TODO: Should convert this to a dataclass for python 3.7+
class GUIGraph:
    def __init__(self, ch_id, plot_info, show=False, label='Noname', **kwargs):
        self.ch_id = ch_id
        self.show = show
        self.label = label
        self.fig = plt.figure()
        self.wid = FigureCanvas(self.fig)
        self.ax = self.fig.add_subplot(111, **kwargs)
        self.plot = self.ax.plot(range(100), [1 / 2] * 100, label=self.label)[0]
        self.ax.set_xlabel(plot_info.xlabel)
        self.ax.set_ylabel(plot_info.ylabel)
        self.ax.legend()
        self.carrier_ch_n = int(ch_id[1]) if int(ch_id[0]) < 2 else None
        self.plot_info = plot_info

    def update_data(self):
        if self.ch_id not in carrier.results:
            # Logger.critical('No data found')
            return
        if self.plot_info.plot_type == 'T':
            x_data, y_data, y_max = carrier.results[self.ch_id]
        elif self.plot_info.plot_type == 'F':
            x_data, y_data, xargmax, y_max = carrier.results[self.ch_id]
        self.plot.set_xdata(x_data)
        self.plot.set_ydata(y_data)
        if not self.plot_info.autoscale:
            self.ax.set_xlim(self.plot_info.xlim)
            self.ax.set_ylim(self.plot_info.ylim)
        else:
            self.ax.relim()
            self.ax.autoscale()

    def set_plot_active(self, b):
        self.show = b

    @staticmethod
    def setup_gui_graphs(carrier):
        # Load possible types of limits: For now T for time domain,
        #                                and F for frequency
        g_plot_type_limits['T'] = GUIGraphLimits('T', xlabel='Time [s]',
                                                 ylabel='ADC count',
                                                 xlim=[0, 0.01], ylim=[-1., 1.])
        g_plot_type_limits['F'] = GUIGraphLimits('F', xlabel='Frequency [Hz]',
                                                 ylabel='[V/sqrt(Hz)]',
                                                 xlim=[0, 5e6],
                                                 ylim=[1e-11, 60000],
                                                 autoscale=True)
        # Create 2 GUI graphs for each channel of data coming from the carrier
        # 2 graphs, 1 for T and 1 for F
        for i in range(carrier.n_channels):
            ch_id = "0" + str(i)
            g_scope_channels[ch_id] = GUIGraph(ch_id, g_plot_type_limits['T'],
                                               label='CH{}-TimeDomain'.format(i))
            ch_id = "1" + str(i)
            g_scope_channels[ch_id] = GUIGraph(ch_id, g_plot_type_limits['F'],
                                               label='CH{}-Frequency'.format(i))
        ch_id = "3"
        g_scope_channels[ch_id] = GUIGraph(ch_id, g_plot_type_limits['F'],
                                               label='CSD'.format(i))



class Logic(BoxLayout):
    autoscale = ObjectProperty(False)

    def __init__(self, **kwargs):
        super(Logic, self).__init__()
        self.csd_channels = 0, 1
        Clock.schedule_interval(self.update_graph, 0.01)
        self.plot_id = '00'
        self.plot_Q = []

    def update_lim(self, axis, *args):
        CH = g_scope_channels[self.plot_id]
        plot_limits = g_plot_type_limits[CH.plot_info.plot_type]
        if axis == 'autoscale':
            plot_limits.autoscale = args[1]
            return
        text = args[1]
        try:
            if axis == "X":
                plot_limits.xlim = eval(text)
            elif axis == "Y":
                plot_limits.ylim = eval(text)
        except Exception:
            Logger.warning('Invalid limits: ' + text)

    def plot_settings_update(self, plot_id, plot_selected):
        if plot_selected:
            self.plot_Q.append(plot_id)
        else:
            self.plot_Q.remove(plot_id)

        if len(self.plot_Q) == 0:
            self.ids.settings_box.size_hint = [0, 0]
            return
        else:
            self.ids.settings_box.size_hint = [1, .1]

        self.plot_id = self.plot_Q[-1]
        CH = g_scope_channels[self.plot_id]
        plot_limits = g_plot_type_limits[CH.plot_info.plot_type]
        try:
            self.ids.ch_name.text = str('CH' + str(int(self.plot_id[1]) + 1) + ' ' +
                                        ('T' if self.plot_id[0] == '0' else 'F'))
        except Exception:
            self.ids.ch_name.text = 'Cross\nSpectral\nDensity'
        self.ids.ylim.text = str(plot_limits.ylim)
        self.ids.xlim.text = str(plot_limits.xlim)
        self.autoscale = plot_limits.autoscale

    def plot_select(self, plot_id, *args):
        '''
        plot_id == plot_type + channel_number
        plot_type is '0' for Timeseries, '1' for FFT, '3' for Cross Spectral Density
        TODO: We don't need to handle plot types in this messy way if they are formalized
        into classes and dealt with inheritance
        '''
        plot_selected = args[-1]  # Adds the plot when True, else removes it

        CH = g_scope_channels[plot_id]

        self.plot_settings_update(plot_id, plot_selected)

        if plot_selected:
            CH.set_plot_active(True)
            self.add_widget(CH.wid)
            plot_type = plot_id[0]
            if plot_type == '0':
                carrier.add_subscription(plot_id, Processing.time_domain,
                                         int(plot_id[1]))
            elif plot_type == '1':
                carrier.add_subscription(plot_id, Processing.stacking_fft,
                                         int(plot_id[1]), 'hanning')
            elif plot_type == '3':
                print(self.csd_channels)
                carrier.add_subscription('3', Processing.H,
                                         self.csd_channels[0],
                                         self.csd_channels[1], 'hanning')
        else:
            CH.set_plot_active(False)
            self.remove_widget(CH.wid)
            carrier.remove_subscription(plot_id)

    def csd_validate(self, *args):
        try:
            self.csd_channels = tuple(
                map(lambda x: int(x) - 1, args[1].split('-')))
            if any([x >= carrier.n_channels for x in self.csd_channels]):
                raise Exception
            Logger.info('Set CSD channels to: '.format(args[1]))
            carrier.add_subscription('3', Processing.csd, self.csd_channels[0],
                                     self.csd_channels[1], 'hanning')
        except Exception:
            Logger.warning('Invalid CSD string: ' + args[1])

    def save_data(self, *args):
        carrier.add_subscription(
            'save', Processing.save, copy.deepcopy(carrier._db), single_subscribe=True)

    def restack_data(self, *args):
        Processing.reset_ch_stack_count(0)
        Processing.reset_ch_stack_count(1)

    def update_graph(self, dt):
        for _, ch in g_scope_channels.items():
            if ch.show:
                ch.update_data()
                ch.wid.draw()


class Oscope(App):
    def build(self):
        return Builder.load_file("look.kv")


if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser(description='Read/Write from FPGA memory')
    parser.add_argument(
        '-a',
        '--ip',
        help='ip_address',
        dest='ip',
        type=str,
        default='192.168.19.8')
    parser.add_argument(
        '-p', '--port', help='port', dest='port', type=int, default=803)
    parser.add_argument(
        '-m', '--mask', help='mask', dest='mask', type=str, default='0x33')
    parser.add_argument(
        '-n',
        '--npt_wish',
        help='number of points per channel',
        type=int,
        default=4096)
    parser.add_argument(
        '-c', '--count', help='number of acquisitions', type=int, default=1)
    parser.add_argument(
        '-l', '--log_decimation_factor', help='Log downsample ratio', type=int, default=2)
    parser.add_argument(
        '-t', '--testmode', help='run in test mode', action='store_true')
    parser.add_argument(
        "-u",
        "--use_spartan",
        action="store_true",
        help="use spartan")
    args, unknown = parser.parse_known_args()
    sys.argv[1:] = unknown
    args = parser.parse_args(sys.argv[2:])
    carrier = ZestOnBMB7Carrier(
        ip_addr=args.ip,
        port=args.port,
        mask=args.mask,
        npt_wish=args.npt_wish,
        count=args.count,
        use_spartan=args.use_spartan,
        log_decimation_factor=args.log_decimation_factor,
        test=False)
    # carrier = LTCOnMarblemini()
    GUIGraph.setup_gui_graphs(carrier)
    acq_thread = Thread(target=carrier.acquire_data)
    acq_thread.daemon = True
    acq_thread.start()
    Oscope().run()
