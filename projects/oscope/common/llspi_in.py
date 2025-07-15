def frombin(x):
    vv = 0
    for b in x:
        vv = vv * 2 + int(b)
    return vv


def lmk_output(v):
    vv = frombin(v)
    # print "# %8.8x"%vv
    print("0 101")
    print(("0 %3.3x" % (vv >> 24)))
    print(("0 %3.3x" % ((vv >> 16) & 0xff)))
    print(("0 %3.3x" % ((vv >> 8) & 0xff)))
    print(("0 %3.3x" % ((vv) & 0xff)))
    print("0 100")


# LMK01801 register names taken directly from datasheet

# R0
CLKin1_MUX = "01"  # divide
CLKin1_DIV = "000"  # 8
CLKin0_MUX = "01"  # divide
CLKin0_DIV = "111"  # 7
CLKin1_BUF_TYPE = "0"  # bipolar
CLKin0_BUF_TYPE = "0"  # bipolar
CLKout12_13_PD = "0"
CLKout8_11_PD = "0"
CLKout4_7_PD = "0"
CLKout0_3_PD = "0"
POWERDOWN = "0"
RESET = "1"
R0 = ("01001000" + CLKin1_MUX + CLKin1_DIV + CLKin0_MUX + CLKin0_DIV + "11" + CLKin1_BUF_TYPE +
      CLKin0_BUF_TYPE + CLKout12_13_PD + CLKout8_11_PD + CLKout4_7_PD + CLKout0_3_PD + POWERDOWN +
      RESET + "0000")
lmk_output(R0)
RESET = "0"
R0 = ("01001000" + CLKin1_MUX + CLKin1_DIV + CLKin0_MUX + CLKin0_DIV + "11" + CLKin1_BUF_TYPE +
      CLKin0_BUF_TYPE + CLKout12_13_PD + CLKout8_11_PD + CLKout4_7_PD + CLKout0_3_PD + POWERDOWN +
      RESET + "0000")
lmk_output(R0)

# R1
CLKout7_TYPE = "0000"  # Powerdown
CLKout6_TYPE = "0000"  # Powerdown
CLKout5_TYPE = "0001"  # LVPECL
CLKout4_TYPE = "0000"  # Powerdown
CLKout3_TYPE = "000"  # Powerdown
CLKout2_TYPE = "110"  # CMOS  J13 test point
CLKout1_TYPE = "001"  # LVDS  DAC2
CLKout0_TYPE = "001"  # LVDS  DAC1
R1 = (CLKout7_TYPE + CLKout6_TYPE + CLKout5_TYPE + CLKout4_TYPE + CLKout3_TYPE + CLKout2_TYPE +
      CLKout1_TYPE + CLKout0_TYPE + "0001")
lmk_output(R1)

# R2
CLKout13_TYPE = "0000"  # Powerdown
CLKout12_TYPE = "0000"  # Powerdown
CLKout11_TYPE = "0110"  # CMOS J24 test point
CLKout10_TYPE = "0001"  # LVDS J20
CLKout9_TYPE = "0000"  # Powerdown
CLKout8_TYPE = "0000"  # Powerdown
R2 = ("0000" + CLKout13_TYPE + CLKout12_TYPE + CLKout11_TYPE + CLKout10_TYPE + CLKout9_TYPE +
      CLKout8_TYPE + "0010")
lmk_output(R2)

# R3
SYNC1_AUTO = "0"
SYNC0_AUTO = "0"
SYNC1_FAST = "1"
SYNC0_FAST = "1"
NO_SYNC_CLKout12_13 = "0"
NO_SYNC_CLKout8_11 = "0"
NO_SYNC_CLKout4_7 = "0"
NO_SYNC_CLKout0_3 = "0"
SYNC1_POL_INV = "1"
SYNC0_POL_INV = "1"
SYNC1_QUAL = "00"
CLKout12_13_HS = "0"
CLKout12_13_ADLY = "000000"
R3 = ("00010" + SYNC1_AUTO + SYNC0_AUTO + SYNC1_FAST + SYNC0_FAST + "011" + NO_SYNC_CLKout12_13 +
      NO_SYNC_CLKout8_11 + NO_SYNC_CLKout4_7 + NO_SYNC_CLKout0_3 + SYNC1_POL_INV + SYNC0_POL_INV +
      "0" + SYNC1_QUAL + CLKout12_13_HS + CLKout12_13_ADLY + "0011")
lmk_output(R3)

# R4
CLKout12_13_DDLY = "0000000000"
R4 = "000000000000000000" + CLKout12_13_DDLY + "0100"
lmk_output(R4)

# R5
CLKout12_13_DIV = "00000000001"
CLKout13_ADLY_SEL = "0"
CLKout12_ADLY_SEL = "0"
CLKout8_11_DIV = "001"  # 1
CLKout4_7_DIV = "001"  # 1
CLKout0_3_DIV = "010"  # 2
R5 = ("0000" + CLKout12_13_DIV + "00" + CLKout13_ADLY_SEL + CLKout12_ADLY_SEL + CLKout8_11_DIV +
      CLKout4_7_DIV + CLKout0_3_DIV + "0101")
lmk_output(R5)

# R15
uWireLock = "0"
R15 = "000000000000000000000101111" + uWireLock + "1111"
lmk_output(R15)


# AD9653
def adc_output(c, a, v):
    vv = frombin(v)
    print(("0 %3.3x" % (c + 0x100)))
    print(("0 %3.3x" % ((
        (a + 0) >> 8) & 0xff)))  # w=0 for transfer length 1 octet
    print(("0 %3.3x" % (a & 0xff)))
    print(("0 %3.3x" % vv))
    print("0 100")


def adc_read(c, a):
    print(("0 %3.3x" % (c + 0x100)))
    print(("0 %3.3x" % ((
        (a + 32768) >> 8) & 0xff)))  # w=0 for transfer length 1 octet
    print(("0 %3.3x" % (a & 0xff)))
    print(("0 %3.3x" % (c + 0x190)))  # turn read bit on and P2_ADC_SDIO_DIR off
    print("0 000")  # pad data to shift out
    print("0 100")


for chip in (2, 3):
    adc_output(chip, 0, "00011000")  # MSB first, SDO inactive
    adc_read(chip, 1)
    adc_read(chip, 2)


def ad7794_status():
    print("0 107")
    print("0 048")
    print("0 187")
    print("0 055")  # padding, supposed to come back 00
    print("0 055")  # padding, supposed to come back 0a
    print("0 100")


ad7794_status()
