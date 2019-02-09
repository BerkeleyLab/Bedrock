import ad9653
class c_llspi:

    def __init__(self):
        pass

    def ctl_bits(self, write, chipsel, read_en=0, adc_sdio_dir=0):
        return [(write << 8)+(read_en << 7)+(adc_sdio_dir << 4)+chipsel]

    def data_bytes(self, data, Nbyte):
        out = []
        for index in range(Nbyte-1, 0-1, -1):
            out.append((data & (0xff << (index*8))) >> (index*8))
        return out
        pass

    def adwlist(self, datalist, addr, write):
        return [(data, addr, write) for data in datalist]


if __name__ == "__main__":
    a = c_llspi()
    print(hex(a.ctl_bits(write=1, chipsel=2)))
    print(hex(a.ctl_bits(write=1, chipsel=2, read_en=1, adc_sdio_dir=1)))
    print([hex(n) for n in a.data_bytes(0xabcd1234, 5)])
