import time
import struct
import numpy
import datetime
import sys
import os

sys.path.append(os.path.join(os.path.dirname(__file__), "../../dsp"))

from banyan_ch_find import banyan_ch_find

# Grab the start time early, so things like
# python get_raw_adcs.py | tee `date "+%Y%m%d_%H%M%S"`.log
# will usually get a timestamp that matches
start_time = datetime.datetime.now()


def banyan_status(dev):
    b_status, clk_status = dev.reg_read(['banyan_status', 'clk_status_out'])
    # full and not (running or armed)
    b_readable = b_status & 0x40000000 and not (b_status & 0x80400000)
    astep = 1 << ((b_status >> 24) & 0x3F)
    return b_readable, astep, clk_status


def get_raw_adcs_run(dev, filewritepath='raw_adcs_', ext_trig=False, freq=7/33.0,
                     mask="0xff", npt_wish=0, count=10, save_data=True, verbose=False):

    _, npt, _ = banyan_status(dev)
    if npt == 1:
        raise ValueError("Aborting since hardware module not present")
    mask_int = int(mask, 0)
    # npt_wish only works correctly if mask is 0xff
    if npt_wish and npt_wish < npt and mask_int == 0xff:
        npt = npt_wish
    print("npt = %d" % npt)

    dev.reg_write([('banyan_mask', mask_int)])
    chans = banyan_ch_find(mask_int)
    print(chans, 8/len(chans))
    nptx = int(npt*8/len(chans))
    theta = numpy.array(range(nptx))*freq*2*numpy.pi
    basis = numpy.vstack((numpy.cos(theta), numpy.sin(theta), theta*0+1)).T
    chan_txt = "column assignment for banyan_mask 0x%2.2x: " % mask_int + " ".join(["%d" % x for x in chans])

    header = ''
    filename = ''

    for run_n in range(count):
        print(run_n)
        (block, timestamp) = collect_adcs(dev, npt, len(chans), ext_trig=ext_trig)
        nblock = numpy.array(block).transpose()
        coeffzs = []
        for jx in range(len(chans) if verbose else 0):
            fit = numpy.linalg.lstsq(basis, nblock.T[jx], rcond=-1)
            coeff = fit[0]
            coeffz = coeff[0]+1j*coeff[1]
            print_dbfs = numpy.log10(abs(coeffz)/32768.0)*20
            tup = jx, abs(coeffz), print_dbfs, numpy.angle(coeffz)*180/numpy.pi
            print("analysis %d  %7.1f  %7.2f dBFS  %7.2f degrees" % tup)
            coeffzs += [coeffz]
        if verbose and len(chans) == 2:
            diff1 = (numpy.angle(coeffzs[1]) - numpy.angle(coeffzs[0]))*180/numpy.pi
            if diff1 > 180:
                diff1 -= 360
            if diff1 < -180:
                diff1 += 360
            print("difference %6.2f" % diff1)
        if save_data is True:
            # ISO 8601  2016-06-02T16:06:14Z
            datetimestr = datetime.datetime.utcnow().isoformat()+"Z "+str(timestamp)
            header = "\n".join([datetimestr, chan_txt])

            data_dir = start_time.strftime(filewritepath + '%Y%m%d_%H%M%S')
            if not os.path.exists(data_dir):
                os.mkdir(data_dir)

            filename = data_dir + '/raw_z_%2.2d' % (run_n)
            numpy.savetxt(filename, nblock, fmt="%d", header=header)
    return header, filename, block

    # print 'try this'
    # print process_adcs(dev, npt, mask_int, freq=freq)  #,block,timestamp);


def pair_ram(buff, idx, count):

    buff_slice = buff[idx:idx+count]

    # break 32-bit elements into 16-bit raw ADC samples
    ram1 = [(x >> 16) & 0xffff for x in buff_slice]
    ram2 = [x & 0xffff for x in buff_slice]
    return [ram2, ram1]


def pair_ram_prc(prc, addr, count):
    foo = prc.reg_read_alist(range(addr, addr+count))
    uuu = [struct.unpack('!hh', x[2]) for x in foo]
    ram1 = [x[1] for x in uuu]
    ram2 = [x[0] for x in uuu]
    return [ram1, ram2]


def reshape_buffer(buf, astep, npt):
    # TODO: This copy can be avoided if leep/raw.py spits out numpy arrays,
    #       which we should look into
    data = numpy.array(buf)
    # Read the upper and lower part of the banyan buffer
    p1, p2 = (data & 0xffff).astype('int16'), ((data >> 16) & 0xffff).astype('int16')
    out = numpy.empty((8, 2*astep))
    # Interleave p1 and p2
    out[::2, :] = p1.reshape(4, 2*astep)
    out[1::2, :] = p2.reshape(4, 2*astep)
    out = out[:, :npt]
    return out


def gen_test_data(npt):
    return numpy.hstack([numpy.ones(npt).astype(numpy.int32) * (i+1) for i in range(8)])


def collect(dev, npt, print_minmax=True, ext_trig=False, allow_clk_frozen=False, slow_chain=True):
    dev.reg_write([('rawadc_trig_req', 1)]) if ext_trig else dev.reg_write([('rawadc_trig', 1)])

    if slow_chain:
        timestamp, minmax = slow_chain_readout(dev)
    else:
        timestamp, minmax = (0, 16*[0])
    if print_minmax:
        print(" ".join(["%d" % x for x in minmax]), "%.8f" % (timestamp*14/1320.0e6))

    while True:
        time.sleep(0.002)
        b_readable, astep, clk_status = banyan_status(dev)
        if b_readable:
            break
    # See logic for clk_status_r in digitizer_config.v, and associated comments.
    # The allow_clk_frozen feature is needed because collect() is called by zest_setup.py
    # as part of the data transfer verification process.
    if not (clk_status == 2 or allow_clk_frozen and clk_status == 1):
        raise SystemError('Loss of clock detected!  Rerun "zest_setup.py -r" to recover.  Disaster, aborting!')

    # TODO: The I/O call here takes twice as long, as leep/raw.py is not aware of the banyan, dual
    #       read option. The old collect_prc takes advantage of that but not leep.
    full_buffer, = dev.reg_read([('banyan_data')])
    value = []
    for ix in range(0, 8, 2):
        value.extend(pair_ram(full_buffer, ix*astep, npt))
    return value, timestamp


def collect_prc(prc, npt, print_minmax=True, ext_trig=False, allow_clk_frozen=False, slow_chain=True):
    prc.reg_write([{'rawadc_trig_req': 1}]) if ext_trig else prc.reg_write([{'rawadc_trig': 1}])

    if slow_chain:
        timestamp, minmax = slow_chain_readout(dev)
    else:
        timestamp, minmax = (0, 16*[0])
    if print_minmax:
        print(" ".join(["%d" % x for x in minmax]), "%.8f" % (timestamp*14/1320.0e6))

    while True:
        time.sleep(0.002)
        b_readable, astep, clk_status = banyan_status(dev)
        if b_readable:
            break
    # See logic for clk_status_r in digitizer_config.v, and associated comments.
    # The allow_clk_frozen feature is needed because collect() is called by zest_setup.py
    # as part of the data transfer verification process.
    if not (clk_status == 2 or allow_clk_frozen and clk_status == 1):
        raise SystemError('Loss of clock detected!  Rerun "zest_setup.py -r" to recover.  Disaster, aborting!')

    addr_wave0 = prc.get_read_address('banyan_data')
    value = []
    for ix in range(0, 8, 2):
        value.extend(pair_ram_prc(prc, addr_wave0+ix*astep, npt))
    return value, timestamp


def collect_adcs(dev, npt, nchans, print_minmax=True, ext_trig=False):
    '''
    nchans must be the result of len(banyan_ch_find())
    '''
    value, timestamp = collect(dev, npt, print_minmax, ext_trig=ext_trig)
    # value holds 8 raw RAM blocks
    # block will have these assembled into ADC channels
    mult = 8//nchans
    block = []
    for ix in range(nchans):
        aaa = [value[jx] for jx in range(int(ix*mult), int(ix*mult+mult))]
        block.append(sum(aaa, []))
    block2 = []
    for bx in block:
        bx2 = [x if x < 32768 else x-65536 for x in bx]
        block2.append(bx2)
    return block2, timestamp


def process_adcs(dev, npt, mask_int, freq=7/33.0):  # ,block,timestamp):
    chans = banyan_ch_find(mask_int)
    nptx = int(npt*(8/len(chans)))
    theta = numpy.array(range(nptx))*freq*2*numpy.pi
    basis = numpy.vstack((numpy.cos(theta), numpy.sin(theta), theta*0+1)).T
    (block, timestamp) = collect_adcs(dev, npt, len(chans), print_minmax=False)
    nblock = numpy.array(block).transpose()
    # print 'len(chans)',len(chans),type(block),len(block),len(block[0]),nblock.T.shape
    result = []
    phase0 = 0
    for ichan in range(len(chans)):
        fit = numpy.linalg.lstsq(basis, nblock.T[ichan], rcond=-1)
        coeffz = fit[0][0]+1j*fit[0][1]
        phase0 = numpy.angle(coeffz)*180/numpy.pi if ichan == 0 else phase0
        # print phase0
        result.extend([abs(coeffz), (numpy.angle(coeffz)*180/numpy.pi-phase0) % 360])
    return result


def slow_chain_unpack(readlist):
    nums = [256*readlist[ix]+readlist[ix+1] for ix in range(0, 32, 2)]
    nums = [x if x < 32768 else x-65536 for x in nums]
    timestamp = 0
    for ix in range(8):
        timestamp = timestamp*256 + int(readlist[41-ix])
    timestamp = timestamp/32  # integer number of 1320/14 MHz adc_clk cycles
    # ignore old_tag and new_tag for now
    return (timestamp, nums)  # nums is 16-long list of minmax values


def slow_chain_readout(dev):
    readlist = dev.reg_read(42*[('slow_chain_out')])
    return slow_chain_unpack(readlist)


def get_freq(fstring):
    # will crash if the string isn't either a simple float (e.g., 0.2121)
    # or a fraction (e.g., 7/33).
    a = fstring.split('/')
    if len(a) == 2:
        freq = int(a[0]) / float(int(a[1]))
    else:
        freq = float(fstring)
    # print("%s %f" % (fstring, freq))
    return freq


def usage():
    print("python get_raw_adcs_.py -a leep://192.168.21.12 -m 0xff -n 1 -c 8192")


if __name__ == "__main__":

    from argparse import ArgumentParser

    parser = ArgumentParser(description="Banyan Spurs: Legacy logic on waveform acquisition and logging")

    parser.add_argument('-a', '--address', dest="dev_addr", default=None,
                        help='Device URL (leep://<IP> or ca://<PREFIX>)')
    parser.add_argument('-D', '--dir', dest='filewritepath', default="raw_adcs_",
                        help='Log/data directory prefix (can include path)')
    parser.add_argument('-f', '--freq', dest='freq', default="7/33", type=str,
                        help='IF/Fs ratio, where rational numbers like 7/33 are accepted')
    parser.add_argument('-e', '--ext_trig', dest='ext_trig', action='store_true', default=False,
                        help='Use external trigger to capture data')
    parser.add_argument('-m', '--mask', dest="mask", default="0xff",
                        help='Channel mask')
    parser.add_argument('-n', '--npt', dest="npt_wish", default=0, type=int,
                        help='Number of points per acquisition')
    parser.add_argument('-c', '--count', dest="count", default=10, type=int,
                        help='Number of acquisitions')
    parser.add_argument('-v', '--verbose', dest='verbose', action='store_true', default=False,
                        help='Verbose mode')
    parser.add_argument('-t', '--timeout', type=float, default=0.1,
                        help='LEEP network timeout')

    args = parser.parse_args()

    print("get_raw_adcs: collect and save Banyan waveforms")

    freq = get_freq(args.freq)

    import leep

    print("Raw ADC acquisition")
    print('Carrier board URL %s' % args.dev_addr)
    dev = leep.open(args.dev_addr, instance=[], timeout=args.timeout)

    print("Using external trigger...") if args.ext_trig else print("Using internal trigger...")
    get_raw_adcs_run(dev, filewritepath=args.filewritepath, freq=freq, ext_trig=args.ext_trig,
                     mask=args.mask, npt_wish=args.npt_wish, count=args.count, verbose=args.verbose)
    print("Done")
