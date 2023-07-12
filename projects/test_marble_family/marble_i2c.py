#! /usr/bin/python3

# Build a hex file for i2c_chunk to make I2C board data
# available to gateware on marble platform.

import sys
try:
    from i2cbridge import assem
except:
    try:
        import assem
    except:
        print("Must set PYTHONPATH=path/to/bedrock/peripheral_drivers/i2cbridge")
        sys.exit(0)

qsfp_init_d = {
    # Address : (size, fmt_string)
    148 : (16, "QSFP{}_VENDOR_NAME"),
    168 : (16, "QSFP{}_PART_NAME"),
    184 : (2, "QSFP{}_REVISION_CODE"),
    186 : (2, "QSFP{}_WAVELENGTH"),
    196 : (16, "QSFP{}_SER_NUM"),
    212 : (8, "QSFP{}_DATE_CODE")
    }

qsfp_poll_d = {
    2  : (1, "QSFP{}_MODULE_STATUS"),
    22 : (2, "QSFP{}_TEMPERATURE"),
    26 : (2, "QSFP{}_VSUPPLY"),
    34 : (8, "QSFP{}_RXPOWER"), # 4 channels, 2 bytes each
    128: (2, "QSFP{}_IDENTIFIER"), # identifier and extended identifier
    }

class MarbleI2C():
    # I2C bus map
    _i2c_map = {
        ("U5", 0xe0) : {     # Bus mux U5
            # Branch number : (branch name, branch dict)
            0 : ("FMC1", {}),
            1 : ("FMC2", {}),
            2 : ("U2", {}),
            3 : ("SO-DIMM", {}),
            4 : ("QSFP1", {
                # IC name : I2C address
                "J17" : 0xa0
                }),
            5 : ("QSFP2", {
                # IC name : I2C address
                "J8" : 0xa0
                }),
            6 : ("APP", {
                # IC name : I2C address
                "U57" : 0x84 ,
                "U32" : 0x82 ,
                "U17" : 0x80 ,
                "Y6" : 0xea ,
                "U34" : 0x44 ,
                "U39" : 0x42
                }),
            }
        }

    # QSFP index : IC name
    _qsfp_map = {0 : "J17", 1 : "J8"}

    def __init__(self, i2c_assembler=None):
        if i2c_assembler is None:
            self._s = assem.I2CAssembler()
        else:
            self._s = i2c_assembler
        self._associate()
        self._ch_selected = None

    def _associate(self):
        """Build a 2D list from the map"""
        if hasattr(self, "_a"):
            return
        self._a = []
        for mux, tree in self._i2c_map.items():
            mux_name, mux_addr = mux
            for ch, branch in tree.items():
                branch_name, branch_dict = branch
                for ic_name, ic_addr in branch_dict.items():
                    self._a.append((ic_name, ic_addr, branch_name, ch, mux_name, mux_addr))
        return

    @classmethod
    def get_muxes(cls):
        muxes = []
        for mux, tree in cls._i2c_map.items():
            mux_name, mux_addr = mux
            muxes.append((mux_name, mux_addr))
        return muxes

    def get_ics(self):
        ics = []
        for l in self._a:
            name = l[0]
            addr = l[1]
            ics.append((name, addr))
        return ics

    def get_i2c_addr(self, name):
        """Returns I2C address of IC with name 'name' if found; None otherwise."""
        for l in self._a:
            if name == l[0]:
                return l[1]
        return None

    def get_i2c_name(self, addr):
        """Returns name of IC with I2C address 'address' if found; None otherwise."""
        for l in self._a:
            if addr == l[1]:
                return l[0]
        return None

    def select_ic(self, ic):
        for nic in self._a:
            ic_name, ic_addr, branch_name, ch, mux_name, mux_addr = nic
            if ic.lower().strip() == ic_name.lower().strip():
                # If we found a match, mux to it
                self._busmux(mux_addr, ch)
                return ic_addr
        return None

    def select_branch(self, branch):
        for nic in self._a:
            ic_name, ic_addr, branch_name, ch, mux_name, mux_addr = nic
            if branch_name.lower().strip() == branch.lower().strip():
                # If we found a match, mux to it
                self._busmux(mux_addr, ch)
                return ch
        return None

    def get_addr(self, ic):
        for nic in self._a:
            ic_name, ic_addr, branch_name, ch, mux_name, mux_addr = nic
            if ic.lower().strip() == ic_name.lower().strip():
                return ic_addr
        return None

    def _busmux(self, mux_addr, mux_ch):
        if self._ch_selected != mux_ch:
            self._s.write(mux_addr, self._chsel(mux_ch), [])
            self._ch_selected = mux_ch
        return

    @staticmethod
    def _chsel(n):
        n = max(min(7, int(n)), 0) # peg n
        return (1<<n) & 0xff

    # check datasheet for info:
    # https://www.mouser.com/pdfdocs/AN-2152100GQSFP28LR4EEPROMmapRevC.pdf
    # Read static info from lower bank
    def _qsfp_do(self, qsfp_n=0, prog_dict={}):
        ic_name = self._qsfp_map.get(qsfp_n, None)
        for mem_addr, v in prog_dict.items():
            size, fmt = v
            self.read(ic_name, mem_addr, size, reg_name=fmt.format(qsfp_n+1))
        return True


    def qsfp_init(self, qsfp_n=0):
        return self._qsfp_do(qsfp_n, qsfp_init_d)


    def qsfp_poll(self, qsfp_n=0):
        return self._qsfp_do(qsfp_n, qsfp_poll_d)


    def chsel(n):
        n = max(min(7, int(n)), 0) # peg n
        return (1<<n) & 0xff


    def busmux_reset(self):
        # TODO - enable this functionality
        self._s.pause(10)
        self._s.hw_config(1)  # turn on reset
        self._s.pause(10)
        self._s.hw_config(0)  # turn off reset
        self._s.pause(10)
        return


    def bsp_config(self):
        # 0 is output, 1 is input
        # Port num  Pin num Dir 0/1
        # -------------------------
        # 0         0       x
        # 0         1       x
        # 0         2       x
        # 0         3       Out 0 (QSFP1_LPMODE)    # Set high for now TODO - does this mode work?
        # 0         4       In  1 (QSFP1_INT)
        # 0         5       In  1 (QSFP1_MOD_PRS)
        # 0         6       Out 0 (QSFP1_RST)       # Set high (low-true)
        # 0         7       Out 0 (QSFP1_MOD_SEL)   # Set low (low-true)
        # 1         0       x
        # 1         1       x
        # 1         2       x
        # 1         3       Out 0 (QSFP2_LPMODE)    # Set high for now
        # 1         4       In  1 (QSFP2_INT)
        # 1         5       In  1 (QSFP2_MOD_PRS)
        # 1         6       Out 0 (QSFP2_RST)       # Set high (low-true)
        # 1         7       Out 0 (QSFP2_MOD_SEL)   # Set low (low-true)
        # Safest to set unused pins as output low (avoid spurious transitions)
        # Select App bus
        self._s.set_resx(0)  # Start from address 0
        self.busmux_reset()
        dirs = (1<<4) | (1<<5)
        states = (1<<3) | (1<<6)
        self.write("U34", 2, [states, states])  # U34 Output registers
        self.write("U34", 6, [dirs, dirs])      # U34 Configuration registers
        return

    def bsp_readback(self):
        self.read("U34", 0, 1, reg_name="U34_PORT0")  # U34 port 0 pin states
        self.read("U34", 1, 1, reg_name="U34_PORT1")  # U34 port 1 pin states
        #self.read("U17", 0, 2, reg_name="FMC1_PWR_CONFIG")  # U17 config
        #self.read("U17", 1, 2, reg_name="FMC1_PWR_SHVOLTS")  # U17 shunt voltage
        #self.read("U32", 0, 2, reg_name="FMC2_PWR_CONFIG")  # U32 config
        #self.read("U32", 1, 2, reg_name="FMC2_PWR_SHVOLTS")  # U32 shunt voltage
        return

    def read(self, ic_name, madr, dlen, addr_bytes=1, reg_name = None):
        ic_addr = self.select_ic(ic_name)
        if ic_addr is None:
            raise Exception(f"Unknown IC name {ic_name}")
        else:
            return self._s.read(ic_addr, madr, dlen, addr_bytes=addr_bytes, reg_name=reg_name)

    def write(self, ic_name, madr, data, addr_bytes=1):
        ic_addr = self.select_ic(ic_name)
        if ic_addr is None:
            raise Exception(f"Unknown IC name {ic_name}")
        else:
            return self._s.write(ic_addr, madr, data, addr_bytes=addr_bytes)
