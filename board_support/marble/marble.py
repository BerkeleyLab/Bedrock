from litex.build.generic_platform import *
from litex.build.xilinx import XilinxPlatform, VivadoProgrammer

# IOs ----------------------------------------------------------------------------------------------

# TODO:
# 1. TMDS
# 2. Check other TODOs
# 3. Check signal standards (NOT obvious from schematic) will have to dig through
#    datasheets
# 4. System clock?! For now derive from MGTREF

_io = [
    # ("clk20_vcxo", 0, Subsignal("p", Pins("R3"), IOStandard("DIFF_SSTL15")),
    #  Subsignal("n", Pins("P3"), IOStandard("DIFF_SSTL15"))),
    # ("clk156", 0, Subsignal("p", Pins("M21"), IOStandard("LVDS_25")),
    #  Subsignal("n", Pins("M22"), IOStandard("LVDS_25"))),
    ("mgt_clk_0", 0, Subsignal("p", Pins("F6")), Subsignal("n", Pins("E6"))),
    ("mgt_clk_1", 0, Subsignal("p", Pins("F10")), Subsignal("n", Pins("E10"))),
    # ("serial", 0,
    #     Subsignal("cts", Pins("V19")),
    #     Subsignal("rts", Pins("W19")),
    #     Subsignal("tx", Pins("U19")),
    #     Subsignal("rx", Pins("T19")),
    #     IOStandard("LVCMOS18")
    # ),
    ("eth_clocks", 0, Subsignal("tx", Pins("J15")),
     Subsignal("rx", Pins("L19")), IOStandard("LVCMOS18")),
    ("eth", 0, Subsignal("rx_dv", Pins("L13")),
     Subsignal("rx_data", Pins("K13 H14 J14 K14")),
     Subsignal("tx_en", Pins("J16")),
     Subsignal("tx_data", Pins("G15 G16 G13 H13")),
     Subsignal("rst_n", Pins("M17")), IOStandard("LVCMOS18"),
     Misc("SLEW=FAST"), Drive(16)),
    ("ddram",
        0,
        Subsignal("a",
                  Pins("L6 M5 P6 K6 M1 M3 N2 M6", "P1 P2 K3 N5 L3 R1 N3 L4"),
                  IOStandard("SSTL15")),
        Subsignal("ba", Pins("L5 M2 N4"), IOStandard("SSTL15")),
        Subsignal(
            "ras_n", Pins("J4"),
            IOStandard("SSTL15")),  # TODO: Typically _N what about marble?
        Subsignal(
            "cas_n", Pins("J6"),
            IOStandard("SSTL15")),  # TODO: Typically _N what about marble?
        Subsignal(
            "we_n", Pins("H2"),
            IOStandard("SSTL15")),  # TODO: Typically _N what about marble?
        Subsignal(
            "cs_n", Pins("T3"),
            IOStandard("SSTL15")),  # TODO: couldn't find chip select on Marble
        Subsignal("dm", Pins("G2 E2"), IOStandard("SSTL15")),
        Subsignal("dq",
                  Pins("G3 J1 H4 H5 E3 K1 H3 J5", "G1 B1 F1 F3 C2 A1 D2 B2"),
                  IOStandard("SSTL15")),
        Subsignal("dqs_p", Pins("K2 E1"),
                  IOStandard("DIFF_SSTL15")),  # TODO check L is before H
        Subsignal("dqs_n", Pins("J2 D1"),
                  IOStandard("DIFF_SSTL15")),  # TODO check L is before H
        Subsignal("clk_p", Pins("P5"), IOStandard("DIFF_SSTL15")),
        Subsignal("clk_n", Pins("P4"), IOStandard("DIFF_SSTL15")),
        Subsignal("cke", Pins("L1"), IOStandard("SSTL15")),
        Subsignal("odt", Pins("K4"), IOStandard("SSTL15")),
        Subsignal("reset_n", Pins("G4"), IOStandard("LVCMOS15"))),
]

# Connectors ---------------------------------------------------------------------------------------

_connectors = [("LPC-1", {
    'CLK0_M2C_N': 'W20',
    'CLK0_M2C_P': 'W19',
    'CLK1_M2C_N': 'Y19',
    'CLK1_M2C_P': 'Y18',
    'LA_0_N': 'V20',
    'LA_0_P': 'U20',
    'LA_1_N': 'V19',
    'LA_1_P': 'V18',
    'LA_2_N': 'R16',
    'LA_2_P': 'P15',
    'LA_3_N': 'N14',
    'LA_3_P': 'N13',
    'LA_4_N': 'W17',
    'LA_4_P': 'V17',
    'LA_5_N': 'R19',
    'LA_5_P': 'P19',
    'LA_6_N': 'AB18',
    'LA_6_P': 'AA18',
    'LA_7_N': 'AA21',
    'LA_7_P': 'AA20',
    'LA_8_N': 'P17',
    'LA_8_P': 'N17',
    'LA_9_N': 'T18',
    'LA_9_P': 'R18',
    'LA_10_N': 'AB20',
    'LA_10_P': 'AA19',
    'LA_11_N': 'R17',
    'LA_11_P': 'P16',
    'LA_12_N': 'U18',
    'LA_12_P': 'U17',
    'LA_13_N': 'W22',
    'LA_13_P': 'W21',
    'LA_14_N': 'AB22',
    'LA_14_P': 'AB21',
    'LA_15_N': 'Y22',
    'LA_15_P': 'Y21',
    'LA_16_N': 'R14',
    'LA_16_P': 'P14',
    'LA_17_N': 'K19',
    'LA_17_P': 'K18',
    'LA_18_N': 'H19',
    'LA_18_P': 'J19',
    'LA_19_N': 'J17',
    'LA_19_P': 'K17',
    'LA_20_N': 'L15',
    'LA_20_P': 'L14',
    'LA_21_N': 'N19',
    'LA_21_P': 'N18',
    'LA_22_N': 'L21',
    'LA_22_P': 'M21',
    'LA_23_N': 'M20',
    'LA_23_P': 'N20',
    'LA_24_N': 'H18',
    'LA_24_P': 'H17',
    'LA_25_N': 'L18',
    'LA_25_P': 'M18',
    'LA_26_N': 'G20',
    'LA_26_P': 'H20',
    'LA_27_N': 'M22',
    'LA_27_P': 'N22',
    'LA_28_N': 'M16',
    'LA_28_P': 'M15',
    'LA_29_N': 'K22',
    'LA_29_P': 'K21',
    'LA_30_N': 'K16',
    'LA_30_P': 'L16',
    'LA_31_N': 'H22',
    'LA_31_P': 'J22',
    'LA_32_N': 'G18',
    'LA_32_P': 'G17',
    'LA_33_N': 'J21',
    'LA_33_P': 'J20'
}), ("LPC-2", {
    'CLK0_M2C_N': 'W4',
    'CLK0_M2C_P': 'V4',
    'CLK1_M2C_N': 'T4',
    'CLK1_M2C_P': 'R4',
    'LA_0_N': 'U5',
    'LA_0_P': 'T5',
    'LA_1_N': 'AA4',
    'LA_1_P': 'Y4',
    'LA_2_N': 'V3',
    'LA_2_P': 'U3',
    'LA_3_N': 'V2',
    'LA_3_P': 'U2',
    'LA_4_N': 'V5',
    'LA_4_P': 'U6',
    'LA_5_N': 'T6',
    'LA_5_P': 'R6',
    'LA_6_N': 'U1',
    'LA_6_P': 'T1',
    'LA_7_N': 'V8',
    'LA_7_P': 'V9',
    'LA_8_N': 'Y2',
    'LA_8_P': 'W2',
    'LA_9_N': 'AA3',
    'LA_9_P': 'Y3',
    'LA_10_N': 'Y1',
    'LA_10_P': 'W1',
    'LA_11_N': 'AA6',
    'LA_11_P': 'Y6',
    'LA_12_N': 'W5',
    'LA_12_P': 'W6',
    'LA_13_N': 'W7',
    'LA_13_P': 'V7',
    'LA_14_N': 'AB1',
    'LA_14_P': 'AA1',
    'LA_15_N': 'AB5',
    'LA_15_P': 'AA5',
    'LA_16_N': 'AB2',
    'LA_16_P': 'AB3',
    'LA_17_N': 'W12',
    'LA_17_P': 'W11',
    'LA_18_N': 'V14',
    'LA_18_P': 'V13',
    'LA_19_N': 'Y12',
    'LA_19_P': 'Y11',
    'LA_20_N': 'AA11',
    'LA_20_P': 'AA10',
    'LA_21_N': 'AA14',
    'LA_21_P': 'Y13',
    'LA_22_N': 'W16',
    'LA_22_P': 'W15',
    'LA_23_N': 'W10',
    'LA_23_P': 'V10',
    'LA_24_N': 'Y14',
    'LA_24_P': 'W14',
    'LA_25_N': 'AB12',
    'LA_25_P': 'AB11',
    'LA_26_N': 'AA16',
    'LA_26_P': 'Y16',
    'LA_27_N': 'AB10',
    'LA_27_P': 'AA9',
    'LA_28_N': 'T15',
    'LA_28_P': 'T14',
    'LA_29_N': 'U16',
    'LA_29_P': 'T16',
    'LA_30_N': 'V15',
    'LA_30_P': 'U15',
    'LA_31_N': 'AB13',
    'LA_31_P': 'AA13',
    'LA_32_N': 'AB15',
    'LA_32_P': 'AA15',
    'LA_33_N': 'AB17',
    'LA_33_P': 'AB16'
})]

# Platform -----------------------------------------------------------------------------------------


class Platform(XilinxPlatform):
    def __init__(self):
        XilinxPlatform.__init__(
            self, "xc7a200t-fbg484", _io, _connectors, toolchain="vivado")
        # For now set to use the default VIVADO programmer, should be changed to xc3sprog
        self.toolchain.bitstream_commands = [
            "set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]"
        ]
        self.toolchain.additional_commands = [
            "write_cfgmem -force -format bin -interface spix4 -size 16 -loadbit \"up 0x0 {build_name}.bit\" -file {build_name}.bin"
        ]

    def create_programmer(self):
        # TODO: Should be changed to xc3sprog if confirmed so
        return VivadoProgrammer()

    def do_finalize(self, fragment):
        XilinxPlatform.do_finalize(self, fragment)
        try:
            # TODO: This clock doesn't exist, so remove this constraint, not a big deal
            self.add_period_constraint(
                self.lookup_request("clk200").p, 1e9 / 200e6)
        except ConstraintError:
            pass
        try:
            self.add_period_constraint(
                self.lookup_request("eth_clocks").rx, 1e9 / 125e6)
        except ConstraintError:
            pass
        try:
            self.add_period_constraint(
                self.lookup_request("eth_clocks").tx, 1e9 / 125e6)
        except ConstraintError:
            pass
