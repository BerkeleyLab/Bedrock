import sys

import numpy as np
from matplotlib import pyplot as plt
import matplotlib.animation as animation

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
    scale = 1 << (bits-1)  # signed
    sample_rate = 100000000.


def get_volts(raw_counts):
    return raw_counts / (1. * ADC.scale)


def run(ip_addr='192.168.1.121',
        port=50006,
        mask="0xff",
        npt_wish=0,
        count=10,
        verbose=False,
        filewritepath=None,
        use_spartan=False):

    mask_int = int(mask, 0)
    prc = c_prc(
        ip_addr, port, filewritepath=filewritepath, use_spartan=use_spartan)

    npt = get_npt(prc)
    n_channels, channels = write_mask(prc, mask_int)
    pts_per_ch = npt * 8 // n_channels

    fig, axes = plt.subplots(nrows=n_channels)
    axes = [axes] if n_channels == 1 else axes
    styles = ['r-', 'g-', 'y-', 'm-'][:n_channels]

    x = np.arange(0, pts_per_ch) / 10e3
    x = np.fft.rfftfreq(pts_per_ch, d=1/ADC.sample_rate)
    y = np.sin(x)

    def plot(ax, style, ch):
        line = ax.plot(x, y, style, label=ch, animated=True)[0]
        ax.set_ylabel('ADC data scaled to +/-1v')
        ax.set_xlabel('Time[us]')
        ax.legend()
        return line
    lines = [plot(ax, style, ch) for ax, style, ch in zip(axes, styles, channels)]

    def animate(x):
        (block, timestamp) = collect_adcs(prc, npt, n_channels)
        nblock = get_volts(np.array(block))
        # print(x)
        for j, line in enumerate(lines, start=1):
            ax = axes[j-1]
            ax.relim()
            ax.autoscale_view()
            ch_data = nblock[j-1]
            rfft = np.abs(np.fft.rfft(get_volts(ch_data)))
            line.set_ydata(rfft)
            # line.set_ydata()
        return lines

    # npt_wish only works correctly if mask is 0xff
    if npt_wish and npt_wish < npt and mask_int == 0xff:
        npt = npt_wish
    print(("npt = {}".format(npt)))
    pts_per_ch = npt * 8 / n_channels

    chan_txt = "column assignment for banyan_mask 0x%2.2x: " % mask_int + " ".join(
        ["%d" % x for x in channels])

    # We'd normally specify a reasonable "interval" here...
    ani = animation.FuncAnimation(fig, animate, interval=0.1, blit=True)
    plt.show()
    # for run_n in range(count):
    #     print('Run: {}'.format(run_n))
    #     animate(nblock.T)
    #     if False:
    #         # ISO 8601  2016-06-02T16:06:14Z
    #         datetimestr = datetime.datetime.utcnow().isoformat() + "Z " + str(
    #             timestamp)
    #         header = "\n".join(["9999", datetimestr, chan_txt])
    #         if filewritepath:
    #             # Make sure path has terminating '/'
    #             if filewritepath.endswith('/') is False:
    #                 filewritepath = filewritepath + '/'
    #         else:
    #             filewritepath = ''
    #         np.savetxt(
    #             filewritepath + 'raw_z_%2.2d' % (run_n),
    #             nblock,
    #             fmt="%d",
    #             header=header)


if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser(description='Read/Write from FPGA memory')
    parser.add_argument('-a', '--ip', help='ip_address', dest='ip', type=str,
                        default='192.168.1.121')
    parser.add_argument('-p', '--port', help='port', dest='port', type=int,
                        default=50006)
    parser.add_argument('-m', '--mask', help='mask', dest='mask', type=str,
                        default='0x3')
    parser.add_argument('-n', '--npt_wish', help='number of points per channel', type=int,
                        default=4096)
    parser.add_argument('-c', '--count', help='number of acquisitions', type=int,
                        default=1)
    parser.add_argument('-f', '--filewritepath', help='static file out',
                        type=str, default="")
    parser.add_argument("-u", "--use_spartan", action="store_true", help="use spartan",
                        default=True)
    args = parser.parse_args()
    run(ip_addr=args.ip,
        port=args.port,
        mask=args.mask,
        npt_wish=args.npt_wish,
        count=args.count,
        filewritepath=args.filewritepath,
        use_spartan=args.use_spartan)
