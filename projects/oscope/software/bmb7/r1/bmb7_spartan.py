#!/bin/env python

from socket import socket, AF_INET, SOCK_DGRAM
import time
from datetime import datetime
from bmb7.r1.bmb7_show_readout import print_monitor_bytes
ERROR = 'NOT BMB7 1.0'


class SI570:
    HSDIV_2_0_N1_6_2 = 7
    N1_1_0_RFREQ_37_32 = 8
    RFREQ_31_24 = 9
    RFREQ_23_16 = 10
    RFREQ_15_8 = 11
    RFREQ_7_0 = 12
    SETTINGS = 135
    FREEZE_DCO = 137


class PCA9534:
    INPUT = 0
    OUTPUT = 1
    POLARITY = 2
    DIRECTION = 3


class LTC2990:
    STATUS = 0
    CONTROL = 1
    TRIGGER = 2
    T_MSB = 4
    T_LSB = 5
    V1_MSB = 6
    V1_LSB = 7
    V2_MSB = 8
    V2_LSB = 9
    V3_MSB = 10
    V3_LSB = 11
    V4_MSB = 12
    V4_LSB = 13
    VCC_MSB = 14
    VCC_LSB = 15


def conv_n(x, n):
    if x > (2**(n - 1) - 1):
        x = x - 2**n
    return x


class interface():
    def __init__(self, target, fname=''):

        self.host = target
        self.port = 50001
        self.uart_1_port = 50003
        self.uart_2_port = 50004
        self.WRITE_LENGTH = 63
        self.READ_LENGTH = 187

        # Embedded firmware match tag
        self.HASH = '82b054d3cb7c761e7f99dd25844c1ce3fbf5dcb5d2bcab726a6a86b06668d08a'
        self.BUILD_DATE = 1460677350

        # Interface socket
        self.UDPSock = socket(AF_INET, SOCK_DGRAM)
        self.UDPSock.bind(("0.0.0.0", 0))
        self.UDPSock.settimeout(2)

        # Check the firmware ID
        self.check_firmware_id()

    def check_firmware_id(self):
        print('BMB7 Spartan-6 firmware information:')
        d = self.get_bytes()[139:187]
        if d == "":
            print('No Spartan firmware info found')
            self.wrong_board = True
            raise ValueError(ERROR)
            return
        self.wrong_board = False
        d.reverse()

        s = str()
        for i in d[0:32]:
            s += '{:02x}'.format(i)
        print('SHA256 bitfile hash: ' + s)

        build_date = 0
        for i in range(0, 8):
            build_date += int(d[40 + i]) * 2**(56 - i * 8)
        print('Build timestamp: ' + str(build_date) + ' (' + str(
            datetime.utcfromtimestamp(build_date)) + ')')

        storage_date = 0
        for i in range(0, 8):
            storage_date += int(d[32 + i]) * 2**(56 - i * 8)
        print('Storage timestamp: ' + str(storage_date) + ' (' + str(
            datetime.utcfromtimestamp(storage_date)) + ')')

        if False and build_date != self.BUILD_DATE:
            raise Exception(
                '\n\nFirmware build date (' + str(build_date) +
                ') does not match the software build date requirement (' + str(
                    self.BUILD_DATE) +
                '), please update the BMB7 Spartan-6 firmware image.\n')

        if s != self.HASH:
            print("\nInvalid Spartan-6 firmware for BMB7 r1.0")
            error = 'Found on hardware:  ' + s[:32] + '\n'
            error += 'Needed by software: ' + self.HASH[:32] + '\n'
            error += 'ERROR: Please check firmware/software compatibility!\n'
            raise Exception(error)

    def set_byte(self, index, data, mask):
        d = bytearray(self.WRITE_LENGTH)
        m = bytearray(self.WRITE_LENGTH)
        d[index] = data
        m[index] = mask
        self.send_receive(d, m)

    def get_byte(self, index):
        d = bytearray(self.WRITE_LENGTH)
        m = bytearray(self.WRITE_LENGTH)
        res = self.send_receive(d, m)
        return res[index]

    def get_bytes(self):
        d = bytearray(self.WRITE_LENGTH)
        m = bytearray(self.WRITE_LENGTH)
        return self.send_receive(d, m)

    def send_receive(self, data, mask):
        data.reverse()
        mask.reverse()
        rbytes = bytearray()
        rbytes[:] = (mask + data)

        read_bytes = str()

        while True:
            try:
                self.UDPSock.sendto(bytearray(rbytes), (self.host, self.port))
                read_bytes = self.UDPSock.recv(self.READ_LENGTH)
                if not read_bytes:
                    print("No data received")
                break
            except KeyboardInterrupt:
                print('Ctrl-C detected')
                exit(0)
            except:
                continue

        res = bytearray(read_bytes)
        res.reverse()
        return res

    def i2c_chain_reset(self):
        self.set_byte(0, 0x3, 0x7)
        self.set_byte(0, 0x7, 0x7)

    def i2c_chain_set(self, value):
        self.i2c_chain_reset()

        address = 0xE0
        address = int('{:08b}'.format(address)[::-1], 2)
        value = int('{:08b}'.format(value)[::-1], 2)

        self.i2c_start()

        self.i2c_write(address)
        self.i2c_check_ack()
        self.i2c_write(value)
        self.i2c_check_ack()

        self.i2c_stop()

    def i2c_chain_get(self):
        address = 0xE1
        address = int('{:08b}'.format(address)[::-1], 2)

        self.i2c_start()

        self.i2c_write(address)
        self.i2c_check_ack()

        result = self.i2c_read()
        self.i2c_clk(1)

        self.i2c_stop()

        return result

    # def disable_kintex_data(self):
    #   self.write_bytes[5] = self.write_bytes[5] & 0xF3
    #   self.send_receive()

    # def enable_kintex_data(self):
    #   self.write_bytes[5] = self.write_bytes[5] | 0xC
    #   self.send_receive()

    def enable_uart_1(self):
        self.set_byte(5, 0x10, 0x10)
        # self.write_bytes[5] = self.write_bytes[5] | 0x10
        # self.send_receive()

    def disable_uart_1(self):
        self.set_byte(5, 0, 0x10)
        # self.write_bytes[5] = self.write_bytes[5] & 0x2F
        # self.send_receive()

    def enable_uart_2(self):
        self.set_byte(5, 0x20, 0x20)
        # self.write_bytes[5] = self.write_bytes[5] | 0x20
        # self.send_receive()

    def disable_uart_2(self):
        self.set_byte(5, 0x0, 0x20)
        # self.write_bytes[5] = self.write_bytes[5] & 0x1F
        # self.send_receive()

    def pca9534_direction_set(self, address, direction):
        address = ((0x20 | address) << 1)
        address = int('{:08b}'.format(address)[::-1], 2)
        command = int('{:08b}'.format(PCA9534.DIRECTION)[::-1], 2)
        direction = int('{:08b}'.format(direction)[::-1], 2)

        # Set direction bits
        self.i2c_start()
        self.i2c_write(address)
        self.i2c_check_ack()
        self.i2c_write(command)
        self.i2c_check_ack()
        self.i2c_write(direction)
        self.i2c_check_ack()
        self.i2c_stop()

    def print_status(self):
        # print 'SPI flash reader:',
        # if self.read_bytes[16] == 2:
        #        print 'ERROR'
        # elif self.read_bytes[16] == 1:
        #        print 'DONE'
        # else:
        #        print 'ACTIVE'

        # print 'SPI flash data out:', hex(self.read_bytes[17])

        while True:
            v = self.get_byte(3)
            print('System I2C controller:')
            if v == 2:
                print('ERROR')
                break
            elif v == 1:
                print('IDLE')
                break
            else:
                print('ACTIVE')
            time.sleep(1)

        print('Main +3.3V status:', self.get_main_3p3v_status())
        print('Main +1.8V status:', self.get_main_1p8v_status())
        print('Kintex +1.0V VCCINT status:', self.get_kintex_vccint_status())
        print('Kintex +1.0V GTX status:', self.get_kintex_1p0v_gtx_status())

        print('Boot +3.3V status:', self.get_boot_3p3v_status())
        print('Spartan +1.2V VCCINT status:', self.get_spartan_vccint_status())

        print('Standby +1.2V status:', self.get_standby_1p2v_status())

        print('Top FMC present:', not (self.get_n_top_fmc_present()))
        print('Top FMC +12V status:',
              int(not (self.get_n_top_fmc_12v_status())))
        print('Top FMC +3.3V / VADJ status:',
              self.get_top_fmc_vadj_3p3v_status())
        print('Bottom FMC present:', not (self.get_n_bottom_fmc_present()))
        print('Bottom FMC +12V status:',
              int(not (self.get_n_bottom_fmc_12v_status())))
        print('Bottom FMC +3.3V / VADJ status:',
              self.get_bottom_fmc_vadj_3p3v_status())

        print('S6 QSFP present:', not (self.get_n_s6_qsfp_present()))

    def get_main_3p3v_status(self):
        return self.get_port_expander_bit(0x1, 0, 7)

    def get_top_fmc_vadj_3p3v_status(self):
        return self.get_port_expander_bit(0x1, 0, 4)

    def get_bottom_fmc_vadj_3p3v_status(self):
        return self.get_port_expander_bit(0x1, 1, 6)

    def get_main_1p8v_status(self):
        return self.get_port_expander_bit(0x4, 1, 0)

    def get_kintex_1p0v_gtx_status(self):
        return self.get_port_expander_bit(0x4, 1, 2)

    def get_kintex_vccint_status(self):
        return self.get_port_expander_bit(0x4, 1, 4)

    def get_n_s6_qsfp_present(self):
        return self.get_port_expander_bit(0x4, 0, 1)

    def get_standby_1p2v_status(self):
        return self.get_port_expander_bit(0x4, 0, 5)

    def get_n_bottom_fmc_present(self):
        return self.get_port_expander_bit(0x2, 0, 1)

    def get_boot_3p3v_status(self):
        return self.get_port_expander_bit(0x2, 0, 5)

    def get_spartan_vccint_status(self):
        return self.get_port_expander_bit(0x2, 0, 7)

    def get_n_top_fmc_present(self):
        return self.get_port_expander_bit(0x1, 1, 1)

    def get_n_top_fmc_12v_status(self):
        return self.get_port_expander_bit(0x1, 0, 2)

    def get_n_bottom_fmc_12v_status(self):
        return self.get_port_expander_bit(0x1, 1, 4)

    def standby_1p2v_enable(self):
        self.power_supply_enable(0x4, 0, 4)

    def standby_1p2v_disable(self):
        self.power_supply_disable(0x4, 0, 4)

    def boot_3p3v_enable(self):
        self.power_supply_enable(0x2, 0, 4)

    def boot_3p3v_disable(self):
        self.power_supply_disable(0x2, 0, 4)

    def main_3p3v_enable(self):
        self.power_supply_enable(0x1, 0, 6)

    def main_3p3v_disable(self):
        self.power_supply_disable(0x1, 0, 6)

    def fmc_top_3p3v_enable(self):
        self.power_supply_enable(0x1, 0, 3)

    def fmc_top_3p3v_disable(self):
        self.power_supply_disable(0x1, 0, 3)

    def fmc_top_vadj_enable(self):
        self.power_supply_enable(0x1, 0, 5)

    def fmc_top_vadj_disable(self):
        self.power_supply_disable(0x1, 0, 5)

    def fmc_bot_3p3v_enable(self):
        self.power_supply_enable(0x1, 1, 5)

    def fmc_bot_3p3v_disable(self):
        self.power_supply_disable(0x1, 1, 5)

    def fmc_bot_vadj_enable(self):
        self.power_supply_enable(0x1, 1, 7)

    def fmc_bot_vadj_disable(self):
        self.power_supply_disable(0x1, 1, 7)

    def main_1p8v_enable(self):
        self.power_supply_enable(0x4, 1, 1)

    def main_1p8v_disable(self):
        self.power_supply_disable(0x4, 1, 1)

    def fmc_top_12v_enable(self):
        self.power_supply_enable(1, 0, 1, True)

    def fmc_top_12v_disable(self):
        self.power_supply_disable(1, 0, 1)

    def fmc_bot_12v_enable(self):
        self.power_supply_enable(1, 1, 3, True)

    def fmc_bot_12v_disable(self):
        self.power_supply_disable(1, 1, 3)

    def kintex_vccint_enable(self):
        self.power_supply_enable(0x4, 1, 5)

    def kintex_vccint_disable(self):
        self.power_supply_disable(0x4, 1, 5)

    def kintex_1p0v_gtx_enable(self):
        self.power_supply_enable(0x4, 1, 3)

    def kintex_1p0v_gtx_disable(self):
        self.power_supply_disable(0x4, 1, 3)

    def kintex_1p2v_gtx_enable(self):
        self.power_supply_enable(0x4, 0, 6)

    def kintex_1p2v_gtx_disable(self):
        self.power_supply_disable(0x4, 0, 6)

    def kintex_1p8v_gtx_enable(self):
        self.power_supply_enable(0x4, 1, 6)

    def kintex_1p8v_gtx_disable(self):
        self.power_supply_disable(0x4, 1, 6)

    def spartan_vccint_enable(self):
        self.power_supply_enable(0x2, 0, 6)

    def spartan_vccint_disable(self):
        self.power_supply_disable(0x2, 0, 6)

    def spartan_1p2v_gtx_enable(self):
        self.power_supply_enable(0x4, 0, 7)

    def spartan_1p2v_gtx_disable(self):
        self.power_supply_disable(0x4, 0, 7)

    def get_port_expander_bit(self, chain, address, bit):
        self.i2c_chain_set(chain)
        # print chain, address, bit, hex(self.pca9534_read(address))
        return ((self.pca9534_read(address) >> bit) & 0x1)

    def power_supply_enable(self, chain, address, bit, inverted=False):
        i = 1 << bit

        self.i2c_chain_set(chain)

        # Mask out to get the correct setting
        if inverted:
            self.pca9534_write(address, (self.pca9534_read(address) & ~i))
        else:
            self.pca9534_write(address, (self.pca9534_read(address) & ~i) | i)

        self.pca9534_direction_set(address,
                                   (self.pca9534_direction_get(address) & ~i))

    def power_supply_disable(self, chain, address, bit):
        i = 1 << bit

        self.i2c_chain_set(chain)

        # Mask out to get the correct setting
        self.pca9534_direction_set(address, (
            self.pca9534_direction_get(address) & ~i) | i)

    def pca9534_direction_get(self, address):
        address_r = ((0x20 | address) << 1) | 1
        addr = ((0x20 | address) << 1)
        address_r = int('{:08b}'.format(address_r)[::-1], 2)
        addr = int('{:08b}'.format(addr)[::-1], 2)
        command = int('{:08b}'.format(PCA9534.DIRECTION)[::-1], 2)

        # Set direction bits
        self.i2c_start()

        self.i2c_write(addr)
        self.i2c_check_ack()
        self.i2c_write(command)
        self.i2c_check_ack()

        self.i2c_repeated_start()

        self.i2c_write(address_r)
        self.i2c_check_ack()
        result = self.i2c_read()
        self.i2c_clk(1)

        self.i2c_stop()

        return result

    def set_top_fmc_vadj_resistor(self, value):
        self.max5387_write(0, 1, value)

    def set_top_fmc_3p3v_resistor(self, value):
        self.max5387_write(0, 2, value)

    def set_bottom_fmc_vadj_resistor(self, value):
        self.max5387_write(1, 1, value)

    def set_bottom_fmc_3p3v_resistor(self, value):
        self.max5387_write(1, 2, value)

    def atsha204_wake(self):
        addr = int('{:08b}'.format(0xC9)[::-1], 2)

        self.i2c_chain_set(0x8)
        self.i2c_start()
        time.sleep(0.001)  # Wake
        self.i2c_stop()
        self.i2c_start()
        self.i2c_write(addr)
        self.i2c_check_ack()
        result = self.i2c_read()
        self.i2c_clk(1)
        self.i2c_stop()
        print(hex(result))

    def max5387_write(self, address, resistor, value):
        # Digital potentiometers are on the first chain
        self.i2c_chain_set(0x1)

        addr = ((0x28 | address) << 1)
        addr = int('{:08b}'.format(addr)[::-1], 2)
        resistor = (0x10 | resistor)
        resistor = int('{:08b}'.format(resistor)[::-1], 2)
        value = int('{:08b}'.format(value)[::-1], 2)

        # Set value bits
        self.i2c_start()
        self.i2c_write(addr)
        self.i2c_check_ack()
        self.i2c_write(resistor)
        self.i2c_check_ack()
        self.i2c_write(value)
        self.i2c_check_ack()
        self.i2c_stop()

    def pca9534_write(self, address, value):
        addr = ((0x20 | address) << 1)
        addr = int('{:08b}'.format(addr)[::-1], 2)
        value = int('{:08b}'.format(value)[::-1], 2)
        command = int('{:08b}'.format(PCA9534.OUTPUT)[::-1], 2)

        # Set value bits
        self.i2c_start()
        self.i2c_write(addr)
        self.i2c_check_ack()
        self.i2c_write(command)
        self.i2c_check_ack()
        self.i2c_write(value)
        self.i2c_check_ack()
        self.i2c_stop()

    def pca9534_read(self, address):
        address_r = ((0x20 | address) << 1) | 1
        addr = ((0x20 | address) << 1)
        address_r = int('{:08b}'.format(address_r)[::-1], 2)
        addr = int('{:08b}'.format(addr)[::-1], 2)
        command = int('{:08b}'.format(PCA9534.INPUT)[::-1], 2)

        self.i2c_start()

        self.i2c_write(addr)
        self.i2c_check_ack()
        self.i2c_write(command)
        self.i2c_check_ack()

        self.i2c_repeated_start()

        self.i2c_write(address_r)
        self.i2c_check_ack()
        result = self.i2c_read()
        self.i2c_clk(1)

        self.i2c_stop()

        return result

    def write_m24c02_prom(self, prom_address, word_address, value):
        addr = (prom_address << 1)
        addr = int('{:08b}'.format(addr)[::-1], 2)
        w = int('{:08b}'.format((word_address) & 0xFF)[::-1], 2)
        val = int('{:08b}'.format(value)[::-1], 2)

        self.fmc_i2c_start()

        self.fmc_i2c_write(addr)
        self.fmc_i2c_check_ack()
        self.fmc_i2c_write(w)
        self.fmc_i2c_check_ack()
        self.fmc_i2c_write(val)
        self.fmc_i2c_check_ack()

        self.fmc_i2c_stop()

        time.sleep(0.005)

    def read_m24c02_prom(self, prom_address, word_address):
        address_r = (prom_address << 1) | 1
        addr = (prom_address << 1)
        address_r = int('{:08b}'.format(address_r)[::-1], 2)
        addr = int('{:08b}'.format(addr)[::-1], 2)
        w = int('{:08b}'.format((word_address) & 0xFF)[::-1], 2)

        self.fmc_i2c_start()

        self.fmc_i2c_write(addr)
        self.fmc_i2c_check_ack()
        self.fmc_i2c_write(w)
        self.fmc_i2c_check_ack()

        self.fmc_i2c_repeated_start()

        self.fmc_i2c_write(address_r)
        self.fmc_i2c_check_ack()
        result = self.fmc_i2c_read()
        self.fmc_i2c_clk(1)

        self.fmc_i2c_stop()

        return result

    def write_at24c32d_prom(self,
                            prom_address,
                            word_address,
                            value,
                            bottom_site=False):
        addr = (prom_address << 1)
        addr = int('{:08b}'.format(addr)[::-1], 2)
        wh = int('{:08b}'.format((word_address >> 8) & 0xFF)[::-1], 2)
        wl = int('{:08b}'.format((word_address) & 0xFF)[::-1], 2)
        val = int('{:08b}'.format(value)[::-1], 2)

        if bottom_site is True:
            self.i2c_chain_set(1)
        else:
            self.i2c_chain_set(4)

        self.fmc_i2c_start()

        self.fmc_i2c_write(addr)
        self.fmc_i2c_check_ack()
        self.fmc_i2c_write(wh)
        self.fmc_i2c_check_ack()
        self.fmc_i2c_write(wl)
        self.fmc_i2c_check_ack()
        self.fmc_i2c_write(val)
        self.fmc_i2c_check_ack()

        self.fmc_i2c_stop()

        time.sleep(0.005)

    def read_at24c32d_prom(self,
                           word_address,
                           bottom_site=False,
                           prom_address=0x50):
        address_r = (prom_address << 1) | 1
        addr = (prom_address << 1)
        address_r = int('{:08b}'.format(address_r)[::-1], 2)
        addr = int('{:08b}'.format(addr)[::-1], 2)
        wh = int('{:08b}'.format((word_address >> 8) & 0xFF)[::-1], 2)
        wl = int('{:08b}'.format((word_address) & 0xFF)[::-1], 2)

        if bottom_site is True:
            self.i2c_chain_set(1)
        else:
            self.i2c_chain_set(4)

        self.fmc_i2c_start()

        self.fmc_i2c_write(addr)
        self.fmc_i2c_check_ack()
        self.fmc_i2c_write(wh)
        self.fmc_i2c_check_ack()
        self.fmc_i2c_write(wl)
        self.fmc_i2c_check_ack()

        self.fmc_i2c_repeated_start()

        self.fmc_i2c_write(address_r)
        self.fmc_i2c_check_ack()
        result = self.fmc_i2c_read()
        self.fmc_i2c_clk(1)

        self.fmc_i2c_stop()

        return result

    # def gtp_init(self):
    #        self.write_bytes[1] = 0xE
    #        self.send_receive()
    #        self.write_bytes[1] = 0xC
    #        self.send_receive()

    #        time.sleep(1)

    #        self.write_bytes[1] = 0x8
    #        self.send_receive()
    #        self.write_bytes[1] = 0
    #        self.send_receive()

    # def gtp_status(self):
    #        self.send_receive()
    #        print 'PLLs LOCKED:', hex(self.read_bytes[6] >> 4)
    #        print 'RESET DONE:', hex(self.read_bytes[6] & 0xF)
    #        print 'RX DATA CHECKER TRACKING:', hex(self.read_bytes[7] >> 4)
    #        print 'RX BYTE IS ALIGNED:', hex(self.read_bytes[7] & 0xF)
    #        print 'RX DATA ERROR COUNTS:', hex(self.read_bytes[140]), hex(self.read_bytes[139])

    #        self.write_bytes[63] = 1
    #        self.send_receive()
    #        time.sleep(0.1)
    #        self.write_bytes[63] = 0
    #        self.send_receive()

    #        print

    #        for i in range(0, 16):
    #                self.write_bytes[64] = i
    #                self.send_receive()
    #                self.send_receive()
    # print str(i) + ':', hex(self.read_bytes[145]),
    # hex(self.read_bytes[144]), hex(self.read_bytes[143]),
    # hex(self.read_bytes[142]), hex(self.read_bytes[141])

    def fmc_i2c_clk(self, bit):

        # Isolate reset bits with clock low and set data bit
        self.set_byte(4, ((bit & 1) << 1), 0x02)
        # time.sleep(0.001)

        # Set clock high
        self.set_byte(4, 0x1, 0x1)
        # time.sleep(0.001)

        # Sample bit
        # time.sleep(0.001)
        result = int(self.get_byte(5) & 0x1)

        # Bring clock low
        self.set_byte(4, 0, 0x1)
        # time.sleep(0.001)

        # Bring data low
        self.set_byte(4, 0, 0x2)
        # time.sleep(0.001)

        return result

    def fmc_i2c_start(self):

        # Bring clock and data high
        self.set_byte(4, 0x3, 0x3)
        # time.sleep(0.001)

        # Bring data low
        self.set_byte(4, 0, 0x2)
        # time.sleep(0.001)

        # Bring clock low
        self.set_byte(4, 0, 0x1)
        # time.sleep(0.001)

    def fmc_i2c_repeated_start(self):

        # Bring data high
        self.set_byte(4, 0x2, 0x2)
        # time.sleep(0.001)

        # Bring clock and data high
        self.set_byte(4, 0x1, 0x1)
        # time.sleep(0.001)

        # Bring data low
        self.set_byte(4, 0, 0x2)
        # time.sleep(0.001)

        # Bring clock low
        self.set_byte(4, 0, 0x1)
        # time.sleep(0.001)

    def fmc_i2c_stop(self):

        # Bring clock high
        self.set_byte(4, 0x1, 0x1)
        # time.sleep(0.001)

        # Bring data high
        self.set_byte(4, 0x2, 0x2)
        # time.sleep(0.001)

    def fmc_i2c_write(self, value):

        for i in range(0, 8):
            self.fmc_i2c_clk(value & 0x1)
            value = value >> 1

    def fmc_i2c_read(self):

        result = int()
        for i in range(0, 8):
            bit = self.fmc_i2c_clk(1)
            result = (result << 1) | bit

        return result

    def fmc_i2c_check_ack(self, must_ack=True):

        if self.fmc_i2c_clk(1) == 1:
            if (must_ack):
                raise Exception('FMC I2C acknowledge failed')
            else:
                return False

        return True

    def i2c_clk(self, bit):

        # Isolate reset bits with clock low and set data bit
        self.set_byte(0, ((bit & 1) << 1), 0x3)
        # time.sleep(0.001)

        # Set clock high
        self.set_byte(0, 0x1, 0x1)
        # time.sleep(0.001)

        # Sample bit
        result = int(self.get_byte(0) & 0x1)

        # Bring clock low
        self.set_byte(0, 0, 0x1)
        # time.sleep(0.001)

        # Bring data low
        self.set_byte(0, 0, 0x2)
        # time.sleep(0.001)

        return result

    def i2c_start(self):

        # Bring clock and data high
        self.set_byte(0, 0x3, 0x3)
        # time.sleep(0.001)

        # Bring data low
        self.set_byte(0, 0, 0x2)
        # time.sleep(0.001)

        # Bring clock low
        self.set_byte(0, 0, 0x1)
        # time.sleep(0.001)

    def i2c_repeated_start(self):

        # Bring data high
        self.set_byte(0, 0x2, 0x2)
        # time.sleep(0.001)

        # Bring clock high
        self.set_byte(0, 0x1, 0x1)
        # time.sleep(0.001)

        # Bring data low
        self.set_byte(0, 0, 0x2)
        # time.sleep(0.001)

        # Bring clock low
        self.set_byte(0, 0, 0x1)
        # time.sleep(0.001)

    def i2c_stop(self):

        # Bring clock high
        self.set_byte(0, 0x1, 0x1)
        # time.sleep(0.001)

        # Bring data high
        self.set_byte(0, 0x2, 0x2)
        # time.sleep(0.001)

    def i2c_write(self, value):

        for i in range(0, 8):
            self.i2c_clk(value & 0x1)
            value = value >> 1

    def i2c_read(self):

        result = int()
        for i in range(0, 8):
            bit = self.i2c_clk(1)
            result = (result << 1) | bit

        return result

    def i2c_check_ack(self, must_ack=True):

        if self.i2c_clk(1) == 1:
            if (must_ack):
                raise Exception('I2C acknowledge failed')
            else:
                return False

        return True

    def ltc2990_i2c_write(self, address, command, data):
        address = 0x98 | ((address & 0x3) << 1)
        address = int('{:08b}'.format(address)[::-1], 2)
        command = int('{:08b}'.format(command)[::-1], 2)
        data = int('{:08b}'.format(data)[::-1], 2)

        self.i2c_start()

        self.i2c_write(address)
        self.i2c_check_ack()
        self.i2c_write(command)
        self.i2c_check_ack()
        self.i2c_write(data)
        self.i2c_check_ack()

        self.i2c_stop()

    def ltc2990_i2c_read(self, address, command):
        address = 0x98 | ((address & 0x3) << 1)
        address_r = int(address) | 1
        address = int('{:08b}'.format(address)[::-1], 2)
        address_r = int('{:08b}'.format(address_r)[::-1], 2)
        command = int('{:08b}'.format(command)[::-1], 2)

        self.i2c_start()

        self.i2c_write(address)
        self.i2c_check_ack()
        self.i2c_write(command)
        self.i2c_check_ack()

        self.i2c_repeated_start()

        self.i2c_write(address_r)
        self.i2c_check_ack()
        result = self.i2c_read()
        self.i2c_clk(1)

        self.i2c_stop()

        return result

    def si57X_get(self):
        print('INCOMPLETE')
        exit()
        # self.set_byte(10, 0x1, 0x1)

        # self.write_bytes[10] = 1
        # self.send_receive()
        # self.write_bytes[10] = 0
        # self.send_receive()
        # while True:
        #        self.send_receive()
        #        if self.read_bytes[8] == 1:
        #                break
        #        if self.read_bytes[8] == 2:
        #                raise Exception('SI57X I2C error')
        # return [int(self.read_bytes[15]) << 32 |
        #        int(self.read_bytes[14]) << 24 |
        #        int(self.read_bytes[13]) << 16 |
        #        int(self.read_bytes[12]) << 8 |
        #        int(self.read_bytes[11]),
        #        int(self.read_bytes[10]),
        #        int(self.read_bytes[9])
        #        ]

    def si57X_set(self, v):
        print('INCOMPLETE')
        exit()
        # self.write_bytes[10] = 5
        # self.send_receive()
        # self.write_bytes[11] = v[2]
        # self.write_bytes[12] = v[1]
        # self.write_bytes[13] = v[0] & 0xFF
        # self.write_bytes[14] = (v[0] >> 8) & 0xFF
        # self.write_bytes[15] = (v[0] >> 16) & 0xFF
        # self.write_bytes[16] = (v[0] >> 24) & 0xFF
        # self.write_bytes[17] = (v[0] >> 32) & 0xFF
        # self.write_bytes[10] = 4
        # self.send_receive()
        # while True:
        #        self.send_receive()
        #        if self.read_bytes[8] == 1:
        #                break
        #        if self.read_bytes[8] == 2:
        #                raise Exception('SI57X I2C error')
        # Verify the values
        # match = True
        # for i in range(0, 7):
        #        match &= (self.read_bytes[9+i] == self.write_bytes[11+i])
        # if match == False:
        #        raise Exception('SI57X frequency update failed')

    def si57X_enable(self):
        self.set_byte(10, 0, 0x2)

    def si57X_disable(self):
        self.set_byte(10, 0x2, 0x2)

    def trigger_monitor_v1v2v3v4(self, device):
        self.ltc2990_i2c_write(device, 1, 0xDF)
        self.ltc2990_i2c_write(device, LTC2990.TRIGGER, 0)

    def trigger_monitor_v1v2tr2(self, device):
        self.ltc2990_i2c_write(device, 1, 0xD8)
        self.ltc2990_i2c_write(device, LTC2990.TRIGGER, 0)

    def trigger_monitor_dv12dv34(self, device):
        self.ltc2990_i2c_write(device, 1, 0xDE)
        self.ltc2990_i2c_write(device, LTC2990.TRIGGER, 0)

    def get_monitor(self, device):

        while self.ltc2990_i2c_read(device, LTC2990.STATUS) & 0x1:
            continue

        # short_open1 = self.ltc2990_i2c_read(device, LTC2990.V1_MSB)
        # short_open1 = ((short_open1 & 0x40) >> 6) | ((short_open1 & 0x20) >> 5)
        # short_open2 = self.ltc2990_i2c_read(device, LTC2990.V3_MSB)
        # short_open2 = ((short_open2 & 0x40) >> 6) | ((short_open2 & 0x20) >> 5)

        return [
            (float((self.ltc2990_i2c_read(device, LTC2990.T_MSB) & 0x1F) * 256 +
                   self.ltc2990_i2c_read(device, LTC2990.T_LSB)) * 0.0625) - 273.2,
            2.5 + float((self.ltc2990_i2c_read(device, LTC2990.VCC_MSB) & 0x3F) * 256 +
                        self.ltc2990_i2c_read(device, LTC2990.VCC_LSB)) * 0.00030518,

            # V1V2V3V4 conversions
            float(conv_n((self.ltc2990_i2c_read(device, LTC2990.V1_MSB) & 0x7F) * 256 + \
                         self.ltc2990_i2c_read(device, LTC2990.V1_LSB), 15)) * 0.00030518,
            # float(conv_n((self.ltc2990_i2c_read(device, LTC2990.V2_MSB) & 0x7F) * 256 +
            #       self.ltc2990_i2c_read(device, LTC2990.V2_LSB), 15)) * 0.00030518,
            float(conv_n((self.ltc2990_i2c_read(device, LTC2990.V3_MSB) & 0x7F) * 256 + \
                         self.ltc2990_i2c_read(device, LTC2990.V3_LSB), 15)) * 0.00030518,
            # float(conv_n((self.ltc2990_i2c_read(device, LTC2990.V4_MSB) & 0x7F) * 256 +
            # self.ltc2990_i2c_read(device, LTC2990.V4_LSB), 15)) * 0.00030518,

            # TR2 conversions
            (float((self.ltc2990_i2c_read(device, LTC2990.V4_MSB) & 0x1F) * 256 + \
                   self.ltc2990_i2c_read(device, LTC2990.V4_LSB)) * 0.0625) - 273.2,
            0,  # short_open1,
            (float((self.ltc2990_i2c_read(device, LTC2990.V4_MSB) & 0x1F) * 256 +
                   self.ltc2990_i2c_read(device, LTC2990.V4_LSB)) * 0.0625) - 273.2,
            # * 1.004 * 2.3 / 2.0) - (273.2 / (1.004 * 3.0 * (2.3 / 2.0))),
            0,  # short_open2,
            # Current conversions
            float(conv_n((self.ltc2990_i2c_read(device, LTC2990.V2_MSB) & 0x7F) * 256 + \
                         self.ltc2990_i2c_read(device, LTC2990.V2_LSB), 15)) * (0.00001942 / 0.02),
            float(conv_n((self.ltc2990_i2c_read(device, LTC2990.V4_MSB) & 0x7F) * 256 + \
                         self.ltc2990_i2c_read(device, LTC2990.V4_LSB), 15)) * (0.00001942 / 0.02),
        ]

    def get_humidity(self):
        command = 0xF5  # RH measure no I2C block
        command = int('{:08b}'.format(command)[::-1], 2)

        self.i2c_start()
        self.i2c_write(0x1)
        self.i2c_check_ack()
        self.i2c_write(command)
        self.i2c_check_ack()
        self.i2c_stop()

        time.sleep(0.00002)

        self.i2c_start()
        self.i2c_write(0x81)

        while (not (self.i2c_check_ack(False))):
            self.i2c_stop()
            self.i2c_start()
            self.i2c_write(0x81)

        res1 = self.i2c_read()
        self.i2c_clk(0)
        res2 = self.i2c_read()
        self.i2c_clk(0)
        res3 = self.i2c_read()
        self.i2c_clk(1)
        self.i2c_stop()

        print(" ".join([hex(res1), hex(res2), hex(res3)]))

        humidity = -6.0 + (125.0 * float(res1 * 256 + (res2 & 0xFC)) / 65536.0)
        print(humidity)

    def load_jitter_cleaner(self):
        # Load from PROM
        self.set_byte(3, 2, 2)

        # Power down
        self.set_byte(2, 2, 3)

        # Disable power down, select reference 1
        self.set_byte(2, 3, 3)

    def store_jitter_cleaner(self):
        target = 0x1F

        self.set_byte(3, 2, 7)

        for i in range(0, 32):
            self.set_byte(3, (target & 1), 7)  # data
            target = (target >> 1)
            self.set_byte(3, 4, 4)  # clk

        self.set_byte(3, 2, 7)

    def setup_jitter_cleaner(self):

        # pdb = 16, refsel = 17
        # mosi = 24, le = 25, clk = 26
        # pll_lock = 33, spi miso = 32

        # Power down
        self.set_byte(2, 2, 3)

        # Disable power down, select reference 1
        self.set_byte(2, 3, 3)

        # Forward VCO to outputs 0 LVDS, 1 CMOS, 2 LVDS
        self.jitter_cleaner_spi_write(0, 0xE986032)
        self.jitter_cleaner_spi_write(1, 0x2186030)  # x40 000011
        self.jitter_cleaner_spi_write(2, 0xE986030)

        # Disable outputs 3, 4
        self.jitter_cleaner_spi_write(3, 0x6800000)
        self.jitter_cleaner_spi_write(4, 0x6800001)

        # VCO configuration for 25MHz -> 125MHz
        # Low VCO band, 1875MHz, feedback divider = 100, output prescale = 3
        # 400kHz loop filter, 3.5mA charge pump
        self.jitter_cleaner_spi_write(5, 0xF80C087)
        self.jitter_cleaner_spi_write(6, 0x3EF09A)
        self.jitter_cleaner_spi_write(7, 0xBD0035F)

        # Read a register
        for i in range(0, 9):
            print(str(i) + ': ' + str(hex(self.jitter_cleaner_spi_read(i))))

        print(self.get_byte(4) & 2)

    def jitter_cleaner_spi_write(self, addr, value):
        if addr > 8:
            raise Exception('Jitter cleaner write address greater than 8')

        target = (value << 4) | addr

        self.set_byte(3, 2, 7)

        for i in range(0, 32):
            self.set_byte(3, (target & 1), 7)  # data
            target = (target >> 1)
            self.set_byte(3, 4, 4)  # clk

        self.set_byte(3, 2, 7)

    def jitter_cleaner_spi_read(self, addr):
        if addr > 15:
            raise Exception('Jitter cleaner read address greater than 15')

        target = (addr << 4) | 0xE
        res = 0

        self.set_byte(3, 2, 7)

        for i in range(0, 32):
            self.set_byte(3, (target & 1), 7)  # data
            target = (target >> 1)
            self.set_byte(3, 4, 4)  # clk

        self.set_byte(3, 2, 7)

        for i in range(0, 32):
            self.set_byte(3, (target & 1), 7)  # data
            target = (target >> 1)
            self.set_byte(3, 4, 4)  # clk
            res = (res >> 1) | ((self.get_byte(4) & 1) << 31)

        self.set_byte(3, 2, 7)

        return (res >> 4)

    def print_monitors(self):

        self.set_byte(18, 0x10, 0x10)
        self.set_byte(18, 0, 0x10)

        # Poll done
        while True:
            v = self.get_byte(3)
            if v == 2:
                print('ERROR')
                break
            elif v == 1:
                break
            time.sleep(0.5)

        read_bytes = self.get_bytes()
        # print("[" + ", ".join(["%d" % x for x in read_bytes]) + "]")
        print_monitor_bytes(read_bytes)
