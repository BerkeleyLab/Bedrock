#!/bin/env python

from socket import *
from qsfp_info import *
import string, time, sys
from datetime import datetime, timedelta

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
	if x > (2**(n-1) - 1):
		x = x - 2**n
	return x

class interface():

        def __init__(self, target, fname = ''):

                self.host = target
                self.port = 50001
                self.uart_1_port = 50003
                self.uart_2_port = 50004
                self.WRITE_LENGTH = 63
                self.READ_LENGTH = 74

                # Embedded firmware match tag
                self.HASH = '52f7f6ef0906f3a6b76b1373d0fc1c09eb62e883f5c0e9abcaec2eeebcfc800f'
                self.BUILD_DATE = 1491930836

                # Interface socket
                self.UDPSock = socket(AF_INET,SOCK_DGRAM)
                self.UDPSock.bind(("0.0.0.0", 0))
                self.UDPSock.settimeout(2)

                # Check the firmware ID
                self.check_firmware_id()

                # Reset debug I2C pins
                self.set_byte(0, 7, 7)

        def initialize(self):

                # Possibly specific to LBNL/LCLS-II Digitizer board?
                self.kintex_vccint_enable()
                self.main_3p3v_enable()
                self.set_top_fmc_vadj_resistor(0x14)
                self.set_bottom_fmc_vadj_resistor(0x0)
                self.fmc_vadj_enable()
                self.fmc_3p3v_enable()
                self.fmc_12v_enable()
                self.kintex_1p0v_gtx_enable()
                self.kintex_1p2v_gtx_enable()

        def check_firmware_id(self):
                print 'QF2-pre Spartan-6 firmware information:'
                d = self.get_bytes()[24:72]
                d.reverse()

                print 'SHA256 bitfile hash:',
                s = str()
                for i in d[0:32]:
                        s += '{:02x}'.format(i)
                print s

                build_date = 0
                for i in range(0, 8):
                        build_date += int(d[40+i]) * 2**(56-i*8)
                print 'Build timestamp:', build_date, '('+str(datetime.utcfromtimestamp(build_date))+')'

                storage_date = 0
                for i in range(0, 8):
                        storage_date += int(d[32+i]) * 2**(56-i*8)
                print 'Storage timestamp:', storage_date, '('+str(datetime.utcfromtimestamp(storage_date))+')'

                if False and (build_date != self.BUILD_DATE):
                        raise Exception('\n\nFirmware build date ('+str(build_date)+') does not match the software build date requirement ('+str(self.BUILD_DATE)+'), please update the QF2-pre Spartan-6 firmware image.\n')

                if s != self.HASH:
                        print("\nInvalid Spartan-6 firmware for BMB7 r1.5")
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
                                self.UDPSock.sendto(str(rbytes),(self.host, self.port))
                                read_bytes = self.UDPSock.recv(self.READ_LENGTH)
                                if not read_bytes:
                                        print "No data received"
                                break
                        except KeyboardInterrupt:
                                print 'Ctrl-C detected'
                                exit(0)
                        except:
                                continue

                res = bytearray(read_bytes)
                res.reverse()
                return res

        def i2c_chain_set(self, value):
                # Reset the mux first
                self.set_byte(0, 0x3, 0x7)
                self.set_byte(0, 0x7, 0x7)

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

        def print_status(self):

                # Wait for system I2C controller to be inactive
                while True:
                        v = self.get_byte(3)
                        print 'System I2C controller:',
                        if v == 2:
                                print 'ERROR'
                                break
                        elif v == 1:
                                print 'IDLE'
                                break
                        else:
                                print 'ACTIVE'
                        time.sleep(1)



#               print 'Main +3.3V status:', self.get_main_3p3v_status()
#               print 'Main +1.8V status:', self.get_main_1p8v_status()
#               print 'Kintex +1.0V VCCINT status:', self.get_kintex_vccint_status()
#               print 'Kintex +1.0V GTX status:', self.get_kintex_1p0v_gtx_status()
#
#               print 'Boot +3.3V status:', self.get_boot_3p3v_status()
#               print 'Spartan +1.2V VCCINT status:', self.get_spartan_vccint_status()
#
#               print 'Standby +1.2V status:', self.get_standby_1p2v_status()
#
#               print 'Top FMC present:', not(self.get_n_top_fmc_present())
#               print 'Top FMC +12V status:', int(not(self.get_n_top_fmc_12v_status()))
#               print 'Top FMC +3.3V / VADJ status:', self.get_top_fmc_vadj_3p3v_status()
#               print 'Bottom FMC present:', not(self.get_n_bottom_fmc_present())
#               print 'Bottom FMC +12V status:', int(not(self.get_n_bottom_fmc_12v_status()))
#               print 'Bottom FMC +3.3V / VADJ status:', self.get_bottom_fmc_vadj_3p3v_status()
#
#               print 'S6 QSFP present:', not(self.get_n_s6_qsfp_present())

#       def get_n_fmc_3p3v_status(self):
#               return self.get_port_expander_bit(0x1, 1, 6)

#       def get_n_bottom_fmc_present(self):
#               return self.get_port_expander_bit(0x2, 0, 1)
#
#       def get_n_bottom_fmc_12v_status(self):
#               return self.get_port_expander_bit(0x1, 1, 4)
#

        def main_3p3v_enable(self):
                self.pca9534_bit_set(0x2, 0, 6, True)

        def main_3p3v_disable(self):
                self.pca9534_bit_set(0x2, 0, 6, False)

        def fmc_vadj_enable(self):
                self.pca9534_bit_set(0x2, 0, 5, True)

        def fmc_vadj_disable(self):
                self.pca9534_bit_set(0x2, 0, 5, False)
                
        def fmc_3p3v_enable(self):
                self.pca9534_bit_set(0x2, 0, 4, True)

        def fmc_3p3v_disable(self):
                self.pca9534_bit_set(0x2, 0, 4, False)

        def fmc_12v_enable(self):
                self.pca9534_bit_set(0x2, 0, 0, True)

        def fmc_12v_disable(self):
                self.pca9534_bit_set(0x2, 0, 0, False)

        def kintex_vccint_enable(self):
                self.pca9534_bit_set(0x80, 0, 1, True)

        def kintex_vccint_disable(self):
                self.pca9534_bit_set(0x80, 0, 1, False)

        def kintex_1p0v_gtx_enable(self):
                self.pca9534_bit_set(0x80, 0, 0, True)

        def kintex_1p0v_gtx_disable(self):
                self.pca9534_bit_set(0x80, 0, 0, False)

        def kintex_1p2v_gtx_enable(self):
                self.pca9534_bit_set(0x80, 0, 7, True)

        def kintex_1p2v_gtx_disable(self):
                self.pca9534_bit_set(0x80, 0, 7, False)

        def get_port_expander_bit(self, chain, address, bit):
                return ((self.pca9534_read_input(chain, address) >> bit) & 0x1)

        def pca9534_bit_set(self, chain, address, bit, state = True):
                i = 1 << bit

                # Mask out to get the correct setting
                if state:
                        self.pca9534_write(chain, address, (self.pca9534_read_output(chain, address) & ~i) | i)
                else:
                        self.pca9534_write(chain, address, (self.pca9534_read_output(chain, address) & ~i))

                self.pca9534_direction_set(chain, address, (self.pca9534_direction_get(chain, address) & ~i))
                        

        def pca9534_direction_set(self, chain, address, direction):
                self.i2c_controller_write(chain, 0x20 | address, PCA9534.DIRECTION, direction)
                return

        #address = ((0x20 | address) << 1)
        #        address = int('{:08b}'.format(address)[::-1], 2)
        #        command = int('{:08b}'.format(PCA9534.DIRECTION)[::-1], 2)
        #        direction = int('{:08b}'.format(direction)[::-1], 2)

                # Set direction bits
        #        self.i2c_start()
        #        self.i2c_write(address)
        #        self.i2c_check_ack()
        #        self.i2c_write(command)
        #        self.i2c_check_ack()
        #        self.i2c_write(direction)
        #        self.i2c_check_ack()
        #        self.i2c_stop()
                
        def pca9534_direction_get(self, chain, address):
                return self.i2c_controller_read(chain, 0x20 | address, PCA9534.DIRECTION)


        #address_r = ((0x20 | address) << 1) | 1
        #        addr = ((0x20 | address) << 1)
        #        address_r = int('{:08b}'.format(address_r)[::-1], 2)
        #        addr = int('{:08b}'.format(addr)[::-1], 2)
        #        command = int('{:08b}'.format(PCA9534.DIRECTION)[::-1], 2)

                # Set direction bits
        #        self.i2c_start()

        #        self.i2c_write(addr)
        #        self.i2c_check_ack()
        #        self.i2c_write(command)
        #        self.i2c_check_ack()
                
        #        self.i2c_repeated_start()

        #        self.i2c_write(address_r)
        #        self.i2c_check_ack()
        #        result = self.i2c_read()
        #        self.i2c_clk(1)
                
        #        self.i2c_stop()

        #        return result

        def pca9534_write(self, chain, address, value):
                self.i2c_controller_write(chain, 0x20 | address, PCA9534.OUTPUT, value)

        def pca9534_read_output(self, chain, address):
                return self.i2c_controller_read(chain, 0x20 | address, PCA9534.OUTPUT)

        def pca9534_read_input(self, chain, address):
                return self.i2c_controller_read(chain, 0x20 | address, PCA9534.INPUT)

        #address_r = ((0x20 | address) << 1) | 1
        #        addr = ((0x20 | address) << 1)
        #        address_r = int('{:08b}'.format(address_r)[::-1], 2)
        #        addr = int('{:08b}'.format(addr)[::-1], 2)
        #        command = int('{:08b}'.format(PCA9534.INPUT)[::-1], 2)
                
         #       self.i2c_start()

         #       self.i2c_write(addr)
         #       self.i2c_check_ack()
         #       self.i2c_write(command)
         #       self.i2c_check_ack()
                
         #       self.i2c_repeated_start()
                
         #       self.i2c_write(address_r)
         #       self.i2c_check_ack()
         #       result = self.i2c_read()
         #       self.i2c_clk(1)
                
         #       self.i2c_stop()
                
         #       return result

        def set_top_fmc_vadj_resistor(self, value):
                self.max5387_write(0, 2, value)

        def set_bottom_fmc_vadj_resistor(self, value):
                self.max5387_write(0, 1, value)
               
        def atsha204_wake(self):
                addr = int('{:08b}'.format(0xC8)[::-1], 2)
                addr_r = int('{:08b}'.format(0xC9)[::-1], 2)

                self.i2c_start()
                time.sleep(0.001) # Wake
                self.i2c_stop()
                self.i2c_start()
                time.sleep(0.001) # Wake
                self.i2c_stop()

                self.i2c_start()
                self.i2c_write(addr_r)
                self.i2c_check_ack()
                l =  self.i2c_read()
                self.i2c_clk(1)
                self.i2c_stop()

                if l != 4:
                        raise Exception('Failed to wake ATSHA204A')

                self.i2c_start()
                self.i2c_write(addr_r)
                self.i2c_check_ack()
                l = self.i2c_read()
                self.i2c_clk(1)
                self.i2c_stop()

                if l != 0x11:
                        raise Exception('Failed to wake ATSHA204A')

                self.i2c_start()
                self.i2c_write(addr_r)
                self.i2c_check_ack()
                l = self.i2c_read()
                self.i2c_clk(1)
                self.i2c_stop()

                if l != 0x33:
                        raise Exception('Failed to wake ATSHA204A')

                self.i2c_start()
                self.i2c_write(addr_r)
                self.i2c_check_ack()
                l = self.i2c_read()
                self.i2c_clk(1)
                self.i2c_stop()

                if l != 0x43:
                        raise Exception('Failed to wake ATSHA204A')

        def atsha204_sleep(self):
                addr = int('{:08b}'.format(0xC8)[::-1], 2)
                word = int('{:08b}'.format(0x01)[::-1], 2)

                self.i2c_start()
                self.i2c_write(addr)
                self.i2c_check_ack()
                self.i2c_write(word)
                self.i2c_check_ack()
                self.i2c_stop()

        def crc16_arc(self, data):
                generator = 0x8005
                crc = 0

                for d in data:

                        crc = crc ^ (int('{:08b}'.format(d)[::-1], 2) << 8)

                        for i in range(0, 8):
                                crc = crc << 1
                                if ( (crc & 0x10000) != 0 ):
                                        crc = (crc & 0xFFFF) ^ generator
                
                return crc

        # read 0x02
        def atsha204_cfg_read(self, radd):
                addr = int('{:08b}'.format(0xC8)[::-1], 2)
                addr_r = int('{:08b}'.format(0xC9)[::-1], 2)
                word = int('{:08b}'.format(0x03)[::-1], 2)
                count = int('{:08b}'.format(0x07)[::-1], 2)
                cmd = int('{:08b}'.format(0x02)[::-1], 2)

                crc = self.crc16_arc([0x07, 0x02, 0x00, radd, 0x00])                
                crcl = int('{:08b}'.format(crc & 0xFF)[::-1], 2)
                crch = int('{:08b}'.format(crc >> 8)[::-1], 2)

                radd = int('{:08b}'.format(radd)[::-1], 2)

                self.i2c_chain_set(0x8)
                self.atsha204_wake()

                self.i2c_start()
                self.i2c_write(addr)
                self.i2c_check_ack()
                self.i2c_write(word)
                self.i2c_check_ack()
                self.i2c_write(count) # count + crc(2) + opcode + param1 + param2(2)
                self.i2c_check_ack()
                self.i2c_write(cmd) # 0x02
                self.i2c_check_ack()
                self.i2c_write(0) # param1
                self.i2c_check_ack()
                self.i2c_write(radd) # param2 (addr)
                self.i2c_check_ack()
                self.i2c_write(0) # param2
                self.i2c_check_ack()
                self.i2c_write(crcl) # crc lsb
                self.i2c_check_ack()
                self.i2c_write(crch) # crc msb
                self.i2c_check_ack()
                self.i2c_stop()
                
                self.i2c_start()
                self.i2c_write(addr)
                self.i2c_check_ack()
                
                # wait texec (max) for read
                time.sleep(0.004)

                # Read (must be done by now)
                v = list()
                self.i2c_start()
                self.i2c_write(addr_r)
                self.i2c_check_ack()
                v.append(self.i2c_read())
                self.i2c_clk(1)
                self.i2c_stop()
                
                for i in range(1, v[0]):
                        self.i2c_start()
                        self.i2c_write(addr_r)
                        self.i2c_check_ack()
                        v.append(self.i2c_read())
                        self.i2c_clk(1)
                        self.i2c_stop()

                if (self.crc16_arc(v[0:-2]) != ((v[-1] << 8) | v[-2])):
                        raise Exception('CRC error reading ATSHA204A')

                # Put the device back to sleep
                self.atsha204_sleep()

                return v[1:5]

        def atsha204_random(self):
                addr = int('{:08b}'.format(0xC8)[::-1], 2)
                addr_r = int('{:08b}'.format(0xC9)[::-1], 2)
                word = int('{:08b}'.format(0x03)[::-1], 2)
                count = int('{:08b}'.format(0x07)[::-1], 2)
                cmd = int('{:08b}'.format(0x1B)[::-1], 2)

                crc = self.crc16_arc([0x07, 0x1B, 0x00, 0x00, 0x00])                
                crcl = int('{:08b}'.format(crc & 0xFF)[::-1], 2)
                crch = int('{:08b}'.format(crc >> 8)[::-1], 2)

                self.i2c_chain_set(0x8)
                self.atsha204_wake()

                self.i2c_start()
                self.i2c_write(addr)
                self.i2c_check_ack()
                self.i2c_write(word)
                self.i2c_check_ack()
                self.i2c_write(count) # count + crc(2) + opcode + param1 + param2(2)
                self.i2c_check_ack()
                self.i2c_write(cmd) # 0x1b
                self.i2c_check_ack()
                self.i2c_write(0) # param1
                self.i2c_check_ack()
                self.i2c_write(0) # param2
                self.i2c_check_ack()
                self.i2c_write(0) # param2
                self.i2c_check_ack()
                self.i2c_write(crcl) # crc lsb
                self.i2c_check_ack()
                self.i2c_write(crch) # crc msb
                self.i2c_check_ack()
                self.i2c_stop()
                
                # wait texec (max)
                time.sleep(0.1)

                # Read (must be done by now)
                self.i2c_start()
                self.i2c_write(addr_r)
                self.i2c_check_ack()
                l = self.i2c_read()
                self.i2c_clk(1)
                self.i2c_stop()
                
                for i in range(1, l):
                        self.i2c_start()
                        self.i2c_write(addr_r)
                        self.i2c_check_ack()
                        print hex(self.i2c_read())
                        self.i2c_clk(1)
                        self.i2c_stop()

                # Put the device back to sleep
                self.atsha204_sleep()
               
        def max5387_write(self, address, resistor, value):
                self.i2c_controller_write(0x2, 0x28 | address, 0x10 | resistor, value)
                return

                #self.i2c_chain_set(0x2)                
        #addr = ((0x28 | address) << 1)
        #        addr = int('{:08b}'.format(addr)[::-1], 2)
         #       resistor = (0x10 | resistor)
          #      resistor = int('{:08b}'.format(resistor)[::-1], 2)
           #     value = int('{:08b}'.format(value)[::-1], 2)

            #    # Set value bits
             #   self.i2c_start()
              #  self.i2c_write(addr)
               # self.i2c_check_ack()
             #   self.i2c_write(resistor)
             #   self.i2c_check_ack()
             #   self.i2c_write(value)
             #   self.i2c_check_ack()
             #   self.i2c_stop()

        def write_m24c02_prom(self, prom_address, word_address, bottom_site, value):

                if bottom_site == True:
                        self.i2c_controller_write(1, prom_address, word_address, value)
                else:
                        self.i2c_controller_write(4, prom_address, word_address, value)

                time.sleep(0.005)

                return

        #addr = (prom_address << 1)
        #        addr = int('{:08b}'.format(addr)[::-1], 2)
         #       w = int('{:08b}'.format((word_address) & 0xFF)[::-1], 2)
          #      val = int('{:08b}'.format(value)[::-1], 2)
#
 #               # Select chain
  #              if bottom_site == True:
   #                     self.i2c_chain_set(1)
 #            else:
     #                   self.i2c_chain_set(4)
#
  #              self.i2c_start()
#
  #              self.i2c_write(addr)
 #               self.i2c_check_ack()
    #            self.i2c_write(w)
   #             self.i2c_check_ack()
     #           self.i2c_write(val)
      #          self.i2c_check_ack()
#
 #               self.i2c_stop()              


        def read_m24c02_prom(self, prom_address, word_address, bottom_site):

                if bottom_site == True:
                        return self.i2c_controller_read(1, prom_address, word_address)
                else:
                        return self.i2c_controller_read(4, prom_address, word_address)

               # address_r = (prom_address << 1) | 1
               # addr = (prom_address << 1)
               # address_r = int('{:08b}'.format(address_r)[::-1], 2)
               # addr = int('{:08b}'.format(addr)[::-1], 2)
               # w = int('{:08b}'.format((word_address) & 0xFF)[::-1], 2)
                
               # # Select chain
               # if bottom_site == True:
               #         self.i2c_chain_set(1)
               # else:
               #         self.i2c_chain_set(4)
                        
               # self.i2c_start()
                        
               # self.i2c_write(addr)
               # self.i2c_check_ack()
               # self.i2c_write(w)
               # self.i2c_check_ack()

               # self.i2c_repeated_start()

        #self.i2c_write(address_r)
        #        self.i2c_check_ack()
        #        result = self.i2c_read()
        #        self.i2c_clk(1)

        #        self.i2c_stop()

#                return result

#       def write_at24c32d_prom(self, prom_address, word_address, value):
#               addr = (prom_address << 1)
#               addr = int('{:08b}'.format(addr)[::-1], 2)
#               wh = int('{:08b}'.format((word_address >> 8) & 0xFF)[::-1], 2)
#               wl = int('{:08b}'.format((word_address) & 0xFF)[::-1], 2)
#               val = int('{:08b}'.format(value)[::-1], 2)
#
#               self.fmc_i2c_start()
#
#               self.fmc_i2c_write(addr)
#               self.fmc_i2c_check_ack()
#               self.fmc_i2c_write(wh)
#               self.fmc_i2c_check_ack()
#               self.fmc_i2c_write(wl)
#               self.fmc_i2c_check_ack()
#               self.fmc_i2c_write(val)
#               self.fmc_i2c_check_ack()
#
#               self.fmc_i2c_stop()              
#
#               time.sleep(0.005)
#
        def read_at24c32d_prom(self, prom_address, word_address, bottom_site=False):
               address_r = (prom_address << 1) | 1
               addr = (prom_address << 1)
               address_r = int('{:08b}'.format(address_r)[::-1], 2)
               addr = int('{:08b}'.format(addr)[::-1], 2)
               wh = int('{:08b}'.format((word_address >> 8) & 0xFF)[::-1], 2)
               wl = int('{:08b}'.format((word_address) & 0xFF)[::-1], 2)

               if bottom_site == True:
                       self.i2c_chain_set(1)
               else:
                       self.i2c_chain_set(4)

               self.i2c_start()

               self.i2c_write(addr)
               self.i2c_check_ack()
               self.i2c_write(wh)
               self.i2c_check_ack()
               self.i2c_write(wl)
               self.i2c_check_ack()

               self.i2c_repeated_start()

               self.i2c_write(address_r)
               self.i2c_check_ack()
               result = self.i2c_read()
               self.i2c_clk(1)

               self.i2c_stop()

               return result
#
#       #def gtp_init(self):
#       #        self.write_bytes[1] = 0xE
#       #        self.send_receive()
#       #        self.write_bytes[1] = 0xC
#       #        self.send_receive()
#
#       #        time.sleep(1)
#
#       #        self.write_bytes[1] = 0x8
#       #        self.send_receive()
#       #        self.write_bytes[1] = 0
#       #        self.send_receive()
#
#       #def gtp_status(self):
#       #        self.send_receive()
#       #        print 'PLLs LOCKED:', hex(self.read_bytes[6] >> 4)
#       #        print 'RESET DONE:', hex(self.read_bytes[6] & 0xF)
#       #        print 'RX DATA CHECKER TRACKING:', hex(self.read_bytes[7] >> 4)
#       #        print 'RX BYTE IS ALIGNED:', hex(self.read_bytes[7] & 0xF)
#       #        print 'RX DATA ERROR COUNTS:', hex(self.read_bytes[140]), hex(self.read_bytes[139])
#
#       #        self.write_bytes[63] = 1
#       #        self.send_receive()
#       #        time.sleep(0.1)
#       #        self.write_bytes[63] = 0
#       #        self.send_receive()
#
#       #        print
#
#       #        for i in range(0, 16):
#       #                self.write_bytes[64] = i
#       #                self.send_receive()
#       #                self.send_receive()
#       #                print str(i) + ':', hex(self.read_bytes[145]), hex(self.read_bytes[144]), hex(self.read_bytes[143]), hex(self.read_bytes[142]), hex(self.read_bytes[141])


        def i2c_clk(self, bit):
                
                # Isolate reset bits with clock low and set data bit
                self.set_byte(0, ((bit & 1) << 1), 0x3)
                
                # Set clock high
                self.set_byte(0, 0x1, 0x1)

                # Sample bit
                result = int(self.get_byte(0) & 0x2) >> 1
               
                # Bring clock low
                self.set_byte(0, 0, 0x1)

                # Bring data low
                self.set_byte(0, 0, 0x2)
                
                return result

        def i2c_start(self):

                # Bring clock and data high
                self.set_byte(0, 0x3, 0x3)

                # Bring data low
                self.set_byte(0, 0, 0x2)

                # Bring clock low
                self.set_byte(0, 0, 0x1)

        def i2c_repeated_start(self):

                # Bring data high
                self.set_byte(0, 0x2, 0x2)

                # Bring clock high
                self.set_byte(0, 0x1, 0x1)

                # Bring data low
                self.set_byte(0, 0, 0x2)

                # Bring clock low
                self.set_byte(0, 0, 0x1)

        def i2c_stop(self):

                # Bring clock high
                self.set_byte(0, 0x1, 0x1)

                # Bring data high
                self.set_byte(0, 0x2, 0x2)
              
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

        def i2c_check_ack(self, must_ack = True):
                
                if self.i2c_clk(1) == 1:
                        if ( must_ack ):
                                raise Exception('I2C acknowledge failed')
                        else:
                                return False

                return True

#       def ltc2990_i2c_write(self, address, command, data):
#               address = 0x98 | ((address & 0x3) << 1)
#               address = int('{:08b}'.format(address)[::-1], 2)
#               command = int('{:08b}'.format(command)[::-1], 2)
#               data = int('{:08b}'.format(data)[::-1], 2)
#
#               self.i2c_start()
#
#               self.i2c_write(address)
#               self.i2c_check_ack()
#               self.i2c_write(command)
#               self.i2c_check_ack()
#               self.i2c_write(data)
#               self.i2c_check_ack()
#
#               self.i2c_stop()
#
#       def ltc2990_i2c_read(self, address, command):
#               address = 0x98 |  ((address & 0x3) << 1)
#               address_r = int(address) | 1
#               address = int('{:08b}'.format(address)[::-1], 2)
#               address_r = int('{:08b}'.format(address_r)[::-1], 2)
#               command = int('{:08b}'.format(command)[::-1], 2)
#
#               self.i2c_start()
#
#               self.i2c_write(address)
#               self.i2c_check_ack()
#               self.i2c_write(command)
#               self.i2c_check_ack()
#
#               self.i2c_repeated_start()
#
#               self.i2c_write(address_r)
#               self.i2c_check_ack()
#               result = self.i2c_read()
#               self.i2c_clk(1)
#
#               self.i2c_stop()
#
#               return result

        def kintex_qsfp_1_get(self):

                # Modsel the Kintex-7 QSFP1, disable the others
                self.pca9534_bit_set(0x80, 0, 2, True) # k7_1
                self.pca9534_bit_set(0x80, 0, 3, True) # k7_2
                self.pca9534_bit_set(0x80, 0, 4, True) # s6

                self.pca9534_bit_set(0x80, 0, 2, False) # k7_1

                # Chain is already set, query the QSFP
                return self.qsfp_get()

        def kintex_qsfp_2_get(self):

                # Modsel the Kintex-7 QSFP2, disable the others
                self.pca9534_bit_set(0x80, 0, 2, True) # k7_1
                self.pca9534_bit_set(0x80, 0, 3, True) # k7_2
                self.pca9534_bit_set(0x80, 0, 4, True) # s6

                self.pca9534_bit_set(0x80, 0, 3, False) # k7_2

                # Chain is already set, query the QSFP
                return self.qsfp_get()

        def spartan_qsfp_get(self):

                # Modsel the Spartan-6 QSFP, disable the others
                self.pca9534_bit_set(0x80, 0, 2, True) # k7_1
                self.pca9534_bit_set(0x80, 0, 3, True) # k7_2
                self.pca9534_bit_set(0x80, 0, 4, True) # s6

                self.pca9534_bit_set(0x80, 0, 4, False) # s6

                return self.qsfp_get()

        def qsfp_get(self):
                # Chain is already set, query the QSFP
                self.i2c_controller_write(0x80, 0x50, 128, 0) #self.qsfp_set(128, 0)

                result = dict()
                for i in range(0, 256):
                        #try:
                        x = self.i2c_controller_read(0x80, 0x50, i)
                        result[i] = x
                        #except:
                        #        continue

                # Lower memory
                result['IDENTIFIER'] = QSFP_INFO.IDENTIFIER.get(result[0], 'Unknown / unspecified')
                result['STATUS'] = QSFP_INFO.STATUS.get(result[2], 'Unknown / unspecified')
                for j in range(0, 4):
                        result['LOS RX' + str(j+1)] = '(' + str((result[3] >> j) & 1) + ')'
                        result['LOS TX' + str(j+1)] = '(' + str((result[3] >> j+4) & 1) + ')'
                        result['FAULT TX' + str(j+1)] = '(' + str((result[4] >> j) & 1) + ')'
                result['TEMPERATURE'] = str(float(conv_n((result[22] << 8) | result[23], 16)) / 256.0) + ' C'
                result['SUPPLY VOLTAGE'] = str(float((result[26] << 8) | result[27]) * 0.0001) + ' V'

                # Upper memory
                result['NOMINAL BIT RATE'] = str(float(result[140]) * 0.1) + ' Gb/s'
                result['SUPPORTED OM3 50um LENGTH'] = str(result[143] * 2) + ' m'
                output = str()
                for j in range(148, 164):
                        output += str(unichr(result[j]))
                result['VENDOR NAME'] = output
                result['IEEE COMPANY ID'] = '0x' + '{:06x}'.format(result[165] << 16 | result[166] << 8 | result[167])
                output = str()
                for j in range(168, 186):
                        output += str(unichr(result[j]))
                result['PART NUMBER'] = output
                result['REVISION LEVEL'] = str(unichr(result[184])) + str(unichr(result[185]))
                result['LASER WAVELENGTH'] = str(float((result[186] << 8) | result[187]) / 20.0) + ' nm'
                output = str()
                for j in range(196, 212):
                        output += str(unichr(result[j]))
                result['VENDOR SERIAL NUMBER'] = output

                return result

        def si57X_b_get(self):

                # Put SI57X_B controller in reset, with update low
                self.set_byte(10, 0x1, 0x5)

                # Release SI57X_A controller from reset
                self.set_byte(10, 0x0, 0x1)

                # Wait until done or error
                while True:
                        x = self.get_byte(16)
                        if x == 1:
                                break
                        if x == 2:
                                raise Exception('SI57X_B I2C error')

                # Read the data
                r = self.get_bytes()

                return {
                        'RFREQ' : (int(r[23]) << 32 |
                                   int(r[22]) << 24 |
                                   int(r[21]) << 16 |
                                   int(r[20]) << 8 |
                                   int(r[19])),
                        'N1' : int(r[18]),
                        'HSDIV' : int(r[17])
                        }

        def si57X_a_get(self):

                # Put SI57X_A controller in reset, with update low
                self.set_byte(2, 0x1, 0x5)

                # Release SI57X_A controller from reset
                self.set_byte(2, 0x0, 0x1)

                # Wait until done or error
                while True:
                        x = self.get_byte(8)
                        if x == 1:
                                break
                        if x == 2:
                                raise Exception('SI57X_A I2C error')

                # Read the data
                r = self.get_bytes()

                return {
                        'RFREQ' : (int(r[15]) << 32 |
                                   int(r[14]) << 24 |
                                   int(r[13]) << 16 |
                                   int(r[12]) << 8 |
                                   int(r[11])),
                        'N1' : int(r[10]),
                        'HSDIV' : int(r[9])
                        }

        def si57X_a_set(self, a):
                # Put SI57X_A controller in reset, with update high
                self.set_byte(2, 0x5, 0x5)
                
                # Load new settings
                self.set_byte(3, a['HSDIV'], 0xFF)
                self.set_byte(4, a['N1'], 0xFF)
                self.set_byte(5, a['RFREQ'] & 0xFF, 0xFF)
                self.set_byte(6, (a['RFREQ'] >> 8) & 0xFF, 0xFF)
                self.set_byte(7, (a['RFREQ'] >> 16) & 0xFF, 0xFF)
                self.set_byte(8, (a['RFREQ'] >> 24) & 0xFF, 0xFF)
                self.set_byte(9, (a['RFREQ'] >> 32) & 0xFF, 0xFF)

                # Release controller from reset
                self.set_byte(2, 0x0, 0x1)

                # Wait until done or error
                while True:
                        x = self.get_byte(8)
                        if x == 1:
                                break
                        if x == 2:
                                raise Exception('SI57X_A I2C error')

                # Verify the values
                # Read the data
                r = self.get_bytes()
                x = {
                        'RFREQ' : (int(r[15]) << 32 |
                                   int(r[14]) << 24 |
                                   int(r[13]) << 16 |
                                   int(r[12]) << 8 |
                                   int(r[11])),
                        'N1' : int(r[10]),
                        'HSDIV' : int(r[9])
                        }

                if x['HSDIV'] != a['HSDIV']:
                        raise Exception('SI57X_A frequency update failed')
                if x['N1'] != a['N1']:
                        raise Exception('SI57X_A frequency update failed')
                if x['RFREQ'] != a['RFREQ']:
                        raise Exception('SI57X_A frequency update failed')

        def si57X_a_enable(self):
                self.set_byte(2, 0x2, 0x2)

        def si57X_a_disable(self):
                self.set_byte(2, 0x0, 0x2)

        def si57X_b_enable(self):
                self.set_byte(10, 0x2, 0x2)

        def si57X_b_disable(self):
                self.set_byte(10, 0x0, 0x2)

#       def trigger_monitor_v1v2v3v4(self, device):
#               self.ltc2990_i2c_write(device, 1, 0xDF)
#               self.ltc2990_i2c_write(device, LTC2990.TRIGGER, 0)
#
#       def trigger_monitor_v1v2tr2(self, device):
#               self.ltc2990_i2c_write(device, 1, 0xD8)
#               self.ltc2990_i2c_write(device, LTC2990.TRIGGER, 0)
#
#       def trigger_monitor_dv12dv34(self, device):
#               self.ltc2990_i2c_write(device, 1, 0xDE)
#               self.ltc2990_i2c_write(device, LTC2990.TRIGGER, 0)
#
#       def get_monitor(self, device):
#
#               while self.ltc2990_i2c_read(device, LTC2990.STATUS) & 0x1:
#                       continue
#
#               #short_open1 = self.ltc2990_i2c_read(device, LTC2990.V1_MSB)
#               #short_open1 = ((short_open1 & 0x40) >> 6) | ((short_open1 & 0x20) >> 5)
#               #short_open2 = self.ltc2990_i2c_read(device, LTC2990.V3_MSB)
#               #short_open2 = ((short_open2 & 0x40) >> 6) | ((short_open2 & 0x20) >> 5)
#
#               return [
#                       (float((self.ltc2990_i2c_read(device, LTC2990.T_MSB) & 0x1F) * 256 + self.ltc2990_i2c_read(device, LTC2990.T_LSB)) * 0.0625) - 273.2,
#                       2.5 + float((self.ltc2990_i2c_read(device, LTC2990.VCC_MSB) & 0x3F) * 256 + self.ltc2990_i2c_read(device, LTC2990.VCC_LSB)) * 0.00030518,
#                       
#                       # V1V2V3V4 conversions
#                       float(conv_n((self.ltc2990_i2c_read(device, LTC2990.V1_MSB) & 0x7F) * 256 + self.ltc2990_i2c_read(device, LTC2990.V1_LSB), 15)) * 0.00030518,
#                       #float(conv_n((self.ltc2990_i2c_read(device, LTC2990.V2_MSB) & 0x7F) * 256 + self.ltc2990_i2c_read(device, LTC2990.V2_LSB), 15)) * 0.00030518,
#                       float(conv_n((self.ltc2990_i2c_read(device, LTC2990.V3_MSB) & 0x7F) * 256 + self.ltc2990_i2c_read(device, LTC2990.V3_LSB), 15)) * 0.00030518,
#                       #float(conv_n((self.ltc2990_i2c_read(device, LTC2990.V4_MSB) & 0x7F) * 256 + self.ltc2990_i2c_read(device, LTC2990.V4_LSB), 15)) * 0.00030518,
#
#                       # TR2 conversions
#                       (float((self.ltc2990_i2c_read(device, LTC2990.V4_MSB) & 0x1F) * 256 + self.ltc2990_i2c_read(device, LTC2990.V4_LSB)) * 0.0625) - 273.2,
#                       0, #short_open1,
#                       (float((self.ltc2990_i2c_read(device, LTC2990.V4_MSB) & 0x1F) * 256 + self.ltc2990_i2c_read(device, LTC2990.V4_LSB)) * 0.0625) - 273.2, # * 1.004 * 2.3 / 2.0) - (273.2 / (1.004 * 3.0 * (2.3 / 2.0))),
#                       0, #short_open2,
#
#                       # Current conversions                        
#                       float(conv_n((self.ltc2990_i2c_read(device, LTC2990.V2_MSB) & 0x7F) * 256 + self.ltc2990_i2c_read(device, LTC2990.V2_LSB), 15)) * (0.00001942 / 0.02),
#                       float(conv_n((self.ltc2990_i2c_read(device, LTC2990.V4_MSB) & 0x7F) * 256 + self.ltc2990_i2c_read(device, LTC2990.V4_LSB), 15)) * (0.00001942 / 0.02),
#
#                       ]
#               
#       def get_humidity(self):
#               command = 0xF5 # RH measure no I2C block
#               command = int('{:08b}'.format(command)[::-1], 2)
#
#               self.i2c_start()
#               self.i2c_write(0x1)
#               self.i2c_check_ack()
#               self.i2c_write(command)
#               self.i2c_check_ack()
#               self.i2c_stop()
#
#               time.sleep(0.00002)
#
#               self.i2c_start()
#               self.i2c_write(0x81)
#
#               while (not(self.i2c_check_ack(False))):
#                       self.i2c_stop()
#                       self.i2c_start()
#                       self.i2c_write(0x81)
#                       
#               res1 = self.i2c_read()
#               self.i2c_clk(0)
#               res2 = self.i2c_read()
#               self.i2c_clk(0)
#               res3 = self.i2c_read()
#               self.i2c_clk(1)
#               self.i2c_stop()
#
#               print hex(res1), hex(res2), hex(res3)
#
#               humidity = -6.0 + (125.0 * float(res1 * 256 + (res2 & 0xFC)) / 65536.0)
#               print humidity
#

        #def read_ina226(self, address):

        def write_8b_adc128d818(self, chain, address, value):
                addr = (0x1D << 1)
                addr_r = (0x1D << 1) | 1
                addr = int('{:08b}'.format(addr)[::-1], 2)
                addr_r = int('{:08b}'.format(addr_r)[::-1], 2)
                w = int('{:08b}'.format((address) & 0xFF)[::-1], 2)
                v = int('{:08b}'.format((value) & 0xFF)[::-1], 2)

                self.i2c_chain_set(chain)

                self.i2c_start()

                self.i2c_write(addr)
                self.i2c_check_ack()
                self.i2c_write(w)
                self.i2c_check_ack()
                self.i2c_write(v)
                self.i2c_check_ack()

                self.i2c_stop()             

        def read_8b_adc128d818(self, chain, address):
                addr = (0x1D << 1)
                addr_r = (0x1D << 1) | 1
                addr = int('{:08b}'.format(addr)[::-1], 2)
                addr_r = int('{:08b}'.format(addr_r)[::-1], 2)
                w = int('{:08b}'.format((address) & 0xFF)[::-1], 2)

                self.i2c_chain_set(chain)

                self.i2c_start()

                self.i2c_write(addr)
                self.i2c_check_ack()
                self.i2c_write(w)
                self.i2c_check_ack()
                
                self.i2c_repeated_start()

                self.i2c_write(addr_r)
                self.i2c_check_ack()
                result = self.i2c_read()
                self.i2c_clk(1)

                self.i2c_stop()             

                return result

        def read_16b_adc128d818(self, chain, address):
                addr = (0x1D << 1)
                addr_r = (0x1D << 1) | 1
                addr = int('{:08b}'.format(addr)[::-1], 2)
                addr_r = int('{:08b}'.format(addr_r)[::-1], 2)
                w = int('{:08b}'.format((address) & 0xFF)[::-1], 2)

                self.i2c_chain_set(chain)

                self.i2c_start()

                self.i2c_write(addr)
                self.i2c_check_ack()
                self.i2c_write(w)
                self.i2c_check_ack()
                
                self.i2c_repeated_start()

                self.i2c_write(addr_r)
                self.i2c_check_ack()
                result = self.i2c_read()
                self.i2c_clk(0)
                result = (result << 8) | self.i2c_read()
                self.i2c_clk(1)

                self.i2c_stop()             

                return (2.56 * float(result) / 65536.0)

        def read_adc128d818_values(self, chain):
                
                #print self.read_8b_adc128d818(chain, 0x3E) # Manufacturer ID (0x1)
                #print self.read_8b_adc128d818(chain, 0x3F) # Revision ID (0x9)

                # Check device ready
                while True:
                        if self.i2c_controller_read(chain, 0x1D, 0xC) == 0:
                                break
                        time.sleep(0.01)

                #self.write_8b_adc128d818(chain, 0xB, 2) # Advanced configuration
                self.i2c_controller_write(chain, 0x1D, 0xB, 2)

                #self.write_8b_adc128d818(chain, 0x9, 1) # One-shot
                self.i2c_controller_write(chain, 0x1D, 0x9, 1)
                
                # Check device ready
                while True:
                        #if self.read_8b_adc128d818(chain, 0xC) == 0:
                        #        break
                        if self.i2c_controller_read(chain, 0x1D, 0xC) == 0:
                                break
                        time.sleep(0.01)

                results = list()
                for i in range(0x20, 0x28):
                        results.append(2.56 * float(self.i2c_controller_read(chain, 0x1D, i, True)) / 65536.0)
                        #results.append(self.read_16b_adc128d818(chain, i))

                return results

        def write_16b_ina226(self, chain, device, address, value):
                d = int('{:08b}'.format((0x40 | device) << 1)[::-1], 2)
                a = int('{:08b}'.format((address) & 0xFF)[::-1], 2)
                msb = int('{:08b}'.format((value >> 8) & 0xFF)[::-1], 2)
                lsb = int('{:08b}'.format(value & 0xFF)[::-1], 2)

                self.i2c_chain_set(chain)

                self.i2c_start()

                self.i2c_write(d)
                self.i2c_check_ack()
                self.i2c_write(a)
                self.i2c_check_ack()
                self.i2c_write(msb)
                self.i2c_check_ack()
                self.i2c_write(lsb)
                self.i2c_check_ack()

                self.i2c_stop()             

        def read_16b_ina226(self, chain, device, address):
                d = int('{:08b}'.format((0x40 | device) << 1)[::-1], 2)
                d_r = int('{:08b}'.format(((0x40 | device) << 1) | 1)[::-1], 2)
                a = int('{:08b}'.format((address) & 0xFF)[::-1], 2)

                self.i2c_chain_set(chain)

                self.i2c_start()

                self.i2c_write(d)
                self.i2c_check_ack()
                self.i2c_write(a)
                self.i2c_check_ack()

                self.i2c_repeated_start()

                self.i2c_write(d_r)
                self.i2c_check_ack()
                result = self.i2c_read()
                self.i2c_clk(0)
                result = (result << 8) | self.i2c_read()
                self.i2c_clk(1)

                self.i2c_stop()             

                return result

        def read_ina226_values(self):

                # Chip IDs
                #print hex(self.read_16b_ina226(0x2, 0, 0xFE)) # +3.3V_MAIN
                ##print hex(self.read_16b_ina226(0x2, 1, 0xFE)) # +3.3V_FMC
                ##print hex(self.read_16b_ina226(0x2, 2, 0xFE)) # +12V_FMC
                ##print hex(self.read_16b_ina226(0x2, 3, 0xFE)) # VADJ
                ##print hex(self.read_16b_ina226(0x40, 0, 0xFE)) # +3.3V_BOOT
                ##print hex(self.read_16b_ina226(0x40, 1, 0xFE)) # +1.0V_K7_VCCINT
                ##print hex(self.read_16b_ina226(0x40, 2, 0xFE)) # +1.8V_K7_VCCAUX
                ##print hex(self.read_16b_ina226(0x40, 3, 0xFE)) # +1.0V_K7_GTX
                ##print hex(self.read_16b_ina226(0x40, 4, 0xFE)) # +1.2V_BOOT
                ##print hex(self.read_16b_ina226(0x40, 5, 0xFE)) # +12V

                # Bus voltages
                #for i in range(0, 4):
                #        print  float(self.read_16b_ina226(0x2, i, 0x2)) * 0.00125
                #for i in range(0, 6):
                #        print float(self.read_16b_ina226(0x40, i, 0x2)) * 0.00125

                # Change to average of 64 samples

                results = list()
                for i in range(0, 4):
                        self.i2c_controller_write(0x2, 0x40|i, 0x0, 0x4727, True) # write_16b_ina226(0x2, i, 0x0, 0x4727)
                        r = self.i2c_controller_read(0x2, 0x40|i, 0x1, True) #self.read_16b_ina226(0x2, i, 0x1)
                        if ( r & 0x8000 != 0 ):
                                results.append(0.0)
                                results.append(0.0)
                        else:
                                results.append(float(self.i2c_controller_read(0x2, 0x40|i, 0x1, True)) * 0.0000025)
                                results.append(float(self.i2c_controller_read(0x2, 0x40|i, 0x2, True)) * 0.00125 * results[-1])
                                #results.append(float(self.read_16b_ina226(0x2, i, 0x1)) * 0.0000025)
                                #results.append(float(self.read_16b_ina226(0x2, i, 0x2)) * 0.00125 * results[-1])
                                
                for i in range(0, 6):
                        #if i == 1:
                        #        results.append(0.0)
                        #        results.append(0.0)
                        #        continue

                        self.i2c_controller_write(0x40, 0x40|i, 0x0, 0x4727, True) # write_16b_ina226(0x2, i, 0x0, 0x4727)
                        r = self.i2c_controller_read(0x40, 0x40|i, 0x1, True) #self.read_16b_ina226(0x2, i, 0x1)
                        #self.write_16b_ina226(0x40, i, 0x0, 0x4727)
                        if ( r & 0x8000 != 0 ):
                                results.append(0.0)
                                results.append(0.0)
                        else:
                                results.append(float(self.i2c_controller_read(0x40, 0x40|i, 0x1, True)) * 0.0000025)
                                results.append(float(self.i2c_controller_read(0x40, 0x40|i, 0x2, True)) * 0.00125 * results[-1])

                return results

        def i2c_controller_read(self, chain, address, register, read_16b=False):
                
                # Reset controller, 8b, read
                if read_16b:
                        self.set_byte(18, 7, 7)
                else:
                        self.set_byte(18, 5, 7)
        
                # Chain
                self.set_byte(19, chain, 0xFF)
                
                # Slave address
                self.set_byte(20, address<<1, 0xFF)
                
                # Register address
                self.set_byte(21, register, 0xFF)

                # Start controller, 8b, read
                self.set_byte(18, 0, 1)

                # Wait for done or error
                while True:
                        x = self.get_byte(2)
                        if x != 0:
                                break
                        
                if x == 2:
                        raise Exception('I2C acknowledge failed')

                if read_16b:
                        x = self.get_bytes()
                        return ((int(x[73]) << 8) | int(x[72]))
                
                return int(self.get_byte(72))

        def i2c_controller_write(self, chain, address, register, data, write_16b=False):
                
                # Reset controller, write
                if write_16b:
                        self.set_byte(18, 3, 7)
                else:
                        self.set_byte(18, 1, 7)
        
                # Chain
                self.set_byte(19, chain, 0xFF)
                
                # Slave address
                self.set_byte(20, address<<1, 0xFF)
                
                # Register address
                self.set_byte(21, register, 0xFF)

                # Write data LSB
                self.set_byte(22, data & 0xFF, 0xFF)

                # Write data MSB
                self.set_byte(23, (data >> 8) & 0xFF, 0xFF)

                # Start transaction
                self.set_byte(18, 0, 1)

                # Wait for done or error
                while True:
                        x = self.get_byte(2)
                        if x != 0:
                                break
                        
                if x == 2:
                        raise Exception('I2C acknowledge failed')

        def read_tmp461_value(self):
                
                local_temperature = float(self.i2c_controller_read(0x2, 0x48, 0x0))
                local_temperature = local_temperature + (float(self.i2c_controller_read(0x2, 0x48, 0x15) >> 4) * 0.0625)

                remote_temperature = float(self.i2c_controller_read(0x2, 0x48, 0x1))
                remote_temperature = remote_temperature + (float(self.i2c_controller_read(0x2, 0x48, 0x10) >> 4) * 0.0625)

                return [local_temperature, remote_temperature]

        def print_monitors(self):

                # TODO: Fix two's complement calculations
                # TODO: Check sense resistor values

                x = self.read_adc128d818_values(0x2)
                y = self.read_adc128d818_values(0x40)
                z = self.read_ina226_values()
                t = self.read_tmp461_value()

                print
                print '+12V:', (11.0 * y[0]), 'V', (z[18] / 0.004), 'A', (z[19] / 0.004), 'W'
                print

                print '+3.3V_BOOT:', (2.0 * y[7]), 'V', (z[8] / 0.01), 'A', (z[9] / 0.01), 'W'
                print '+1.2V_BOOT:', y[1], 'V', (z[16] / 0.01), 'A', (z[17] / 0.01), 'W'
                print

                print '+1.0V_K7_VCCINT:', y[3], 'V', (z[10] / 0.004), 'A', (z[11] / 0.004), 'W'
                print '+1.8V_K7_VCCAUX:', y[2], 'V', (z[12] / 0.01), 'A', (z[13] / 0.01), 'W'
                print 'K7_MGTAVTT:', y[4], 'V'
                print 'K7_MGTAVCC:', y[5], 'V', (z[14] / 0.01), 'A', (z[15] / 0.01), 'W'
                print 'K7_MGTAVCCAUX:', y[6], 'V'
                print '+2.5V_K7_A;', (2.0 * x[6]), 'V'
                print '+2.5V_K7_B:', (2.0 * x[7]), 'V'
                print '+3.3V_MAIN:', (2.0 * x[5]), 'V', (z[0] / 0.004), 'A', (z[1] / 0.004), 'W'
                print

                print '+12V_FMC:', (11.0 * x[2]), 'V', (z[4] / 0.01), 'A', (z[5] / 0.01), 'W'
                print '+3.3V_FMC:', (2.0 * x[1]), 'V', (z[2] / 0.004), 'A', (z[3] / 0.004), 'W'
                print 'VADJ_FMC_TOP:', (2.0 * x[0]), 'V'
                print 'VADJ_FMC_BOT:', x[3], 'V'
                print 'VADJ SUPPLY:', (z[6] / 0.01), 'A', (z[7] / 0.01), 'W'

                print
                print 'LTM4628 TEMPERATURE:', (150.0 - ((x[4] - 0.2) / 0.0023)), 'C'
                print 'TMP461 TEMPERATURE:', t[0], 'C'
                print 'Kintex-7 TEMPERATURE:', t[1], 'C'
