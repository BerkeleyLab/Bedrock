#! /usr/bin/python3

# A usage example of creating an I2C program with the high-level API
# offered by marble_i2c.py

import sys
try:
    import marble_i2c
except ImportError:
    raise Exception("Must set PYTHONPATH=path/to/bedrock/projects/test_marble_family")

# QSFP Initial read (static) registers
qsfp_init_d = {
    # Address : (size, fmt_string)
    148: (16, "QSFP{}_VENDOR_NAME"),
    168: (16, "QSFP{}_PART_NAME"),
    184: (2, "QSFP{}_REVISION_CODE"),
    186: (2, "QSFP{}_WAVELENGTH"),
    196: (16, "QSFP{}_SER_NUM"),
    212: (8, "QSFP{}_DATE_CODE")
}

# QSFP Polling read (dynamic) registers
qsfp_poll_d = {
    2:   (1, "QSFP{}_MODULE_STATUS"),
    22:  (2, "QSFP{}_TEMPERATURE"),
    26:  (2, "QSFP{}_VSUPPLY"),
    34:  (8, "QSFP{}_RXPOWER"),     # 4 channels, 2 bytes each
    128: (2, "QSFP{}_IDENTIFIER"),  # identifier and extended identifier
}


def _int(x):
    try:
        return int(x)
    except ValueError:
        pass
    try:
        return int(x, 16)
    except ValueError:
        pass
    try:
        return int(x, 2)
    except ValueError:
        pass
    return None


class MarbleI2CProg(marble_i2c.MarbleI2C):
    def __init__(self, i2c_assembler=None):
        super().__init__(i2c_assembler)

    def qsfp_init(self, qsfp_n=0):
        return self.qsfp_read_many(qsfp_n, qsfp_init_d)

    def qsfp_poll(self, qsfp_n=0):
        return self.qsfp_read_many(qsfp_n, qsfp_poll_d)

    def busmux_reset(self):
        """This requires hooking up ~hw_config[0] to TWI_RST (low-true) in gateware."""
        if self._s is None:
            return
        self._s.pause(10)
        self._s.hw_config(1)  # turn on reset
        self._s.pause(10)
        self._s.hw_config(0)  # turn off reset
        self._s.pause(10)
        return

    def bsp_config(self):
        """Initial platform configuration."""
        # Overridden method
        self.set_resx(0)  # Start from address 0
        self.busmux_reset()
        self.U34_configure()
        self.U39_configure()
        return


def build_prog(argv):
    m = MarbleI2CProg()

    # ======= Program Instructions =======
    # Setup
    m.bsp_config()
    m.qsfp_init(0)
    m.qsfp_init(1)
    # HACK ALERT! We have to do this twice so this info is in both buffers
    m.buffer_flip()
    m.set_resx(0)  # Go back to resx 0
    m.qsfp_init(0)
    m.qsfp_init(1)
    # Loop start
    jump_n = m.jump_pad()
    # Required after a jump point before reading
    m.set_resx()

    # Read board configuration
    m.hw_config(2)  # Light an LED (on hw_config[1])
    m.bsp_poll()
    # Read QSFP1 dynamic params
    m.qsfp_poll(0)
    # Read QSFP2 dynamic params
    m.qsfp_poll(1)

    m.buffer_flip()
    m.pause(4096)   # Pause for roughly 0.24ms
    m.hw_config(0)  # Turn LED off
    m.pause(4096)   # Pause for roughly 0.24ms
    m.jump(jump_n)  # Jump back to loop start

    # ======= Demo Functionality =======
    if len(argv) > 1:
        op = argv[1]
        if len(argv) > 2:
            offset = _int(argv[2])
        else:
            offset = 0
        if op == 'p':
            m.write_program()
        else:
            m.write_reg_map(offset=offset, style=op)
        return 0

    # ======= (Anti-)Regression Test =======
    rval = 0
    errstr = None
    try:
        m.check_program()
    except marble_i2c.assem.I2C_Assembler_Exception as err:
        rval = 1
        errstr = str(err)
    if rval == 0:
        print("PASS")
    else:
        print("FAIL: {}".format(errstr))
    return rval


if __name__ == "__main__":
    build_prog(sys.argv)
