import sys
import time
import getopt


# AD7794 used to monitor temperatures on the Digitizer Board
#
#  6-Channel, Low Noise, Low Power ADC. Used to read 4 thermistors on the Digitizer board.
#  Data sheet available at: http://www.analog.com/media/en/technical-documentation/data-sheets/AD7794_7795.pdf
#  01534278628e602cd160f0683c836b3f238877356b2270a018e558a575199512  AD7794_7795.pdf
class c_ad7794(object):
    # Initialization function
    # @param VBIAS Bias Voltage Generator Enable. 0 = Bias voltage generator disabled
    # @param BO Burnout Current Enable Bit. 0 = disabled
    # @param U_B Unipolar/Bipolar Bit. 0 = Unipolar
    # @param BOOST Set to reduce power-up time. 0 = disabled
    # @param G Gain Select Bits. 0x7 Gain = 128. ADC Input Range(2.5V Reference) 19.53mV
    # @param REFSEL Reference Select Bits. 0 is External reference applied between REFIN1(+) and REFIN1(-)
    # @param REF_DET Enables the reference detect function. 0 = disabled
    # @param BUF Configures the ADC for buffered or unbuffered mode of operation. 1 = Buffered mode
    def init(self,
             WEN=0,
             R_Wb=0,
             RS=0,
             CREAD=0,
             md=0,
             psw=0,
             VBIAS=0,
             BO=0,
             U_B=0,
             BOOST=0,
             G=7,
             REFSEL=0,
             REF_DET=0,
             BUF=1,
             CH=0):
        self.VBIAS = VBIAS & 0x3
        self.BO = BO & 0x1
        self.U_B = U_B & 0x1
        self.BOOST = BOOST & 0x1
        self.G = G & 0x7
        self.REFSEL = REFSEL & 0x3
        self.REF_DET = REF_DET & 0x1
        self.BUF = BUF & 0x1
        self.CH = CH & 0xf
        pass

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
        return (self.WEN << 7) + (self.R_Wb << 6) + (self.RS << 3) + (
            self.CREAD << 2)

    def status_register(self, value):
        # RDY = (value>>7)&0x1
        # ERR = (value>>6)&0x1
        # NOXREF = (value>>5)&0x1
        # CHIP_94_OR_95 = (value>>3)&0x1
        # CH = (value>>0)&0x7
        pass

    def configuration_register(self, chan=None, G=None, REFSEL=None):
        if chan is None:
            chan = self.CH
        if G is None:
            G = self.G
        if REFSEL is None:
            REFSEL = self.REFSEL
        val = (((self.VBIAS << 14) + (self.BO << 13) + (self.U_B << 12) +
                (self.BOOST << 11) + (G << 8) + (REFSEL << 6) +
                (self.REF_DET << 5) + (self.BUF << 4) + (chan)) << 8)
        return val | 0x0000ff

    def read_channel(self, prc, ch, gain=0):
        config = self.configuration_register(chan=ch, G=gain, REFSEL=2)
        # print 'chan',chan,'config',format(config,'06x'),'reading'
        prc.ad7794_write(0x2, config)
        prc.ad7794_write(0x1, 0x200aff)
        time.sleep(0.3)
        read0 = prc.ad7794_read(0x0)
        if False:
            print([format(i, '06x') for i in read0])
        read3 = prc.ad7794_read(0x3)
        if False:
            print([format(i, '06x') for i in read3])
        return read3[3]


def usage():
    print('python ad7794.py -a 192.168.21.12')


if __name__ == "__main__":
    from prc import c_prc
    opts, args = getopt.getopt(sys.argv[1:], 'ha:p:',
                               ['help', 'addr=', 'port='])
    ip_addr = '192.168.21.11'
    port = 50006
    for opt, arg in opts:
        if opt in ('-h', '--help'):
            usage()
            sys.exit()
        elif opt in ('-a', '--address'):
            ip_addr = arg
        elif opt in ('-p', '--port'):
            port = int(arg)

    prc = c_prc(ip_addr, port)

    prc.ad7794.init(G=0, REFSEL=2, CH=3)
    while 1:
        for chan in [0, 1, 2, 5, 6]:
            v = prc.ad7794.read_channel(prc, chan)
            print('%6.4f' % (v * 1.0 / 2**23 - 1))
        print
