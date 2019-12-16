# Unfinished/untested setup for i2cbridge as incorporated in marble1
# based on i2cbridge/ramtest.py

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


# dadr is the I2C bus address of the device, with low bit clear
# e.g., 0x42 for U39 or 0x44 for U34.
# sets the read address, then repeated start, then reads data
def ram_read(dadr, madr, dlen, addr_bytes=1):
    if addr_bytes == 0:
        return [o_wx+1, dadr, o_rd+1+dlen, dadr+1]
    if addr_bytes == 1:
        return [o_wx+2, dadr, madr, o_rd+1+dlen, dadr+1]
    elif addr_bytes == 2:
        return [o_wx+3, dadr, int(madr/256), madr & 256, o_rd+1+dlen, dadr+1]


# Combine short and long pauses to get specified cycles
#
# In real life, configured for production (q1=2, q2=7),
# one count of n represents 8ns * 32 * 14 * 4 = 14.336 us
# and a single p2 instruction can pause up to 14.22 ms.
# Simulations are shortened from this.
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


# select one port of an I2C bus multiplexer
# port_n must be between 0 and 7
def busmux_sel(port_n):
    tca9548a_addr = 0xe0
    return ram_write(tca9548a_addr, 1 << port_n, [])


# see i2c_map.txt for more documentation on I2C addresses
def hw_test_prog():
    a = []
    a += pause(2)  # ignored?
    a += set_resx(0)  # avoid any confusion
    a += hw_config(1)  # turn on reset
    a += pause(2)
    a += hw_config(0)  # turn off reset
    a += pause(2)
    a += busmux_sel(6)  # App bus
    a += ram_read(0xe0, 0, 1, addr_bytes=0)
    a += ram_write(0x42, 6, [0xff, 0xf3])  # Configuration registers
    a += jump(1)
    a += (32-len(a))*[0]  # pad
    #
    # Toggle LEDs at 2.5 Hz
    a += trig_analyz()
    a += set_resx(1)
    a += ram_write(0x42, 2, [0, 4])  # Output registers
    a += pause(2)
    a += ram_read(0x42, 0, 2)  # Physical pin logic levels
    a += pause(6944)  # 13888
    a += ram_write(0x42, 2, [0, 8])  # Output registers
    a += pause(2)
    a += ram_read(0x42, 0, 2)  # Physical pin logic levels
    # INA219 U17 FMC1 address 0x80
    a += ram_read(0x80, 0, 2)  # config
    a += ram_read(0x80, 1, 2)  # shunt voltage
    a += ram_read(0x80, 2, 2)  # bus voltage
    # INA219 U32 FMC2 address 0x82
    a += ram_read(0x82, 0, 2)  # config
    a += ram_read(0x82, 1, 2)  # shunt voltage
    a += ram_read(0x82, 2, 2)  # bus voltage
    a += buffer_flip()
    a += pause(6944)
    a += jump(1)
    return a


if __name__ == "__main__":
    a = hw_test_prog()
    print("\n".join(["%02x" % x for x in a]))
