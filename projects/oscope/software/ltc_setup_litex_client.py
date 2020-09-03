#!/usr/bin/env python3

import time

import numpy as np

from litex import RemoteClient


class LTC_SPI:
    # config bits
    OFFLINE = 0  # all pins high-z (reset=1)
    CS_POLARITY = 3  # active level of chip select (reset=0)
    CLK_POLARITY = 4  # idle level of clk (reset=0)
    CLK_PHASE = 5  # first edge after cs assertion to sample data on (reset=0)
    LSB_FIRST = 6  # LSB is the first bit on the wire (reset=0)
    HALF_DUPLEX = 7  # 3-wire SPI, in/out on mosi (reset=0)
    DIV_READ = 16  # SPI read clk divider (reset=0)
    DIV_WRITE = 24  # f_clk / f_spi_write == div_write + 2
    # xfer bits
    CS_MASK = 0  # Active high bit mask of chip selects to assert (reset=0)
    WRITE_LENGTH = 16  # How many bits to write and ...
    READ_LENGTH = 24  # when to switch over in half duplex mode

    def __init__(self, r):
        self.r = r

    def sleep_and_get_data(self):
        while self.r.regs.spi_status.read() != 1:
            print('.')
            time.sleep(0.1)
        return self.r.regs.spi_miso.read() & 0xFF

    def set_reg(self, adr, val):
        word = (0 << 15) | ((adr & 0x7F) << 8) | (val & 0xFF)
        self.r.regs.spi_mosi.write(word)
        self.r.regs.spi_control.write((16 << 8) | 1)

    def get_reg(self, adr):
        word = (1 << 15) | ((adr & 0x7F) << 8)
        self.r.regs.spi_mosi.write(word)
        self.r.regs.spi_control.write((16 << 8) | 1)
        return self.sleep_and_get_data()

    def setTp(self, tpValue):
        # Test pattern on + value MSB
        self.set_reg(3, (1 << 7) | tpValue >> 8)
        # Test pattern value LSB
        self.set_reg(4, tpValue & 0xFF)


def setIdelay(r, target_val):
    '''
    increments / decrements IDELAY to reach target_val
    '''
    val = r.regs.lvds_idelay_value.read()
    val -= target_val
    if val > 0:
        for i in range(val):
            r.regs.lvds_idelay_dec.write(1)
    else:
        for i in range(-val):
            r.regs.lvds_idelay_inc.write(1)


def autoIdelay(r, VAL=1):
    '''
    testpattern must be 0x01
    bitslips must have been carried out already such that
    data_peek reads 0x01
    '''
    # approximately center the idelay first
    setIdelay(r, 16)

    # decrement until the channels break
    for i in range(32):
        val0 = r.regs.lvds_data_peek0.read()
        val1 = r.regs.lvds_data_peek2.read()
        if val0 != VAL or val1 != VAL:
            break
        r.regs.lvds_idelay_dec.write(1)
    minValue = r.regs.lvds_idelay_value.read()

    # step back up a little
    for i in range(5):
        r.regs.lvds_idelay_inc.write(1)

    # increment until the channels break
    for i in range(32):
        val0 = r.regs.lvds_data_peek0.read()
        val1 = r.regs.lvds_data_peek2.read()
        if val0 != VAL or val1 != VAL:
            break
        r.regs.lvds_idelay_inc.write(1)
    maxValue = r.regs.lvds_idelay_value.read()

    # set idelay to the sweet spot in the middle
    setIdelay(r, (minValue + maxValue) // 2)

    print('autoIdelay(): min = {:}, mean = {:}, max = {:} idelays'.format(
        minValue,
        r.regs.lvds_idelay_value.read(),
        maxValue
    ))


def autoBitslip(r):
    '''
    resets IDELAY to the middle,
    fires bitslips until the frame signal reads 0xF0
    '''
    setIdelay(r, 16)
    for i in range(8):
        val = r.regs.lvds_frame_peek.read()
        print(bin(val))
        if val == 0xF0:
            print("autoBitslip(): aligned after", i)
            return
        r.regs.lvds_bitslip_csr.write(1)
    raise RuntimeError("autoBitslip(): failed alignment :(")


def initLTC(r, check_align=False):
    print("Resetting LTC")
    ltc_spi = LTC_SPI(r)
    ltc_spi.set_reg(0, 0x80)   # reset the chip
    r.regs.ctrl_reset.write(1)
    VAL = 0x1234
    ltc_spi.setTp(VAL)
    print(1, ltc_spi.get_reg(1))
    print(2, ltc_spi.get_reg(2))
    print(3, ltc_spi.get_reg(3))
    print(4, ltc_spi.get_reg(4))
    freqs = []
    v = None
    for i in range(5):
        x = r.regs.lvds_f_sample_value.read()
        if v is not None:
            print(x - v)
        v = x
        freqs.append(v)
        time.sleep(1)
    print(freqs)
    autoBitslip(r)
    autoIdelay(r, VAL)

    if check_align:
        print("ADC word bits:")
        for i in range(14):
            tp = 1 << i
            ltc_spi.setTp(tp)
            tp_read = r.regs.lvds_data_peek0.read()
            print("{:014b} {:014b}".format(tp, tp_read))
            if tp != tp_read:
                raise RuntimeError("LVDS alignment error")

    ltc_spi.set_reg(3, 0)  # Test pattern off
    ltc_spi.set_reg(1, (1 << 5))  # Randomizer off, twos complement output


from matplotlib import pyplot as plt
import socket

def get_data(wb, plot=False):
    wb.regs.acq_acq_start.write(1)
    time.sleep(0.1)
    try:
        while wb.regs.acq_buf_full.read() == 0:
            time.sleep(0.1)
    except socket.timeout:
        print('to1')
        return None
    data = []
    try:
        for i in range(8192//128):
            d = wb.read(wb.mems.adc_data_buffer.base + i * 128, 128)
            if len(d) != 128:
                print(len(d), d)
                return None
            data += d
    except socket.timeout:
        print('to2')
        return None
    print(len(data))
    c1, c2 = [], []
    for x in data:
        c1.append(np.int16(x & 0xffff) // 4)
        c2.append(np.int16((x & 0xffff0000) >> 16) // 4)
    if plot:
        print([hex(x) for x in data[:40]])
        print([hex(x) for x in c1[:20]])
        print([hex(x) for x in c2[:20]])
        plt.plot(c1)
        plt.plot(c2)
        plt.show()
    return np.vstack((c1, c2))


if __name__ == "__main__":
    wb = RemoteClient()
    wb.open()
    print(wb.regs.acq_buf_full.read())
    initLTC(wb)
    # print([hex(x) for x in wb.read(wb.mems.adc_data_buffer.base, 100)])
    # ltc_spi = LTC_SPI(wb)
    # ltc_spi.setTp(0x1234)
    wb.regs.acq_acq_start.write(1)
    get_data(wb, plot=True)
    wb.close()
