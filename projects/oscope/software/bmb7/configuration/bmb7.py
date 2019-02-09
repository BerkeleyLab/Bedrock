#!/bin/env python
from __future__ import absolute_import

from socket import *
import string
import argparse
import time
import sys
import sys
import time
from bmb7.configuration.jtag import jtag, xilinx_bitfile_parser, xilinx_virtex_5, xilinx_spartan_6, xilinx_kintex_7, xilinx_virtex_7
from bmb7.configuration.spi import spi

class c_bmb7(object):

    def __init__(self, host, reset=False, readdress=False):
        print(host)
        self.host = host
        self.chain = None
        # self.init_chain()
        if reset:
            self.reset(host)

    def init_chain(self):
        self.chain = jtag.chain(ip=self.host, stream_port=50005, input_select=1, speed=0)
        n = self.chain.num_devices()
        print('There are {} devices in the chain:'.format(n))
        for i in range(0, self.chain.num_devices()):
            ei = self.chain.idcode(i)
            en = self.chain.idcode_resolve_name(self.chain.idcode(i))
            print(hex(ei) + ' - ' + en)
        print('')

    def reset(self, host):
        #		self.spartan_power_cycle()
        # self.spartan_power_all_enabled()
        pass

    def spartan_power_all_enabled(self):

        self.spartan.kintex_vccint_enable()
        self.spartan.main_1p8v_enable()
        self.spartan.main_3p3v_enable()

# GTX
        self.spartan.spartan_1p2v_gtx_enable()
        self.spartan.kintex_1p2v_gtx_enable()
        self.spartan.kintex_1p0v_gtx_enable()
        self.spartan.kintex_1p8v_gtx_enable()

# FMC
        self.spartan.set_bottom_fmc_3p3v_resistor(0x0)
        self.spartan.set_top_fmc_3p3v_resistor(0x0)
        self.spartan.set_bottom_fmc_vadj_resistor(0x0)
        self.spartan.set_top_fmc_vadj_resistor(0x0B)  # 2.5V instead of 3.3V

        self.spartan.fmc_top_12v_enable()
        self.spartan.fmc_bot_12v_enable()

        self.spartan.fmc_top_vadj_enable()
        self.spartan.fmc_bot_vadj_enable()
        self.spartan.fmc_top_3p3v_enable()
        self.spartan.fmc_bot_3p3v_enable()

    def program_kintex_7(self, bitfilepath):
        # Parse the bitfile and resolve the part type
        print('Loading bitfile: ' + bitfilepath)
        bitfile = xilinx_bitfile_parser.bitfile(bitfilepath)

        print('Design name: ' + bitfile.design_name())
        print('Device name: ' + str(bitfile.device_name()))
        print('Build date: ' + bitfile.build_date())
        print('Build time: ' + bitfile.build_time())
        print('Length: ' + str(bitfile.length()) + ' bits')

        print('')

        if self.chain is None:
            self.init_chain()
        matching_devices = list()
        for i in range(0, self.chain.num_devices()):
            if bitfile.match_idcode(self.chain.idcode(i)):
                matching_devices.append(i)

        if len(matching_devices) == 0:
            print('No devices matching bitfile found in JTAG chain')
            exit()

        # Default to first (and only) entry
        device_choice = matching_devices[0]

        # Override choice from argument line if there's more than one device
        # if len(matching_devices) > 1:
        #     if not device_choices:
        #         print('More than one matching FPGA in device chain - you must add a chain ID to the arguments')
        #         exit()

        #     choice_made = False
        #     for i in matching_devices:
        #         if i == int(device_choices):
        #             device_choice = i
        #             choice_made = True

        #     if choice_made == False:
        #         print('No matching device selection found that corresponds to JTAG chain')
        #         exit()
        # else:
        print('Defaulting device selection in chain from IDCODE')

        print('Device selected for programming is in chain location: ' + str(device_choice))

        if str('Xilinx Virtex 5') in self.chain.idcode_resolve_name(self.chain.idcode(device_choice)):
            print('Xilinx Virtex 5 interface selected')
            interface = xilinx_virtex_5.interface(self.chain)
        elif str('Xilinx Spartan 6') in self.chain.idcode_resolve_name(self.chain.idcode(device_choice)):
            print('Xilinx Spartan 6 interface selected')
            interface = xilinx_spartan_6.interface(self.chain)
        elif str('Xilinx Kintex 7') in self.chain.idcode_resolve_name(self.chain.idcode(device_choice)):
            print('Xilinx Kintex 7 interface selected')
            interface = xilinx_kintex_7.interface(self.chain)
        elif str('Xilinx Virtex 7') in self.chain.idcode_resolve_name(self.chain.idcode(device_choice)):
            print('Xilinx Virtex 7 interface selected')
            interface = xilinx_virtex_7.interface(self.chain)
        else:
            print('Not able to program this device')
            exit()

        print('Programming...')
        print('')

# Load the bitfile
        interface.program(bitfile.data(), device_choice)

    def spartan_power_cycle(self):
        # FMC
        self.spartan.fmc_top_12v_disable()
        self.spartan.fmc_bot_12v_disable()
        self.spartan.fmc_top_vadj_disable()
        self.spartan.fmc_bot_vadj_disable()
        self.spartan.fmc_top_3p3v_disable()
        self.spartan.fmc_bot_3p3v_disable()

        time.sleep(1.5)
        self.spartan.fmc_top_12v_enable()
        self.spartan.fmc_bot_12v_enable()
        self.spartan.fmc_top_vadj_enable()
        self.spartan.fmc_bot_vadj_enable()
        self.spartan.fmc_top_3p3v_enable()
        self.spartan.fmc_bot_3p3v_enable()

    def fletcher(self, data):

        sum1 = 0xAA
        sum2 = 0x55

        for i in data:
            sum1 = sum1 + int(i)
            sum2 = sum1 + sum2

        sum1 = sum1 % 255
        sum2 = sum2 % 255

        return bytearray([sum1, sum2])

    def fletcher_check(self, data):

        v = self.fletcher(data)

        sum1 = 0xFF - ((int(v[0]) + int(v[1])) % 255)
        sum2 = 0xFF - ((int(v[0]) + sum1) % 255)

        return bytearray([sum1, sum2])

    def program_spartan_6_configuration(self, boardmac, new_boardaddr, current_boardaddr="192.168.1.127", sha256=None):

        print('start program_spartan_6_configuration')
        CONFIG_ADDRESS = 23 * 65536
# Initialise the interface to the PROM
        # jtag.chain(ip=current_boardaddr, stream_port=50005, input_select=0, speed=0, noinit=True))
        prom = spi.interface(self.chain)

# Read the VCR and VECR
        print('PROM ID (0x20BA, Capacity=0x19, EDID+CFD length=0x10, EDID (2 bytes), CFD (14 bytes)')

        print('VCR (should be 0xfb by default): ' + str(hex(prom.read_register(spi.RDVCR, 1)[0])))
        print('VECR (should be 0xdf): ', str(hex(prom.read_register(spi.RDVECR, 1)[0])))

        if prom.prom_size() != 25:
            print('PROM size incorrect, read ' + str(prom.prom_size()))
            exit()

        print('PROM size: 256Mb == 500 x 64KB blocks')

        print('Programming Spartan-6 configuration settings')

        pd = prom.read_data(CONFIG_ADDRESS, 87)

        x = bytearray(85)
        x = pd[0:85]

# Multicast MAC
        x[0] = 0x01
        x[1] = 0x00
        x[2] = 0x5E
        x[3] = 0x73
        x[4] = 0x47
        x[5] = 0x01

# Multicast IP
        x[6] = 0xE0
        x[7] = 0xF3
        x[8] = 0x47
        x[9] = 0x01

# Multicast port
        x[10] = 0x04
        x[11] = 0xEC

# Board MAC
        if (boardmac != None):
            mac = boardmac.split(':')
            if (len(mac) != 6):
                print('Bad board MAC address')
                sys.exit(1)
            for i in range(0, 6):
                x[12+i] = int(mac[i], 16)

# Board IP
        if (new_boardaddr != None):
            board = new_boardaddr.split('.')
            if (len(board) != 4):
                print('Bad board IP address')
                sys.exit(1)
            for i in range(0, 4):
                x[18+i] = int(board[i], 10)

# SHA256 for Kintex-7 bitstream
        if (sha256 != None):
            hash = sha256.split(' ')
            if (len(hash) != 32):
                print('Bad Kintex7 hash')
                sys.exit(1)
            for i in range(0, 32):
                x[i+22] = int(hash[i], 16)

        x[61] = 0x00
        x[62] = 0x01
        x[63] = 0x3F
        x[64] = 0x01
        x[65] = 0x00
        x[66] = 0x0E
        x[67] = 0x02
        x[68] = 0xBB

        x[69] = 0xEA
        x[70] = 0xD4
        x[71] = 0x9B
        x[72] = 0x03
        x[73] = 0x00
        x[74] = 0x04
        x[75] = 0x01
        x[76] = 0xB2

        x[77] = 0x01
        x[78] = 0xB2
        x[79] = 0x7F
        x[80] = 0xFF
        x[81] = 0xFF
        x[82] = 0xFF
        x[83] = 0x01  # [0] == POWER BURST MODE ENABLE
        x[84] = 0xFF

        v = self.fletcher_check(x)
        x += v

# for i in x:
#    print hex(i),
# print

        if (x == pd):
            print('Values already programmed')
            exit()

        x += bytearray(256 - len(x))

        prom.subsector_erase(CONFIG_ADDRESS)
        prom.page_program(x, CONFIG_ADDRESS)

        pd = prom.read_data(CONFIG_ADDRESS, 87)

        if (x[0:87] != pd):
            print('Update failed')


if __name__ == "__main__":
    readdress = True
    if readdress:
        parser = argparse.ArgumentParser(description='Write BMB-7 Spartan6 flash memory.',
                                         formatter_class=argparse.ArgumentDefaultsHelpFormatter)
        parser.add_argument('-a', '--addr', default='192.168.1.127', help='IP address of board')
        parser.add_argument('-b', '--board', help='New IP address to be written into flash')
        parser.add_argument('-m', '--mac', help='New MAC address to be written into flash')
        parser.add_argument('-s', '--hash', help='New Kintex7 bootstrap SHA256 hash')
        args = parser.parse_args()
        carrier = c_bmb7(args.addr, readdress=True)
        carrier.program_spartan_6_configuration(boardmac=args.mac, new_boardaddr=args.board,
                                                current_boardaddr=args.addr, sha256=args.hash)
    else:
        ip = "192.168.21.11"
        bitfilepath = "../prc.bit"
        device_choice = None
        if (len(sys.argv) > 1):
            ip = sys.argv[1]
        if (len(sys.argv) > 2):
            bitfilepath = sys.argv[2]
        if (len(sys.argv) > 3):
            device_choice = sys.argv[3]

        carrier = c_bmb7(ip)
        carrier.spartan_power_cycle()
        carrier.spartan_power_all_enabled()
        carrier.program_direct_kintex_7(bitfilepath=bitfilepath, device_choices=None)
