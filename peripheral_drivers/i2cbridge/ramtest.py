# sequencer op codes
o_zz = 0x00
o_rd = 0x20
o_wr = 0x40
o_wx = 0x60
o_p1 = 0x80
o_p2 = 0xa0
o_jp = 0xc0
o_sx = 0xe0
# add to these the number of bytes read or written.
# Note that o_wr and o_wx will be followed by that number of bytes
# in the instruction stream, but o_rd is only followed by one more
# byte (the device address); the data read cycles still happen, and
# post results to the result bus, but don't consume instruction bytes.


# dadr is the device address, zero lsb as placeholder for read flag
def ram_write(dadr, madr, data):
    n = 2 + len(data)
    return [o_wr+n, dadr, madr] + data


# sets the read address, then repeated start, then reads data
def ram_read(dadr, madr, dlen):
    return [o_wx+2, dadr, madr, o_rd+1+dlen, dadr+1]


# combine short and long pauses to get specified cycles
# configured for production (q1=2, q2=7), tests will not conform
def pause(n):
    r = []
    while n >= 992:
        r += [o_p2 + 31]
        n -= 31*32
    if n > 32:
        x = int(n/32)
        r += [o_p2 + x]
        n -= x*32
    if n > 0:
        r += [o_p1 + n]
    return r


def jump(n):
    return [o_jp + n]


def set_resx(n):
    return [o_sx + n]


def buffer_flip():
    return [o_zz + 2]


def trig_analyz():
    return [o_zz + 3]


def hw_config(n):
    return [o_zz + 16 + n]


def ram_test_prog():
    sadr = 0x20
    a = []
    a += pause(2)  # ignored?
    a += hw_config(2)
    a += trig_analyz()
    a += ram_write(sadr, 1, [0xa5, 0x5a])
    a += pause(4)
    a += ram_read(sadr, 2, 1)
    a += ram_read(sadr, 1, 2)
    a += jump(1)
    a += (32-len(a))*[0]  # pad

    a += set_resx(1)
    a += ram_read(sadr, 1, 1)
    a += buffer_flip()
    a += pause(34)
    a += jump(1)
    return a


if __name__ == "__main__":
    a = ram_test_prog()
    print("\n".join(["%02x" % x for x in a]))
