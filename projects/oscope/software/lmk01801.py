# LMK01801 register names taken directly from datasheet
class c_lmk01801:
    def R0(
            self,
            CLKin1_MUX="00",  # divide
            CLKin1_DIV="010",  # 8
            CLKin0_MUX="00",  # divide
            CLKin0_DIV="010",  # 7
            CLKin1_BUF_TYPE="0",  # bipolar
            CLKin0_BUF_TYPE="0",  # bipolar
            CLKout12_13_PD="0",
            CLKout8_11_PD="0",
            CLKout4_7_PD="0",
            CLKout0_3_PD="0",
            POWERDOWN="0",
            RESET="0"):
        return eval('0b' + "01001000" + CLKin1_MUX + CLKin1_DIV + CLKin0_MUX
                    + CLKin0_DIV + "11" + CLKin1_BUF_TYPE + CLKin0_BUF_TYPE
                    + CLKout12_13_PD + CLKout8_11_PD + CLKout4_7_PD
                    + CLKout0_3_PD + POWERDOWN + RESET)

    def R1(
            self,
            CLKout7_TYPE="0001",  # Powerdown
            CLKout6_TYPE="0001",  # LVDS
            CLKout5_TYPE="0001",  # LVPECL
            CLKout4_TYPE="0001",  # Powerdown
            CLKout3_TYPE="001",  # LVDS
            CLKout2_TYPE="001",  # CMOS  J13 test point
            CLKout1_TYPE="001",  # LVDS  ADC2
            CLKout0_TYPE="001"  # LVDS  ADC1
    ):
        return eval('0b' + CLKout7_TYPE + CLKout6_TYPE + CLKout5_TYPE +
                    CLKout4_TYPE + CLKout3_TYPE + CLKout2_TYPE + CLKout1_TYPE +
                    CLKout0_TYPE)

    def R2(
            self,
            CLKout13_TYPE="0001",  # Powerdown
            CLKout12_TYPE="0001",  # Powerdown
            CLKout11_TYPE="0001",  # CMOS J24 test point
            CLKout10_TYPE="0001",  # LVDS J20
            CLKout9_TYPE="0001",  # Powerdown
            CLKout8_TYPE="0001"):  # Powerdown
        return eval('0b' + "0000" + CLKout13_TYPE + CLKout12_TYPE +
                    CLKout11_TYPE + CLKout10_TYPE + CLKout9_TYPE +
                    CLKout8_TYPE)

    def R3(self,
           SYNC1_AUTO="1",
           SYNC0_AUTO="1",
           SYNC1_FAST="0",
           SYNC0_FAST="0",
           NO_SYNC_CLKout12_13="0",
           NO_SYNC_CLKout8_11="0",
           NO_SYNC_CLKout4_7="0",
           NO_SYNC_CLKout0_3="0",
           SYNC1_POL_INV="1",
           SYNC0_POL_INV="1",
           SYNC1_QUAL="00",
           CLKout12_13_HS="0",
           CLKout12_13_ADLY="000000"):
        return eval('0b' + "00010" + SYNC1_AUTO + SYNC0_AUTO + SYNC1_FAST +
                    SYNC0_FAST + "011" + NO_SYNC_CLKout12_13 +
                    NO_SYNC_CLKout8_11 + NO_SYNC_CLKout4_7 + NO_SYNC_CLKout0_3
                    + SYNC1_POL_INV + SYNC0_POL_INV + "0" + SYNC1_QUAL +
                    CLKout12_13_HS + CLKout12_13_ADLY)

    def R4(self, CLKout12_13_DDLY="0000000101"):
        return eval('0b' + "000000000000000000" + CLKout12_13_DDLY)

    def R5(
            self,
            CLKout12_13_DIV="00000000001",
            CLKout13_ADLY_SEL="0",
            CLKout12_ADLY_SEL="0",
            CLKout8_11_DIV="001",  # 1
            CLKout4_7_DIV="001",  # 1
            CLKout0_3_DIV="001"  # 2
    ):
        return eval('0b' + "0000" + CLKout12_13_DIV + "00" + CLKout13_ADLY_SEL
                    + CLKout12_ADLY_SEL + CLKout8_11_DIV + CLKout4_7_DIV +
                    CLKout0_3_DIV)

    def R15(self, uWireLock="0"):
        return eval('0b' + "000000000000000000000101111" + uWireLock)

    def d28a4(self, data, addr):
        if data != data & 0xfffffff:
            print('data should be 28 bits', hex(data))
        if addr != addr & 0xf:
            print('addr should be 4 bits', hex(addr))
        return ((data & 0xfffffff) << 4) | (addr & 0xf)

    def reset_list(self):
        return [
            self.d28a4(self.R0(), 0), self.d28a4(
                self.R0(RESET='0'),
                0), self.d28a4(self.R1(), 1), self.d28a4(self.R2(), 2),
            self.d28a4(self.R3(), 3), self.d28a4(self.R4(), 4),
            self.d28a4(self.R5(), 5), self.d28a4(self.R15(), 15)
        ]


if __name__ == "__main__":
    c1 = c_lmk01801()
    dlist = c1.reset_list()
    print([hex(d) for d in dlist])
    # wlist = [0x101, d>>24, d>>16, d>>8, d, 0x100, for d in dlist]
    dawlist = [(5, dlist[i], 1) for i in range(len(dlist))]
    print(dawlist)
