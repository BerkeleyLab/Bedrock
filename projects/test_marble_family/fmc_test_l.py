# Mapping functions to support CERN's OHWR FMC Carrier Tester board
# https://www.ohwr.org/project/fmc-conn-tester/wikis/home
# a703f7f70230f579a87bd9c17df9f9591a629c91d9f8a5fc84de695a3bcf9ae3  EDA-02327-V1-0_sch.pdf
# specifically its connectivity between the LA bank and I2C port expanders

# Lookup from MCP23017 register to IO_VADJ_ signal number on schematic
# within a row, arranged from msb to lsb
vadj_n = [
    51, 52, 73, 9, 74, 8, 31, 33,    # IC1 A
    53, 30, 72, 28, 29, 7, 50, 6,    # IC1 B
    45, 44, 23, 32, 11, 10, 54, 55,  # IC2 A
    56, 75, 76, 35, 34, 12, 13, 57,  # IC2 B
    17, 64, 18, 19, 42, 65, 41, 40,  # IC3 A
    66, 67, 80, 20, 43, 68, 21, 22,  # IC3 B
    61, 15, 60, 70, 38, 63, 39, 16,  # IC4 A
    14, 58, 77, 78, 37, 36, 59, 69,  # IC4 B
    5, 3, 25, 2, 24, 46, 47, 1,      # IC5 A
    26, 4, 27, 49, 71, 48, 62, 79    # IC5 B
]

# Lookup from IO_VSADJ_ number to FMC signal name
fmc_n = {
    1: "VREF_A_M2C",
    2: "LA02_P",
    3: "LA02_N",
    4: "LA04_P",
    5: "LA04_N",
    6: "LA07_P",
    7: "LA07_N",
    8: "LA11_P",
    9: "LA11_N",
    10: "LA15_P",
    11: "LA15_N",
    12: "LA19_P",
    13: "LA19_N",
    14: "LA21_P",
    15: "LA21_N",
    16: "LA24_P",
    17: "LA24_N",
    18: "LA28_P",
    19: "LA28_N",
    20: "LA30_P",
    21: "LA30_N",
    22: "LA32_P",
    23: "LA32_N",
    24: "LA00_P",
    25: "LA00_N",
    26: "LA03_P",
    27: "LA03_N",
    28: "LA08_P",
    29: "LA08_N",
    30: "LA12_P",
    31: "LA12_N",
    32: "LA16_P",
    33: "LA16_N",
    34: "LA20_P",
    35: "LA20_N",
    36: "LA22_P",
    37: "LA22_N",
    38: "LA25_P",
    39: "LA25_N",
    40: "LA29_P",
    41: "LA29_N",
    42: "LA31_P",
    43: "LA31_N",
    44: "LA33_P",
    45: "LA33_N",
    46: "CLK1_M2C_P",
    47: "CLK1_M2C_N",
    48: "LA01_P",
    49: "LA01_N",
    50: "LA05_P",
    51: "LA05_N",
    52: "LA09_P",
    53: "LA09_N",
    54: "LA13_P",
    55: "LA13_N",
    56: "LA17_P",
    57: "LA17_N",
    58: "LA23_P",
    59: "LA23_N",
    60: "LA26_P",
    61: "LA26_N",
    62: "PG_C2M",
    63: "TCK_TO_FMC",
    64: "TDI_TO_FMC",
    65: "TDO_FROM_FMC",
    66: "TMS_TO_FMC",
    67: "TRST_TO_FMC",
    68: "GA1",
    69: "LA27_P",
    70: "LA27_N",
    71: "LA06_P",
    72: "LA06_N",
    73: "LA10_P",
    74: "LA10_N",
    75: "LA14_P",
    76: "LA14_N",
    77: "LA18_P",
    78: "LA18_N",
    79: "M2C_DIR",
    80: "GA0"
}


def tobin(x, count=8):
    # Integer to binary; count is number of bits
    # Props to W.J. van der Laan in http://code.activestate.com/recipes/219300/
    return list(map(lambda y: (x >> y) & 1, range(count-1, -1, -1)))


def fmc_decode(n, a, squelch=True, verbose=True):
    if verbose:
        fmc_asc = ", ".join(["0x%2.2x" % x for x in a])
        print("FMC%s dig: %s" % (n+1, fmc_asc))
    # squelch bits:
    #  TDI_TO_FMC
    #  TDO_FROM_FMC
    #  TMS_TO_FMC
    #  TRST_TO_FMC
    #  TCK_TO_FMC
    #  VREF_A_M2C
    #  PG_C2M
    sb = [0x00, 0x00, 0x00, 0x00, 0x44, 0xc0, 0x04, 0x00, 0x01, 0x02]
    found = []
    ga = 0
    for ix in range(10):
        bits = tobin(a[ix] & ~sb[ix]) if squelch else tobin(a[ix])
        # print(bits)
        for jx in range(8):
            bname = fmc_n[vadj_n[ix*8+jx]]
            if bname == "GA0":
                ga = ga + bits[jx]
            elif bname == "GA1":
                ga = ga + bits[jx]*2
            elif bits[jx] == 1:
                found += [bname]
                if verbose:
                    print("  FMC%d on: %s" % (n+1, bname))
    return found, ga


def fmc_goal(n):
    pn = "P" if int(n/33) else "N"
    d = n % 33
    # LA02 is special, used for I2C pins
    if d > 1:
        d = d+1
    return "LA%2.2d_%s" % (d, pn)
