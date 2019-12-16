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


# Read static info from lower bank
def sfp_init(port_n):
    a = busmux_sel(port_n)
    a += ram_read(0xe0, 0, 1, addr_bytes=0)
    a += ram_read(0xa0, 20, 16)  # Vendor
    a += ram_read(0xa0, 40, 16)  # Part
    a += ram_read(0xa0, 68, 16)  # Serial
    a += ram_read(0xa0, 92, 1)   # hope bit 5 is set for internal cal
    # XXX pretty sure I want all the cal constants, too
    return a


# Read dynamic component from upper bank
def sfp_poll(port_n):
    a = busmux_sel(port_n)
    a += ram_read(0xa2, 96, 10)  # 5 x 16-bit raw ADC values
    return a


# see i2c_map.txt for more documentation on I2C addresses
def hw_test_prog():
    ina_list = [0x80, 0x82, 0x84]  # U17, U3, unplaced
    # SFP1 is closest to edge of board
    # SFP4 is closest to center of board
    sfp_list = [2, 5, 4, 3]  # SFP modules 1-4
    a = []
    a += pause(2)  # ignored?
    a += set_resx(2)  # avoid any confusion
    a += hw_config(1)  # turn on reset
    a += pause(2)
    a += hw_config(0)  # turn off reset
    a += pause(2)
    #
    a += busmux_sel(6)  # App bus
    a += ram_read(0xe0, 0, 1, addr_bytes=0)  # busmux readback
    a += ram_write(0x42, 6, [0xff, 0xf3])  # U39 Configuration registers
    a += ram_write(0x44, 6, [0xbb, 0xbb])  # U34 Configuration registers
    a += ram_write(0x44, 6, [0x00, 0x00])  # U34 Output registers
    for ax in ina_list:
        a += ram_read(ax, 0, 2)  # config
    for sfp_port in sfp_list:
        a += sfp_init(sfp_port)
    #
    jump_n = 5
    a += jump(jump_n)
    pad_n = 32*jump_n-len(a)
    if pad_n < 0:
        print("Oops!  negative pad %d" % pad_n)
    a += pad_n*[0]  # pad
    #
    # Start of polling loop
    a += trig_analyz()
    a += set_resx(0)
    a += busmux_sel(6)  # App bus
    a += ram_write(0x42, 2, [0, 4])  # Output registers
    a += pause(2)
    a += ram_read(0x42, 0, 2)  # Physical pin logic levels
    a += ram_read(0x44, 0, 2)  # Physical pin logic levels
    for ax in ina_list:
        a += ram_read(ax, 1, 2)  # shunt voltage
        a += ram_read(ax, 2, 2)  # bus voltage
    #
    for sfp_port in sfp_list:
        a += sfp_poll(sfp_port)
    a += pause(6944)
    #
    a += busmux_sel(6)  # App bus
    a += ram_write(0x42, 2, [0, 8])  # Output registers
    a += pause(2)
    a += ram_read(0x42, 0, 2)  # Physical pin logic levels
    a += buffer_flip()
    a += pause(6944)
    if True:  # extra weird little flicker
        a += ram_write(0x42, 2, [0, 4])  # Output registers
        a += pause(1056)
        a += ram_write(0x42, 2, [0, 8])  # Output registers
        a += pause(1056)
    a += jump(jump_n)
    return a


if __name__ == "__main__":
    a = hw_test_prog()
    print("\n".join(["%02x" % x for x in a]))
