from llspi import c_llspi
from ad9781 import c_ad9781


class c_llspi_ad9781(c_llspi, c_ad9781):

    def __init__(self, chip):
        self.chip = chip

    def write(self, addr, data):
        dlist = self.ctl_bits(write=1, chipsel=self.chip)
        dlist += self.data_bytes(self.instruction_word(read=0, n0n1=0, addr=addr), Nbyte=1)
        dlist += self.data_bytes(self.data_words(bytelist=[eval('0b'+data)]), Nbyte=1)
        dlist += self.ctl_bits(write=1, chipsel=0)
        return dlist

    def read(self, addr):
        dlist = self.ctl_bits(write=1, chipsel=self.chip)
        dlist += self.data_bytes(self.instruction_word(read=1, n0n1=0, addr=addr), Nbyte=1)
        dlist += self.ctl_bits(write=1, chipsel=self.chip, read_en=1)
        dlist += self.data_bytes(self.data_words(bytelist=[0b01010101]), Nbyte=1)
        dlist += self.ctl_bits(write=1, chipsel=0)
        return dlist

    def adwlist(self, datalist, addr, write):
        return [(data, addr, write) for data in datalist]
