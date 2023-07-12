#! /usr/bin/python3

# Marble-specific I2C map and helper functions

_assem_warn = """INFO: Cannot import module 'assem'; no I2C program assembly available.
Must set PYTHONPATH=path/to/bedrock/peripheral_drivers/i2cbridge to use this functionality
"""
import inspect
_assem_available = True
try:
    from i2cbridge import assem
except ImportError:
    try:
        import assem
    except ImportError:
        _assem_available = False


class MarbleI2C():
    # I2C bus map
    _i2c_map = {
        ("U5", 0xe0): {     # Bus mux U5
            # Branch number : (branch name, branch dict)
            0: ("FMC1", {}),
            1: ("FMC2", {}),
            2: ("CLK", {
                "U2": 0x90
            }),
            3: ("SO-DIMM", {
                # Write-protected memory range 0x50-0x57;
                # Unprotected memory range 0x30-0x37
                # See "Serial Presence Detect" on Wikipedia
                "SK1": 0x50
            }),
            4: ("QSFP1", {
                # IC name : I2C address
                "J17": 0xa0
            }),
            5: ("QSFP2", {
                # IC name : I2C address
                "J8": 0xa0
            }),
            6: ("APP", {
                # IC name : I2C address
                "U57": 0x84,
                "U32": 0x82,
                "U17": 0x80,
                "Y6": 0xea,
                "U34": 0x44,
                "U39": 0x42
            }),
        }
    }

    # QSFP index : IC name
    _qsfp_map = {0: "J17", 1: "J8"}

    # INA219 index : IC name
    _ina219_map = {0: "U17", 1: "U32", 2: "U57"}

    # ========= IC-Specific Information =================
    # U34 (PCAL9555) I2C GPIO expander
    # Unused pins are set as input and have internal weak pullups
    # Pin   Net             Dir Note
    # ------------------------------
    # P0_0  (unused)        In
    # P0_1  (unused)        In
    # P0_2  (unused)        In
    # P0_3  QSFP1_LPMODE    Out Low-true (1 = high-power mode)
    # P0_4  QSFP1_INT       In  High-true (1 = interrupt)
    # P0_5  QSFP1_MOD_PRS   In  Low-true (0 = module present)
    # P0_6  QSFP1_RST       Out Low-true (0 = reset)
    # P0_7  QSFP1_MOD_SEL   Out Low-true (0 = module selected)
    u34_port0_dir = 0b00110111

    # Pin   Net             Dir Note
    # ------------------------------
    # P1_0  (unused)        In
    # P1_1  (unused)        In
    # P1_2  (unused)        In
    # P1_3  QSFP2_LPMODE    Out Low-true (1 = high-power mode)
    # P1_4  QSFP2_INT       In  High-true (1 = interrupt)
    # P1_5  QSFP2_MOD_PRS   In  Low-true (0 = module present)
    # P1_6  QSFP2_RST       Out Low-true (0 = reset)
    # P1_7  QSFP2_MOD_SEL   Out Low-true (0 = module selected)
    u34_port1_dir = 0b00110111

    # U39 (PCAL9555) I2C GPIO expander
    # Pin   Net             Dir
    # -------------------------
    # P0_0  SI570_OE        Out
    # P0_1  (unused)        In
    # P0_2  EN_USB_JTAG     In
    # P0_3  EN_CON_JTAG_R   In
    # P0_4  ALERT           In
    # P0_5  FANFAIL         In
    # P0_6  THERM           In
    # P0_7  CFG_WP_B        In
    u39_port0_dir = 0b11111110

    # Pin   Net             Dir
    # -------------------------
    # P1_0  (unused)        In
    # P1_1  (unused)        In
    # P1_2  LD14_N          Out
    # P1_3  LD13_N          Out
    # P1_4  (unused)        In
    # P1_5  (unused)        In
    # P1_6  (unused)        In
    # P1_7  CLKMUX_RST      Out
    u39_port1_dir = 0b01110011

    # U2 (ADDN4600) MGT clock multiplexer
    u2_xpt_config = 0x40  # XPT Configuration register

    @staticmethod
    def _chsel(n):
        n = max(min(7, int(n)), 0)  # peg n
        return (1 << n) & 0xff

    def __init__(self, i2c_assembler=None):
        self._s = i2c_assembler
        if self._s is None:
            if _assem_available:
                self._s = assem.I2CAssembler()
        if self._s is None:
            print(_assem_warn)
        self._associate()
        self._inherit()
        self._ch_selected = None
        return

    def _inherit(self):
        """[private] Inherit methods from I2CAssembler avoiding conflicts by prepending 'll_'
        (for 'low-level' functionality) any conflicting names."""
        if self._s is None:
            return
        prefix = "ll_"
        for fn_name in dir(self._s):
            # Skip private functions
            if not fn_name.startswith('_'):
                fn = getattr(self._s, fn_name)
                if inspect.ismethod(fn):
                    # Look for name conflicts
                    if getattr(self, fn_name, False):
                        fn_name = prefix+fn_name
                    # self.ll_foo = self._s.foo
                    setattr(self, fn_name, fn)
        return

    def _associate(self):
        """[private] Build a 2D list from the map"""
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

    def _busmux(self, mux_addr, mux_ch):
        """[private] Select a channel with the bus multiplexer at address mux_addr."""
        if self._s is None:
            return
        if self._ch_selected != mux_ch:
            self._s.write(mux_addr, self._chsel(mux_ch), [])
            self._ch_selected = mux_ch
        return

    @classmethod
    def get_muxes(cls):
        """Returns a list of tuples (name_str, i2c_address_int) for all bus multiplexers
        in the I2C map."""
        muxes = []
        for mux, tree in cls._i2c_map.items():
            mux_name, mux_addr = mux
            muxes.append((mux_name, mux_addr))
        return muxes

    def get_ics(self):
        """Returns a list of tuples (name_str, i2c_address_int) for all ICs in the I2C map."""
        ics = []
        for _l in self._a:
            name = _l[0]
            addr = _l[1]
            ics.append((name, addr))
        return ics

    def get_i2c_addr(self, ic_name):
        """Get the I2C address of IC with name 'ic_name'
        Params:
            string ic_name: Any valid IC name in the I2C map
        Returns int I2C address if 'ic_name'  is found in the I2C map, otherwise None.
        """
        for _l in self._a:
            if ic_name == _l[0]:
                return _l[1]
        return None

    def get_i2c_name(self, i2c_addr):
        """Get the name of IC with I2C address 'i2c_addr'
        Params:
            int i2c_addr: I2C address of the desired IC (0-255).
        Returns string IC name if 'i2c_addr' is found in the I2C map, otherwise None.
        """
        for _l in self._a:
            if i2c_addr == _l[1]:
                return _l[0]
        return None

    def select_ic(self, ic_name):
        """Select (enable) the branch of a particular IC by name.
        Params:
            string ic_name: Any valid IC name in the I2C map
        Returns int I2C address if 'ic_name'  is found in the I2C map, otherwise None.
        Note: Use get_i2c_addr() if you just want the address and don't want to change
        the state of the bus multiplexer.
        """
        for nic in self._a:
            _ic_name, ic_addr, branch_name, ch, mux_name, mux_addr = nic
            if ic_name.lower().strip() == _ic_name.lower().strip():
                # If we found a match, mux to it
                self._busmux(mux_addr, ch)
                return ic_addr
        return None

    def select_branch(self, branch):
        """Select (enable) a branch of the bus mux by name.
        Params:
            string branch: One of 'FMC1', 'FMC2', 'CLK', 'SO-DIMM', 'QSFP1', 'QSFP2', 'APP'
        Returns int channel number (0-7) that was selected or None if 'branch' does not match
        any of the above.
        """
        for nic in self._a:
            ic_name, ic_addr, branch_name, ch, mux_name, mux_addr = nic
            if branch_name.lower().strip() == branch.lower().strip():
                # If we found a match, mux to it
                self._busmux(mux_addr, ch)
                return ch
        return None

    def get_addr(self, ic_name):
        """Get the I2C address of IC given by string 'ic_name'
        Params:
            string ic_name: Any valid IC name in the I2C map
        Returns I2C address (int) if 'ic_name' is found in the I2C map, otherwise None."""
        for nic in self._a:
            _ic_name, ic_addr, branch_name, ch, mux_name, mux_addr = nic
            if ic_name.lower().strip() == _ic_name.lower().strip():
                return ic_addr
        return None

    def bsp_configure(self):
        """Initial configuration of Marble board.  Optionally override based on
        application."""
        self.U34_configure()
        self.U39_configure()
        return

    def bsp_poll(self):
        """Override based on application."""
        self.U34_read_data()
        self.U39_read_data()
        return

    # =============== I2C Commands by IC Name Helper Functions ================
    def read(self, ic_name, madr, dlen, addr_bytes=1, reg_name=None):
        if self._s is None:
            return
        ic_addr = self.select_ic(ic_name)
        if ic_addr is None:
            raise Exception(f"Unknown IC name {ic_name}")
        else:
            return self._s.read(ic_addr, madr, dlen, addr_bytes=addr_bytes, reg_name=reg_name)

    def write(self, ic_name, madr, data, addr_bytes=1):
        if self._s is None:
            return
        ic_addr = self.select_ic(ic_name)
        if ic_addr is None:
            raise Exception(f"Unknown IC name {ic_name}")
        else:
            return self._s.write(ic_addr, madr, data, addr_bytes=addr_bytes)
    # ============ SI570 (Y6) Clock Generator Helper Functions ================
    # TODO

    # ============= U2 MGT Clock Multiplexer Helper Functions =================
    def U2_select_clock(self, in_ch, out_ch):
        """Configure U2 MGT clock mux to route input channge in_ch to output channel
        out_ch.
        Params:
            int in_ch:  Input channel (0-7)
            int out_ch: Output channel (0-7)
        Gotchas:
            Raises an exception if you try to use any of the unused outputs.
            You might accidentally turn off your clock.
        """
        if out_ch in (2, 3, 6, 7):
            raise Exception(f"Attempting to use unconnected output {out_ch} of MGT clock mux U2")
        data = ((in_ch & 0x7) << 4) | (out_ch & 0x7)
        return self.write("U2", self.u2_xpt_config, data, addr_bytes=1)

    # ================== QSFP (J17/J8) Helper Functions =======================
    def qsfp_read(self, qsfp_n, mem_addr, size, reg_name=None):
        """Simple wrapper allowing reads from QSFPs by index instead of by IC name."""
        ic_name = self._qsfp_map.get(qsfp_n)
        return self.read(ic_name, mem_addr, size, addr_bytes=1, reg_name=reg_name)

    def qsfp_read_many(self, qsfp_n=0, prog_dict={}):
        """Helper function to add several reads to the I2C program for either
        QSFP1 (J17) or QSFP2 (J8) selected by qsfp_n (0 or 1).
        Params:
            dict prog_dict: Dict of entries each with the format
                                int mem_addr : (int nbytes, string fmt_str)
                            The single-byte memory address 'mem_addr' is the memory offset
                            in the QSFP+ standard memory map
                            (ref: https://www.mouser.com/pdfdocs/AN-2152100GQSFP28LR4EEPROMmapRevC.pdf)
                            The integer 'nbytes' is the number of bytes to read (0-30)
                            The format string 'fmt_str' determines the corresponding
                            name in the memory map resolved by fmt_str.format(qsfp_n+1)
        Gotchas:
            Best use case is when reading the same information from both QSFPs.
            Enforces the same register name convention for both QSFPs.
        """
        ic_name = self._qsfp_map.get(qsfp_n, None)
        for mem_addr, v in prog_dict.items():
            size, fmt = v
            self.read(ic_name, mem_addr, size, reg_name=fmt.format(qsfp_n+1))
        return

    # ======================= U34 Helper Functions ============================
    def U34_configure(self):
        """Configure GPIO expander U34 with proper input/output settings on each pin
        of both ports."""
        return self.write("U34", 6, [self.u34_port0_dir, self.u34_port1_dir])  # U34 Configuration registers

    def U34_set_data(self, datamask):
        """Set pin state of outputs on GPIO expander U34 (PCAL9555).
        Params:
            datamask :  If datamask is an integer, it is interpreted as a bitmask
                        where bit 0 corresponds to P0_0 and bit 15 corresponds to P1_7.
                        If datamask is a list, it is expected to be a list of integers
                        of length 2 where each integer is an 8-bit bitmask of each port
                        (datamask[0] => Port 0, datamask[1] => Port 1).
        Returns None
        Gotchas:
            Always writes both ports!
            Only allows setting direction on ports configured as outputs.
        """
        if not hasattr(datamask, '__len__'):
            datamask = [(datamask >> 8), datamask & 0xff]
        p0_mask = (~self.u34_port0_dir) & 0xff
        p1_mask = (~self.u34_port1_dir) & 0xff
        data0 = datamask[0] & p0_mask
        data1 = datamask[1] & p1_mask
        self.write("U34", 2, [data0, data1])  # U34 data registers
        self.write("U34", 6, [self.u34_port0_dir, self.u34_port1_dir])  # U34 Configuration registers
        return

    def U34_read_data(self):
        """Add a read instruction to the I2C program to read the state of GPIO pins on
        GPIO expander U34 (PCAL9555).  Shows up in memory map as 'U34_PORT_DATA'"""
        return self.read("U34", 2, 2, reg_name="U34_PORT_DATA")

    # ======================= U39 Helper Functions ============================
    def U39_configure(self):
        """Configure GPIO expander U39 with proper input/output settings on each pin
        of both ports."""
        return self.write("U39", 6, [self.u39_port0_dir, self.u39_port1_dir])  # U39 Configuration registers

    def U39_set_data(self, datamask):
        """Set pin state of outputs on GPIO expander U39 (PCAL9555).
        Params:
            datamask :  If datamask is an integer, it is interpreted as a bitmask
                        where bit 0 corresponds to P0_0 and bit 15 corresponds to P1_7.
                        If datamask is a list, it is expected to be a list of integers
                        of length 2 where each integer is an 8-bit bitmask of each port
                        (datamask[0] => Port 0, datamask[1] => Port 1).
        Returns None
        Gotchas:
            Always writes both ports!
            Only allows setting direction on ports configured as outputs.
        """
        if not hasattr(datamask, '__len__'):
            datamask = [(datamask >> 8), datamask & 0xff]
        p0_mask = (~self.u39_port0_dir) & 0xff
        p1_mask = (~self.u39_port1_dir) & 0xff
        data0 = datamask[0] & p0_mask
        data1 = datamask[1] & p1_mask
        self.write("U39", 2, [data0, data1])  # U39 data registers
        return

    def U39_read_data(self):
        """Add a read instruction to the I2C program to read the state of GPIO pins on
        GPIO expander U39 (PCAL9555).  Shows up in memory map as 'U39_PORT_DATA'"""
        return self.read("U39", 2, 2, reg_name="U39_PORT_DATA")

    # ================ INA219 (U17, U32, U57) Helper Functions ================
    def INA219_read_bus_voltage(self, ic_name, reg_name=None):
        """Add a read instruction to the I2C program to read the value of the bus
        voltage register within INA219 IC given by 'ic_name'
        Params:
            string ic_name: One of ('U17', 'U32', or 'U57')
            string reg_name: The name to be used in the memory map for the result address
        Gotchas:
            Raises an Exception if you specify an IC other than the three listed above
        Note: to convert result to mV, multiply by 4.
        """
        matched = False
        for index, name in self._ina219_map.items():
            if name == ic_name:
                matched = True
        if not matched:
            raise Exception(f"Using INA219 helper function on incompatible IC {ic_name}")
        ina219_reg_bus_voltage = 2  # Just for clarity
        return self.read(ic_name, ina219_reg_bus_voltage, 2, reg_name=reg_name)

    def INA219_read_shunt_voltage(self, ic_name, reg_name=None):
        """Add a read instruction to the I2C program to read the value of the shunt
        voltage register within INA219 IC given by 'ic_name'
        Params:
            string ic_name: One of ('U17', 'U32', or 'U57')
            string reg_name: The name to be used in the memory map for the result address
        Gotchas:
            Raises an Exception if you specify an IC other than the three listed above
        Note: converting shunt voltage to current is outside the scope of this module.
        """
        matched = False
        for index, name in self._ina219_map.items():
            if name == ic_name:
                matched = True
        if not matched:
            raise Exception(f"Using INA219 helper function on incompatible IC {ic_name}")
        ina219_reg_shunt_voltage = 1  # Just for clarity
        return self.read(ic_name, ina219_reg_shunt_voltage, 2, reg_name=reg_name)


if __name__ == "__main__":
    m = MarbleI2C()
