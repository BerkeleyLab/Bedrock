import argparse
import sys

import numpy as np
from matplotlib import pyplot as plt


def get_output(sat_ctl, x):
    mag = x ** 2
    quad = mag ** 2
    quad = (np.where(mag, mag <= 1, 1) * quad +
            np.where(mag, mag > 1, 1) * (2 * mag - 1))
    gain = 1 + sat_ctl - mag + quad / 4
    return gain * x


def simulate():
    x = np.linspace(0, 1, 1000) * np.sqrt(2)
    for sat_ctl in np.linspace(0.25, 0.75, 5):
        y = get_output(sat_ctl, x)
        plt.plot(x, y)
    plt.show()


def make_check(show_plots=False):
    sat_ctl = 0.75
    verilog_out = np.loadtxt('a_compress.dat')
    x = verilog_out[:, 0] * np.sqrt(2) / (1 << 17)
    y_verilog = verilog_out[:, 1] * np.sqrt(2) / (1 << 17)
    y_simulate = get_output(sat_ctl, x)

    if show_plots:
        plt.plot(x, y_verilog, verilog_out, 'r')
        plt.xlabel('input')
        plt.ylabel('output')
        plt.show()

    err = y_simulate - y_verilog

    if np.max(np.abs(err)) > 0.0001:
        print('FAIL')
        sys.exit(1)
    else:
        print('PASS')


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Test a_compress')
    parser.add_argument('-c', '--check', action='store_true', default=True,
                        help='Purely run the check')
    parser.add_argument('-s', '--simulate', action='store_true',
                        help='Run the simulation and then check and show plots')
    args = parser.parse_args()
    if args.simulate:
        simulate()
        make_check(show_plots=True)
    else:
        make_check()
