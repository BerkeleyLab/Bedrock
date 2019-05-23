try:
    basestring
except NameError:
    basestring = str


class c_ad9781:
    def string_or_int(self, vin):
        if isinstance(vin, basestring):
            vin0 = eval(vin)
        elif isinstance(vin, int):
            vin0 = vin
        else:
            print(type(vin))
        return vin0

    def instruction_word(self, read, n0n1, addr):
        read_internal = self.string_or_int(read) & 0x1
        value = (read_internal << 7) + (n0n1 << 5) + addr
        # print(hex(value))
        return value

    def data_words(self, bytelist):
        dataout = 0
        for data in bytelist:
            dataout = (dataout << 8) + data
        return dataout


if __name__ == "__main__":
    adc1 = c_ad9781()
    print(adc1.instruction_word(read=1, n0n1=0, addr=1))
    print(hex(adc1.data_words([35], 1)))
