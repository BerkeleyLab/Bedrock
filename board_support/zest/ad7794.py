import sys


# AD7794 used to monitor temperatures on the Digitizer Board
#
#  6-Channel, Low Noise, Low Power ADC. Used to read 4 thermistors on the Digitizer board.
#  Data sheet available at: https://www.analog.com/media/en/technical-documentation/data-sheets/AD7794_7795.pdf
#  01534278628e602cd160f0683c836b3f238877356b2270a018e558a575199512  AD7794_7795.pdf
class c_ad7794(object):
    # Initialization function
    # @param VBIAS Bias Voltage Generator Enable. 0 = Bias voltage generator disabled
    # @param BO Burnout Current Enable Bit. 0 = disabled
    # @param U_B Unipolar/Bipolar Bit. 0 = Bipolar, 1 = Unipolar
    # @param BOOST Set to reduce power-up time. 0 = disabled
    # @param G Gain Select Bits. 0x7 Gain = 128. ADC Input Range(2.5V Reference) 19.53mV
    # @param REFSEL Reference Select Bits. 0 is External reference applied between REFIN1(+) and REFIN1(-)
    # @param REF_DET Enables the reference detect function. 0 = disabled
    # @param BUF Configures the ADC for buffered or unbuffered mode of operation. 1 = Buffered mode
    def __init__(self,
                 VBIAS=0,
                 BO=0,
                 U_B=0,
                 BOOST=0,
                 G=0,
                 REFSEL=0,
                 REF_DET=0,
                 BUF=1,
                 REF1_V=3.3,
                 REF2_V=0.0):
        self.VBIAS = VBIAS & 0x3
        self.BO = BO & 0x1
        self.U_B = U_B & 0x1
        self.BOOST = BOOST & 0x1
        self.G = G & 0x7
        self.REFSEL = REFSEL & 0x3
        self.REF_DET = REF_DET & 0x1
        self.BUF = BUF & 0x1
        self.REF1_V = REF1_V
        self.REF2_V = REF2_V
        self.LINPARM = [(0.0, 0.0)]*7  # Default linear params of all 7 channels

    def calibrate(self, chan, v1, v2, t1, t2, override=False):
        if not override:
            import numpy
            pp = numpy.polyfit([v1, v2], [t1, t2], 1)
            slp, off = pp[0], pp[1]
        else:
            (slp, off) = override

        self.LINPARM[chan] = (slp, off)

    # Communications Register Definition
    # @param read R/W. 0 = write operation. 1 = read operation
    # @param addr Register Address Bits
    # @param cread Continuous Read. 1 enables functionallity
    def cmd(self, read=1, addr=0x1e, cread=0):
        result = (read << 6) + (addr << 3) + (cread << 2)
        return result

    def dataaddr(self, data, addr):
        res = (data << 8) + addr
        return res

    def cmddecode(self, cmdval):
        read = (cmdval >> 6) & 1
        addr = (cmdval >> 3) & 0x7
        cread = (cmdval >> 2) & 0x1
        return [read, addr, cread]

    def communications_register(self):
        WEN = 0
        R_Wb = 0
        RS = 0
        CREAD = 0
        return (WEN << 7) + (R_Wb << 6) + (RS << 3) + (CREAD << 2)

    def status_register(self, value):
        # RDY = (value>>7)&0x1
        # ERR = (value>>6)&0x1
        # NOXREF = (value>>5)&0x1
        # CHIP_94_OR_95 = (value>>3)&0x1
        # CH = (value>>0)&0x7
        pass

    def configuration_register(self, chan):
        val = (((self.VBIAS << 14) + (self.BO << 13) + (self.U_B << 12) +
                (self.BOOST << 11) + (self.G << 8) + (self.REFSEL << 6) +
                (self.REF_DET << 5) + (self.BUF << 4) + (chan)) << 8)
        return val | 0x0000ff

    def conv_volt(self, readout, chan):
        vref = 0.0
        if chan == 6 or self.REFSEL == 2:
            vref = 1.17
        else:
            if self.REFSEL == 0:
                vref = self.REF1_V
            elif self.REFSEL == 1:
                vref = self.REF2_V
            elif self.REFSEL == 3:
                vref = 0.0  # Reserved

        if self.U_B == 1:  # Unipolar
            return readout*vref*0.5**24
        else:  # Bipolar
            return (readout - 2**23)*vref*0.5**23

    def conv_deg(self, readout, chan):
        return self.conv_volt(readout, chan)*self.LINPARM[chan][0] + self.LINPARM[chan][1]


def usage():
    print('python %s -a [IP ADDR]' % sys.argv[0])


if __name__ == "__main__":
    import getopt
    from zest_setup import c_zest

    opts, args = getopt.getopt(sys.argv[1:], 'ha:p:',
                               ['help', 'addr='])
    ip_addr = '192.168.21.11'
    for opt, arg in opts:
        if opt in ('-h', '--help'):
            usage()
            sys.exit()
        elif opt in ('-a', '--address'):
            ip_addr = arg

    print("Hardcoded sensitivity")
    prc = c_zest(ip_addr)
    prc.ad7794_calibrate()
    prc.ad7794_print()
    print("\n")

    r = prc.ad7794_read_channel(6)
    t = prc.ad7794.conv_deg(r, 6)
    v = prc.ad7794.conv_volt(r, 6)
    print("Test calibrated sensitivity, assuming %5.4f C" % t)
    prc.ad7794.calibrate(chan=6, v1=v, v2=0, t1=t, t2=-273.15)
    prc.ad7794_print()
    print("\n\n")

    while 1:
        prc.ad7794_print()
        print("")
