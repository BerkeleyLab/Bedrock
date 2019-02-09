import struct
import time
from datetime import datetime


def tobin(x, count=8):
    # Integer to binary; count is number of bits
    # Some credit to W.J. van der Laan in
    # http://code.activestate.com/recipes/219300/
    return map(lambda y: (x >> y) & 1, range(count-1, -1, -1))


def vcd_header(fh, sigs, first, timescale="1ns", now=None):
    dw = len(sigs)
    if not now:
        now = datetime.isoformat(datetime.utcnow())
    print >>fh, "$date %s $end" % now
    print >>fh, "$version c2vcd $end"
    print >>fh, "$timescale %s $end" % timescale
    print >>fh, "$scope module logic $end"
    for ix in range(dw):
        print >>fh, "$var wire 1 %s %s $end" % (chr(65+ix), sigs[ix])
    print >>fh, "$upscope $end"
    print >>fh, "$enddefinitions $end"
    print >>fh, "$dumpvars"
    for ix in range(dw):
        print >>fh, "b%d %s" % (first[ix], chr(65+ix))
    print >>fh, "$end"


# 50 MHz and ns time step means multiply integer time count by 20
# tw parameter should be configured to match that set for ctrace.v
def write_vcd(fh, sigs, data, tstep=20, tw=16):
    dw = len(sigs)  # this also needs to match ctrace.v parameter
    t = 0
    pc = 0
    mtime = 1 << tw
    data_mask = (1 << dw) - 1
    old_vbin = None
    for a in data:
        dt = a >> dw
        if dt == 0:
            dt = mtime
        t = t + dt
        v = a & data_mask
        vbin = tobin(v, count=dw)
        if pc == 0:
            vcd_header(fh, sigs, vbin)
        else:
            for ix in range(dw):
                if vbin[ix] != old_vbin[ix]:
                    print >>fh, "b%d %s" % (vbin[ix], chr(65+ix))
        print >>fh, "#%d" % (t*tstep)
        old_vbin = vbin
        pc += 1


def ctrace_start(fpga, index=""):

    ctrace_base = 'ctrace' + index
    ctrace_running_name = ctrace_base + '_running'
    ctrace_start_name = ctrace_base + '_start'

    print(ctrace_running_name)
    print(ctrace_start_name)

    req = ctrace_running_name, (ctrace_start_name, 1), ctrace_running_name
    a1, a2 = fpga.query_resp_list(req)

    print(ctrace_running_name + " before 0x%x  after 0x%x" % (a1, a2))
    tc = 0
    while a2 == 0:
        time.sleep(0.001)
        a2 = fpga.query_resp_list([ctrace_running_name])[0]
        print(ctrace_running_name + " recheck!!         0x%x" % a2)
        tc += 1
        if tc > 5:
            print("No evidence " + ctrace_base + " started, aborting!")
            exit(1)


def ctrace_collect(fpga, index="", base_addr=None, npt=8192):
    if base_addr is None:
        addr = 0x160000
    else:
        addr = base_addr

    print(addr)

    ctrace_base = 'ctrace' + index
    ctrace_running_name = ctrace_base + '_running'

    wait_cnt = 0
    while True:
        a = fpga.query_resp_list([ctrace_running_name])[0]
        print("poll ctrace_running 0x%x" % a)
        if (a & 1) == 0:
            break
        wait_cnt += 1
        time.sleep(0.1)
    print("%d wait cycles" % wait_cnt)
    foo = fpga.reg_read_alist(range(addr, addr+npt))
    return [struct.unpack('!I', x[2])[0] for x in foo]


def ctrace_dump(dw, uuu, tw=16):
    npt = len(uuu)
    # split should be made configurable
    print("# %d %d" % (tw, dw))
    mask = (1 << dw) - 1
    for ix in range(npt):
        print("%d %d %x" % (ix, uuu[ix] >> dw, uuu[ix] & mask))


def usage():
    print('python ctrace_dump.py -a 192.168.165.44 -s -f foo.vcd')


if __name__ == "__main__":
    from llrf_bmb7 import c_llrf_bmb7
    import sys
    import getopt
    larglist = 'help', 'addr=', 'port=', 'start', 'dump', 'verbose', 'file='
    opts, args = getopt.getopt(sys.argv[1:], 'ha:p:sdvf:', larglist)
    ip_addr = '192.168.21.48'
    port = 50006
    do_start = False
    do_dump = False
    verbose = False
    out_file = None
    for opt, arg in opts:
        if opt in ('-h', '--help'):
            usage()
            sys.exit()
        elif opt in ('-a', '--address'):
            ip_addr = arg
        elif opt in ('-p', '--port'):
            port = int(arg)
        elif opt in ('-s', '--start'):
            do_start = True
        elif opt in ('-d', '--dump'):
            do_dump = True
        elif opt in ('-f', '--file'):
            out_file = arg
        elif opt in ('-v', '--verbose'):
            verbose = True
    fpga = c_llrf_bmb7(ip_addr, port)
    # signals should be runtime config
    # this static configuration matches application_top.v
    signals = ["wrong_frame", "crc_fault", "wrong_prot", "timeout", "gtx_rxs",
               "valid_sync", "error", "byte_aligned"]
    signals = ["bit%2.2d" % jx for jx in range(8)] + signals
    tw = 16
    aw = 13
    # done with setup, now start the actions
    if do_start:
        ctrace_start(fpga)
    if do_dump or out_file:
        uuu = ctrace_collect(fpga, npt=1 << aw)
    if out_file:
        with open(out_file, 'w') as fh:
            write_vcd(fh, signals, uuu, tw=tw)
    if do_dump:
        ctrace_dump(len(signals), uuu, tw=tw)
