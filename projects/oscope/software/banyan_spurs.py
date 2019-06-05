import time
import struct

import numpy as np
import datetime

from prc import c_prc
from banyan_ch_find import banyan_ch_find


def get_basis(pts_per_ch):
    '''
    Return basis vector for
    c1 cos_th + c2 sin_th + c3
    '''
    theta = np.array(list(range(pts_per_ch))) * 7 * 2 * np.pi / 33
    basis = np.vstack((np.cos(theta), np.sin(theta), theta * 0 + 1)).T
    return basis


def banyan_spurs_run(ip_addr='192.168.21.11',
                     port=50006,
                     mask="0xff",
                     npt_wish=0,
                     count=10,
                     verbose=False,
                     filewritepath=None,
                     use_spartan=False):
    prc = c_prc(
        ip_addr, port, filewritepath=filewritepath, use_spartan=use_spartan)

    banyan_status = prc.reg_read_value(['banyan_status'])[0]
    npt = 1 << ((banyan_status >> 24) & 0x3F)
    if npt == 1:
        print("aborting since hardware module not present")
        sys.exit(2)

    mask_int = int(mask, 0)
    prc.reg_write([{'banyan_mask': mask_int}])
    channels = banyan_ch_find(mask_int)
    n_channels = len(channels)
    print((channels, 8 // n_channels))

    #  npt_wish only works correctly if mask is 0xff
    if npt_wish and npt_wish < npt and mask_int == 0xff:
        npt = npt_wish
    print(("npt = {}".format(npt)))
    pts_per_ch = npt * 8 // n_channels

    basis = get_basis(pts_per_ch)
    chan_txt = "column assignment for banyan_mask 0x%2.2x: " % mask_int + " ".join(
        ["%d" % x for x in channels])

    print('Doing Noise analysis at frequency 7/33 * ADC frequency')
    for run_n in range(count):
        print(('Run: {}'.format(run_n)))
        (block, timestamp) = collect_adcs(prc, npt, n_channels)
        nblock = np.array(block).transpose()
        coeffzs = []
        for jx in range(n_channels if verbose else 0):
            fit = np.linalg.lstsq(basis, nblock.T[jx], rcond=-1)
            coeff = fit[0]
            coeffz = coeff[0] + 1j * coeff[1]
            dbfs = 20 * np.log10(abs(coeffz) / 32768.0)
            print(("analysis %d  %7.1f  %7.2f dBFS  %7.2f degrees" % (
                jx, abs(coeffz), dbfs, np.angle(coeffz) * 180 / np.pi)))
            coeffzs += [coeffz]
        if verbose and n_channels == 2:
            diff1 = (np.angle(coeffzs[1]) - np.angle(coeffzs[0])) * 180 / np.pi
            if diff1 > 180:
                diff1 -= 360
            if diff1 < -180:
                diff1 += 360
            print(("difference %6.2f" % diff1))
        if True:
            # ISO 8601  2016-06-02T16:06:14Z
            datetimestr = datetime.datetime.utcnow().isoformat() + "Z " + str(
                timestamp)
            header = "\n".join(["9999", datetimestr, chan_txt])

            if filewritepath:
                # Make sure path has terminating '/'
                if filewritepath.endswith('/') is False:
                    filewritepath = filewritepath + '/'
            else:
                filewritepath = ''
            np.savetxt(
                filewritepath + 'raw_z_%2.2d' % (run_n),
                nblock,
                fmt="%d",
                header=header)
    # print 'try this'
    # print process_adcs(prc,npt,mask_int)#,block,timestamp);


def pair_ram(prc, addr, count):
    '''
    addr needs to be numeric
    '''
    foo = prc.reg_read_alist(list(range(addr, addr + count)))
    uuu = [struct.unpack('!hh', x[2]) for x in foo]
    ram1 = [x[1] for x in uuu]
    ram2 = [x[0] for x in uuu]
    return [ram1, ram2]


def collect(prc, npt, print_minmax=True, allow_clk_frozen=False):
    prc.reg_write([{'rawadc_trig': 1}])
    (timestamp, minmax) = prc.slow_chain_readout()
    # if print_minmax:
    #     minmax_str = " ".join(["%d" % x for x in minmax])
    #     print(minmax_str, "%.8f" % (timestamp * 14 / 1320.0e6))
    while True:
        time.sleep(0.002)
        status = prc.reg_read_value(['banyan_status', 'clk_status_out'])
        b_status = status[0]
        clk_status = status[1]
        if not (b_status & 0x80000000):
            break
    # See logic for clk_status_r in digitizer_config.v, and associated comments.
    # The allow_clk_frozen feature is needed because collect() is called by prc.py
    # as part of the data transfer verification process.
    if not (clk_status == 2 or allow_clk_frozen and clk_status == 1):
        print('Loss of clock detected!'
              ' Rerun "prc.py -r" to recover.'
              ' Disaster, aborting!')
        exit(3)
    astep = 1 << ((b_status >> 24) & 0x3F)
    addr_wave0 = prc.get_read_address('banyan_data')
    value = []
    for ix in range(0, 8, 2):
        value.extend(pair_ram(prc, addr_wave0 + ix * astep, npt))
    return (value, timestamp)


# nchannels must be the result of len(banyan_ch_find())
def collect_adcs(prc, npt, nchannels, print_minmax=True):
    (value, timestamp) = collect(prc, npt, print_minmax)
    # value holds 8 raw RAM blocks
    # block will have these assembled into ADC channels
    mult = 8 // nchannels
    block = []
    for ix in range(nchannels):
        aaa = [value[jx] for jx in range(ix * mult, ix * mult + mult)]
        block.append(sum(aaa, []))
    return (block, timestamp)


def process_adcs(prc, npt, mask_int):
    channels = banyan_ch_find(mask_int)
    n_channels = len(channels)
    pts_per_ch = npt * (8 / n_channels)
    basis = get_basis(pts_per_ch)

    (block, timestamp) = collect_adcs(prc, npt, n_channels, print_minmax=False)
    nblock = np.array(block).transpose()
    # print('n_channels', n_channels, type(block), len(block), len(block[0]),
    #       nblock.T.shape)
    result = []
    phase0 = 0
    for ichan in range(n_channels):
        fit = np.linalg.lstsq(basis, nblock.T[ichan], rcond=-1)
        coeffz = fit[0][0] + 1j * fit[0][1]
        phase0 = np.angle(coeffz) * 180 / np.pi if ichan == 0 else phase0
        # print(phase0)
        result.extend(
            [abs(coeffz), (np.angle(coeffz) * 180 / np.pi - phase0) % 360])
    return result


def usage():
    print('python banyan_spurs.py -a 192.168.21.12 -m 0xff -n 1 -c 8192')


if __name__ == "__main__":
    import getopt
    import sys
    opts, args = getopt.getopt(sys.argv[1:], 'ha:p:c:m:n:vw:u', [
        'help', 'addr=', 'port=', 'count=', 'mask=', 'npt=', 'verbose',
        'filewritepath=', 'usespartan'
    ])
    ip_addr = '192.168.21.11'
    port = 50006
    mask = "0xff"
    npt_wish = 0
    count = 10
    verbose = False
    filewritepath = None
    use_spartan = False
    for opt, arg in opts:
        if opt in ('-h', '--help'):
            usage()
            sys.exit()
        elif opt in ('-a', '--address'):
            ip_addr = arg
        elif opt in ('-p', '--port'):
            port = int(arg)
        elif opt in ('-m', '--mask'):
            mask = arg
        elif opt in ('-n', '--npt'):
            npt_wish = int(arg)
        elif opt in ('-c', '--count'):
            count = int(arg)
        elif opt in ('-v', '--verbose'):
            verbose = True
        elif opt in ('-w', '--filewritepath'):
            filewritepath = arg
        elif opt in ('-u', '--usespartan'):
            use_spartan = True
    banyan_spurs_run(
        ip_addr=ip_addr,
        port=port,
        mask=mask,
        npt_wish=npt_wish,
        count=count,
        verbose=verbose,
        filewritepath=filewritepath,
        use_spartan=use_spartan)
