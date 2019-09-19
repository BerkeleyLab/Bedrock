from llspi import c_llspi
from ad9653 import c_ad9653


class c_llspi_ad9653(c_llspi, c_ad9653):
    def __init__(self, chip):
        self.chip = chip

    def write(self, addr, data):
        dlist = (self.ctl_bits(write=1, chipsel=self.chip, read_en=0))
        dlist += (self.data_bytes(self.instruction_word(read=0, w0w1=0, addr=addr), Nbyte=2))
        dlist += (self.data_bytes(self.data_words([eval('0b'+data)]), 1))
        dlist += (self.ctl_bits(write=1, chipsel=0))
        return dlist

    def read(self, addr):
        dlist = (self.ctl_bits(write=1, chipsel=self.chip))
        dlist += (self.data_bytes(self.instruction_word(read=1, w0w1=0, addr=addr), Nbyte=2))
        dlist += (self.ctl_bits(write=1, chipsel=self.chip, read_en=1, adc_sdio_dir=1))
        dlist += (self.data_bytes(self.data_words([0b01010101]), 1))
        dlist += (self.ctl_bits(write=1, chipsel=0))
        return dlist
