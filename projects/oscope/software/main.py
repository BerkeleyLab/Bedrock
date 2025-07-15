#!/usr/bin/env python

# Considering KIVY itself has no args, the following helps transfer
# the CLargs to python
import os
os.environ["KIVY_NO_ARGS"] = "1"

from kivy.logger import Logger
from kivy.garden.matplotlib.backend_kivyagg import FigureCanvas
from kivy.clock import Clock
from kivy.uix.boxlayout import BoxLayout
from kivy.app import App
from kivy.lang import Builder
from kivy.properties import ObjectProperty

import copy
import dataclasses
import json

from threading import Thread

from matplotlib import pyplot as plt

from carrier import ZestOnBMB7Carrier, LTCOnMarblemini
from misc import Processing

g_plot_type_limits = {}


@dataclasses.dataclass
class GUIGraphLimits:
    plot_type: str
    xlim: (float, float)
    ylim: (float, float)
    xlabel: str
    ylabel: str
    ylog: bool
    xlog: bool
    autoscale: bool


# TODO: Could convert this to a dataclass for python 3.7+
class GUIGraph:
    graphs = {}
    oscope_default_state = {
        'T': {'plot_type': 'T',
              'xlabel': 'Time [s]',
              'ylabel': 'ADC count',
              'xlim': [0, 0.01],
              'ylim': [-1., 1.],
              'autoscale': False,
              'ylog': False,
              'xlog': False},
        'F': {'plot_type': 'F',
              'xlabel': 'Frequency [Hz]',
              'ylabel': '[V/sqrt(Hz)]',
              'xlim': [0, 5e6],
              'ylim': [1e-11, 60000],
              'autoscale': True,
              'ylog': False,
              'xlog': False},
        'active_graphs': []
    }

    def __init__(self, ch_id, plot_info, show=False, label='Noname', **kwargs):
        self.ch_id = ch_id
        self.show = show
        self.label = label
        self.fig = plt.figure()
        self.wid = FigureCanvas(self.fig)
        self.ax = self.fig.add_subplot(111, **kwargs)
        self.line = self.ax.plot(range(100), [1 / 2] * 100, label=self.label)[0]
        self.ax.set_xlabel(plot_info.xlabel)
        self.ax.set_ylabel(plot_info.ylabel)
        self.ax.legend()
        self.ax.grid(True)
        self.carrier_ch_n = int(ch_id[1]) if int(ch_id[0]) < 2 else None
        self.plot_info = plot_info
        self._old_results = []

    def update_data(self):
        if self.ch_id not in carrier.results:
            # Logger.critical('No data found')
            return
        if carrier.results[self.ch_id] is self._old_results:
            return
        if self.plot_info.plot_type == 'T':
            x_data, y_data, y_max, ts = carrier.results[self.ch_id]
        elif self.plot_info.plot_type == 'F':
            x_data, y_data, xargmax, y_max = carrier.results[self.ch_id]
        self.line.set_xdata(x_data)
        self.line.set_ydata(y_data)
        self._old_results = carrier.results[self.ch_id]
        if not self.plot_info.autoscale:
            self.ax.set_xlim(self.plot_info.xlim)
            self.ax.set_ylim(self.plot_info.ylim)
        else:
            self.ax.relim()
            self.ax.autoscale()
        self.wid.draw()
        self.wid.flush_events()

    def set_plot_active(self, b):
        self.show = b

    @staticmethod
    def load_settings(settings_file='oscope_state.json'):
        try:
            with open(settings_file, 'r') as jf:
                oscope_state = json.load(jf)
        except IOError as e:
            Logger.warning(f'{e} occurred while reading settings_file, loading default settings')
            oscope_state = GUIGraph.oscope_default_state
        except json.JSONDecodeError as e:
            Logger.warning(f'{e} occurred while reading settings_file, loading default settings')
            oscope_state = GUIGraph.oscope_default_state
        return oscope_state

    @staticmethod
    def save_settings(settings_file='oscope_state.json'):
        GUIGraph.oscope_state['T'] = dataclasses.asdict(g_plot_type_limits['T'])
        GUIGraph.oscope_state['F'] = dataclasses.asdict(g_plot_type_limits['F'])
        GUIGraph.oscope_state['active_graphs'] = [g.ch_id for g in GUIGraph.graphs.values() if g.show]
        try:
            with open(settings_file, 'w') as jf:
                json.dump(GUIGraph.oscope_state, jf)
        except IOError:
            Logger.warning('State of oscope couldn\'t be saved')

    @staticmethod
    def setup_gui_graphs(carrier):
        GUIGraph.oscope_state = GUIGraph.load_settings()
        # Load possible types of limits: For now T for time domain,
        #                                and F for frequency
        g_plot_type_limits['T'] = GUIGraphLimits(**GUIGraph.oscope_state['T'])
        g_plot_type_limits['F'] = GUIGraphLimits(**GUIGraph.oscope_state['F'])
        # Create 2 GUI graphs for each channel of data coming from the carrier
        # 2 graphs, 1 for T and 1 for F
        for i in range(carrier.n_channels):
            ch_id = "0" + str(i)
            GUIGraph.graphs[ch_id] = GUIGraph(ch_id, g_plot_type_limits['T'],
                                              show=ch_id in GUIGraph.oscope_state['active_graphs'],
                                              label='CH{}-TimeDomain'.format(i))
            ch_id = "1" + str(i)
            GUIGraph.graphs[ch_id] = GUIGraph(ch_id, g_plot_type_limits['F'],
                                              show=ch_id in GUIGraph.oscope_state['active_graphs'],
                                              label='CH{}-Frequency'.format(i))
        ch_id = "3"
        GUIGraph.graphs[ch_id] = GUIGraph(ch_id, g_plot_type_limits['F'],
                                          show=ch_id in GUIGraph.oscope_state['active_graphs'],
                                          label='CSD')


class Logic(BoxLayout):
    autoscale = ObjectProperty(False)

    def __init__(self, **kwargs):
        super(Logic, self).__init__()
        self.csd_channels = 0, 1
        Clock.schedule_interval(self.update_graph, 1/5)
        self.plot_id = '00'
        self.plot_Q = []

    def update_ldf(self, *args):
        ldf = args[-1]
        ldf = ldf.text
        ldf = int(str(ldf))
        assert ldf < 32
        carrier.set_log_decimation_factor(ldf)

    def update_lim(self, axis, *args):
        '''
        Called from .kv
        '''
        CH = GUIGraph.graphs[self.plot_id]
        plot_limits = g_plot_type_limits[CH.plot_info.plot_type]
        if axis == 'autoscale':
            plot_limits.autoscale = args[1]
            GUIGraph.save_settings()
            return
        text = args[1]
        try:
            if axis == "X":
                plot_limits.xlim = eval(text)
            elif axis == "Y":
                plot_limits.ylim = eval(text)
        except Exception:
            Logger.warning('Invalid limits: ' + text)
        GUIGraph.save_settings()

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
        CH = GUIGraph.graphs[self.plot_id]
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
        Called from .kv
        plot_id == plot_type + channel_number
        plot_type is '0' for Timeseries, '1' for FFT, '3' for Cross Spectral Density
        TODO: We don't need to handle plot types in this messy way if they are formalized
        into classes and dealt with inheritance
        '''
        plot_selected = args[-1]  # Adds the plot when True, else removes it

        CH = GUIGraph.graphs[plot_id]

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
        GUIGraph.save_settings()

    def csd_validate(self, *args):
        try:
            self.csd_channels = tuple(
                map(lambda x: int(x) - 1, args[1].split('-')))
            if any([x >= carrier.n_channels for x in self.csd_channels]):
                raise Exception
            Logger.info('Set CSD channels to: {}'.format(args[1]))
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
        for _, ch in GUIGraph.graphs.items():
            if ch.show:
                ch.update_data()


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
        default='192.168.19.8:803')
    parser.add_argument(
        '-m', '--mask', help='mask', dest='mask', type=str, default='0x0f')
    parser.add_argument(
        '-b', '--board', help='ltc or zest', type=str, default='zest')
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
    args = parser.parse_args()
    if args.board == 'ltc':
        carrier = LTCOnMarblemini()
    else:
        carrier = ZestOnBMB7Carrier(
            ip_addr=args.ip,
            mask=args.mask,
            npt_wish=args.npt_wish,
            count=args.count,
            log_decimation_factor=args.log_decimation_factor,
            test=False)
    GUIGraph.setup_gui_graphs(carrier)
    acq_thread = Thread(target=carrier.acquire_data)
    acq_thread.daemon = True
    acq_thread.start()
    Oscope().run()
