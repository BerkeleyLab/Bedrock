#!/usr/bin/env python

import os
import sys

sys.path.append(
    os.path.join(os.path.dirname(__file__), "../submodules/qf2_pre"))
from qf2_python.configuration.jtag import xilinx_kintex_7, xilinx_virtex_5, xilinx_virtex_7
from qf2_python.configuration.jtag import xilinx_spartan_6, jtag, xilinx_bitfile_parser


class c_qf2(object):
    def __init__(self, ip, reset=False, readdress=False):
        self.ip = ip
        self.sequencer_port = 50003

        self.chain = jtag.chain(
            ip=self.ip,
            stream_port=self.sequencer_port,
            input_select=1,
            speed=0)

        if reset:
            self.reset(self.ip)

    def reset(self, host):
        # Nothing here for now, can be used to propagate reset functions down to this level
        pass

    def program_kintex_7(self, bitfilepath):

        # Initialize the chain control
        print('There are {} devices in the chain:'.format(
            self.chain.num_devices()))

        print()
        for i in range(0, self.chain.num_devices()):
            print(hex(self.chain.idcode(i)) + ' - ' +
                  self.chain.idcode_resolve_name(self.chain.idcode(i)))
        print()

        # Parse the bitfile and resolve the part type
        print('Loading bitfile: {}'.format(bitfilepath))
        bitfile = xilinx_bitfile_parser.bitfile(bitfilepath)

        print('Design name:', bitfile.design_name())
        print('Device name:', bitfile.device_name())
        print('Build date:', bitfile.build_date())
        print('Build time:', bitfile.build_time())
        print('Length:', bitfile.length(), 'bits')

        print()

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
        #        if len(sys.argv) < 4:
        #                print 'More than one matching FPGA in device chain - you must add a chain ID to the arguments'
        #                exit()

        #        choice_made = False
        #        for i in matching_devices:
        #                if i == int(sys.argv[3]):
        #                        device_choice = i
        #                        choice_made = True

        #        if choice_made == False:
        #                print 'No matching device selection found that corresponds to JTAG chain'
        #                exit()
        # else:
        print('Defaulting device selection in chain from IDCODE')

        print('Device selected for programming is in chain location:',
              str(device_choice))

        if str('Xilinx Virtex 5') in self.chain.idcode_resolve_name(
                self.chain.idcode(device_choice)):
            print('Xilinx Virtex 5 interface selected')
            interface = xilinx_virtex_5.interface(self.chain)
        elif str('Xilinx Spartan 6') in self.chain.idcode_resolve_name(
                self.chain.idcode(device_choice)):
            print('Xilinx Spartan 6 interface selected')
            interface = xilinx_spartan_6.interface(self.chain)
        elif str('Xilinx Kintex 7') in self.chain.idcode_resolve_name(
                self.chain.idcode(device_choice)):
            print('Xilinx Kintex 7 interface selected')
            interface = xilinx_kintex_7.interface(self.chain)
        elif str('Xilinx Virtex 7') in self.chain.idcode_resolve_name(
                self.chain.idcode(device_choice)):
            print('Xilinx Virtex 7 interface selected')
            interface = xilinx_virtex_7.interface(self.chain)
        else:
            print('Not able to program this device')
            exit()

        print('Programming...')
        print()

        # Load the bitfile
        interface.program(bitfile.data(), device_choice)
