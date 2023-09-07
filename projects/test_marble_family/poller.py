import sys
bedrock_dir = "../../"
sys.path.append(bedrock_dir + "peripheral_drivers/i2cbridge")
import assem


# select one port of an I2C bus multiplexer
# port_n must be between 0 and 7
def busmux_sel(s, port_n):
    tca9548a_addr = 0xe0
    return s.write(tca9548a_addr, 1 << port_n, [])


# see i2c_map.txt for more documentation on I2C addresses
def hw_test_prog():
    s = assem.i2c_assem()
    a = []
    a += s.pause(2)  # ignored?
    a += s.set_resx(3)  # avoid any confusion
    a += s.hw_config(1)  # turn on reset
    a += s.pause(2)
    a += s.hw_config(0)  # turn off reset
    a += s.pause(2)
    a += busmux_sel(s, 6)  # App bus
    a += s.read(0xe0, 0, 1, addr_bytes=0)
    a += s.read(0x80, 0, 2)  # U17 config
    a += s.read(0x82, 0, 2)  # U32 config
    a += s.read(0x84, 0, 2)  # U58 config
    a += s.write(0x42, 6, [0xfe, 0x73])  # Configuration registers
    a += s.jump(1)
    a += s.pad(1, len(a))
    #
    # Toggle LEDs at 2.5 Hz
    a += s.trig_analyz()
    a += s.set_resx(0)
    a += s.write(0x42, 2, [0, 0x84])  # Output registers
    a += s.pause(2)
    a += s.read(0x42, 0, 2)  # Physical pin logic levels
    a += s.read(0x44, 0, 2)  # Physical pin logic levels
    # INA219 U17 FMC1 address 0x80
    a += s.read(0x80, 1, 2)  # shunt voltage
    a += s.read(0x80, 2, 2)  # bus voltage
    # INA219 U32 FMC2 address 0x82
    a += s.read(0x82, 1, 2)  # shunt voltage
    a += s.read(0x82, 2, 2)  # bus voltage
    # INA219 U58 FMC2 address 0x84
    a += s.read(0x84, 1, 2)  # shunt voltage
    a += s.read(0x84, 2, 2)  # bus voltage
    a += s.pause(6944)  # 13888
    a += s.write(0x42, 2, [0, 0x88])  # Output registers
    a += s.pause(2)
    a += s.read(0x42, 0, 2)  # Physical pin logic levels
    a += s.buffer_flip()
    a += s.pause(6944)
    a += s.jump(1)
    return a


if __name__ == "__main__":
    a = hw_test_prog()
    print("\n".join(["%02x" % x for x in a]))
