import time
from datetime import datetime


def tobin(x, count=8):
    # Integer to binary; count is number of bits
    # Some credit to W.J. van der Laan in
    # https://code.activestate.com/recipes/219300/
    return [(x >> y) & 1 for y in range(count-1, -1, -1)]


def vcd_header(fh, sigs, first, timescale="1ns", now=None):
    dw = len(sigs)
    if not now:
        now = datetime.isoformat(datetime.utcnow())
    print("$date %s $end" % now, file=fh)
    print("$version c2vcd $end", file=fh)
    print("$timescale %s $end" % timescale, file=fh)
    print("$scope module logic $end", file=fh)
    for ix in range(dw):
        print("$var wire 1 %s %s $end" % (chr(65+ix), sigs[ix]), file=fh)
    print("$upscope $end", file=fh)
    print("$enddefinitions $end", file=fh)
    print("$dumpvars", file=fh)
    for ix in range(dw):
        print("b%d %s" % (first[ix], chr(65+ix)), file=fh)
    print("$end", file=fh)


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
                    print("b%d %s" % (vbin[ix], chr(65+ix)), file=fh)
        print("#%d" % (t*tstep), file=fh)
        old_vbin = vbin
        pc += 1


def ctrace_start(fpga, ctrace_base="ctrace"):

    ctrace_status_name = ctrace_base + '_status'
    ctrace_start_name = ctrace_base + '_start'

    # print(ctrace_status_name)
    # print(ctrace_start_name)

    # req = [ctrace_status_name, (ctrace_start_name, 1), ctrace_status_name]
    # sucks that we lost the simple ability to read/write/read
    # could still force it with fpga.exchange(), right?
    fpga.reg_write([(ctrace_start_name, 0)])
    a1 = fpga.reg_read([ctrace_status_name])[0]
    fpga.reg_write([(ctrace_start_name, 1)])
    a2 = fpga.reg_read([ctrace_status_name])[0]

    print((ctrace_status_name + " before 0x%x  after 0x%x" % (a1, a2)))
    tc = 0
    while False and a2 == 0:
        time.sleep(0.001)
        a2 = fpga.reg_read([ctrace_status_name])[0]
        print((ctrace_status_name + " recheck!!         0x%x" % a2))
        tc += 1
        if tc > 5:
            print(("No evidence " + ctrace_base + " started, aborting!"))
            exit(1)


def ctrace_collect(fpga, ctrace_base="ctrace"):

    ctrace_status_name = ctrace_base + '_status'
    ctrace_data_name = ctrace_base + '_out'

    wait_cnt = 0
    while True:
        a = fpga.reg_read([ctrace_status_name])[0]
        print("poll %s 0x%x" % (ctrace_status_name, a))
        if (a & 1) == 0:
            break
        wait_cnt += 1
        time.sleep(0.1)
    print(("%d wait cycles" % wait_cnt))
    foo = fpga.reg_read([ctrace_data_name])[0]
    return foo


def ctrace_dump(dw, uuu, tw=16):
    npt = len(uuu)
    print(("# %d %d %d" % (tw, dw, npt)))
    mask = (1 << dw) - 1
    for ix in range(npt):
        print(("%d %d %x" % (ix, uuu[ix] >> dw, uuu[ix] & mask)))


def usage():
    print('python ctrace_dump_gps.py -a 192.168.165.44 -s -f foo.vcd')


if __name__ == "__main__":
    import leep
    import sys
    import getopt
    larglist = 'help', 'addr=', 'port=', 'start', 'dump', 'verbose', 'file='
    opts, args = getopt.getopt(sys.argv[1:], 'ha:p:sdvf:', larglist)
    ip_addr = ''
    port = 803
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
    if ip_addr == '':
        print("must supply IP address")
        exit(1)
    leep_addr = "leep://" + ip_addr + ":" + str(port)
    fpga = leep.open(leep_addr)
    # signals, tw, tstep should be runtime config
    # this static configuration matches GPS_CTRACE option in lb_marble_slave.v
    signals = ["pps", "uart"]
    tw = 18
    tstep = 8  # ns
    # effective aw determined at runtime via leep and config_rom
    # done with setup, now start the actions
    if do_start:
        ctrace_start(fpga)
    if do_dump or out_file:
        uuu = ctrace_collect(fpga)
    if out_file:
        with open(out_file, 'w') as fh:
            write_vcd(fh, signals, uuu, tstep=tstep, tw=tw)
    if do_dump:
        ctrace_dump(len(signals), uuu, tw=tw)
