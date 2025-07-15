import sys
import time
from llspi import c_llspi
from ad9653 import c_ad9653


# This class "just" constructs data lists to be sent to llspi.v
# that will perform the desired AD9653 SPI transaction
class c_llspi_ad9653(c_llspi, c_ad9653):
    def __init__(self, chip):
        self.chip = chip  # this is the llspi chipsel == ctl_bits[2:0]

    def write(self, addr, data):
        dlist = (self.ctl_bits(write=1, chipsel=self.chip, read_en=0))
        dlist += (self.data_bytes(
            self.instruction_word(
                read=0, w0w1=0, addr=addr), Nbyte=2))
        dlist += (self.data_bytes(self.data_words([eval('0b' + data)]), 1))
        dlist += (self.ctl_bits(write=1, chipsel=0))
        return dlist

    def read(self, addr):
        dlist = (self.ctl_bits(write=1, chipsel=self.chip))
        dlist += (self.data_bytes(
            self.instruction_word(
                read=1, w0w1=0, addr=addr), Nbyte=2))
        dlist += (self.ctl_bits(
            write=1, chipsel=self.chip, read_en=1, adc_sdio_dir=1))
        dlist += (self.data_bytes(self.data_words([0b01010101]), 1))
        dlist += (self.ctl_bits(write=1, chipsel=0))
        return dlist


# This class uses LEEP to interact with llspi.v
# Independent of which peripheral chip is attached to llspi.
# All of these methods are unmodified cut-and-paste from zest_setup.py
class leep_llspi():
    def __init__(self, leep):
        self.leep = leep

    def spi_write(self, obj, addr, value):
        self.verbose_send(obj.write(addr, value))

    def wait_for_tx_fifo_empty(self):
        retries = 0
        while 1:
            rrvalue = self.leep.reg_read([('llspi_status')])[0]
            empty = (rrvalue >> 4) & 1
            please_read = (rrvalue + 1) & 0xf
            if empty:
                break
            time.sleep(0.002)
            retries += 1
        # print(rrvalue, type(rrvalue), hex(rrvalue), please_read)
        if retries > 0:
            print("%d retries" % retries)
        return please_read

    def verbose_send(self, dlist):
        write_list = []
        [write_list.append(('llspi_we', x)) for x in dlist]
        self.leep.reg_write(write_list)
        time.sleep(0.002)
        return self.wait_for_tx_fifo_empty()

    # Each element of obj_list needs to have a read(addr) method to construct the
    # llspi command list.
    def spi_readn(self, obj_list, addr):
        please_read = self.verbose_send(sum([adc.read(addr) for adc in obj_list], []))
        lol = len(obj_list)
        if please_read != lol:
            print("spi_readn mismatch please_read %d  len(obj_list) %d" % (please_read, lol))
        if please_read:
            result1 = self.leep.reg_read([('llspi_result')]*please_read)
            return [(None, None, x) for x in result1]


if __name__ == "__main__":
    import getopt
    import leep

    opts, args = getopt.getopt(sys.argv[1:], 'ha:p:', ['help', 'addr='])
    ip_addr = '192.168.195.84'

    for opt, arg in opts:
        if opt in ('-h', '--help'):
            sys.exit()
        elif opt in ('-a', '--address'):
            ip_addr = arg

    leep_addr = None
    if leep_addr is None:
        leep_addr = "leep://" + str(ip_addr)

    leep = leep.open(leep_addr, timeout=2.0, instance=[])
    leepll = leep_llspi(leep)  # temporary(?) stand-in for c_zest
    U2_adc_spi = c_llspi_ad9653(2)

    # Write test
    # If this were a real chip, this would set its test mode
    leepll.spi_write(U2_adc_spi, 0xd, '00001100')

    # Read test
    # If this were a real chip, this would read its Chip ID and Chip Grade
    for addr in [0x01, 0x02]:
        foo = leepll.spi_readn([U2_adc_spi], addr)
        print("Addr 0x%2.2x:  0x%2.2x" % (addr, foo[0][2]))

    print("Done")
