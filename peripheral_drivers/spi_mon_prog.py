class spi_mon_prog:
    def __init__(self, IMEM=512, RMEM=128):
        '''IMEM and RMEM must match hardware configuration'''
        self.IMEM = IMEM
        self.RMEM = RMEM
        self.MAX_CMD = (IMEM-1) // 5  # Reserve one byte for end-of-stream marker

    def gen(self, cmd_arr, verbose=False):
        '''cmd_arr is array of tuples: (hw_sel, rnw, command[31:0])'''
        l_cmd = len(cmd_arr)
        if l_cmd > self.MAX_CMD:
            print("spi_mon: SPI commands (%d) exceed instruction memory size" % l_cmd)
            return []
        imem_a = []
        rcnt = 0
        for c in cmd_arr:
            sel, rnw, cmd = c[0] & 0xF, c[1] & 0x1, c[2] & 0xFFFFFFFF
            opt = 0 | sel << 1 | rnw
            imem_a += [opt]
            rcnt += rnw
            imem_a += [0xFF & cmd >> (24-x*8) for x in range(4)]  # Break into big-endian bytes
        # Append end-of-stream
        imem_a += [1 << 5]
        if verbose:
            print("spi_mon: %d/%d instructions, %d return values" % (l_cmd, self.MAX_CMD, rcnt))

        # Pad stream up to IMEM
        imem_a += [0]*(self.IMEM - len(imem_a))

        return imem_a


if __name__ == "__main__":
    """ spi_mon_prog usage demo """
    cmd_arr = [(0, 0, 0x00000A01),
               (0, 1, 0xFFFFFF01),
               (0, 0, 0x00000B02),
               (0, 1, 0xFFFFFF02),
               (1, 0, 0x00000A01),
               (1, 0, 0xA0A0A005),
               (1, 0, 0xB0B0B009),
               (1, 1, 0xFFFFFF03),
               (1, 1, 0xFFFFFF04),
               (1, 1, 0xFFFFFF05)]

    sprog = spi_mon_prog()
    imem = sprog.gen(cmd_arr, verbose=False)
    for i in imem:
        print("%02x" % i)
