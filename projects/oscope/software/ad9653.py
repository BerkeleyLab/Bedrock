try:
    basestring
except NameError:
    basestring = str


class c_ad9653:
    def string_or_int(self, vin):
        if isinstance(vin, basestring):
            vin0 = eval(vin)
        elif isinstance(vin, int):
            vin0 = vin
        else:
            print(type(vin))
        return vin0

    def instruction_word(self, read, w0w1, addr):
        read_internal = self.string_or_int(read) & 0x1
        w0w1_internal = self.string_or_int(w0w1) & 0x3
        addr_internal = self.string_or_int(addr) & 0x1fff
        return (read_internal << 15) + (w0w1_internal << 13) + addr_internal

    def data_words(self, datalist):
        dataout = 0
        for data in datalist:
            dataout = (dataout << 8) + data
        return dataout


if __name__ == "__main__":
    adc1 = c_ad9653()
    print(adc1.instruction_word(read=1, w0w1=0, addr=1))
    print(hex(adc1.data_words([35], 1)))
