# Utility to read GPS NMEA data from Marble Ethernet
# Here, NMEA is shorthand for NMEA 0183
#   https://en.wikipedia.org/wiki/NMEA_0183
from sys import stdin, stdout
from time import sleep, time
import leep
sats = []


# helpful hints at
# http://aprs.gids.nl/nmea/#gsv
def handle_gsv(gsv_state, a):
    global sats
    s_nmsg, s_imsg, s_nsat = gsv_state
    # print(a)
    ax = [int(x) if x != "" else -1 for x in a]
    # print("GSV state machine", gsv_state, ax[0:3])
    nmsg, imsg, nsat = ax[0:3]
    if s_imsg == 0 or (s_nmsg == nmsg and (s_imsg+1) == imsg):
        pass
        # print("next!")
    else:
        # print("pass!")
        next
    sats += ax[3:7], ax[7:11], ax[11:15], ax[15:19]
    if nmsg == imsg:
        # last in the set
        # print("foo", sats)
        print("  PRN   Elev   Azim   SNR")
        for sx in sats:
            if len(sx) == 4 and sx[1] >= 0:
                print("   %2d    %3d    %3d    %2d" % tuple(sx))
        sats = []
        imsg = 0
    return nmsg, imsg, nsat


def gps2dec(x):
    dd, ff = x.split(".")
    gdeg = int(dd[:-2]) + float(dd[-2:] + "." + ff)/60.0
    # print(x, gdeg)
    return gdeg


# helpful hints at
# https://code.activestate.com/recipes/576789-nmea-sentence-checksum/
def nmea_line(gsv_state, ll, verbose=False):
    ll = ll.strip()
    if len(ll) > 0 and ll[0] != "$":
        # print("bad start: " + ll)
        return gsv_state
    bb = ll[1:].split("*")
    if len(bb) == 2:
        nmea, chk1 = bb
        # chk2 = reduce(operator.xor, (ord(s) for s in nmea), 0)
        chk2 = 0
        for s in nmea:
            chk2 = chk2 ^ ord(s)
        if ("%2.2X" % chk2) != chk1:
            print("bad checksum: %2.2X %s %s" % (chk2, chk1, nmea))
            return gsv_state
        if verbose:
            print("valid %s" % nmea)
        aa = nmea.split(",")
        if aa[0] == "GPGSV":
            gsv_state = handle_gsv(gsv_state, aa[1:])
        if aa[0] == "GPGGA" and len(aa) > 6:
            # helpful hints at http://aprs.gids.nl/nmea/#gga
            # note the weird time format: "060534.000" means
            # 06:05:34.000 Z
            # note the weird lat/lon format: "3752.6812 N" means
            # 37 degrees 52.6812 minutes North
            gt = aa[1]
            utc_time = gt[0:2] + ":" + gt[2:4] + ":" + gt[4:] + " Z"
            lat = gps2dec(aa[2])
            lon = gps2dec(aa[4])
            pl = utc_time, lat, aa[3], lon, aa[5]
            print("GPS time  %s  coordinates %.6f %s, %.6f %s" % pl)
        if aa[0] == "GPRMC" and len(aa) > 9:
            # helpful hints at http://aprs.gids.nl/nmea/#rmc
            # same weird formats as above, plus date "111222" means 2022-12-11
            gt = aa[1]
            utc_time = gt[0:2] + ":" + gt[2:4] + ":" + gt[4:] + " Z"
            ds = aa[9]
            dd, mm, yy = ds[0:2], ds[2:4], ds[4:6]
            isod = "20" + yy + "-" + mm + "-" + dd
            ww = aa[2]
            rxw = "OK" if ww == "A" else "Warning" if ww == "V" else "Unknown"
            pl = rxw, isod, utc_time
            print("GPS fix %s  %s T %s" % pl)
    return gsv_state


def poll_wait(interval):
    t1 = time()
    w = interval - t1 % interval
    print("# sleeping %.3f" % w)
    stdout.flush()
    sleep(w)
    t2 = time()
    print("# poll_wait from %.3f to %.3f" % (t1, t2))


def live_buffer(leep_dev, verbose=False):
    if True:
        leep_dev.reg_write([("gps_buf_reset", 1)])
        while True:
            stdout.flush()
            sleep(1.8)
            stat = leep_dev.reg_read(["gps_stat"])[0]
            # last nibble (gps_pins) usually 6, sometimes 2
            # middle nibble (pps_cnt) counts at 1 Hz
            # the 0x100 bit (gps_buf_full) turns on about 3 seconds
            #   after buffer reset
            print("# gps_stat 0x%3.3x" % stat)
            if stat & 0x100:
                break
    buff = leep_dev.reg_read(["gps_buff"])[0]
    nmea = "".join([chr(x) for x in buff])
    if False:
        print("--")
        print(nmea)
        print("--")
    gsv_state = (0, 0, 0)
    for ll in nmea.split('\n'):
        gsv_state = nmea_line(gsv_state, ll, verbose=verbose)


if __name__ == "__main__":
    # XXX argparse me!
    import argparse
    import sys
    parser = argparse.ArgumentParser(
        description="Utility to read GPS NMEA from Marble Ethernet")
    parser.add_argument('-a', '--addr', required=True, help='IP address (required)')
    parser.add_argument('-p', '--port', type=int, default=803, help='Port number (default 803)')
    parser.add_argument('-i', '--interval', type=float, default=60.0, help='Polling inteval (seconds)')
    parser.add_argument('-v', '--verbose', action='store_true', help='Verbose output')
    parser.add_argument('--test', action='store_true', help="Test parsing data from stdin")
    args = parser.parse_args()

    if not args.test:
        leep_addr = "leep://" + args.addr + ":" + str(args.port)
        try:
            leep_dev = leep.open(leep_addr)
        except OSError as err:
            print("Leep initialization error:", err)
            sys.exit(1)
        #
        if args.interval > 0:
            while True:
                try:
                    poll_wait(args.interval)
                    live_buffer(leep_dev, verbose=args.verbose)
                except KeyboardInterrupt:
                    print("\nExiting")
                    break
        else:
            try:
                live_buffer(leep_dev, verbose=args.verbose)
            except KeyboardInterrupt:
                print("\nExiting")
                pass
    else:
        gsv_state = (0, 0, 0)
        for ll in stdin.readlines():
            gsv_state = nmea_line(gsv_state, ll, verbose=args.verbose)
