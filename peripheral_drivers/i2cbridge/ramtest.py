import assem


def ram_test_prog():
    sadr = 0x20
    s = assem.i2c_assem()
    a = []
    a += s.pause(2)  # ignored?
    a += s.hw_config(2)
    a += s.trig_analyz()
    a += s.write(sadr, 1, [0xa5, 0x5a])
    a += s.pause(4)
    a += s.read(sadr, 2, 1)
    a += s.read(sadr, 1, 2)
    a += s.jump(1)
    a += s.pad(1, len(a))

    a += s.set_resx(1)
    a += s.read(sadr, 1, 1)
    a += s.buffer_flip()
    a += s.pause(34)
    a += s.jump(1)
    return a


if __name__ == "__main__":
    a = ram_test_prog()
    print("\n".join(["%02x" % x for x in a]))
