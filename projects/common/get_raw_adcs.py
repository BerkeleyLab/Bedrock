# XXX There's another file with this same name, and similar
# (but incompatible) collect() routine, in lcls2_llrf/software/prc/ .
# These two versions desperately need to be reconciled,
# and one of them removed.
# XXX This copy is _not_ used by lcls2_llrf flows (prc or injector).

import time
import struct
from banyan_ch_find import banyan_ch_find
import numpy
import datetime
import sys
import os

sys.path.append(os.path.join(os.path.dirname(__file__), "../submodules/FEED/src/python"))

# Grab the start time early, so things like
# python get_raw_adcs.py | tee `date "+%Y%m%d_%H%M%S"`.log
# will usually get a timestamp that matches
start_time = datetime.datetime.now()


def get_raw_adcs_run(dev, filewritepath='raw_adcs_', mask="0xff", npt_wish=0, count=10, save_data=True, verbose=False):

    b_status = dev.reg_read([('banyan_status')])[0]
    npt = 1 << ((b_status >> 24) & 0x3F)
    if npt == 1:
        print("aborting since hardware module not present")
        sys.exit(2)
    mask_int = int(mask, 0)
    # npt_wish only works correctly if mask is 0xff
    if npt_wish and npt_wish < npt and mask_int == 0xff:
        npt = npt_wish
    print("npt = %d" % npt)

    dev.reg_write([('banyan_mask', mask_int)])
    chans = banyan_ch_find(mask_int)
    print(chans, 8/len(chans))
    nptx = int(npt*8/len(chans))
    theta = numpy.array(range(nptx))*7*2*numpy.pi/33
    basis = numpy.vstack((numpy.cos(theta), numpy.sin(theta), theta*0+1)).T
    chan_txt = "column assignment for banyan_mask 0x%2.2x: " % mask_int + " ".join(["%d" % x for x in chans])

    header = ''
    filename = ''

    for run_n in range(count):
        print(run_n)
        (block, timestamp) = collect_adcs(dev, npt, len(chans))
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


def collect(dev, npt, print_minmax=True, allow_clk_frozen=False):
    dev.reg_write([('rawadc_trig', 1)])
    timestamp, minmax = slow_chain_readout(dev)
    if print_minmax:
        print(" ".join(["%d" % x for x in minmax]), "%.8f" % (timestamp*14/1320.0e6))
    while True:
        time.sleep(0.002)
        status = dev.reg_read(['banyan_status', 'clk_status_out'])
        b_status = status[0]
        clk_status = status[1]
        # print "%8.8x"%b_status
        if not (b_status & 0x80000000):
            break
    # See logic for clk_status_r in digitizer_config.v, and associated comments.
    # The allow_clk_frozen feature is needed because collect() is called by zest_setup.py
    # as part of the data transfer verification process.
    if not (clk_status == 2 or allow_clk_frozen and clk_status == 1):
        print('Loss of clock detected!  Rerun "zest_setup.py -r" to recover.  Disaster, aborting!')
        exit(3)
    astep = 1 << ((b_status >> 24) & 0x3F)

    # TODO: The I/O call here takes twice as long, as leep/raw.py is not aware of the banyan, dual
    #       read option. The old collect_prc takes advantage of that but not leep.
    full_buffer, = dev.reg_read([('banyan_data')])
    # full_buffer = gen_test_data(npt)  # For debugging
    return reshape_buffer(full_buffer, astep, npt), timestamp


def collect_prc(prc, npt, print_minmax=True, allow_clk_frozen=False):
    prc.reg_write([{'rawadc_trig': 1}])
    (timestamp, minmax) = prc.slow_chain_readout()
    if print_minmax:
        print(" ".join(["%d" % x for x in minmax]), "%.8f" % (timestamp*14/1320.0e6))
    while True:
        time.sleep(0.002)
        status = prc.reg_read_value(['banyan_status', 'clk_status_out'])
        b_status = status[0]
        clk_status = status[1]
        # print "%8.8x"%b_status
        if not (b_status & 0x80000000):
            break
    # See logic for clk_status_r in digitizer_config.v, and associated comments.
    # The allow_clk_frozen feature is needed because collect() is called by zest_setup.py
    # as part of the data transfer verification process.
    if not (clk_status == 2 or allow_clk_frozen and clk_status == 1):
        print('Loss of clock detected!  Rerun "zest_setup.py -r" to recover.  Disaster, aborting!')
        exit(3)
    astep = 1 << ((b_status >> 24) & 0x3F)
    addr_wave0 = prc.get_read_address('banyan_data')
    value = []
    for ix in range(0, 8, 2):
        value.extend(pair_ram_prc(prc, addr_wave0+ix*astep, npt))
    return (value, timestamp)


def collect_adcs(dev, npt, nchans, print_minmax=True):
    '''
    nchans must be the result of len(banyan_ch_find())
    '''
    value, timestamp = collect(dev, npt, print_minmax)
    # value holds 8 raw RAM blocks
    # block will have these assembled into ADC channels
    mult = 8//nchans
    block = []
    for ix in range(nchans):
        ch_data = value[ix*mult:(ix+1)*mult].reshape(mult*npt)
        block.append(ch_data)
    return block, timestamp


def process_adcs(dev, npt, mask_int):  # ,block,timestamp):
    chans = banyan_ch_find(mask_int)
    nptx = int(npt*(8/len(chans)))
    theta = numpy.array(range(nptx))*7*2*numpy.pi/33
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
        timestamp = timestamp*256 + readlist[41-ix]
    timestamp = timestamp/32  # integer number of 1320/14 MHz adc_clk cycles
    # ignore old_tag and new_tag for now
    return (timestamp, nums)  # nums is 16-long list of minmax values


def slow_chain_readout(dev):
    readlist = dev.reg_read(42*[('slow_chain_out')])
    return slow_chain_unpack(readlist)


def usage():
    print("python get_raw_adcs_.py -a leep://192.168.21.12 -m 0xff -n 1 -c 8192")


if __name__ == "__main__":

    from argparse import ArgumentParser

    parser = ArgumentParser(description="Banyan Spurs: Legacy logic on waveform acquisition and logging")

    parser.add_argument('-a', '--address', dest="dev_addr", default=None,
                        help='Device URL (leep://<IP> or ca://<PREFIX>)')
    parser.add_argument('-D', '--dir', dest='filewritepath', default="raw_adcs_",
                        help='Log/data directory prefix (can include path)')
    parser.add_argument('-m', '--mask', dest="mask", default="0xff",
                        help='Channel mask')
    parser.add_argument('-n', '--npt', dest="npt_wish", default=0, type=int,
                        help='Number of points per acquisition')
    parser.add_argument('-c', '--count', dest="count", default=10, type=int,
                        help='Number of acquisitions')
    parser.add_argument('-v', '--verbose', dest='verbose', action='store_true', default=False,
                        help='Verbose mode')

    args = parser.parse_args()

    print("get_raw_adcs: collect and save Banyan waveforms")

    import leep

    print("Raw ADC acquisition")
    print('Carrier board URL %s' % args.dev_addr)
    dev = leep.open(args.dev_addr, instance=[])

    get_raw_adcs_run(dev, filewritepath=args.filewritepath, mask=args.mask,
                     npt_wish=args.npt_wish, count=args.count, verbose=args.verbose)
    print("Done")
