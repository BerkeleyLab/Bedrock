'''
Assembler for the i2cbridge program sequencer
'''


class i2c_assem:
    def __init__(self):
        # sequencer op codes
        self.o_zz = 0x00
        self.o_rd = 0x20
        self.o_wr = 0x40
        self.o_wx = 0x60
        self.o_p1 = 0x80
        self.o_p2 = 0xa0
        self.o_jp = 0xc0
        self.o_sx = 0xe0
        # add to these the number of bytes read or written.
        # Note that o_wr and o_wx will be followed by that number of bytes
        # in the instruction stream, but o_rd is only followed by one more
        # byte (the device address); the data read cycles still happen, and
        # post results to the result bus, but don't consume instruction bytes.

    # write data words to specified dadr
    def write(self, dadr, madr, data):
        if dadr & 1:
            print("Address error 0x%2.2x" % dadr)
        if len(data) > 29:
            print("Write length error: %d" % len(data))
        n = 2 + len(data)
        return [self.o_wr+n, dadr, madr] + data

    # sets the read address, then repeated start, then reads data
    def read(self, dadr, madr, dlen, addr_bytes=1):
        if dadr & 1:
            print("Address error 0x%2.2x" % dadr)
        if dlen > 30:
            print("Read length error: %d" % dlen)
        if addr_bytes == 0:
            return [self.o_wx+1, dadr, self.o_rd+1+dlen, dadr+1]
        if addr_bytes == 1:
            return [self.o_wx+2, dadr, madr, self.o_rd+1+dlen, dadr+1]
        elif addr_bytes == 2:
            return [self.o_wx+3, dadr, int(madr/256), madr & 256, self.o_rd+1+dlen, dadr+1]

    # combine short and long pauses to get specified cycles
    # configured for production (q1=2, q2=7), tests will not conform
    def pause(self, n):
        r = []
        while n >= 992:
            r += [self.o_p2 + 31]
            n -= 31*32
        if n > 32:
            x = int(n/32)
            r += [self.o_p2 + x]
            n -= x*32
        if n > 0:
            r += [self.o_p1 + n]
        return r

    def jump(self, n):
        return [self.o_jp + n]

    def set_resx(self, n):
        return [self.o_sx + n]

    def buffer_flip(self):
        return [self.o_zz + 2]

    def trig_analyz(self):
        return [self.o_zz + 3]

    def hw_config(self, n):
        return [self.o_zz + 16 + n]

    # l is length of program so far
    # jump_n is jump address after padding
    def pad(self, jump_n, length):
        pad_n = 32*jump_n - length
        if pad_n < 0:
            print("Oops!  negative pad %d" % pad_n)
        return pad_n*[0]
