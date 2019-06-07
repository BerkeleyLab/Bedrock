from kivy.logger import Logger
from kivy.garden.matplotlib.backend_kivyagg import FigureCanvas
from kivy.clock import Clock
from kivy.uix.boxlayout import BoxLayout
from kivy.app import App
from kivy.lang import Builder
'''
top-level multichannel plotter.
Revamp with kivy started
TODO:
1. Move MeshLinePlot into a Kivy Graph object
2. Verify the performance of gather data and plot (for now different threads)
'''
import sys
import time
from threading import Thread

import numpy as np
from matplotlib import pyplot as plt

from banyan_ch_find import banyan_ch_find
from banyan_spurs import collect_adcs
from prc import c_prc


def write_mask(prc, mask_int):
    prc.reg_write([{'banyan_mask': mask_int}])
    channels = banyan_ch_find(mask_int)
    n_channels = len(channels)
    print((channels, 8 / n_channels))
    return n_channels, channels


def get_npt(prc):
    banyan_status = prc.reg_read_value(['banyan_status'])[0]
    npt = 1 << ((banyan_status >> 24) & 0x3F)
    if npt == 1:
        print("aborting since hardware module not present")
        sys.exit(2)
    return npt


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
    dbm_to_Vrms = np.sqrt(1e-3 * (10 ** 0.6) * 50)
    Vzp = dbm_to_Vrms * np.sqrt(2)

    def counts_to_volts(raw_counts):
        # TODO: This should be adjusted to ADC.Vzp and verified
        return raw_counts * ADC.count_to_1volt


class Carrier:
    def __init__(self,
                 ip_addr='192.168.1.121',
                 port=50006,
                 mask="0xff",
                 npt_wish=0,
                 count=10,
                 verbose=False,
                 filewritepath=None,
                 use_spartan=False,
                 test=False):
        if not test:
            self.carrier = c_prc(ip_addr, port, filewritepath=filewritepath,
                                 use_spartan=use_spartan)

            self.npt = get_npt(self.carrier)
            mask_int = int(mask, 0)
            self.n_channels, channels = write_mask(self.carrier, mask_int)
        else:
            banyan_aw = 13
            self.npt = 2 ** banyan_aw
            self.n_channels = 2

        self.pts_per_ch = self.npt * 8 // self.n_channels
        self.test_counter = 0
        self.subscriptions, self.results = {}, {}

    def test_data(self, *args):
        while True:
            self.test_counter += 1
            self.nblock = np.array([np.random.random_sample(self.pts_per_ch)
                                    for _ in range(self.n_channels)])
            self.process_subscriptions()
            time.sleep(0.2)

    def acquire_data(self, *args):
        # collect_adcs is not normal:
        # It always collects npt * 8 data points.
        # Each channel gets [(npt * 8) // n_channels] datapoints
        data_block, self.ts = collect_adcs(
            self.carrier, self.npt, self.n_channels)
        # ADC count / FULL SCALE => [-1.0, 1.        pass
        self.nblock = ADC.counts_to_volts(np.array(data_block))
        self.process_subscriptions()

    def process_subscriptions(self):
        for ch_id, (ch_n, fn) in self.subscriptions.items():
            self.results[ch_id] = fn(self.nblock[ch_n])

    def add_subscription(self, sub_id, ch_n, fn):
        # TODO: Add args/kwargs to the function
        self.subscriptions[sub_id] = (ch_n, fn)
        Logger.critical('Added subscription {}'.format(sub_id))

    def remove_subscription(self, sub_id):
        self.subscriptions.pop(sub_id)


class Processing:
    @staticmethod
    def identity(ch_data):
        return range(len(ch_data)), ch_data

    @staticmethod
    def fft(x, **kwargs):
        pass

    @staticmethod
    def csd(x, **kwargs):
        pass


g_channels = {}


# TODO: Should convert this to a dataclass for python 3.7+
class GUIGraphChannel:
    def __init__(self, ch_id, show=False, xlog=False, ylog=False):
        self.ch_id = ch_id
        self.show = show
        self.xlog = xlog
        self.ylog = ylog
        self.fig = plt.figure()
        self.wid = FigureCanvas(self.fig)
        self.ax = self.fig.add_subplot(111)
        self.plot = self.ax.plot(range(100), [1/2]*100)[0]
        self.carrier_ch_n = int(ch_id[1]) if int(ch_id[0]) < 2 else None

    def update_data(self):
        if self.ch_id not in carrier.results:
            Logger.critical('No data found')
            return
        print(carrier.results[self.ch_id][0])
        self.plot.set_xdata(carrier.results[self.ch_id][0][:10000])
        self.ax.set_xlim(0, 10000)
        self.plot.set_ydata(carrier.results[self.ch_id][1][:10000])
        self.ax.set_ylim(0, 1.0)

    def set_plot_active(self, b):
        self.show = b

    @staticmethod
    def setup_gui_channels(carrier):
        for i in range(carrier.n_channels):
            ch_id = "0" + str(i)
            g_channels[ch_id] = GUIGraphChannel(ch_id)
            ch_id = "1" + str(i)
            g_channels[ch_id] = GUIGraphChannel(ch_id)
        ch_id = "3"
        g_channels[ch_id] = GUIGraphChannel(ch_id)


class Logic(BoxLayout):
    def __init__(self, **kwargs):
        super(Logic, self).__init__()

    def ch_select(self, *args):
        plot_id = args[0]
        CH = g_channels[plot_id]
        if args[-1]:
            CH.set_plot_active(True)
            self.add_widget(CH.wid)
            carrier.add_subscription(plot_id, int(
                args[0][1]), Processing.identity)
        else:
            CH.set_plot_active(False)
            self.remove_widget(CH.wid)
            carrier.remove_subscription(plot_id)

    def start(self):
        Clock.schedule_interval(self.populate_graph, 0.01)

    def stop(self):
        Clock.unschedule(self.populate_graph)

    def populate_graph(self, dt):
        for _, ch in g_channels.items():
            ch.update_data()
            ch.wid.draw()
            # ch.ax.relim()
            # ch.ax.autoscale()


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
        default='192.168.1.121')
    parser.add_argument(
        '-p', '--port', help='port', dest='port', type=int, default=50006)
    parser.add_argument(
        '-m', '--mask', help='mask', dest='mask', type=str, default='0x3')
    parser.add_argument(
        '-n',
        '--npt_wish',
        help='number of points per channel',
        type=int,
        default=4096)
    parser.add_argument(
        '-c', '--count', help='number of acquisitions', type=int, default=1)
    parser.add_argument(
        '-f', '--filewritepath', help='static file out', type=str, default="")
    parser.add_argument(
        "-u",
        "--use_spartan",
        action="store_true",
        help="use spartan",
        default=True)
    args = parser.parse_args()
    carrier = Carrier(ip_addr=args.ip,
                      port=args.port,
                      mask=args.mask,
                      npt_wish=args.npt_wish,
                      count=args.count,
                      filewritepath=args.filewritepath,
                      use_spartan=args.use_spartan,
                      test=True)
    GUIGraphChannel.setup_gui_channels(carrier)
    acq_thread = Thread(target=carrier.test_data)
    acq_thread.daemon = True
    acq_thread.start()
    Oscope().run()
