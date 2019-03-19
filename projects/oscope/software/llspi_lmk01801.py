from llspi import c_llspi
from lmk01801 import c_lmk01801


class c_llspi_lmk01801(c_llspi, c_lmk01801):
    def __init__(self, chip):
        self.chip = chip

    def write(self, addr, data):
        dd = self.d28a4(data, addr)
        dlist = (self.ctl_bits(write=1, chipsel=self.chip))
        dlist += (self.data_bytes(dd, 4))
        dlist += (self.ctl_bits(write=1, chipsel=0))
        return dlist


if __name__ == "__main__":
    clkdiv = c_llspi_lmk01801(chip=1)
