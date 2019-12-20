import sys
bedrock_dir = "../../"
sys.path.append(bedrock_dir + "peripheral_drivers/i2cbridge")
import assem


# select one port of an I2C bus multiplexer
# port_n must be between 0 and 7
def busmux_sel(s, port_n):
    tca9548a_addr = 0xe0
    return s.write(tca9548a_addr, 1 << port_n, [])


# Read static info from lower bank
def sfp_init(s, port_n):
    a = busmux_sel(s, port_n)
    a += s.read(0xe0, 0, 1, addr_bytes=0)
    a += s.read(0xa0, 20, 16)  # Vendor
    a += s.read(0xa0, 40, 16)  # Part
    a += s.read(0xa0, 68, 16)  # Serial
    a += s.read(0xa0, 92, 1)   # hope bit 5 is set for internal cal
    # XXX pretty sure I want all the cal constants, too
    return a


# Read dynamic component from upper bank
def sfp_poll(s, port_n):
    a = busmux_sel(s, port_n)
    a += s.read(0xa2, 96, 10)  # 5 x 16-bit raw ADC values
    return a


def busmux_reset(s):
    a = []
    a += s.pause(10)
    a += s.hw_config(1)  # turn on reset
    a += s.pause(10)
    a += s.hw_config(0)  # turn off reset
    a += s.pause(10)
    return a


# see i2c_map.txt for more documentation on I2C addresses
def hw_test_prog(s):
    ina_list = [0x80, 0x82, 0x84]  # U17, U32, unplaced
    # SFP1 is closest to edge of board
    # SFP4 is closest to center of board
    sfp_list = [2, 5, 4, 3]  # SFP modules 1-4
    fmc_list = [0, 1]
    a = []
    a += s.pause(2)  # ignored?
    a += s.set_resx(2)  # avoid any confusion
    a += busmux_reset(s)
    #
    a += busmux_sel(s, 6)  # App bus
    a += s.read(0xe0, 0, 1, addr_bytes=0)  # busmux readback
    a += s.write(0x42, 6, [0xff, 0xf3])  # U39 Configuration registers
    a += s.write(0x44, 6, [0xbb, 0xbb])  # U34 Configuration registers
    a += s.write(0x44, 6, [0x00, 0x00])  # U34 Output registers
    for ax in ina_list:
        a += s.read(ax, 0, 2)  # config
    for sfp_port in sfp_list:
        a += sfp_init(s, sfp_port)
    a += s.trig_analyz()
    for fmc_port in fmc_list:
        a += busmux_sel(s, fmc_port)
        a += s.pause(10)
        a += s.read(0xe0, 0, 1, addr_bytes=0)  # busmux readback
        a += s.read(0xa0, 0, 27, addr_bytes=2)  # AT24C32D on Zest
    #
    jump_n = 6
    a += s.jump(jump_n)
    a += s.pad(jump_n, len(a))
    #
    # Start of polling loop
    a += s.set_resx(0)
    a += busmux_sel(s, 6)  # App bus
    a += s.write(0x42, 2, [0, 4])  # Output registers
    a += s.pause(2)
    a += s.read(0x42, 0, 2)  # Physical pin logic levels
    a += s.read(0x44, 0, 2)  # Physical pin logic levels
    for ax in ina_list:
        a += s.read(ax, 1, 2)  # shunt voltage
        a += s.read(ax, 2, 2)  # bus voltage
    #
    for sfp_port in sfp_list:
        a += sfp_poll(s, sfp_port)
    a += s.buffer_flip()  # Flip right away, so most info is minimally stale
    # This does mean that the second readout of the PCA9555 will be extra-stale
    # or even (on the first trip through) invalid.
    a += s.pause(6944)
    #
    a += busmux_sel(s, 6)  # App bus
    a += s.write(0x42, 2, [0, 8])  # Output registers
    a += s.pause(2)
    a += s.read(0x42, 0, 2)  # Physical pin logic levels
    a += s.pause(6944)
    if True:  # extra weird little flicker
        a += s.write(0x42, 2, [0, 4])  # Output registers
        a += s.pause(1056)
        a += s.write(0x42, 2, [0, 8])  # Output registers
        a += s.pause(1056)
    a += s.jump(jump_n)
    return a


if __name__ == "__main__":
    s = assem.i2c_assem()
    a = hw_test_prog(s)
    print("\n".join(["%02x" % x for x in a]))
